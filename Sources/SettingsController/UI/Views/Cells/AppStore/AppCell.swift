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

    private static let placeholderIcon: UIImage = {
        let renderer = UIGraphicsImageRenderer(size: Metrics.iconSize)
        return renderer.image { _ in
            UIColor.secondarySystemBackground.setFill()
            UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: Metrics.iconSize),
                cornerRadius: Metrics.iconCornerRadius
            ).fill()
        }
    }()
    
    // MARK: Life Cycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        iconTask?.cancel()
        iconTask = nil
        representedIconURL = nil
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

        iconTask?.cancel()
        iconTask = nil
        representedIconURL = nil
        currentIcon = Self.placeholderIcon

        switch row {
        case .placeholder:
            currentTitle = NSLocalizedString("Loading…", bundle: .module, comment: "")
            accessoryType = .none

        case .failed:
            currentTitle = NSLocalizedString("Failed to load", bundle: .module, comment: "")
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

        iconTask = Task { [weak self] in
            do {
                let image = try await RemoteImageLoader.shared.image(
                    from: url,
                    maxPixelSize: Metrics.iconSize.width,
                    scale: await MainActor.run { UIScreen.main.scale }
                )

                guard !Task.isCancelled else { return }

                await MainActor.run { [weak self] in
                    guard let self, representedIconURL == url else { return }
                    currentIcon = image
                    updateContentConfiguration()
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run { [weak self] in
                    guard let self, representedIconURL == url else { return }
                    currentIcon = Self.placeholderIcon
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
