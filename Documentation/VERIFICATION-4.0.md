# Независимая проверка SettingsController 4.0

Дата: 27 октября 2026, Europe/Moscow. Проверка **не полная**: ограничения перечислены ниже. Merge, push, изменение тегов и релиз не выполнялись.

## Ревизии и изоляция

- Ветка сервера `codex/settingscontroller-4.0-hardening` получена отдельным `git clone --single-branch`; HEAD совпал с заданием: `a605541d84a773c53fcb14cb2dcda40946c7e746`.
- База сравнения: `e167a4e855ec11f570db83bba4a024d80d2d1230`. Проверены diff исходников, модели, routing, lifecycle, внешние операции, renderer, ячейки, тесты, CI и указанные документы.
- Исходный checkout `/Users/vladlikov/Documents/Codex Workspace/SettingsController` был чистым на `main`, HEAD `15fade9`; он не изменялся. Приложения-потребители не менялись.
- Локальная ветка проверки: `codex/independent-verification-4`. Исправления: `64f51fd`, `cc82322`, `6ec399c`; уточнение UI-селектора/keyboard onboarding: `1b6842e`, `bf72e26`; уточнение 18 существующих общих комментариев: `8ab84bc`. Финальная ревизия исходников и тестов: `8ab84bc328a57d005870cac7db7ca5f2cbf601a4` (тот же SHA в `tested-sha.txt` финальных прогонов). Отчёт может находиться в последующем documentation-only коммите.
- Все доказательства вне git: `.build/independent/`, `.build/verification/`, `.build/example-results/`. При передаче также приложены patch и source archive.

## Среда

Xcode 27.1 (27A9275), Swift 6.4 (`swiftlang-6.4.0.34.1`), SDK iOS/iOS Simulator 27.1, macOS 27.2, arm64. Не изменялись глобальный toolchain, signing, Codex/MCP configuration.

Установлены iOS runtimes 18.6, 27.0, 27.1; watchOS 27.0 и visionOS 27.0. Выбран `IOS_RUNTIME=27.0`: runtime 27.1 отклонил создание iPhone 17 Pro с `Incompatible device`; создание на 27.0 прошло. Это ограничение совместимости конкретного runtime/device, а не ошибка компиляции библиотеки. iOS 15 runtime отсутствует. Runtime 18.6 в этой проверке не запускался.

Созданы отдельные устройства:

| Устройство | Runtime | UDID |
|---|---|---|
| iPhone 17 Pro, iPhone Settings Verification | iOS 27.0 (24A434) | CB63421B-6537-4F06-BD44-DB93A8815F35 |
| iPad Pro 11-inch (M4), iPad Settings Verification | iOS 27.0 (24A434) | 73CE98B4-C294-4F51-9CDA-7AC436474CDC |

Обнаружены физические iPhone 16 Pro и iPhone 12 mini, оба iOS 27.2. Sample на них не устанавливался: его signing team не задана; менять её без отдельного разрешения запрещено. Наличие подключённого телефона не засчитывается как device QA.

## Подтверждённые дефекты и исправления

1. **MailController.setPreparingMail**: медленный provider заменял стандартный Send на `UIBarButtonItem(customView: progress)`, что нарушает заданные UIKit-правила; исходный Send оставался enabled. Новый `testPreparingMailKeepsStandardSendButtonDisabled` воспроизвёл три assertion failures на исходном коде. Исправление сохраняет один стандартный bar button и обновляет `isEnabled`. После отмены он снова доступен, текст сохранён. Доказательство: `.build/independent/mail-red.log` (три ожидаемых failures), исходный red bundle при наличии читаемого индекса, baseline/red логи и финальный package run.
2. **AppearanceController.titleForFooterInSection**: пояснение автоматической темы находилось в секции 2 ручного выбора. При `autoTheme=true` такой секции нет. Новый `testAutomaticAppearanceExplanationBelongsToSwitchSection` воспроизвёл три failures для обеих конфигураций. Footer перенесён в секцию 1 рядом с переключателем. Доказательство: `.build/independent/footer-red/test.log`, финальные unit/UI tests. Stale summary, скопированный до завершения red-run, сохранён отдельно с пометкой и не используется для totals.
3. **EmptyStateView**: scrolling viewport был ограничен safe area, вопреки требованию прокрутки под системными bars. Его четыре края привязаны к физическим краям root view; внутренний content layout сохранён. Добавлен `testEmptyDetailScrollViewportExtendsBehindSafeArea` с ненулевыми safe-area insets. Реальная rotation/collapse/expansion этим тестом не заменяется.
4. **Контекст локализации**: 56 translatable keys не имели top-level `comment`; CI-validator этого не замечал. Добавлен осмысленный контекст в Swift и catalog; дополнительно уточнены 18 уже заполненных, но слишком общих комментариев. Добавлена обязательная проверка комментариев в `validate-resources.py`. Тексты переводов не заменялись. Финальный экспорт Xcode подтвердил попадание комментариев в XLIFF: все 74 translatable units имеют notes, missing=0. Автоматический поиск длинных английских source-фраз, повторённых без изменений в неанглийских локалях, совпадений не нашёл; это не native-speaker review. Выявленный автоматически извлекаемый placeholder-only accessibility key `%@. %@. %@` устранён через `Text(verbatim:)` для объединения уже локализованных host-строк; лишний ключ не нужен переводчику.
5. **README**: исправлены устаревшие `.language(email:)`, SwiftBoost, минимальная версия CheckUpdate и указание несуществующего override `SIMULATOR_ID`. Теперь описаны реально поддерживаемые `DEVICE_FAMILY`/`IOS_RUNTIME`.
6. **Генератор sample**: source Info.plist и build settings получают `AdaptyAppleSearchAdsAttributionCollectionEnabled=true`, `ITSAppUsesNonExemptEncryption=false`, как требуют правила текущего задания. В собранном sample эти Boolean значения проверены; `MinimumOSVersion=15.0`. Подписывание не менялось. Sample не использует XcodeGen, поэтому относящиеся только к XcodeGen status-bar settings не вводились.

Результат обновлённого resource-validator дополнительно проверен отрицательным сценарием: удаление `About App.comment` в отдельной копии ресурсов вызывает ожидаемую ошибку `Missing translator context`, оригинальные файлы при этом не меняются.

Новая библиотека, архитектурный framework и публичный контейнер сервисов не создавались. Минимальный iOS 15 и Swift tools 6.3 сохранены. Assertions не ослаблялись; тесты не отключались; искусственные задержки не добавлялись.

## Автоматические результаты

| Финальный прогон | Passed | Failed | Skipped | Revision |
|---|---:|---:|---:|---|
| package / iPhone | 60 | 0 | 0 | `8ab84bc` |
| package / iPad | 60 | 0 | 0 | `8ab84bc` |
| UI / iPhone | 6 | 0 | 0 | `8ab84bc` |
| UI / iPad | 6 | 0 | 0 | `8ab84bc` |

Итоговые counts и SHA приведены в `final-results.json` рядом с этим отчётом в передаваемых outputs; в репозитории оригиналы находятся в `.build/verification/<family>/summary.json` и `.build/independent/apple-mcp/UI-<family>/summary.json`; `.build/example-results/` содержит промежуточные CLI UI-прогоны. Не смешивать package tests и UI tests.

Начальная ревизия до исправлений: package iPhone **57 passed / 0 failed / 0 skipped**. После первых исправлений: package iPhone и iPad **59 / 0 / 0**. Дополнительный benchmark: **1 / 0 / 0**, не включён в продуктовый набор. Исходные три UI tests на iPad: **3 / 0 / 0**; это промежуточный прогон, не доказательство последующего кода.

Финальные UI-прогоны выполнены официальным Apple Xcode MCP RunAllTests; оригинальные counts, список шести Passed tests, console log и xcresult сохранены в `.build/independent/apple-mcp/UI-<family>/`. Встроенная package-схема внутри sample вернула ноль тестов — это не засчитано как pass, package проверяется через CLI. Повторявшиеся ожидания CLI до старта XCTest сохранены отдельно; собственный derived data был пересоздан с сохранением старого каталога. Тестовые устройства и signing не сбрасывались.

Каждый финальный package-прогон сохраняет `tested-sha.txt`, `destination.txt`, `toolchain.txt` (package), `test.log`, `summary.json`, `.xcresult`; UI дополнительно экспортирует screenshots/manifest. Полные финальные команды/вызовы runner, exit codes CLI и counts MCP: `.build/independent/final/final-run-commands.json`. Предыдущие последовательные CLI batches сохранены отдельно в `commands.json` и historical logs; они не заменяют финальные результаты.

Классификация диагностик:

- Red-прогоны — реальные assertion failures новых регрессионных тестов, не ошибки компиляции. Первый расширенный UI run iPhone: 5 passed / 1 failed / 0 skipped; причина — новый тест ошибочно искал `Close`, тогда как сохранённая реальная hierarchy содержит системный label `close`. Селектор исправлен с привязкой к NavigationBar Contact; assertions сохранены. Screenshot также выявил штатный QuickPath introduction на свежем simulator: тест явно закрывает только этот onboarding, затем проверяет наличие keyboard. В промежуточном iPad-прогоне первые пять UI-сценариев прошли, mail превысил 120 с; после timeout XCTest продолжал действия, а прерывание дало внутреннюю диагностику Xcode и exit 75. Этот прогон сохранён отдельно и не подменён зелёным результатом; первопричина задержки не установлена. Окончательные шесть UI tests через Apple MCP прошли на обоих устройствах без failures/skips; исходный timeout не воспроизвёлся в этих прогонах. Это не доказывает его точную причину. Ошибка регистра Close классифицирована как ошибка тестового селектора, не дефект library Close. Доказательство: `.build/independent/mail-ui-failure/` и `.build/independent/before-selector-fix/`.
- Linker предупреждает, что XCTest текущего SDK собран для iOS 17 при deployment target тестового bundle 15. Это не меняет минимальный target библиотеки и не доказывает запуск на iOS 15.
- Xcode 27.1 печатает `IDESchemeActionSDKRecord ... invalidDigitCount(94232)`; отдельные red-процессы после завершения тестов не завершались. Остановлены только собственные зависшие PID. Не засчитывать зависший process exit как новый product failure.
- Simulator выводит дублирование классов WebKit accessibility bundles, а sample — предупреждения о future launch screen/orientation requirements. Эти сообщения сохранены, системные runtime bundles не редактировались.
- `validate-resources.py`: 79 ключей, 51 локаль, placeholders, отсутствие orphan/missing NSLocalizedString keys, структура privacy plist, отсутствие LanguageController/SwiftBoost, комментарии translatable keys.

## Контракты: сценарий → среда → результат → доказательство

| Сценарий | Среда | Результат и граница доказательства | Доказательство |
|---|---|---|---|
| Language | Package iPhone/iPad, fake openURL | Один public app Settings URL, без provider и промежуточного push | RoutingRegressionTests |
| Lazy custom/user factories, старый `.self` | Package | Factory вызывается при выборе; MainActor-тип, инъекция и routing проверены. Реальные повторные taps при всех split transitions не исчерпаны | RoutingRegressionTests, публичный sample |
| Mail escaping, Unicode/emoji/query/newlines | Package | Round-trip subject/body без потерь в URLComponents; дополнительный macOS Foundation сценарий сохранил 98 000 символов/118 000 UTF-8 bytes (URL 508 045 bytes). Реальный mail-клиент не проверен | MailRegressionTests, MailBuilderTests |
| Повторный Send, отказ open, медленный provider, отмена | Package | Single-flight, сохранение текста, fallback alert, поздний ответ после отмены не открывает mail; weak controller освобождается | MailRegressionTests |
| A→B→B complete→late A | Package | Последний refresh сохраняет premium/User ID; provider игнорирует cancellation | StateRegressionTests |
| Старый defer/handle | Package | Старый запрос не очищает новую операцию; network cancellation не открывает Store fallback | StateRegressionTests, RoutingRegressionTests |
| Premium true→false, карточка→Active→карточка | Package и sample UI | typed false имеет приоритет; исходный card payload восстановлен; постоянно видимый iPad список меняется | StateRegressionTests, UI profile/purchase/logout |
| nil profile vs guest | Package и sample | nil сохраняет snapshot; явный Guest очищает avatar; отсутствующий typed ID очищает About | StateRegressionTests |
| About без ожидания сети/поздних alert | Package | Immediate push; отменённый update/account response не применяется; network error даёт error alert | AboutRegressionTests |
| Каталог loading/loaded/empty/failed/Retry | Package, fixture URLProtocol | HTTP/JSON errors, limit<=0 без запроса, параметры Retry, индекс скрытой секции | CatalogRegressionTests |
| Image sharing/cache/scale/retry | Package | Отмена потребителя не ломает другого, разные scale/insets, retry после ошибки, target-sized bitmap | ImageAndLayoutRegressionTests, SettingsIconTests |
| Hosting/reuse/accessibility labels | Package | Legacy hosting 30 reconfigurations без накопления children/constraints; switch именован, reuse очищает action | ImageAndLayoutRegressionTests, SwitchAccessibilityTests |
| Split/overlay | Package | Удаляется только placeholder, реальный detail сохраняется; configured bottom inset восстанавливается | RoutingRegressionTests |
| Full-screen/sheet, profile, purchase/logout, factory | Sample UI | XCTest проходит реальные нажатия и readback; скриншоты изучаются отдельно | UI summary, attachments/manifest |
| Dark/RTL/AXXXL | Sample UI | Smoke и screenshot, не полная проверка всей длинной страницы/всех CTA | UI dark-rtl-large-text attachment |
| Restore, Appearance footer, mail keyboard/Close | Расширенные sample UI tests | Дополнительные сценарии финального набора; внешняя отправка не выполняется | UI final summary/attachments |
| Privacy bundle | Собранный sample Debug simulator | `SettingsController_SettingsController.bundle/PrivacyInfo.xcprivacy` реально включён | Проверка built app, plist/resource log |

## Визуальная проверка и ограничения инструментов

Просмотрены финальные screenshots iPhone и iPad с исправленным Appearance footer, открытой клавиатурой mail и сохранённым текстом, без обрезания CTA или перекрытия ввода. Также просмотрены реальные XCTest screenshots iPad: светлый sheet с настоящим Profile detail, Guest и восстановленная premium-карточка при остающемся видимым списке, тёмный RTL при максимальном accessibility text size. На просмотренных кадрах premium CTA и профиль не перекрываются. В RTL max-size длинные host-строки в узкой колонке переносятся на несколько строк; весь список в одном кадре не помещается. Это требует проверки прокрутки до последнего пункта, а не заключения по одному screenshot.

Официальный Apple Xcode MCP использован для обнаружения workspace/scheme/destination и InstallAndRun. Device Hub после успешного запуска сообщил противоречивые состояния `Session not found` / device owned by session / session nonexistent on End. После ограниченной проверки использован XcodeBuildMCP на том же iPhone. Screenshot/hierarchy dashboard доступны; два подтверждённых инструментом tap не изменили hierarchy, после другого tap появился SpringBoard. Причина не установлена; это **не подтверждённый дефект продукта** и не успешный ручной сценарий. Доказательство: `.build/independent/manual-ui/QA.md`, screenshot, hierarchy. Независимый XCTest на iPad успешно выполнял navigation/purchase/logout.

Полная VoiceOver focus/navigation и Reduce Motion runtime-проверка не выполнены. Статический `accessibilityLabel`/наличие `accessibilityReduceMotion` и зелёные tests этого не доказывают.

## Производительность и память

Временный benchmark выполнял исходный renderer из базы и текущий renderer в одном процессе, на одинаковых inputs, Debug, iPhone 17 Pro simulator iOS 27.0. Source image: 1024×2048 pt, scale 2 (2048×4096 px), inset 20; output: 30×30 pt, scale 2 (60×60 px), light traits. 7 cold samples на реализацию, чередующийся порядок old/new, перед каждым sample очистка соответствующего cache; после cold — 100 cache hits. Source creation не входит в таймер. Сырой вывод и harness сохранены, временные Swift files удалены из продуктового test target.

| Метрика, медиана | База e167a4e | Текущая реализация |
|---|---:|---:|
| cold render | 33,965 мс | 10,593 мс |
| cache hit | 0,01277 мс | 0,01216 мс |

Доказательство: `.build/independent/performance/{metrics.json,test.log,Performance.xcresult,VerificationPerformanceTests.swift,VerificationLegacyIcon.swift,LegacySettingsIcon.original.swift}`. Это узкий simulator microbenchmark; он не устанавливает ускорение всего settings, FPS, energy или release/device latency. Во время замера окружение не было эксклюзивно изолировано от другой работы.

Instruments templates доступны. Попытка Time Profiler attach к SettingsExample на тестовом iPhone завершилась `Cannot find process matching name: SettingsExample`, trace не получен. После явного RunProject через официальный Xcode MCP получен PID 74399 и успешно записан `Sample-Allocations.trace`: 10,647 с, template Allocations, iPhone simulator 27.0; оглавление сохранено в `allocations-toc.xml`. Trace покрывает idle dashboard, не многократные циклы. Memory Graph/Allocations для повторных settings/mail/About/profile/paywall sessions **не получены**. Проверки weak mail/controller lifetime и legacy hosting — ограниченные регрессии, не общий leak audit.

Воспроизводимое продолжение: открыть sample, выбрать нужный simulator, Product → Profile → Allocations/Time Profiler; поставить baseline после первого открытия; 30 раз открыть/закрыть settings, mail, About, profile и fake paywall, после каждого дождаться settled UI; сравнить living controllers, task allocations и persistent growth; снять Memory Graph после последнего закрытия. Для speed comparison использовать Release и один device/scale/input на обеих ревизиях, отдельно cold/cache, без параллельных прогонов.

## Непроверенные обязательные пункты

- Настоящее выполнение iOS 15; physical iPhone/iPad Settings route и локализация host.
- Apple Mail, third-party mail handler, отсутствие/refusal handler с длинными draft в реальном клиенте; Close/swipe cancel/complete/pop/programmatic dismissal во всех presentation вариантах.
- StoreKit/code-redemption/overlay на устройстве, включая tab bar/rotation/resize; реальные purchases/codes намеренно не выполнялись.
- Все комбинации compact/regular, rotation, resize, collapse/expansion, rapid factory taps, release всех destination controllers; root modal dismissal callbacks при отменённых интерактивных жестах.
- Все update-result UI варианты (нет обновления/доступно/ошибка), catalog superseded retry в реальном scroll/reuse UI, trait refresh каждой видимой ячейки без прокрутки.
- VoiceOver focus, Switch Control, контраст, Reduce Motion, длинные локализованные строки всех экранов; native-speaker review 51 локали.
- Общий MainActor/retain/task audit через Memory Graph и Allocations.
- Финальный privacy report реального host archive и пробная миграция реального потребителя. Проверка package plist структуры и отсутствия direct required-reason API в просмотренных исходниках не сертифицирует host и зависимости.

## Ручной запуск

Из корня проверяемого checkout (использовать установленный совместимый runtime):

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
python3 scripts/validate-resources.py
DEVICE_FAMILY=iPhone IOS_RUNTIME=27.0 bash scripts/test-ios.sh
DEVICE_FAMILY=iPad IOS_RUNTIME=27.0 bash scripts/test-ios.sh
DEVICE_FAMILY=iPhone IOS_RUNTIME=27.0 bash scripts/test-example.sh
DEVICE_FAMILY=iPad IOS_RUNTIME=27.0 bash scripts/test-example.sh
python3 scripts/generate-example.py
open -a /Applications/Xcode.app Examples/SettingsExample/SettingsExample.xcodeproj
```

Команды запускать последовательно. В Xcode выбрать SettingsExample и выделенный simulator. Проверить Open full screen / Open sheet; Demo User → Rename; Premium → fake purchase/restore; Log out; Appearance/Automatically; About User ID; Standalone mail. Не нажимать реальную отправку или redemption. Примеры не должны использовать приватные Settings URLs.

Для benchmark скопировать два сохранённых `Verification*.swift` из evidence/performance в `Tests/SettingsControllerTests/`, выполнить `xcodebuild -scheme SettingsController -destination 'platform=iOS Simulator,id=CB63421B-6537-4F06-BD44-DB93A8815F35' -derivedDataPath .build/xcode -only-testing:SettingsControllerTests/VerificationPerformanceTests test CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=15.0`, затем убрать только эти временные файлы и повторить продуктовые tests. Legacy fixture содержит код базы и переименование типов, не альтернативную production library.

## Пробное подключение к одному приложению и откат

План, **не выполненная миграция**: выбрать отдельную integration-ветку одного реального приложения, сохранить чистый status/его текущий Package.resolved и точную package revision. В Xcode заменить SettingsController requirement на проверяемую revision (либо локальный checkout для первоначального smoke); не использовать `from: 4.0.0` до существования release tag. Для remote revision сначала потребуется отдельно разрешённый push локальных исправлений; сейчас они только локальные.

Применить MIGRATION-4.0: `.language`; убрать дублирующий userID/adaptyProfileID; передавать Adapty profile ID обычной строкой `SettingsMailInfo.userID`; обновлять состояние после purchase/restore/logout/profile edit; logout = guest snapshot + account info без ID. Убедиться, что CheckUpdate разрешён как 1.0.1 и поддерживаемые локали host настроены. Собрать, пройти full-screen/sheet/iPad/account/mail/Settings, проверить archive privacy report. Не менять signing/team и минимальный iOS.

Откат: вернуть одним integration commit прежние API-вызовы приложения, package requirement и сохранённый Package.resolved; resolve/build/smoke на прежней точной ревизии. Не удалять данные приложения и не двигать теги.

## Готовность

**Merge:** финальные package tests — 60/60 на каждом устройстве, UI tests — 6/6 на каждом, failures/skips=0. Автоматические результаты и локальные исправления позволяют продолжить review, но безусловная готовность к merge не подтверждена: остаются перечисленные обязательные runtime/lifecycle/memory проверки. Локальные изменения ещё не находятся в PR.

**Релиз 4.0.0:** не готов к подтверждению. Нужны device/oldest-OS/mail/accessibility/profile/archive/real-host evidence по release checklist. Не считать отсутствие воспроизведённого дефекта доказательством полноты проверки.
