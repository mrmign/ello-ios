////
///  EditorialInviteCell.swift
//

import SnapKit


class EditorialInviteCell: EditorialCell {
    fileprivate let inviteControls = UIView()
    fileprivate let inviteLabel = StyledLabel(style: .editorialHeaderWhite)
    fileprivate let inviteCaption = StyledLabel(style: .editorialCaptionWhite)
    fileprivate let inviteInstructions = StyledLabel(style: .editorialCaptionWhite)
    fileprivate let textBg = UIView()
    fileprivate let textView = ClearTextView()
    fileprivate var submitControls: UIView { return submitButton }
    fileprivate let submitButton = StyledButton(style: .editorialJoin)
    fileprivate let sentLabel = StyledLabel(style: .white)

    fileprivate var collapseInstructions: Constraint!
    fileprivate var timer: Timer?

    var onInviteChange: ((Editorial.InviteInfo) -> Void)?

    @objc
    func submitTapped() {
        guard let emails = textView.text else { return }

        let responder: EditorialToolsResponder? = findResponder()
        responder?.submitInvite(cell: self, emails: emails)

        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(showControls), userInfo: .none, repeats: false)
    }

    override func updateConfig() {
        super.updateConfig()
        textView.text = config.invite?.emails

        let showSent: Bool
        if let sent = config.invite?.sent, Date().timeIntervalSince(sent) < 2 {
            showSent = true
            let timeRemaining = Date().timeIntervalSince(sent)
            timer = Timer.scheduledTimer(timeInterval: timeRemaining, target: self, selector: #selector(showControls), userInfo: .none, repeats: false)
        }
        else {
            showSent = false
            timer?.invalidate()
        }
        inviteControls.isHidden = showSent
        sentLabel.isHidden = !showSent
    }

    @objc
    func showControls() {
        inviteControls.isHidden = false
        sentLabel.isHidden = true
        timer = nil
    }

    override func bindActions() {
        super.bindActions()
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
    }

    override func style() {
        super.style()

        textView.delegate = self
        textView.backgroundColor = .clear
        textView.tintColor = .black
        textView.textColor = .black
        textView.font = UIFont.editorFont()
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets.zero
        textView.showsHorizontalScrollIndicator = false
        textView.keyboardAppearance = .dark
        textView.lineColor = .clear
        textView.selectedLineColor = .clear
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.enablesReturnKeyAutomatically = true
        textView.placeholder = InterfaceString.Editorials.InvitePlaceholder
        textView.placeholderStyle = .placeholder
        textView.keyboardType = .emailAddress

        inviteLabel.text = InterfaceString.Editorials.Invite
        inviteLabel.numberOfLines = 0
        inviteCaption.text = InterfaceString.Editorials.InviteCaption
        inviteCaption.numberOfLines = 0
        inviteInstructions.text = InterfaceString.Editorials.InviteInstructions
        inviteInstructions.numberOfLines = 0
        sentLabel.text = InterfaceString.Editorials.InviteSent
        textBg.backgroundColor = .white
        textView.isEditable = true
        submitButton.isEnabled = false
        submitButton.setTitle(InterfaceString.Editorials.SubmitInvite, for: .normal)
    }

    override func arrange() {
        super.arrange()

        editorialContentView.addSubview(inviteControls)
        editorialContentView.addSubview(sentLabel)

        inviteControls.addSubview(inviteLabel)
        inviteControls.addSubview(inviteCaption)
        inviteControls.addSubview(inviteInstructions)
        inviteControls.addSubview(textBg)
        inviteControls.addSubview(textView)
        inviteControls.addSubview(submitButton)

        sentLabel.snp.makeConstraints { make in
            make.center.equalTo(editorialContentView)
        }

        inviteControls.snp.makeConstraints { make in
            make.edges.equalTo(editorialContentView)
        }

        inviteLabel.snp.makeConstraints { make in
            make.top.equalTo(editorialContentView).inset(Size.smallTopMargin)
            make.leading.equalTo(editorialContentView).inset(Size.defaultMargin)
            make.trailing.lessThanOrEqualTo(editorialContentView).inset(Size.defaultMargin).priority(Priority.required)
        }
        inviteLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)

        inviteCaption.snp.makeConstraints { make in
            make.top.equalTo(inviteLabel.snp.bottom).offset(Size.textFieldMargin)
            make.leading.equalTo(editorialContentView).inset(Size.defaultMargin)
            make.trailing.lessThanOrEqualTo(editorialContentView).inset(Size.defaultMargin).priority(Priority.required)
        }
        inviteCaption.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)

        textBg.snp.makeConstraints { make in
            make.top.equalTo(inviteCaption.snp.bottom).offset(Size.textFieldMargin)
            make.leading.trailing.equalTo(editorialContentView).inset(Size.defaultMargin)
        }

        textView.snp.makeConstraints { make in
            make.edges.equalTo(textBg).inset(UIEdgeInsets(tops: 20, sides: 30))
        }

        inviteInstructions.snp.makeConstraints { make in
            make.top.equalTo(textBg.snp.bottom).offset(Size.textFieldMargin)
            make.leading.equalTo(editorialContentView).inset(Size.defaultMargin)
            make.trailing.lessThanOrEqualTo(editorialContentView).inset(Size.defaultMargin).priority(Priority.required)
            collapseInstructions = make.height.equalTo(0).priority(Priority.required).constraint
        }
        inviteInstructions.setContentHuggingPriority(UILayoutPriorityRequired, for: .vertical)
        collapseInstructions.deactivate()

        submitButton.snp.makeConstraints { make in
            make.top.equalTo(inviteInstructions.snp.bottom).offset(Size.textFieldMargin)
            make.height.equalTo(Size.buttonHeight)
            make.bottom.equalTo(editorialContentView).offset(-Size.defaultMargin.bottom)
            make.leading.trailing.equalTo(editorialContentView).inset(Size.defaultMargin)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onInviteChange = nil
        collapseInstructions.deactivate()
        timer?.invalidate()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutIfNeeded()

        if textView.frame.height < Size.minInviteTextHeight {
            collapseInstructions.activate()
        }
    }
}

extension EditorialInviteCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        (textView as? ClearTextView)?.textDidChange()
        submitButton.isEnabled = textView.text?.isEmpty == false
        let info: Editorial.InviteInfo = (emails: textView.text, sent: nil)
        onInviteChange?(info)
    }
}
