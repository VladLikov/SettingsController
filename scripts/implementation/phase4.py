from pathlib import Path
R=Path.cwd();S=R/'Sources/SettingsController'
def change(p,a,b):
 p=S/p;t=p.read_text();assert a in t,(str(p),a[:100]);p.write_text(t.replace(a,b))
change('UI/Controllers/Mail/MailController.swift','private var mailTask: Task<Void, Never>?','private(set) var mailTask: Task<Void, Never>?')
change('UI/Controllers/About/AboutAppController.swift','private var accountTask: Task<Void, Never>?','private(set) var accountTask: Task<Void, Never>?')
change('UI/Controllers/About/AboutAppController.swift','private var checkUpdateTask: Task<Void, Never>?','private(set) var checkUpdateTask: Task<Void, Never>?')
change('UI/Controllers/About/AboutAppController.swift','''    func cancelRequests() {
        accountLifetime.invalidate()
        updateLifetime.invalidate()
        accountTask?.cancel()
        accountTask = nil''','''    func cancelAccountRequest() {
        accountLifetime.invalidate()
        accountTask?.cancel()
        accountTask = nil
    }

    func acceptAccountInfo(_ info: SettingsMailInfo?, premium: Bool) {
        cancelAccountRequest()
        accountResolved = true
        applyAccountInfo(info, premium: premium)
    }

    func cancelRequests() {
        cancelAccountRequest()
        updateLifetime.invalidate()''')
change('UI/Controllers/Settings/SettingsController+PremiumRefresh.swift','''        let lifetime = stateLifetime
        let request = lifetime.begin()''','''        if wantsAccount { activeAboutController?.cancelAccountRequest() }
        let lifetime = stateLifetime
        let request = lifetime.begin()''')
change('UI/Controllers/Settings/SettingsController+PremiumRefresh.swift','activeAboutController?.applyAccountInfo(info, premium: isPremium)','activeAboutController?.acceptAccountInfo(info, premium: isPremium)')
change('UI/Controllers/Settings/SettingsController+PremiumRefresh.swift','''        let controller = AboutAppController(isPremium: isPremium''','''        // The destination starts the newer account request; an older root refresh
        // must not overwrite it when it completes out of order.
        stateLifetime.invalidate()
        stateRefreshTask?.cancel()
        stateRefreshTask = nil
        needsStateRefresh = true
        let controller = AboutAppController(isPremium: isPremium''')
change('UI/Controllers/Presentation/SplitController.swift','''    var onWillDismiss: (@MainActor () -> Void)?''','''    var onWillPresent: (@MainActor () -> Void)?
    var onWillDismiss: (@MainActor () -> Void)?''')
change('UI/Controllers/Presentation/SplitController.swift','''    override func viewWillDisappear(_ animated: Bool) {''','''    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isBeingPresented { onWillPresent?() }
    }

    override func viewWillDisappear(_ animated: Bool) {''')
change('UI/Controllers/Settings/SettingsController.swift','''        root.onWillDismiss =''','''        root.onWillPresent = { [weak settings] in settings?.beginPresentation() }
        root.onWillDismiss =''')
change('UI/Controllers/Settings/SettingsController.swift','''    func reportDismissal() {''','''    func beginPresentation() {
        didReportDismissal = false
        needsStateRefresh = true
        overlayAppViewDidShown = false
    }

    func reportDismissal() {''')
change('UI/Controllers/Settings/SettingsController.swift','''    public override func viewDidAppear(_ animated: Bool) {''','''    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if presentationRoot == nil && (isBeingPresented || navigationController?.isBeingPresented == true) {
            beginPresentation()
        }
    }

    public override func viewDidAppear(_ animated: Bool) {''')
change('Core/Models/Settings/SettingsIcon.swift','''        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let rect = CGRect(origin: .zero, size: size)
            resolvedColor.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).fill()

            glyph
                .withRenderingMode(.alwaysTemplate)
                .withTintColor(.white, renderingMode: .alwaysOriginal)
                .draw(in: target)
        }''','''        let rect = CGRect(origin: .zero, size: size)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let tintedGlyph = renderer.image { context in
            glyph.withRenderingMode(.alwaysOriginal).draw(in: target)
            UIColor.white.setFill()
            context.fill(rect, blendMode: .sourceIn)
        }
        return renderer.image { _ in
            resolvedColor.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).fill()
            tintedGlyph.draw(in: rect)
        }''')
change('Core/Models/Premium/PremiumPayload.swift','''        destinationControllerType: UIViewController.Type?,
        action: PremiumAction?''','''        destinationControllerType: UIViewController.Type? = nil,
        action: PremiumAction? = nil''')
change('Core/Mail/MailInfoResolver.swift','''        guard let provider else''','''        guard !Task.isCancelled else { return (nil, fallbackPremium) }
        guard let provider else''')
change('UI/Controllers/Settings/SettingsController+PremiumRefresh.swift','''        guard let task = startStateRefresh() else''','''        guard !Task.isCancelled, let task = startStateRefresh() else''')
(S/'Core/Services/AppReview/AppReviewRequester.swift').unlink()
