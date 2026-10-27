//
//  AppCell.swift
//  SettingsController
//
//  Created by Влад Лыков on 29.04.2025.
//

import UIKit

final class AppCell: UITableViewCell {

    private enum Metrics {
        static let iconSize = CGSize(width: 30, height: 30)
        static let iconCornerRadius: CGFloat = 7.5
        static let imageToTextPadding: CGFloat = 15
        static let verticalPadding: CGFloat = 6
    }

    private var iconTask: Task<Void, Never>?
    private var representedIconURL: URL?
    private var currentTitle: String?
    private var currentIcon: UIImage?

    private var isShowingPlaceholder = true
    private var representedScale: CGFloat?
    private var iconRequest = UUID()
    private static let placeholders = NSCache<NSString, UIImage>()
    private func makePlaceholder() -> UIImage {
        let key = "\(traitCollection.userInterfaceStyle.rawValue):\(traitCollection.accessibilityContrast.rawValue):\(traitCollection.displayScale)" as NSString
        if let image = Self.placeholders.object(forKey: key) { return image }
        Self.placeholders.countLimit = 12
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = max(traitCollection.displayScale, 1)
        let image = UIGraphicsImageRenderer(size: Metrics.iconSize, format: format).image { _ in
            UIColor.secondarySystemBackground.resolvedColor(with: traitCollection).setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: Metrics.iconSize), cornerRadius: Metrics.iconCornerRadius).fill()
        }
        Self.placeholders.setObject(image, forKey: key)
        return image
    }

    // MARK: Life Cycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self, UITraitDisplayScale.self]) { (cell: AppCell, previous: UITraitCollection) in
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
        if isShowingPlaceholder { currentIcon = makePlaceholder(); updateContentConfiguration() }
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
        accessoryType = .disclosureIndicator
        contentConfiguration = nil
    }

    deinit {
        iconTask?.cancel()
    }
}

// MARK: - Configure

extension AppCell {
    
    public func configure(with row: AppStoreAppRowState) {

        if case .loaded(let item) = row, representedIconURL == item.iconURL,
           representedScale == max(traitCollection.displayScale, 1), !isShowingPlaceholder || iconTask != nil {
            currentTitle = item.name
            accessoryType = .disclosureIndicator
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
            accessoryType = .none

        case .failed:
            currentTitle = NSLocalizedString("Failed to load. Tap to retry.", bundle: .module, comment: "Developer app catalog error row; tapping retries the same catalog request.")
            accessoryType = .none

        case .loaded(let item):
            currentTitle = item.name
            accessoryType = .disclosureIndicator
            load(icon: item.iconURL)
        }

        updateContentConfiguration()
    }

    private func load(icon url: URL) {

        representedIconURL = url
        let request = UUID()
        iconRequest = request
        let scale = max(traitCollection.displayScale, 1)
        representedScale = scale

        iconTask = Task { [weak self] in
            do {
                let image = try await RemoteImageLoader.shared.image(
                    from: url,
                    maxPixelSize: Metrics.iconSize.width,
                    scale: scale
                )

                guard !Task.isCancelled else { return }

                await MainActor.run { [weak self] in
                    guard let self, iconRequest == request, representedIconURL == url else { return }
                    iconTask = nil
                    isShowingPlaceholder = false
                    currentIcon = image
                    updateContentConfiguration()
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run { [weak self] in
                    guard !Task.isCancelled, let self, iconRequest == request, representedIconURL == url else { return }
                    iconTask = nil
                    isShowingPlaceholder = true
                    currentIcon = makePlaceholder()
                    updateContentConfiguration()
                }
            }
        }
    }

    private func updateContentConfiguration() {
        var configuration = defaultContentConfiguration()
        configuration.text = currentTitle
        configuration.textProperties.color = .label
        configuration.textProperties.numberOfLines = 0
        configuration.textProperties.lineBreakMode = .byWordWrapping
        configuration.directionalLayoutMargins.top = Metrics.verticalPadding
        configuration.directionalLayoutMargins.bottom = Metrics.verticalPadding
        configuration.image = currentIcon
        configuration.imageProperties.maximumSize = Metrics.iconSize
        configuration.imageProperties.reservedLayoutSize = Metrics.iconSize
        configuration.imageProperties.cornerRadius = Metrics.iconCornerRadius
        configuration.imageToTextPadding = Metrics.imageToTextPadding
        contentConfiguration = configuration
    }
}
