import ImageIO
import UIKit

/// The About header, as in Apple's own about screens: the app icon, its name, version and bundle ID.
final class AboutAppHeaderView: UIView {

    private static let iconSize: CGFloat = 88

    init(icon: UIImage?, name: String, version: String, bundleID: String) {
        super.init(frame: .zero)

        let iconView = UIImageView(image: icon ?? Self.placeholderIcon())
        iconView.contentMode = .scaleAspectFill
        iconView.layer.cornerRadius = Self.iconSize * 0.225
        iconView.layer.cornerCurve = .continuous
        iconView.layer.masksToBounds = true
        // The same hairline the system draws around app icons on light backgrounds.
        iconView.layer.borderWidth = 1 / max(UIScreen.main.scale, 1)
        iconView.layer.borderColor = UIColor.separator.cgColor
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = Self.label(name, style: .title2, weight: .semibold, color: .label)
        let versionText = Self.label(version, style: .subheadline, weight: .regular, color: .secondaryLabel)
        let bundleText = Self.label(bundleID, style: .footnote, weight: .regular, color: .tertiaryLabel)

        let stack = UIStackView(arrangedSubviews: [iconView, nameLabel, versionText, bundleText])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.setCustomSpacing(14, after: iconView)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])

        isAccessibilityElement = true
        let versionLabel = NSLocalizedString(
            "App Version", bundle: .module, comment: "Diagnostic label for the installed app version and build.")
        let bundleLabel = NSLocalizedString("Bundle ID", bundle: .module, comment: "Not translated: technical diagnostic label in About.")
        accessibilityLabel = [name, "\(versionLabel) \(version)", "\(bundleLabel) \(bundleID)"].joined(separator: ", ")
        accessibilityTraits = .header
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// The file `AboutIconPlugin` renders from the app's Icon Composer icon, at 88 pt @3x.
    static let renderedIconFile = "SettingsAboutIcon.png"

    /// Loads only standalone icon files. App-icon catalog renditions (including Icon Composer
    /// assets) can raise an Objective-C exception in UIImage(named:), rather than return nil.
    static func appIcon(in bundle: Bundle = .main) -> UIImage? {
        guard let resources = bundle.resourceURL else { return nil }
        // The Liquid Glass rendering comes first: the flat PNG Xcode bundles for an `.icon` has no glass effects.
        let rendered = resources.appendingPathComponent(renderedIconFile)
        if let image = image(at: rendered) {
            return UIImage(cgImage: image, scale: CGFloat(image.width) / iconSize, orientation: .up)
        }
        let idiom = UIDevice.current.userInterfaceIdiom
        // Bundle resolves device-qualified Info.plist keys (such as CFBundleIcons~ipad)
        // for the current device before exposing infoDictionary.
        let info = bundle.infoDictionary ?? [:]
        var files: [String] = []
        if let icons = info["CFBundleIcons"] as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let names = primary["CFBundleIconFiles"] as? [String]
        {
            files.append(contentsOf: names.reversed())
        }
        files.append(contentsOf: (info["CFBundleIconFiles"] as? [String] ?? []).reversed())

        let idiomSuffixes = idiom == .pad ? ["~ipad", ""] : ["~iphone", ""]
        for file in files {
            let path = file as NSString
            let ext = path.pathExtension.isEmpty ? "png" : path.pathExtension
            let name = path.pathExtension.isEmpty ? file : path.deletingPathExtension
            for suffix in idiomSuffixes {
                for scale in ["@3x", "@2x", ""] {
                    let url = resources.appendingPathComponent(name + scale + suffix).appendingPathExtension(ext)
                    if let image = image(at: url) { return UIImage(cgImage: image) }
                }
            }
        }
        return nil
    }

    private static func image(at url: URL) -> CGImage? {
        guard FileManager.default.fileExists(atPath: url.path),
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            CGImageSourceGetType(source) != nil
        else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private static func placeholderIcon() -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(pointSize: iconSize * 0.45, weight: .regular)
        let symbol = UIImage(systemName: "app.fill", withConfiguration: configuration)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        let size = CGSize(width: iconSize, height: iconSize)
        return UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.systemGray3.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            if let symbol {
                symbol.draw(at: CGPoint(x: (size.width - symbol.size.width) / 2, y: (size.height - symbol.size.height) / 2))
            }
        }
    }

    private static func label(_ text: String, style: UIFont.TextStyle, weight: UIFont.Weight, color: UIColor) -> UILabel {
        let label = UILabel()
        let base = UIFont.preferredFont(forTextStyle: style)
        label.font = UIFontMetrics(forTextStyle: style).scaledFont(for: .systemFont(ofSize: base.pointSize, weight: weight))
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = text
        return label
    }
}
