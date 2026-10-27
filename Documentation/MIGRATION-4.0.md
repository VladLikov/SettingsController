# Migrating from 3.1.5 to 4.0 (unreleased)

4.0 is a source-breaking release. Do not change an existing 3.x tag or publish this branch as a patch. Keep the package revision and the host integration changes together when rolling back.

## Language

```swift
// 3.x
.defaultRow(.language(email: supportEmail))
// 4.0
.defaultRow(.language)
```

The intermediate language controller is removed. A tap opens `UIApplication.openSettingsURLString`: the app's page in system Settings. iOS controls whether the Language item is available; this API does not promise to select the nested language page. Configure the host application's supported localizations. No private Settings URL schemes are used and the data provider is not queried for this action.

`MailType.languageRequest` remains supported for independently presented mail forms.

## One User ID

```swift
func settingsMailInfo() async -> SettingsMailInfo? {
    SettingsMailInfo(userID: accountID, productID: currentProductID, isPremium: premiumIsActive)
}
```

Use `userID:` instead of `adaptyProfileID:`. Remove `userID:` from `.about(...)` and `MailController(...)`. About and support diagnostics use only `SettingsMailInfo.userID`. A missing value is displayed as `-`, not inferred from another identifier or retained from the previous account. The package has no Adapty dependency; apps using Adapty can supply their profile ID as this ordinary string.

Product and premium fallback parameters remain supported. Precedence is typed `isPremium`, then `settingsIsPremiumActive()`, then initial configuration when no provider exists. `false` is an actual typed value, not a missing value.

The provider may be queried when preparing mail, opening About and refreshing relevant account/premium rows. It is no longer a mail-send-only hook. Static screens do not fetch account information unnecessarily. Providers should return a consistent account snapshot and cooperate with cancellation when possible.

## Refresh after purchases and profile changes

```swift
Task { @MainActor [weak settingsController] in
    await settingsController?.refreshState()
}
```

Call after a purchase, restore, account switch, profile edit or logout. This is required for custom flows that do not cause the settings screen to reappear, notably sheets and the secondary column on iPad. Appearance/dismissal refreshes are supplementary, not a replacement for notifying the library about application-owned events.

The latest refresh wins. Cancelling its caller cancels that refresh. Old responses cannot overwrite newer state. The initial premium card definition is retained, so active status becomes an Active row and subsequent inactive status restores the original card.

`settingsCurrentUserInfo() == nil` means **no new profile snapshot**. To represent logout explicitly:

```swift
func settingsCurrentUserInfo() async -> UserInfo? {
    loggedIn ? UserInfo(name: profile.name, avatar: profile.avatar)
             : UserInfo(name: "Guest", avatar: nil)
}
```

Also return the logged-out mail/account information and invoke `refreshState()`. A nil avatar in an explicit snapshot clears the old image.

## Lazy destinations

`SettingsDestinationFactory` is `@MainActor () -> UIViewController`. Factories run on an accepted tap, not when configuration is built. Return a fresh controller for each navigation.

```swift
SettingsRow(title: "Profile", icon: icon, destinationFactory: {
    ProfileController(service: accountService)
})

.defaultRow(.user("Name", avatar, destinationFactory: {
    ProfileController(service: accountService)
}))

PremiumPayload(isPremium: false, color: .systemBlue, destinationFactory: {
    UINavigationController(rootViewController: PaywallController(service: purchases))
})
```

Existing `SomeController.self` initializers remain available. Factories and actions are retained by configuration; avoid capturing an owner strongly if it also owns that configuration/controller. Prefer capturing independent dependencies or use an appropriate weak capture.

Routing uses the actual navigation/split container. Only an empty split placeholder is discarded on collapse. The existing compact-title policy for library-managed push destinations is retained.

## Ownership

`delegate:` remains weak. Explicit `dataProvider:` and `eventHandler:` arguments are retained by `SettingsConfiguration`. Do not make a retained provider hold its settings controller strongly; a weak property is usually appropriate.

Standalone `MailController(dataProvider:)` keeps its provider weak. Retain that provider in the host. A completed or cancelled mail request does not retain the controller for the full lifetime of a non-cooperative provider.

## Mail transport

The package prepares a draft and opens an external `mailto:` handler. It no longer rejects that route based on Apple Mail's `MFMailComposeViewController.canSendMail()` result. Opening the handler does not confirm delivery. The user reviews and sends the message in the mail app.

Failed opening preserves the draft and provides explicit Copy Address/Copy Message actions. Copying is user initiated. Diagnostics are not logged. Environment diagnostics now use the accurate label **Preferred Language**, derived from public locale APIs; this is not a promise to read the global system language independently of app language.

## Catalog and appearance

`ourApps(limit:)` values at or below zero hide the section and do not fetch. A successful empty result hides the section; errors display a retry row. Retry retains the original developer ID, limit and excluded app ID. Metadata uses protocol-defined HTTP cache semantics.

Theme selection uses the color's `rawValue`, including when a previously saved color was removed. Choosing a color no longer automatically requests an App Store review. The host can decide whether to request a review in its existing theme-change callback.

`AppItem` has a public initializer. No external-service container or new infrastructure protocols are required by host applications.

## Dismissal callback

For the library-created modal root, `settingsDidDismiss()` reports completion of that presentation once per session. It is not sent for a push to a child, a presented paywall, or a cancelled interactive dismissal. Arbitrary app-owned containers must manage their own navigation lifecycle and use explicit refresh notifications.

## Verification before rollout

Build and run the public example, then migrate one real host app. Verify external Settings/Mail/StoreKit on a device, the oldest supported OS, and the final host archive's privacy report. A successful build with deployment target 15.0 does **not** prove execution on iOS 15. Do not tag 4.0.0 until the release checklist is satisfied.
