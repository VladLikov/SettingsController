import UIKit

/// Space between a settings icon's glyph and the edge of its tile, in points.
public struct IconPadding {

    public let value: CGFloat

    public var edgeInsets: UIEdgeInsets {
        .init(top: value, left: value, bottom: value, right: value)
    }

    public init(_ value: CGFloat = 4) {
        self.value = value
    }
}

@available(*, deprecated, renamed: "IconPadding")
public typealias Inset = IconPadding
