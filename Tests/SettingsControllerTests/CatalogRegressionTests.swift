import XCTest
import Foundation
import UIKit
@testable import SettingsController

@MainActor
final class CatalogRegressionTests: XCTestCase {
    func testNonpositiveLimitsHideSectionAndNeverFetch() async {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [
            SettingsSection(kind: .ourApps(developerID: "dev", limit: -1, excludeAppID: "1")),
            SettingsSection(kind: .ourApps(developerID: "dev", limit: 0, excludeAppID: "1")),
            SettingsSection(kind: .rows([.defaultRow(.language)]))
        ]))
        settings.fetchApps = { _, _, _ in XCTFail("Should not fetch"); return [] }
        settings.loadViewIfNeeded()
        XCTAssertEqual(settings.visibleSectionIDs, [2])
        XCTAssertTrue(settings.appLoadTasks.isEmpty)
        let session = fixtureSession()
        let result = try? await AppStoreAppsLoader.fetch(developerId: "dev", limit: -10, session: session)
        XCTAssertEqual(result, [])
        session.invalidateAndCancel()
    }

    func testEmptyEarlierSectionDoesNotRedirectLaterResult() async throws {
        let first = ControlledValue<[AppItem]>(), second = ControlledValue<[AppItem]>()
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [
            SettingsSection(kind: .ourApps(developerID: "first", limit: 1, excludeAppID: "0")),
            SettingsSection(kind: .ourApps(developerID: "second", limit: 1, excludeAppID: "0"))
        ]))
        settings.fetchApps = { developer, _, _ in try await (developer == "first" ? first : second).value() }
        settings.loadViewIfNeeded()
        let a = try XCTUnwrap(settings.appLoadTasks[0]), b = try XCTUnwrap(settings.appLoadTasks[1])
        await first.waitUntilStarted()
        await second.waitUntilStarted()
        first.complete(.success([]))
        await a.value
        XCTAssertEqual(settings.visibleSectionIDs, [1])
        let item = AppItem(id: 2, name: "Second", iconURL: URL(string: "https://example.com/i.png")!, storeURL: URL(string: "https://apps.apple.com/app/id2")!)
        second.complete(.success([item]))
        await b.value
        XCTAssertEqual(settings.catalogStates[1], .loaded([item]))
        XCTAssertEqual(settings.visibleSectionIDs, [1])
        guard case .rows(let rows) = settings.sections[0].kind,
              case .app(.loaded(let rendered)) = rows[0] else { return XCTFail("Expected the second catalog") }
        XCTAssertEqual(rendered.id, 2)
    }

    func testFailureRetryPreservesOriginalSource() async throws {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [
            SettingsSection(kind: .ourApps(developerID: "original", limit: 3, excludeAppID: "exclude"))
        ]))
        let recorder = CatalogRecorder()
        settings.fetchApps = { developer, limit, excluded in
            await recorder.record(developer, limit, excluded)
            throw URLError(.notConnectedToInternet)
        }
        settings.loadViewIfNeeded()
        await settings.appLoadTasks[0]?.value
        XCTAssertEqual(settings.catalogStates[0], .failed)
        settings.tableView(settings.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        await settings.appLoadTasks[0]?.value
        let values = await recorder.values
        XCTAssertEqual(values, ["original:3:exclude", "original:3:exclude"])
        XCTAssertEqual(settings.catalogStates[0], .failed)
    }

    func testLoaderFiltersMalformedRowsExcludesCurrentAppAndLimits() async throws {
        let developer = UUID().uuidString
        let url = lookupURL(developer)
        let json = #"{"results":[{"kind":"artist"},{"kind":"software","trackId":1,"trackName":"Current","artworkUrl100":"https://example.com/1.png","trackViewUrl":"https://apps.apple.com/app/id1"},{"kind":"software","trackId":2,"trackName":"Second","artworkUrl100":"https://example.com/2.png","trackViewUrl":"https://apps.apple.com/app/id2"},{"kind":"software","trackId":3,"trackName":"Bad","artworkUrl100":"file:///tmp/a","trackViewUrl":"https://apps.apple.com/app/id3"},{"kind":"software","trackId":4,"trackName":"Fourth","artworkUrl100":"https://example.com/4.png","trackViewUrl":"https://apps.apple.com/app/id4"}]}"#
        await FixtureServer.shared.register(url, data: Data(json.utf8))
        let session = fixtureSession()
        defer { session.invalidateAndCancel() }
        let apps = try await AppStoreAppsLoader.fetch(developerId: developer, limit: 1, excludeAppID: "1", session: session)
        XCTAssertEqual(apps.map(\.id), [2])
        let request = await FixtureServer.shared.lastRequest(url)
        XCTAssertEqual(request?.cachePolicy, .useProtocolCachePolicy)
    }

    func testLoaderHTTPAndDecodingFailures() async {
        let session = fixtureSession()
        defer { session.invalidateAndCancel() }
        for status in [500, 200] {
            let developer = UUID().uuidString
            await FixtureServer.shared.register(lookupURL(developer), data: Data("not json".utf8), status: status)
            do {
                _ = try await AppStoreAppsLoader.fetch(developerId: developer, limit: 1, session: session)
                XCTFail("Expected failure")
            } catch {
                if status == 500 { XCTAssertEqual((error as? URLError)?.code, .badServerResponse) }
                else { XCTAssertTrue(error is DecodingError) }
            }
        }
    }
}

private actor CatalogRecorder {
    private(set) var values: [String] = []
    func record(_ developer: String, _ limit: Int, _ exclude: String?) {
        values.append("\(developer):\(limit):\(exclude ?? "nil")")
    }
}

func lookupURL(_ developer: String) -> URL {
    var components = URLComponents(string: "https://itunes.apple.com/lookup")!
    components.queryItems = [URLQueryItem(name: "id", value: developer), URLQueryItem(name: "entity", value: "software")]
    return components.url!
}

func fixtureSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [FixtureURLProtocol.self]
    return URLSession(configuration: configuration)
}

actor FixtureServer {
    static let shared = FixtureServer()
    struct Response: Sendable { let data: Data; let status: Int }
    private struct Entry {
        let response: Response
        var released: Bool
        var requests: [URLRequest] = []
        var pending: [CheckedContinuation<Response, Never>] = []
        var observers: [CheckedContinuation<Void, Never>] = []
    }
    private var entries: [URL: Entry] = [:]

    func register(_ url: URL, data: Data, status: Int = 200, hold: Bool = false) {
        entries[url] = Entry(response: Response(data: data, status: status), released: !hold)
    }

    func response(for request: URLRequest) async -> Response {
        guard let url = request.url, var entry = entries[url] else { return Response(data: Data(), status: 599) }
        entry.requests.append(request)
        let observers = entry.observers
        entry.observers.removeAll()
        entries[url] = entry
        observers.forEach { $0.resume() }
        if entry.released { return entry.response }
        return await withCheckedContinuation { entries[url]?.pending.append($0) }
    }

    func waitForRequest(_ url: URL) async {
        if entries[url]?.requests.isEmpty == false { return }
        await withCheckedContinuation { entries[url]?.observers.append($0) }
    }

    func release(_ url: URL) {
        guard var entry = entries[url] else { return }
        entry.released = true
        let pending = entry.pending
        entry.pending.removeAll()
        entries[url] = entry
        pending.forEach { $0.resume(returning: entry.response) }
    }

    func requestCount(_ url: URL) -> Int { entries[url]?.requests.count ?? 0 }
    func lastRequest(_ url: URL) -> URLRequest? { entries[url]?.requests.last }
}

// URLProtocol explicitly disallows Sendable conformance. Keep it outside the task;
// the test-only delivery bridge serializes access and ignores stopped requests.
private final class FixtureDelivery: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private weak var owner: URLProtocol?
    private var stopped = false

    init(_ owner: URLProtocol) { self.owner = owner }
    func cancel() { lock.withLock { stopped = true } }
    func deliver(_ result: FixtureServer.Response, url: URL) {
        lock.withLock {
            guard !stopped, let owner else { return }
            let response = HTTPURLResponse(url: url, statusCode: result.status, httpVersion: nil, headerFields: nil)!
            owner.client?.urlProtocol(owner, didReceive: response, cacheStoragePolicy: .notAllowed)
            guard !stopped else { return }
            owner.client?.urlProtocol(owner, didLoad: result.data)
            guard !stopped else { return }
            owner.client?.urlProtocolDidFinishLoading(owner)
        }
    }
}

private final class FixtureURLProtocol: URLProtocol {
    private let lock = NSLock()
    private var work: Task<Void, Never>?
    private var delivery: FixtureDelivery?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let request = request
        let delivery = FixtureDelivery(self)
        let task = Task { @Sendable [request, delivery] in
            let result = await FixtureServer.shared.response(for: request)
            guard !Task.isCancelled, let url = request.url else { return }
            delivery.deliver(result, url: url)
        }
        lock.withLock { self.delivery = delivery; work = task }
    }
    override func stopLoading() {
        let pending = lock.withLock {
            let result = (work, delivery)
            work = nil
            delivery = nil
            return result
        }
        pending.1?.cancel()
        pending.0?.cancel()
    }
}
