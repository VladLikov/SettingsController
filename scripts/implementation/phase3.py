from pathlib import Path
R=Path.cwd();S=R/'Sources/SettingsController'
def write(p,t):
 p=R/p;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t)
write('Sources/SettingsController/Core/Services/AppStore/AppUpdateLookup.swift','''import Foundation
import CheckUpdate

struct AppUpdate: Sendable, Equatable {
    let version: String
    let minimumOSVersion: String
    let url: URL
}

enum AppUpdateLookup {
    static func fetch(_ appID: String) async throws -> AppUpdate? {
        guard let result = try await CheckUpdate().getLatestAvailableVersion(for: appID) else { return nil }
        return AppUpdate(version: result.version, minimumOSVersion: result.minimumOsVersion, url: result.upgradeURL)
    }

    static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = lhs.split(separator: ".", omittingEmptySubsequences: false)
        let right = rhs.split(separator: ".", omittingEmptySubsequences: false)
        let a = left.compactMap { Int($0) }, b = right.compactMap { Int($0) }
        guard a.count == left.count, b.count == right.count, !a.isEmpty, !b.isEmpty else {
            return lhs.compare(rhs, options: .numeric)
        }
        for index in 0..<max(a.count, b.count) {
            let x = index < a.count ? a[index] : 0, y = index < b.count ? b[index] : 0
            if x != y { return x < y ? .orderedAscending : .orderedDescending }
        }
        return .orderedSame
    }
}
''')
p=S/'UI/Controllers/About/AboutAppController.swift';t=p.read_text().replace('import CheckUpdate\n','')
t=t.replace('    private let isPremium: Bool\n    private let userID: String?', '''    private(set) var isPremium: Bool
    private(set) var userID: String?
    weak var dataProvider: (any SettingsControllerDataProvider)?
    var openURL: OpenURLOperation = SystemActions.openURL
    var loadUpdate: @Sendable (String) async throws -> AppUpdate? = AppUpdateLookup.fetch
    var currentVersion: @MainActor () -> String? = { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String }
    var currentOSVersion: @MainActor () -> String = { UIDevice.current.systemVersion }
    var onAccountUpdate: (@MainActor (SettingsMailInfo?, Bool) -> Void)?
    private var accountTask: Task<Void, Never>?
    private let accountLifetime = RequestLifetime()
    private let updateLifetime = RequestLifetime()
    private var accountResolved = false''')
t=t.replace('        checkUpdateTask?.cancel()\n    }','        checkUpdateTask?.cancel()\n        accountTask?.cancel()\n    }',1)
t=t.replace('''        setupData()
    }
}''','''        setupData()
        observeAppearance()
        loadAccountInfo()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if settingsIsLeavingHierarchy { cancelRequests() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !accountResolved && accountTask == nil { loadAccountInfo() }
    }

    func cancelRequests() {
        accountLifetime.invalidate()
        updateLifetime.invalidate()
        accountTask?.cancel()
        accountTask = nil
        checkUpdateTask?.cancel()
        checkUpdateTask = nil
        accountResolved = false
    }

    func applyAccountInfo(_ info: SettingsMailInfo?, premium: Bool) {
        let changed = userID != info?.userID || isPremium != premium
        userID = info?.userID
        isPremium = premium
        if changed, isViewLoaded { setupData(); tableView.reloadData() }
    }

    func loadAccountInfo() {
        guard let provider = dataProvider else { return }
        let lifetime = accountLifetime
        let request = lifetime.begin()
        accountTask?.cancel()
        let fallback = isPremium
        accountTask = Task { @MainActor [weak self] in
            defer { if lifetime.finish(request) { self?.accountTask = nil } }
            let result = await MailInfoResolver.resolve(provider: provider, fallbackPremium: fallback)
            guard !Task.isCancelled, lifetime.isCurrent(request) else { return }
            self?.accountResolved = true
            self?.applyAccountInfo(result.info, premium: result.isPremium ?? fallback)
            self?.onAccountUpdate?(result.info, result.isPremium ?? fallback)
        }
    }

    private func observeAppearance() {
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self, UITraitDisplayScale.self]) { (controller: AboutAppController, _: UITraitCollection) in
                controller.tableView.reloadData()
            }
        }
    }

    @available(iOS, introduced: 8, deprecated: 17)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17), isViewLoaded { tableView.reloadData() }
    }
}''',1)
t=t.replace('let systemLanguage = Locale.current.languageCode ?? "-"','let systemLanguage = Locale.preferredLanguages.first ?? "-"')
t=t.replace('NSLocalizedString("System Language",', 'NSLocalizedString("Preferred Language",')
t=t.replace('''                        action: .copyUserID''','''                        action: userID == nil ? .none : .copyUserID''')
t=t.replace('''        config.secondaryText = item.subtitle ?? item.value''','''        config.secondaryText = item.action == .checkForUpdate && checkUpdateTask != nil
            ? NSLocalizedString("Checking…", bundle: .module, comment: "Update check in progress")
            : item.subtitle ?? item.value''')
a=t.index('        case .checkForUpdate:\n            checkUpdateTask?.cancel()');b=t.index('        case .none:',a)
t=t[:a]+'''        case .checkForUpdate:
            checkForUpdate()

'''+t[b:]
t+='''
extension AboutAppController {
    func checkForUpdate() {
        guard checkUpdateTask == nil else { return }
        let lifetime = updateLifetime
        let request = lifetime.begin()
        let lookup = loadUpdate
        let appID = appID
        let version = currentVersion()
        let osVersion = currentOSVersion()
        checkUpdateTask = Task { @MainActor [weak self] in
            defer {
                if lifetime.finish(request) {
                    self?.checkUpdateTask = nil
                    self?.tableView.reloadData()
                }
            }
            do {
                guard let version, let update = try await lookup(appID) else { throw URLError(.cannotParseResponse) }
                guard !Task.isCancelled, lifetime.isCurrent(request), self?.settingsCanPresent == true else { return }
                if AppUpdateLookup.compare(version, update.version) != .orderedAscending {
                    self?.showUpdateMessage(NSLocalizedString("Latest version is installed", bundle: .module, comment: ""))
                } else if AppUpdateLookup.compare(osVersion, update.minimumOSVersion) == .orderedAscending {
                    self?.showUpdateMessage(NSLocalizedString("Update requires a newer iOS version", bundle: .module, comment: "Update cannot run on this OS"))
                } else {
                    self?.showAvailableUpdate(update)
                }
            } catch {
                guard !Task.isCancelled, !(error is CancellationError), (error as? URLError)?.code != .cancelled,
                      lifetime.isCurrent(request), self?.settingsCanPresent == true else { return }
                self?.showUpdateMessage(NSLocalizedString("Unable to check for updates", bundle: .module, comment: "Retry the update check later"))
            }
        }
        tableView.reloadData()
    }

    private func showUpdateMessage(_ title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", bundle: .module, comment: ""), style: .default))
        present(alert, animated: true)
    }

    private func showAvailableUpdate(_ update: AppUpdate) {
        let alert = UIAlertController(
            title: NSLocalizedString("Update available", bundle: .module, comment: "App Store update"),
            message: String(format: NSLocalizedString("Version %@ is available.", bundle: .module, comment: "App version number"), update.version),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("Not Now", bundle: .module, comment: ""), style: .cancel))
        let open = openURL
        let action = UIAlertAction(title: NSLocalizedString("Update", bundle: .module, comment: ""), style: .default) { _ in
            Task { @MainActor in _ = await open(update.url) }
        }
        alert.addAction(action)
        alert.preferredAction = action
        present(alert, animated: true)
    }
}
''';p.write_text(t)
p=S/'UI/Controllers/Settings/SettingsController+PremiumRefresh.swift';t=p.read_text().replace('''        activeAboutController = controller''','''        controller.onAccountUpdate = { [weak self] info, premium in
            self?.applyResolvedState(info: info, premium: premium, user: nil, includesAccount: true)
        }
        activeAboutController = controller''')
t=t.replace('''        let task = Task { @MainActor [weak self] in
            let context''','''        let task = Task { @MainActor [weak self] in
            defer { if lifetime.finish(request) { self?.stateRefreshTask = nil } }
            let context''').replace('''            if lifetime.finish(request) { self?.stateRefreshTask = nil }
        }''','''        }''');p.write_text(t)
p=S/'UI/Controllers/Preferences/AppearanceController.swift';t=p.read_text().replace('    private var reviewRequested: Bool = false\n','').replace('theme.appColor == appColor.color','theme.appColorRawValue == appColor.rawValue')
a=t.index('            guard let oldIndex = colors.firstIndex');b=t.index('            let newAppColor = colors[indexPath.row]',a)
t=t[:a]+'''            guard colors.indices.contains(indexPath.row) else { return }
            if let oldIndex = colors.firstIndex(where: { $0.rawValue == currentRaw }) {
                tableView.cellForRow(at: IndexPath(row: oldIndex, section: 0))?.accessoryType = .none
            }
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark

'''+t[b:]
t=t.replace('''            theme.appColor = newColor
            eventHandler''','''            theme.appColor = newColor
            theme.appColorRawValue = newAppColor.rawValue
            eventHandler''')
a=t.index('            if !reviewRequested {');b=t.index('#if !os(visionOS)',a);t=t[:a]+t[b:]
p.write_text(t)
p=S/'Core/Models/Settings/SettingsIcon.swift';t=p.read_text().replace('guard size.width > 0, size.height > 0, cornerRadius >= 0 else {','guard size.width.isFinite, size.height.isFinite, cornerRadius.isFinite,\n              size.width > 0, size.height > 0, cornerRadius >= 0 else {')
t=t.replace('''        guard let glyph = generateImage() else { return nil }''','''        guard let glyph = image, glyph.size.width > 0, glyph.size.height > 0,
              let target = glyphRect(for: glyph, in: CGRect(origin: .zero, size: size)) else { return nil }''')
t=t.replace('''.draw(in: glyphRect(for: glyph, in: rect))''','''.draw(in: target)''')
a=t.index('    func glyphRect(for glyph: UIImage, in bounds: CGRect) -> CGRect {');b=t.index('    @MainActor\n    func tileCacheKey',a)
t=t[:a]+'''    func glyphRect(for glyph: UIImage, in bounds: CGRect) -> CGRect? {
        let padding = inset?.value ?? 0
        guard padding.isFinite, padding >= 0 else { return nil }
        let virtualSize = CGSize(width: glyph.size.width + padding * 2,
                                 height: glyph.size.height + padding * 2)
        guard virtualSize.width.isFinite, virtualSize.height.isFinite else { return nil }
        let maxSize = inset == nil ? bounds.size.applyingScale(0.7) : bounds.size
        let fitted = virtualSize.aspectFit(in: maxSize)
        let scale = fitted.width / virtualSize.width
        return CGRect(x: bounds.midX - fitted.width / 2 + padding * scale,
                      y: bounds.midY - fitted.height / 2 + padding * scale,
                      width: glyph.size.width * scale, height: glyph.size.height * scale)
    }

'''+t[b:]
t=t.replace('''            insetValue.cacheKeyComponent,''','''            inset == nil ? "inset:none" : "inset:" + insetValue.cacheKeyComponent,''')
p.write_text(t)
p=S/'UI/Views/Cells/Settings/SettingsCell.swift';t=p.read_text().replace('    private var currentIcon: UIImage?','    private var currentIcon: UIImage?\n    private var iconDescription: SettingsIcon?').replace('    override init(style:', '    public override init(style:')
t=t.replace('''        selectionStyle = .default
    }''','''        selectionStyle = .default
        observeAppearance()
    }''',1).replace('''        super.init(coder: coder)
    }''','''        super.init(coder: coder)
        observeAppearance()
    }''',1)
t=t.replace('''        currentIcon = icon?.generateSettingsImage''','''        iconDescription = icon
        currentIcon = icon?.generateSettingsImage''').replace('''        currentIcon = nil

        accessoryType''','''        currentIcon = nil
        iconDescription = nil

        accessoryType''')
pos=t.index('\n}\n\n// MARK: - Configure');t=t[:pos]+'''
    private func observeAppearance() {
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self, UITraitDisplayScale.self]) { (cell: SettingsCell, _: UITraitCollection) in
                cell.refreshIconForTraits()
            }
        }
    }

    @available(iOS, introduced: 8, deprecated: 17)
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17) { refreshIconForTraits() }
    }

    func refreshIconForTraits() {
        currentIcon = iconDescription?.generateSettingsImage(traitCollection: traitCollection)
        updateContentConfiguration()
    }
'''+t[pos:];p.write_text(t)
p=S/'UI/Views/Cells/Settings/ColorCell.swift';t=p.read_text().replace('''        selectionStyle = .none
    }''','''        selectionStyle = .none
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self, UITraitDisplayScale.self]) { (cell: ColorCell, _: UITraitCollection) in
                cell.updateContentConfiguration()
            }
        }
    }''',1)
t=t.replace('''    override func prepareForReuse() {''','''    @available(iOS, introduced: 8, deprecated: 17)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17) { updateContentConfiguration() }
    }

    override func prepareForReuse() {''')
t=t.replace('configuration.image = currentColor.map(Self.makeSwatchImage)','configuration.image = currentColor.map { Self.makeSwatchImage(color: $0.resolvedColor(with: traitCollection), scale: traitCollection.displayScale) }').replace('private static func makeSwatchImage(color: UIColor) -> UIImage {\n        let renderer = UIGraphicsImageRenderer(size: Metrics.swatchSize)','private static func makeSwatchImage(color: UIColor, scale: CGFloat) -> UIImage {\n        let format = UIGraphicsImageRendererFormat.default()\n        format.scale = max(1, scale)\n        let renderer = UIGraphicsImageRenderer(size: Metrics.swatchSize, format: format)');p.write_text(t)
p=S/'UI/Views/Cells/Settings/UserCell.swift';t=p.read_text().replace('label.numberOfLines = 1','label.numberOfLines = 0').replace('label.font = .boldSystemFont(ofSize: 18)','label.font = .preferredFont(forTextStyle: .headline)\n        label.adjustsFontForContentSizeCategory = true').replace('label.textAlignment = .left','label.textAlignment = .natural')
t=t.replace('''        userLabel.text = title''','''        accessibilityLabel = title
        userLabel.text = title''').replace('''        contentView.addSubview(userImageView)''','''        isAccessibilityElement = true
        accessibilityTraits = .button
        userImageView.isAccessibilityElement = false
        contentView.addSubview(userImageView)''')
t=t.replace('''            userLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            userLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),''','''            userImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),
            userImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
            userLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            userLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),''').replace('constant: -4)', 'constant: -16)');p.write_text(t)
write('Sources/SettingsController/UI/Views/Components/Premium/PremiumCard.swift','''import SwiftUI

public struct PremiumCard: View {
    public let image: Image
    public let title: String
    public let subtitle: String
    public let buttonTitle: String
    public let color: UIColor
    public let onTap: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme

    public init(image: Image, title: String, subtitle: String, buttonTitle: String, color: UIColor, onTap: @escaping () -> Void) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.color = color
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 16) {
                        heading
                        callToAction
                    }
                } else {
                    HStack(spacing: 12) {
                        heading
                        Spacer(minLength: 0)
                        callToAction
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            .foregroundColor(.white)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(gradient))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PremiumCardButtonStyle())
        .accessibilityLabel(Text("\(title). \(subtitle). \(buttonTitle)"))
    }

    private var heading: some View {
        HStack(alignment: .center, spacing: 10) {
            image.renderingMode(.template).font(.title2).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title2.bold()).fixedSize(horizontal: false, vertical: true)
                Text(subtitle).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
        }
    }

    private var callToAction: some View {
        Text(buttonTitle)
            .font(.headline)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 22).fill(.white.opacity(0.14)))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.42), lineWidth: 1))
    }

    private var gradient: LinearGradient {
        let resolved = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let lighter: UIColor
        if resolved.getRed(&r, green: &g, blue: &b, alpha: &a) {
            lighter = UIColor(red: min(r + 0.07, 1), green: min(g + 0.12, 1), blue: min(b + 0.18, 1), alpha: a)
        } else { lighter = resolved }
        return LinearGradient(colors: [Color(resolved), Color(lighter)], startPoint: .top, endPoint: .bottom)
    }
}

private struct PremiumCardButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .interactiveSpring(), value: configuration.isPressed)
    }
}
''')
write('Sources/SettingsController/UI/Views/Cells/Premium/PremiumCell.swift','''import UIKit
import SwiftUI

final class PremiumCell: UITableViewCell {
    private var host: UIHostingController<PremiumCard>?
    private weak var hostingParent: UIViewController?
    private var hostConstraints: [NSLayoutConstraint] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        detachHost(discard: true)
        hostingParent = nil
        contentConfiguration = nil
        backgroundConfiguration = nil
        accessoryType = .none
        accessoryView = nil
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { detachHost(discard: false) }
        else if let parent = hostingParent { attachHost(to: parent) }
    }

    func configure(payload: PremiumCardPayload, parent: UIViewController,
                   forceLegacyHosting: Bool = false, onTap: @escaping () -> Void) {
        let card = PremiumCard(image: payload.image, title: payload.title, subtitle: payload.subtitle,
                               buttonTitle: payload.buttonTitle, color: payload.premium.color, onTap: onTap)
        if #available(iOS 16, *), !forceLegacyHosting {
            detachHost(discard: true)
            hostingParent = nil
            contentConfiguration = UIHostingConfiguration { card }.margins(.all, 0)
        } else {
            contentConfiguration = nil
            hostingParent = parent
            if let host { host.rootView = card }
            else { host = UIHostingController(rootView: card) }
            attachHost(to: parent)
            host?.view.invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize,
                                          withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
                                          verticalFittingPriority: UILayoutPriority) -> CGSize {
        guard let host else {
            return super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority,
                                                  verticalFittingPriority: verticalFittingPriority)
        }
        let width = max(targetSize.width, 1)
        let fitted = host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(fitted.height))
    }

    private func attachHost(to parent: UIViewController) {
        guard let host, host.parent !== parent else { return }
        detachHost(discard: false)
        parent.addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        contentView.addSubview(host.view)
        hostConstraints = [
            host.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(hostConstraints)
        host.didMove(toParent: parent)
    }

    private func detachHost(discard: Bool) {
        guard let host else { return }
        if host.parent != nil { host.willMove(toParent: nil) }
        NSLayoutConstraint.deactivate(hostConstraints)
        hostConstraints.removeAll()
        host.view.removeFromSuperview()
        if host.parent != nil { host.removeFromParent() }
        if discard { self.host = nil }
    }
}
''')
write('Sources/SettingsController/UI/Views/Components/EmptyState/EmptyStateView.swift','''import UIKit

final class EmptyStateView: UIView {
    init(title: String?, subtitle: String?) {
        super.init(frame: .zero)
        backgroundColor = .systemGroupedBackground
        let header = UILabel()
        header.text = title
        header.font = .preferredFont(forTextStyle: .largeTitle)
        header.accessibilityTraits.insert(.header)
        let footer = UILabel()
        footer.text = subtitle
        footer.font = .preferredFont(forTextStyle: .body)
        for label in [header, footer] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
            label.textAlignment = .center
            label.textColor = .secondaryLabel
        }
        let scroll = UIScrollView()
        let content = UIView()
        let stack = UIStackView(arrangedSubviews: [header, footer])
        stack.axis = .vertical
        stack.spacing = 12
        [scroll, content, stack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        addSubview(scroll)
        scroll.addSubview(content)
        content.addSubview(stack)
        let preferredHeight = content.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)
        preferredHeight.priority = .defaultLow
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
            content.heightAnchor.constraint(greaterThanOrEqualTo: scroll.frameLayoutGuide.heightAnchor),
            preferredHeight,
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
''')
p=S/'UI/Views/Cells/Settings/SwitchCell.swift';t=p.read_text().replace('    override init(style:', '    public override init(style:');p.write_text(t)
p=S/'Core/Services/Image/RemoteImageLoader.swift';t=p.read_text().replace('''        let pixelSize = Self.pixelSize(maxPixelSize: maxPixelSize, scale: scale)
        let cacheKey = "\(url.absoluteString)#\(pixelSize)" as NSString''','''        try Task.checkCancellation()
        let scale = scale.isFinite && scale > 0 ? scale : 1
        let pixelSize = Self.pixelSize(maxPixelSize: maxPixelSize, scale: scale)
        let cacheKey = "\(url.absoluteString)#\(pixelSize)@\(scale)" as NSString''')
t=t.replace('''            return try await task.value''','''            let image = try await task.value
            try Task.checkCancellation()
            return image''')
t=t.replace('''            inFlightTasks[cacheKey] = nil
            return image''','''            inFlightTasks[cacheKey] = nil
            try Task.checkCancellation()
            return image''')
t=t.replace('''        return max(1, Int((maxPixelSize * scale).rounded(.up)))''','''        let product = maxPixelSize * scale
        guard product.isFinite else { return 1 }
        return Int(min(8192, max(1, product.rounded(.up))))''');p.write_text(t)
p=S/'UI/Views/Cells/AppStore/AppCell.swift';t=p.read_text();a=t.index('    private static let placeholderIcon: UIImage = {');b=t.index('    // MARK: Life Cycle',a)
t=t[:a]+'''    private var isShowingPlaceholder = true
    private func makePlaceholder() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = max(traitCollection.displayScale, 1)
        return UIGraphicsImageRenderer(size: Metrics.iconSize, format: format).image { _ in
            UIColor.secondarySystemBackground.resolvedColor(with: traitCollection).setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: Metrics.iconSize), cornerRadius: Metrics.iconCornerRadius).fill()
        }
    }

'''+t[b:]
t=t.replace('''        accessoryType = .disclosureIndicator
    }''','''        accessoryType = .disclosureIndicator
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self, UITraitDisplayScale.self]) { (cell: AppCell, previous: UITraitCollection) in
                cell.refreshAppearance(previous)
            }
        }
    }''',1)
t=t.replace('''    override func prepareForReuse() {''','''    @available(iOS, introduced: 8, deprecated: 17)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17) { refreshAppearance(previousTraitCollection) }
    }

    private func refreshAppearance(_ previous: UITraitCollection?) {
        if isShowingPlaceholder { currentIcon = makePlaceholder(); updateContentConfiguration() }
        if previous?.displayScale != traitCollection.displayScale, let url = representedIconURL {
            iconTask?.cancel()
            load(icon: url)
        }
    }

    override func prepareForReuse() {''')
t=t.replace('''        currentIcon = Self.placeholderIcon''','''        isShowingPlaceholder = true
        currentIcon = makePlaceholder()''',1)
t=t.replace('currentTitle = NSLocalizedString("Failed to load", bundle: .module, comment: "")','currentTitle = NSLocalizedString("Failed to load. Tap to retry.", bundle: .module, comment: "App catalog error")')
t=t.replace('''        representedIconURL = url

        iconTask''','''        representedIconURL = url
        let scale = max(traitCollection.displayScale, 1)

        iconTask''').replace('scale: await MainActor.run { UIScreen.main.scale }','scale: scale')
t=t.replace('''                    currentIcon = image''','''                    isShowingPlaceholder = false
                    currentIcon = image''')
t=t.replace('''                    guard let self, representedIconURL == url else { return }
                    currentIcon = Self.placeholderIcon''','''                    guard !Task.isCancelled, let self, representedIconURL == url else { return }
                    isShowingPlaceholder = true
                    currentIcon = makePlaceholder()''')
p.write_text(t)
p=S/'UI/Controllers/Settings/SettingsController+StoreKit.swift';t=p.read_text().replace('''        storeProductTask = Task { @MainActor [weak self] in
            let destination''','''        storeProductTask = Task { @MainActor [weak self] in
            defer { if lifetime.finish(request) { self?.storeProductTask = nil } }
            let destination''').replace('''                if lifetime.finish(request) { self?.storeProductTask = nil }
                return''','''                return''').replace('''            if lifetime.finish(request) { self?.storeProductTask = nil }
        }''','''        }''');p.write_text(t)
p=S/'UI/Controllers/Settings/SettingsController.swift';t=p.read_text().replace('''        appLoadTasks[id] = Task { @MainActor [weak self] in
            do {''','''        appLoadTasks[id] = Task { @MainActor [weak self] in
            defer { if lifetime.finish(request) { self?.appLoadTasks[id] = nil } }
            do {''').replace('''            } catch {
                guard !Task.isCancelled, lifetime.isCurrent(request) else { return }
                self?.finishCatalogLoad''','''            } catch {
                guard !Task.isCancelled, !(error is CancellationError), (error as? URLError)?.code != .cancelled,
                      lifetime.isCurrent(request) else { return }
                self?.finishCatalogLoad''');p.write_text(t)
write('Sources/SettingsController/Resources/PrivacyInfo.xcprivacy','''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>NSPrivacyTracking</key><false/>
    <key>NSPrivacyTrackingDomains</key><array/>
    <key>NSPrivacyCollectedDataTypes</key><array/>
    <key>NSPrivacyAccessedAPITypes</key><array/>
</dict></plist>
''')
p=R/'Package.swift';t=p.read_text().replace('        .package(url: "https://github.com/sparrowcode/SwiftBoost", .upToNextMajor(from: "5.0.0")),\n','').replace('                "SwiftBoost",\n','').replace('CheckUpdate.git", from: "1.0.0"','CheckUpdate.git", from: "1.0.1"');p.write_text(t)
