from pathlib import Path
R=Path.cwd()
S=R/'Sources/SettingsController'
def write(p,text):
    p=R/p; p.parent.mkdir(parents=True,exist_ok=True); p.write_text(text)
def replace(p,old,new):
    p=R/p; text=p.read_text(); assert old in text, (str(p),old[:100]); p.write_text(text.replace(old,new))

write('Sources/SettingsController/Core/Services/RequestLifetime.swift', '''import Foundation

/// A cancelled or superseded request may finish, but must never apply its result.
/// Task cancellation is cooperative; this identity check is deliberately separate.
@MainActor
final class RequestLifetime {
    private var currentID: UUID?

    func begin() -> UUID {
        let id = UUID()
        currentID = id
        return id
    }

    func isCurrent(_ id: UUID) -> Bool { currentID == id }

    @discardableResult
    func finish(_ id: UUID) -> Bool {
        guard isCurrent(id) else { return false }
        currentID = nil
        return true
    }

    func invalidate() { currentID = nil }
}
''')
write('Sources/SettingsController/UI/Extensions/UIViewController+Lifecycle.swift', '''import UIKit

extension UIViewController {
    /// A push or a presented child is not the end of this controller's lifetime.
    var settingsIsLeavingHierarchy: Bool {
        var controller: UIViewController? = self
        while let current = controller {
            if current.isBeingDismissed || current.isMovingFromParent { return true }
            controller = current.parent
        }
        return false
    }

    var settingsCanPresent: Bool {
        isViewLoaded && view.window != nil && !settingsIsLeavingHierarchy
            && presentedViewController == nil
    }
}
''')
write('Sources/SettingsController/Core/Services/SystemActions.swift', '''import UIKit

typealias OpenURLOperation = @MainActor (URL) async -> Bool

@MainActor
enum SystemActions {
    static func openURL(_ url: URL) async -> Bool {
        await UIApplication.shared.open(url, options: [:])
    }
}
''')
write('Sources/SettingsController/Core/Mail/MailEnvironment.swift', '''import Foundation
import UIKit

/// A snapshot keeps formatting deterministic and avoids reading system preferences.
struct MailEnvironment: Sendable {
    let appName: String
    let version: String
    let build: String
    let deviceModel: String
    let deviceType: String
    let systemName: String
    let systemVersion: String
    let battery: String
    let locale: String
    let preferredLanguage: String
    let appLanguage: String
    let region: String
    let timeZone: String
    let timestamp: String

    @MainActor
    static func current() -> Self {
        let device = UIDevice.current
        let wasEnabled = device.isBatteryMonitoringEnabled
        device.isBatteryMonitoringEnabled = true
        defer { device.isBatteryMonitoringEnabled = wasEnabled }
        let bundle = Bundle.main
        let locale = Locale.current
        let region: String
        if #available(iOS 16, *) {
            region = locale.region?.identifier ?? "Unknown"
        } else {
            region = locale.regionCode ?? "Unknown"
        }
        return Self(
            appName: bundle.infoDictionary?["CFBundleDisplayName"] as? String
                ?? bundle.infoDictionary?["CFBundleName"] as? String ?? "App",
            version: bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            build: bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            deviceModel: DeviceModel.supportDescription,
            deviceType: device.model,
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            battery: device.batteryLevel >= 0 ? "\(Int(device.batteryLevel * 100))%" : "Unknown",
            locale: locale.identifier,
            preferredLanguage: Locale.preferredLanguages.first ?? "Unknown",
            appLanguage: bundle.preferredLocalizations.first ?? bundle.developmentLocalization ?? "Unknown",
            region: region.lowercased(),
            timeZone: TimeZone.current.identifier,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }
}
''')
write('Sources/SettingsController/Core/Mail/MailBuilder.swift', '''import Foundation

struct MailDraft: Sendable {
    let recipient: String
    let subject: String
    let body: String

    var url: URL? {
        guard !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !recipient.contains("\\r"), !recipient.contains("\\n") else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        // Some mail handlers interpret + as a form-encoded space.
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")
        return components.url
    }
}

@MainActor
enum MailBuilder {
    static func buildMail(
        with text: String, recipient: String, type: MailType,
        isPremium: Bool?, productID: String? = nil,
        mailInfo: SettingsMailInfo? = nil
    ) -> URL? {
        makeDraft(with: text, recipient: recipient, type: type, isPremium: isPremium,
                  productID: productID, mailInfo: mailInfo, environment: .current()).url
    }

    static func makeDraft(
        with text: String, recipient: String, type: MailType,
        isPremium: Bool?, productID: String? = nil,
        mailInfo: SettingsMailInfo? = nil, environment e: MailEnvironment
    ) -> MailDraft {
        let premium = (mailInfo?.isPremium ?? isPremium).map { $0 ? "true" : "false" } ?? "-"
        let body = """
        \(type == .languageRequest ? "Language needed: " : "")\(text)


        ===== DEVICE INFO =====

        Device Model: \(e.deviceModel)
        Device Type: \(e.deviceType)

        OS: \(e.systemName) \(e.systemVersion)

        Battery: \(e.battery)

        ===== APP INFO =====

        App: \(e.appName)
        Version: \(e.version)
        Build: \(e.build)

        ===== USER INFO =====

        User ID: \(mailInfo?.userID ?? "-")
        Product ID: \(mailInfo?.productID ?? productID ?? "-")
        Pro Status: \(premium)

        ===== ENVIRONMENT =====

        Locale: \(e.locale)
        Preferred Language: \(e.preferredLanguage)
        App Language: \(e.appLanguage)
        App Region: \(e.region)
        Time Zone: \(e.timeZone)

        Timestamp: \(e.timestamp)

        """
        return MailDraft(recipient: recipient, subject: "\(e.appName) \(type.subject)", body: body)
    }
}
''')
replace('Sources/SettingsController/Core/Mail/MailInfoResolver.swift',
'        if let premium = info?.isPremium { return (info, premium) }',
'        guard !Task.isCancelled else { return (nil, fallbackPremium) }\n        if let premium = info?.isPremium { return (info, premium) }')
p=S/'UI/Controllers/Mail/MailController.swift'; t=p.read_text().replace('import MessageUI\n','')
t=t.replace('    private var isPreparingMail = false','''    private var isPreparingMail = false
    private let mailLifetime = RequestLifetime()
    var openURL: OpenURLOperation = SystemActions.openURL
    private lazy var progress = UIActivityIndicatorView(style: .medium)''')
t=t.replace('        button.isEnabled = false', '''        button.accessibilityLabel = NSLocalizedString("Send", bundle: .module, comment: "Prepare a draft in the mail app")
        button.isEnabled = false''')
t=t.replace('    public override func viewDidAppear(_ animated: Bool) {','''    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if settingsIsLeavingHierarchy { cancelMailPreparation() }
    }

    public override func viewDidAppear(_ animated: Bool) {''')
t=t.replace('            self?.mailTask?.cancel()', '            self?.cancelMailPreparation()')
t=t.replace('"After tapping Send, you\'ll be redirected to the Mail app and the message will be sent from your mailbox."', '"After tapping Send, a draft opens in your mail app. Review it and send it there."')
t=t.replace('        cell.configure(type: type)','        cell.configure(type: type, text: currentText)')
start=t.index('extension MailController {\n    private func prepareMail()')
t=t[:start]+'''extension MailController {
    func cancelMailPreparation() {
        mailLifetime.invalidate()
        mailTask?.cancel()
        mailTask = nil
        setPreparingMail(false)
    }

    private func setPreparingMail(_ preparing: Bool) {
        isPreparingMail = preparing
        if preparing {
            progress.startAnimating()
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: progress)
        } else {
            progress.stopAnimating()
            sendButton.isEnabled = currentText.count >= type.minCharactersCount
            navigationItem.rightBarButtonItem = sendButton
        }
    }

    func prepareMail() {
        guard !isPreparingMail, currentText.count >= type.minCharactersCount else { return }
        setPreparingMail(true)
        let request = mailLifetime.begin()
        let lifetime = mailLifetime
        let text = currentText
        let provider = dataProvider
        let fallback = isPremium
        let recipient = email
        let type = type
        let product = productID
        let open = openURL

        mailTask = Task { @MainActor [weak self] in
            let diagnostics = await MailInfoResolver.resolve(provider: provider, fallbackPremium: fallback)
            guard !Task.isCancelled, lifetime.isCurrent(request), self?.settingsCanPresent == true else {
                self?.finishMailPreparation(request)
                return
            }
            let draft = MailBuilder.makeDraft(
                with: text, recipient: recipient, type: type,
                isPremium: diagnostics.isPremium, productID: product,
                mailInfo: diagnostics.info, environment: .current()
            )
            let opened: Bool
            if let url = draft.url { opened = await open(url) } else { opened = false }
            guard !Task.isCancelled, lifetime.isCurrent(request) else { return }
            self?.finishMailPreparation(request)
            if !opened, self?.settingsCanPresent == true { self?.showMailFallback(draft) }
        }
    }

    private func finishMailPreparation(_ request: UUID) {
        guard mailLifetime.finish(request) else { return }
        mailTask = nil
        setPreparingMail(false)
    }

    private func showMailFallback(_ draft: MailDraft) {
        let alert = UIAlertController(
            title: NSLocalizedString("Unable to open a mail app", bundle: .module, comment: "Mail URL failed"),
            message: NSLocalizedString("Your message is still here. You can copy the support address or message.", bundle: .module, comment: "Mail fallback"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("Copy Address", bundle: .module, comment: "Mail fallback"), style: .default) { _ in
            UIPasteboard.general.string = draft.recipient
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Copy Message", bundle: .module, comment: "Mail fallback"), style: .default) { _ in
            UIPasteboard.general.string = draft.subject + "\\n\\n" + draft.body
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", bundle: .module, comment: ""), style: .cancel))
        present(alert, animated: true)
    }
}
'''
p.write_text(t)
p=S/'UI/Views/Cells/Mail/MailCell.swift'; t=p.read_text()
t=t.replace('textView.font = .systemFont(ofSize: 16)','textView.font = .preferredFont(forTextStyle: .body)\n        textView.adjustsFontForContentSizeCategory = true')
t=t.replace('label.font = textView.font','label.font = .preferredFont(forTextStyle: .body)\n        label.adjustsFontForContentSizeCategory = true\n        label.isAccessibilityElement = false')
t=t.replace('    override init(style:', '    public override init(style:')
t=t.replace('public func configure(type: MailType) {','public func configure(type: MailType, text: String? = nil) {')
t=t.replace('        placeholderLabel.text = type.placeholder','''        placeholderLabel.text = type.placeholder
        if let text { textView.text = text }
        placeholderLabel.isHidden = !textView.text.isEmpty
        textView.accessibilityLabel = NSLocalizedString("Message", bundle: .module, comment: "")
        textView.accessibilityHint = type.placeholder''')
t=t.replace('            placeholderLabel.trailingAnchor.constraint(', '            placeholderLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16),\n            placeholderLabel.trailingAnchor.constraint(')
p.write_text(t)
(S/'UI/Controllers/Preferences/LanguageController.swift').unlink()
(S/'UI/Controllers/Mail/MailAvailability.swift').unlink()
replace('Sources/SettingsController/Core/Models/Settings/SettingsRowItem.swift','case language(email: String)','case language')
replace('Sources/SettingsController/Core/Models/Settings/SettingsRowItem.swift','case .language(_):','case .language:')
p=S/'UI/Controllers/Settings/SettingsController+TableDelegate.swift'; t=p.read_text(); a=t.index('        case .language(let email):'); b=t.index('        case .appearance',a)
t=t[:a]+'''        case .language:
            tableView.deselectRow(at: indexPath, animated: true)
            openLanguageSettings()

'''+t[b:]; p.write_text(t)
p=S/'UI/Controllers/Settings/SettingsController+Routing.swift'; t=p.read_text().replace('import MessageUI\n','').replace('        guard MailAvailability.canSendEmail() else { return }\n\n','')
t=t.replace('    func sendMail(_ email: String) {','''    func openLanguageSettings() {
        guard languageSettingsTask == nil,
              let url = URL(string: UIApplication.openSettingsURLString) else { return }
        let open = openURL
        languageSettingsTask = Task { @MainActor [weak self] in
            let success = await open(url)
            guard !Task.isCancelled else { return }
            self?.languageSettingsTask = nil
            guard !success, let self, settingsCanPresent else { return }
            let alert = UIAlertController(
                title: NSLocalizedString("Unable to open Settings", bundle: .module, comment: "Opening system settings failed"),
                message: nil, preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", bundle: .module, comment: ""), style: .default))
            present(alert, animated: true)
        }
    }

    func sendMail(_ email: String) {''')
p.write_text(t)
p=S/'UI/Controllers/Settings/SettingsController.swift'; t=p.read_text().replace('    var storeProductTask: Task<Void, Never>?','''    var storeProductTask: Task<Void, Never>?
    var languageSettingsTask: Task<Void, Never>?
    var openURL: OpenURLOperation = SystemActions.openURL''').replace('        storeProductTask?.cancel()','        storeProductTask?.cancel()\n        languageSettingsTask?.cancel()');p.write_text(t)
p=R/'Tests/SettingsControllerTests/MailBuilderTests.swift';t=p.read_text().replace('System Language:', 'Preferred Language:')
t=t.replace('private func mailBody(from url: String) throws -> String {','private func mailBody(from url: URL?) throws -> String {')
t=t.replace('URLComponents(string: url)', 'URLComponents(url: try XCTUnwrap(url), resolvingAgainstBaseURL: false)');p.write_text(t)
