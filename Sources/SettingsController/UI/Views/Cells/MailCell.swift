//
//  MailCellDelegate.swift
//  SettingsController
//
//  Created by Влад Лыков on 11.04.2026.
//

import UIKit

// MARK: - MailCellDelegate

@MainActor
protocol MailCellDelegate: AnyObject {
    func mailCell(_ cell: MailCell, didChangeText text: String)
}

// MARK: - MailCell

public class MailCell: UITableViewCell {
    
    weak var delegate: MailCellDelegate?
    
    // MARK: UI Elements [Private]

    private lazy var textView: UITextView = {
        
        let textView = UITextView()
        
        textView.font = .systemFont(ofSize: 16)
        textView.isEditable = true
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.textColor = .label
        textView.autocapitalizationType = .sentences
        textView.delegate = self

        textView.translatesAutoresizingMaskIntoConstraints = false
        
        return textView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        
        let label = UILabel()
        
        label.textColor = .systemGray
        label.font = textView.font
        label.numberOfLines = 0
        label.isHidden = false
        
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
    
    public func configure(type: MailType) {
        
        placeholderLabel.text = type.placeholder
    }
    
    public func textViewBecomeFirstResponder() {
        
        textView.becomeFirstResponder()
    }
}

// MARK: - Setup View

extension MailCell {
 
    private func setupView() {
        
        selectionStyle = .none

        contentView.addSubview(textView)
        contentView.addSubview(placeholderLabel)
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
            textView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -8
            ),
            textView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 12
            ),
            textView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -12
            ),
            textView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: 100)
            ,
            
            placeholderLabel.topAnchor.constraint(
                equalTo: textView.topAnchor,
                constant: textView.textContainerInset.top
            ),
            placeholderLabel.leadingAnchor.constraint(
                equalTo: textView.leadingAnchor,
                constant: textView.textContainer.lineFragmentPadding
            ),
            placeholderLabel.trailingAnchor.constraint(
                equalTo: textView.trailingAnchor,
                constant: -textView.textContainer.lineFragmentPadding
            )
        ])
    }
}

// MARK: - UITextViewDelegate

extension MailCell: UITextViewDelegate {
    
    public func textViewDidChange(_ textView: UITextView) {
        
        let text = textView.text ?? ""

        placeholderLabel.isHidden = !text.isEmpty
        
        delegate?.mailCell(self, didChangeText: text)
    }
}
