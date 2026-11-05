import UIKit

public enum AppColor: String, CaseIterable, AppColorType {
    case blue, purple, pink, green, red, orange, yellow, gray

    public var title: String {
        switch self {
        case .red: NSLocalizedString("Red", bundle: .module, comment: "Name of the red accent color in the appearance palette.")
        case .green: NSLocalizedString("Green", bundle: .module, comment: "Name of the green accent color in the appearance palette.")
        case .blue: NSLocalizedString("Blue", bundle: .module, comment: "Name of the blue accent color in the appearance palette.")
        case .pink: NSLocalizedString("Pink", bundle: .module, comment: "Name of the pink accent color in the appearance palette.")
        case .purple: NSLocalizedString("Purple", bundle: .module, comment: "Name of the purple accent color in the appearance palette.")
        case .orange: NSLocalizedString("Orange", bundle: .module, comment: "Name of the orange accent color in the appearance palette.")
        case .yellow: NSLocalizedString("Yellow", bundle: .module, comment: "Name of the yellow accent color in the appearance palette.")
        case .gray: NSLocalizedString("Gray", bundle: .module, comment: "Name of the gray accent color in the appearance palette.")
        }
    }

    public var color: UIColor {
        switch self {
        case .red: .systemRed
        case .green: .systemGreen
        case .blue: .systemBlue
        case .pink: .systemPink
        case .purple: .systemIndigo
        case .orange: .systemOrange
        case .yellow: .systemYellow
        case .gray: .systemGray
        }
    }

}
