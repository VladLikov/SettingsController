//
//  ColorCell.swift
//  SettingsController
//
//  Created by Влад Лыков on 07.10.2024.
//

import UIKit

class ColorCell: UITableViewCell {

    private enum Metrics {
        static let swatchSize = CGSize(width: 30, height: 30)
        static let imageToTextPadding: CGFloat = 15
        static let verticalPadding: CGFloat = 6
    }

    private var currentTitle: String?
    private var currentColor: UIColor?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        currentTitle = nil
        currentColor = nil
        contentConfiguration = nil
    }
    
    public func configure(appColor: any AppColorType) {
        currentTitle = appColor.title
        currentColor = appColor.color
        tintColor = appColor.color
        updateContentConfiguration()
    }

    private func updateContentConfiguration() {
        var configuration = defaultContentConfiguration()
        configuration.text = currentTitle
        configuration.textProperties.color = .label
        configuration.textProperties.numberOfLines = 0
        configuration.textProperties.lineBreakMode = .byWordWrapping
        configuration.directionalLayoutMargins.top = Metrics.verticalPadding
        configuration.directionalLayoutMargins.bottom = Metrics.verticalPadding
        configuration.image = currentColor.map(Self.makeSwatchImage)
        configuration.imageProperties.maximumSize = Metrics.swatchSize
        configuration.imageProperties.reservedLayoutSize = Metrics.swatchSize
        configuration.imageToTextPadding = Metrics.imageToTextPadding
        contentConfiguration = configuration
    }

    private static func makeSwatchImage(color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: Metrics.swatchSize)
        return renderer.image { _ in
            color.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: Metrics.swatchSize)).fill()
        }
    }
}
