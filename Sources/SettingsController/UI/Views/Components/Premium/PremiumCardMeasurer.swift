import QuartzCore
import SwiftUI
import UIKit

/// Sizes the premium card without letting a table cell run `ViewThatFits` on every self-sizing pass.
///
/// The horizontal arrangement keeps its heading and call to action on single lines, so its ideal width
/// and height do not depend on the cell width. One measurement of that ideal size therefore answers the
/// same question `ViewThatFits` asks ("does the horizontal row fit?") for every width, and gives its height.
/// Only a stacked card, or the wrapping iOS 15 card, is measured per width. Results are shared by all
/// settings presentations in the process.
@MainActor
enum PremiumCardMeasurer {
    struct Resolution: Equatable {
        let layout: PremiumCardLayout
        let height: CGFloat
    }

    /// Everything that changes the card's size. The image is assumed to be a symbol-sized glyph.
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

    private struct HorizontalMetrics {
        let idealWidth: CGFloat
        let height: CGFloat
    }

    private struct WidthKey: Hashable {
        let content: ContentKey
        let layout: PremiumCardLayout
        let width: CGFloat
    }

    private static let cacheLimit = 64
    private static var horizontalMetrics: [ContentKey: HorizontalMetrics] = [:]
    private static var widthBoundHeights: [WidthKey: CGFloat] = [:]
    private static var lastResolutions: [ContentKey: Resolution] = [:]
    private static let host: UIHostingController<AnyView> = {
        let host = UIHostingController(rootView: AnyView(EmptyView()))
        if #available(iOS 16.0, *) { host.sizingOptions = [] }
        return host
    }()

    static func resolve(_ payload: PremiumCardPayload, width: CGFloat, traits: UITraitCollection) -> Resolution {
        let width = max(width, 1)
        let key = ContentKey(payload: payload, traits: traits)
        let resolution: Resolution
        if #unavailable(iOS 16.0) {
            resolution = Resolution(layout: .automatic, height: widthBoundHeight(payload, key: key, layout: .automatic, width: width))
        } else if traits.preferredContentSizeCategory.isAccessibilityCategory {
            resolution = Resolution(layout: .stacked, height: widthBoundHeight(payload, key: key, layout: .stacked, width: width))
        } else {
            let horizontal = horizontalMetrics(payload, key: key)
            if horizontal.idealWidth <= width {
                resolution = Resolution(layout: .horizontal, height: horizontal.height)
            } else {
                resolution = Resolution(layout: .stacked, height: widthBoundHeight(payload, key: key, layout: .stacked, width: width))
            }
        }
        store(resolution, in: &lastResolutions, for: key)
        return resolution
    }

    /// The most recent height for this content, used as the row estimate so the table does not size twice.
    static func estimatedHeight(for payload: PremiumCardPayload, traits: UITraitCollection) -> CGFloat? {
        lastResolutions[ContentKey(payload: payload, traits: traits)]?.height
    }

    /// The most recent arrangement for this content, so a reused cell renders it before it is sized.
    static func lastLayout(for payload: PremiumCardPayload, traits: UITraitCollection) -> PremiumCardLayout? {
        lastResolutions[ContentKey(payload: payload, traits: traits)]?.layout
    }

    static func removeAll() {
        horizontalMetrics.removeAll()
        widthBoundHeights.removeAll()
        lastResolutions.removeAll()
    }

    private static func horizontalMetrics(_ payload: PremiumCardPayload, key: ContentKey) -> HorizontalMetrics {
        if let metrics = horizontalMetrics[key] { return metrics }
        let ideal = measure(payload, key: key, layout: .horizontal, proposal: nil)
        let metrics = HorizontalMetrics(idealWidth: ideal.width, height: rounded(ideal.height))
        store(metrics, in: &horizontalMetrics, for: key)
        return metrics
    }

    private static func widthBoundHeight(
        _ payload: PremiumCardPayload, key: ContentKey, layout: PremiumCardLayout, width: CGFloat
    ) -> CGFloat {
        let widthKey = WidthKey(content: key, layout: layout, width: width)
        if let height = widthBoundHeights[widthKey] { return height }
        let height = rounded(measure(payload, key: key, layout: layout, proposal: width).height)
        store(height, in: &widthBoundHeights, for: widthKey)
        return height
    }

    /// Measures the padded card content: at its ideal size when `proposal` is nil, otherwise at that width.
    private static func measure(
        _ payload: PremiumCardPayload, key: ContentKey, layout: PremiumCardLayout, proposal: CGFloat?
    ) -> CGSize {
        let signpost = SettingsSignposts.signposter.beginInterval("PremiumCard measurement")
        let start = CACurrentMediaTime()
        defer {
            SettingsSignposts.signposter.endInterval("PremiumCard measurement", signpost)
            PremiumCardSizingStatistics.recordMeasurement(duration: CACurrentMediaTime() - start)
        }
        var content = PremiumCard(
            payload: payload, layout: layout,
            palette: PremiumCardPalette.cached(color: payload.premium.color, traits: .current), onTap: {})
        content.isMeasurement = true
        let sized: AnyView
        if let proposal {
            sized = AnyView(content.frame(width: proposal))
        } else {
            sized = AnyView(content.fixedSize())
        }
        host.rootView = AnyView(
            sized
                .environment(\.dynamicTypeSize, DynamicTypeSize(key.sizeCategory) ?? .large)
                .environment(\.legibilityWeight, key.boldText ? .bold : .regular)
                .environment(\.displayScale, key.displayScale))
        let fitting =
            proposal.map { CGSize(width: $0, height: CGFloat.greatestFiniteMagnitude) }
            ?? CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        return host.sizeThatFits(in: fitting)
    }

    private static func rounded(_ height: CGFloat) -> CGFloat {
        max(PremiumCardMetrics.minimumHeight, ceil(height))
    }

    private static func store<Key: Hashable, Value>(_ value: Value, in cache: inout [Key: Value], for key: Key) {
        if cache[key] == nil, cache.count >= cacheLimit { cache.removeAll() }
        cache[key] = value
    }
}
