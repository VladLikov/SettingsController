# Public integration example

This app imports the package normally and uses in-memory demo account/purchase data. It does not import Adapty, send mail automatically, or make real purchases.

From the repository root:

```sh
python3 scripts/generate-example.py
open Examples/SettingsExample/SettingsExample.xcodeproj
```

Select the `SettingsExample` scheme and an iPhone or iPad simulator. No third-party project generator is required. The generated project points to the local package; generation is deterministic.

The dashboard presents settings full screen or as a sheet. The profile factory supports rename and explicit guest logout. The paywall factory simulates purchase and restore, calling `refreshState()`. The provider is strongly owned while its settings reference is weak. The standalone mail example demonstrates the provider ownership requirement.

Language opens system Settings. The About update check and support actions are deliberately user-initiated external operations; the automated smoke tests do not invoke them.

```sh
bash scripts/test-example.sh
DEVICE_FAMILY=iPad bash scripts/test-example.sh
```

`IOS_RUNTIME=26.5` can select an installed runtime explicitly. Missing requested runtimes fail rather than silently choosing another version. Test output and screenshot attachments are stored under `.build/example-results/`.

For a device build, choose a signing team in Xcode. For Instruments, select Release/Profile and use the release checklist. Automated dark/RTL/large-text smoke checks do not certify full accessibility or real iOS 15 behavior.
