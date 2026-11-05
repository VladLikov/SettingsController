import UIKit

public protocol AppColorType: RawRepresentable, CaseIterable where RawValue == String {
    var title: String { get }
    var color: UIColor { get }
}
