import UIKit

// MARK: - MailCellDelegate

@MainActor
protocol MailCellDelegate: AnyObject {
    func mailCell(_ cell: MailCell, didChangeText text: String, needsHeightUpdate: Bool)
}

// MARK: - MailCell

class MailCell: UITableViewCell {

    weak var delegate: MailCellDelegate?

    private var lastMeasuredTextHeight: CGFloat = 0

    // MARK: UI Elements [Private]

    private lazy var textView: UITextView = {

        let textView = UITextView()

        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.textColor = .label
        textView.autocapitalizationType = .sentences
        textView.delegate = self
        textView.backgroundColor = .clear

        textView.translatesAutoresizingMaskIntoConstraints = false

        return textView
    }()

    private lazy var placeholderLabel: UILabel = {

        let label = UILabel()

        label.textColor = .systemGray
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = false
        label.numberOfLines = 0
        label.isHidden = false
        label.backgroundColor = .clear

        label.translatesAutoresizingMaskIntoConstraints = false

        return label
    }()

    /// How many more characters the message needs; empty once it can be sent.
    private lazy var requirementLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.textAlignment = .natural
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: Life Cycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Configure

extension MailCell {

    func configure(type: MailType, text: String? = nil) {

        placeholderLabel.text = type.placeholder
        if let text { textView.text = text }
        placeholderLabel.isHidden = !textView.text.isEmpty
        textView.accessibilityLabel = NSLocalizedString(
            "Message", bundle: .module, comment: "Section heading for the editable support message.")
        textView.accessibilityHint = type.placeholder
        lastMeasuredTextHeight = measuredTextHeight()
    }

    func beginEditing() {

        textView.becomeFirstResponder()
    }

    /// Returns true when the requirement line appeared or disappeared, which changes the row height.
    @discardableResult
    func showMissingCharacters(_ count: Int) -> Bool {
        let wasVisible = requirementLabel.text != nil
        requirementLabel.text =
            count > 0
            ? String(
                format: NSLocalizedString(
                    "Characters needed: %ld", bundle: .module,
                    comment: "Mail form hint below the message. %ld is how many more characters are needed before Send is enabled."),
                count)
            : nil
        return wasVisible != (requirementLabel.text != nil)
    }

    /// The caret in the coordinate space of `view`, to keep it visible while the row grows.
    func caretRect(in view: UIView) -> CGRect? {
        guard textView.isFirstResponder, let position = textView.selectedTextRange?.end else { return nil }
        return textView.convert(textView.caretRect(for: position), to: view)
    }
}

// MARK: - Setup View

extension MailCell {

    private func setupView() {

        selectionStyle = .none

        contentView.addSubview(textView)
        contentView.addSubview(placeholderLabel)
        contentView.addSubview(requirementLabel)
    }
}

// MARK: - Setup Constraints

extension MailCell {

    private func setupConstraints() {

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 8
            ),
            textView.bottomAnchor.constraint(equalTo: requirementLabel.topAnchor),
            requirementLabel.leadingAnchor.constraint(
                equalTo: textView.leadingAnchor, constant: textView.textContainer.lineFragmentPadding),
            requirementLabel.trailingAnchor.constraint(
                equalTo: textView.trailingAnchor, constant: -textView.textContainer.lineFragmentPadding),
            requirementLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            textView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 12
            ),
            textView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -12
            ),
            textView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: 160),

            placeholderLabel.topAnchor.constraint(
                equalTo: textView.topAnchor,
                constant: textView.textContainerInset.top
            ),
            placeholderLabel.leadingAnchor.constraint(
                equalTo: textView.leadingAnchor,
                constant: textView.textContainer.lineFragmentPadding
            ),
            placeholderLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16),
            placeholderLabel.trailingAnchor.constraint(
                equalTo: textView.trailingAnchor,
                constant: -textView.textContainer.lineFragmentPadding
            ),
        ])
    }
}

// MARK: - UITextViewDelegate

extension MailCell: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {

        let text = textView.text ?? ""

        placeholderLabel.isHidden = !text.isEmpty

        let newHeight = measuredTextHeight()
        let needsHeightUpdate = abs(newHeight - lastMeasuredTextHeight) > 0.5
        lastMeasuredTextHeight = newHeight

        delegate?.mailCell(self, didChangeText: text, needsHeightUpdate: needsHeightUpdate)
    }

    private func measuredTextHeight() -> CGFloat {
        let width = max(textView.bounds.width, contentView.bounds.width - 24)
        let fittingSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        return ceil(textView.sizeThatFits(fittingSize).height)
    }
}
