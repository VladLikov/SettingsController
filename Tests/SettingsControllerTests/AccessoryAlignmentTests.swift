import UIKit
import XCTest

@testable import SettingsController

/// The external arrow of Our Apps rows lines up with the disclosure chevron of the rows above it.
@MainActor
final class AccessoryAlignmentTests: XCTestCase {
    private final class DataSource: NSObject, UITableViewDataSource {
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 2 }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = "Row"
            (indexPath.row == 0 ? RowAccessory.disclosure : .external).apply(to: cell)
            return cell
        }
    }

    func testExternalArrowSharesTheChevronTrailingEdgeAndCenter() throws {
        for (width, style) in [(390.0, UITableView.Style.insetGrouped), (820, .insetGrouped), (390, .grouped)] {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 600))
            let controller = UIViewController()
            window.rootViewController = controller
            window.isHidden = false
            defer {
                window.isHidden = true
                window.rootViewController = nil
            }
            let dataSource = DataSource()
            let table = UITableView(frame: controller.view.bounds, style: style)
            table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
            table.dataSource = dataSource
            controller.view.addSubview(table)
            table.layoutIfNeeded()

            let chevronCell = try XCTUnwrap(table.cellForRow(at: IndexPath(row: 0, section: 0)))
            let arrowCell = try XCTUnwrap(table.cellForRow(at: IndexPath(row: 1, section: 0)))
            chevronCell.layoutIfNeeded()
            arrowCell.layoutIfNeeded()
            let chevron = try XCTUnwrap(
                chevronCell.subviews.first { String(describing: type(of: $0)).contains("Accessory") })
            let arrow = try XCTUnwrap(arrowCell.accessoryView)

            XCTAssertEqual(
                arrowCell.bounds.maxX - arrow.frame.maxX, chevronCell.bounds.maxX - chevron.frame.maxX,
                accuracy: 0.5, "trailing inset, width \(width), style \(style.rawValue)")
            XCTAssertEqual(arrow.frame.midY, chevron.frame.midY, accuracy: 0.5, "center, width \(width)")

            // The glyph keeps its own proportions instead of filling the taller accessory frame.
            let glyph = try XCTUnwrap(arrow.subviews.compactMap { $0 as? UIImageView }.first)
            let image = try XCTUnwrap(glyph.image)
            XCTAssertTrue(
                glyph.contentMode == .center || glyph.bounds.size == image.size,
                "arrow stretched from \(image.size) to \(glyph.bounds.size)")
        }
    }
}
