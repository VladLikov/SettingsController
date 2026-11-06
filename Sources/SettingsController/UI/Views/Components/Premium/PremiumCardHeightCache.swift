import UIKit

/// Remembers premium card heights measured by the cell itself, shared by every settings presentation.
///
/// The card picks its arrangement with `ViewThatFits` in the cell's real environment, exactly as in 4.0.8.
/// Measuring the layout elsewhere differs by a few points near the one-row limit, so only results are
/// cached: repeated self-sizing passes and later presentations reuse them instead of laying out again.
@MainActor
enum PremiumCardHeightCache {
    /// Everything that changes the card's size, except the width. The image is assumed to be a symbol glyph.
    struct ContentKey: Hashable {
        let title: String
        let tierTitle: String?
        let buttonTitle: String
        let sizeCategory: UIContentSizeCategory
        let boldText: Bool
        let displayScale: CGFloat

        init(payload: PremiumCardPayload, traits: UITraitCollection) {
            title = payload.title
            tierTitle = payload.tierTitle
            buttonTitle = payload.buttonTitle
            sizeCategory = traits.preferredContentSizeCategory
            boldText = traits.legibilityWeight == .bold
            displayScale = max(traits.displayScale, 1)
        }
    }

    private struct Key: Hashable {
        let content: ContentKey
        let width: CGFloat
    }

    private static let limit = 64
    private static var heights: [Key: CGFloat] = [:]
    private static var lastHeights: [ContentKey: CGFloat] = [:]

    static func height(for payload: PremiumCardPayload, width: CGFloat, traits: UITraitCollection) -> CGFloat? {
        heights[Key(content: ContentKey(payload: payload, traits: traits), width: width)]
    }

    static func store(_ height: CGFloat, for payload: PremiumCardPayload, width: CGFloat, traits: UITraitCollection) {
        let content = ContentKey(payload: payload, traits: traits)
        if heights.count >= limit { heights.removeAll() }
        if lastHeights.count >= limit { lastHeights.removeAll() }
        heights[Key(content: content, width: width)] = height
        lastHeights[content] = height
    }

    /// The most recent height for this content, used as the row estimate so the table does not size twice.
    static func estimatedHeight(for payload: PremiumCardPayload, traits: UITraitCollection) -> CGFloat? {
        lastHeights[ContentKey(payload: payload, traits: traits)]
    }

    static func removeAll() {
        heights.removeAll()
        lastHeights.removeAll()
    }
}
