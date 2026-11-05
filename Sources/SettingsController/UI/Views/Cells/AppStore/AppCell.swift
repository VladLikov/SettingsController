import UIKit

final class AppCell: UITableViewCell {

    private var iconTask: Task<Void, Never>?
    private var representedIconURL: URL?
    private var currentTitle: String?
    private var currentIcon: UIImage?

    private var isShowingPlaceholder = true
    private var representedScale: CGFloat?
    private var iconRequest = UUID()
    private static let placeholders = NSCache<NSString, UIImage>()
    private func makePlaceholder() -> UIImage {
        let key =
            "\(traitCollection.userInterfaceStyle.rawValue):\(traitCollection.accessibilityContrast.rawValue):\(traitCollection.displayScale)"
            as NSString
        if let image = Self.placeholders.object(forKey: key) { return image }
        Self.placeholders.countLimit = 12
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = max(traitCollection.displayScale, 1)
        let image = UIGraphicsImageRenderer(size: SettingsMetrics.iconSize, format: format).image { _ in
            UIColor.secondarySystemBackground.resolvedColor(with: traitCollection).setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: SettingsMetrics.iconSize), cornerRadius: SettingsMetrics.iconCornerRadius)
                .fill()
        }
        Self.placeholders.setObject(image, forKey: key)
        return image
    }

    // MARK: Life Cycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self, UITraitDisplayScale.self]) {
                (cell: AppCell, previous: UITraitCollection) in
                cell.refreshAppearance(previous)
            }
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @available(iOS, introduced: 8, deprecated: 17)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17) { refreshAppearance(previousTraitCollection) }
    }

    private func refreshAppearance(_ previous: UITraitCollection?) {
        if isShowingPlaceholder {
            currentIcon = makePlaceholder()
            updateContentConfiguration()
        }
        if previous?.displayScale != traitCollection.displayScale, let url = representedIconURL {
            iconTask?.cancel()
            load(icon: url)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        iconTask?.cancel()
        iconTask = nil
        representedIconURL = nil
        iconRequest = UUID()
        currentTitle = nil
        currentIcon = nil
        accessoryType = .none
        accessoryView = nil
        accessibilityValue = nil
        contentConfiguration = nil
    }

    deinit {
        iconTask?.cancel()
    }
}

// MARK: - Configure

extension AppCell {

    /// `isOpening` shows progress while the App Store page for this app loads.
    func configure(with row: AppStoreAppRowState, isOpening: Bool = false) {
        defer { applyAccessory(for: row, isOpening: isOpening) }

        if case .loaded(let item) = row, representedIconURL == item.iconURL,
            representedScale == max(traitCollection.displayScale, 1), !isShowingPlaceholder || iconTask != nil
        {
            currentTitle = item.name
            updateContentConfiguration()
            return
        }
        iconTask?.cancel()
        iconTask = nil
        representedIconURL = nil
        iconRequest = UUID()
        isShowingPlaceholder = true
        currentIcon = makePlaceholder()

        switch row {
        case .placeholder:
            currentTitle = NSLocalizedString("Loading…", bundle: .module, comment: "Placeholder while the developer app catalog loads.")

        case .failed:
            currentTitle = NSLocalizedString(
                "Failed to load. Tap to retry.", bundle: .module,
                comment: "Developer app catalog error row; tapping retries the same catalog request.")

        case .loaded(let item):
            currentTitle = item.name
            load(icon: item.iconURL)
        }

        updateContentConfiguration()
    }

    private func applyAccessory(for row: AppStoreAppRowState, isOpening: Bool) {
        guard isOpening else {
            DisplayRow.app(row).accessory.apply(to: self)
            accessibilityValue = nil
            return
        }
        let indicator = (accessoryView as? UIActivityIndicatorView) ?? UIActivityIndicatorView(style: .medium)
        indicator.isAccessibilityElement = false
        indicator.startAnimating()
        accessoryType = .none
        accessoryView = indicator
        accessibilityValue = NSLocalizedString("Loading…", bundle: .module, comment: "Placeholder while the developer app catalog loads.")
    }

    private func load(icon url: URL) {

        representedIconURL = url
        let request = UUID()
        iconRequest = request
        let scale = max(traitCollection.displayScale, 1)
        representedScale = scale
        let start = CACurrentMediaTime()

        iconTask = Task { @MainActor [weak self] in
            do {
                let image = try await RemoteImageLoader.shared.image(
                    from: url,
                    maxPixelSize: SettingsMetrics.iconSize.width,
                    scale: scale
                )

                guard !Task.isCancelled else { return }

                guard let self, iconRequest == request, representedIconURL == url else { return }
                iconTask = nil
                isShowingPlaceholder = false
                currentIcon = image
                // Cached icons appear at once; icons that arrive from the network fade in.
                if CACurrentMediaTime() - start > 0.05, window != nil, !UIAccessibility.isReduceMotionEnabled {
                    UIView.transition(with: contentView, duration: 0.2, options: [.transitionCrossDissolve, .allowUserInteraction]) {
                        self.updateContentConfiguration()
                    }
                } else {
                    updateContentConfiguration()
                }
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, let self, iconRequest == request, representedIconURL == url else { return }
                iconTask = nil
                isShowingPlaceholder = true
                currentIcon = makePlaceholder()
                updateContentConfiguration()
            }
        }
    }

    private func updateContentConfiguration() {
        var configuration = defaultContentConfiguration()
        configuration.text = currentTitle
        configuration.textProperties.color = .label
        configuration.applySettingsRowLayout()
        configuration.applySettingsIcon(currentIcon)
        contentConfiguration = configuration
    }
}
