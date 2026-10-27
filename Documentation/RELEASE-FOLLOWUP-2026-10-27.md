# Исправления после сверки плана 4.0.0

27 октября 2026. Функциональная ревизия библиотеки — `10ecf605309155da7e2cb9e41a0e6370c91d63b4`; генератор synchronized sample — `7c41ec6`, semantic Mail accessibility IDs — `095e2e9`. После уточнения пользователя вся дальнейшая работа ведётся только внутри `/Users/vladlikov/Downloads/app store current app lock/AppLock`.

## Исправлено

- Mail показывает native activity indicator и текст Preparing message… над редактором. Send остаётся стандартной navigation action и заблокирован до завершения/отмены. Header адаптируется по ширине и высоте; отмена убирает spinner и сохраняет draft.
- Новый статус переведён активным агентом на все 51 существующую локаль с контекстом в Swift и catalog. Validator: 80 ключей/51 локаль, JSON/comments/placeholders/coverage passed. Реальная языковая/визуальная приёмка каждой локали отдельно не выполнена.
- Регрессия Mail проверяет видимый header, animating state, сохранение стандартного Send и очистку после отмены. Public sample UI проверяет медленный provider, disabled Send и Close без внешнего mail.
- Добавлены сценарии CheckUpdate current/update available/incompatible OS и защита результата каталога от старого ответа после нового запроса.
- CHANGELOG дополнен Duo, compiler/runtime requirements и loading state Mail.
- Генератор public sample использует synchronized source folder с membership exceptions между app и UI-test targets. Top-level project/products containers остаются служебными PBXGroup, source folders не представлены classic groups. Signing settings не менялись.

## Подтверждённые результаты

| Набор | Passed | Failed | Skipped |
| --- | ---: | ---: | ---: |
| Package / Duo27.1 |64|0|0|
| Package / iPhone27.0 |62|0|2|
| Package / iPad27.0 |62|0|2|
| Public sample UI / iPhone27.0 |7|0|0|
| Public sample UI / iPad27.0 |7|0|0|
| AppLock migration integration / Duo27.1 |2|0|0|
| Duo Mail UI after native toolbar locator fix095e2e9 |2|0|0|

Два пропуска на 27.0 — только Duo-specific тесты, выполненные на 27.1. Package iPhone был проверен на 1070232, последующий 10ecf60 менял только sample; production Sources/Tests package идентичны. Package iPad/Duo и public sample UI — 10ecf60. Проверка source после переноса подтверждает тот же commit/tree. AppLock сохраняет исходные незакоммиченные файлы; миграционный патч строится относительно сохранённых фактических файлов, а не старого git HEAD приложения.

## Duo native toolbar и инструментальные ограничения

На новом Duo с вертикальным toolbar Close/Send находятся вне accessibility subtree `NavigationBar(Contact)`. Первый полный UI-прогон нового sample дал5 passed/2 failed из-за этого неверного test locator. В стандартные UIBarButtonItem добавлены `settings.mail.close` / `settings.mail.send`; tests находят native buttons глобально по этим идентификаторам, без customView и изменения bar appearance. Assertion enabled/disabled, tap и readback сохранены.

Следующий runner завис до первого UI-действия. После ограниченных попыток остановлены только собственные процессы и перезапущен только выделенный Duo89AED16E без erase/сброса данных. Отдельные результаты двух затронутых Mail tests сохранены отдельно; не смешивать их со старым полным7-test run.

## Измерение allocations выполнено

Получен `Renderer-Allocations.trace` в Instruments27.1 на отдельном Duo27.1 simulator. В одном процессе один source image1024×2048pt @2, inset 20, destination 30×30pt @2. Source создаётся до записи. По 20 cold renders каждого renderer, old/new порядок чередуется, cache очищается перед каждым рендером. Benchmark изолирован временными fixtures; они удалены из product test target после прогона.

В native Instruments UI: Call Trees → Created & Destroyed → All Heap & Anonymous VM. Для стека `renderSettingsTileImage`:

| Реализация | Суммарные temporary allocations, rounded MB |
| --- | ---: |
| Legacy из e167a4e |2005,56|
| Текущая |8,59|

Это реальные созданные и освобождённые allocations за 20 renders, включая framework allocations в этом стеке. Это не peak RSS, не память всего приложения и не Release/device результат. Данные прочитаны через native Instruments accessibility state; trace, harness, provenance, signpost export и workload log сохранены в `.settings-4-verification/library-evidence/profiling`. Workload и запись завершились с exit0, лог содержит 40 renders. Общий Memory Graph/leak audit повторных экранных сессий всё ещё не выполнен.

## Пробная миграция AppLock

Проект: `AppLock/AppLock.xcodeproj` внутри указанной тестовой папки. Локальная package reference ведёт к соседней `SettingsController-4.0-local`, поэтому локальные исправления доступны без push/release.

- `.language(email:)` заменён на `.language`, separate About userID удалён.
- Оба standalone Mail call sites переведены на provider. Home и SceneDelegate передают typed `SettingsMailInfo.userID`; standalone providers удерживаются существующим Home/Scene lifecycle.
- Home хранит settings controller weak. Account/premium изменения дают notification только при изменившемся значении; Home получает его на main run loop и вызывает explicit refresh. После закрытия paywall также выполняется refresh.
- Configuration всегда сохраняет исходный premium card payload, чтобы Active→inactive восстанавливал исходную карточку и при первоначальном premium=true.
- Source Info.plist дополнен ITSAppUsesNonExemptEncryption=false; Adapty attribution key=true сохранён и добавлен в app build settings. Development team, code-sign style, identities и profiles сравнивались с backup и не менялись.
- Реальный host собран официальным Apple MCP. Два интеграционных теста прошли: typed ID/card restoration и notification deduplication. Первое MCP-сообщение о неполном result было преждевременным: закрывшийся original bundle содержит 2 passed. Резервный прогон также 2/0/0; он не учитывается как дополнительные уникальные тесты.
- Исходные версии изменённых файлов — `.settings-4-verification/original-files`; точный patch, hashes и rollback.py рядом. Rollback по умолчанию только dry run, при несовпадении текущего hash отказывается затирать более поздние изменения. Существующий git index приложения не менялся.

## Host archive и privacy

Получен локальный Release unsigned archive `.settings-4-verification/AppLock-SC4-unsigned.xcarchive`. В существующий Crashlytics phase добавлен только opt-in build flag `SETTINGS_CONTROLLER_PRIVACY_AUDIT=YES`: он вызывает нативный `upload-symbols --build-phase --validate` и не загружает dSYM. При отсутствии флага обычная сборка работает как раньше. Script sandbox и signing settings не ослаблялись. Встроенный CLI help подтверждает семантику --validate.

В archive 26 privacy manifests, в том числе host и SettingsController. Оба совпадают с текущими source manifests байт в байт. В built app проверены attribution=true и ITSAppUsesNonExemptEncryption=false. `PRIVACY-INVENTORY.md` / JSON сохраняют пути, hashes и содержимое. Это inventory, а не официальный Xcode PDF.

Archive относится к ревизии до accessibility-ID-only patch095e2e9; privacy source hashes после неё совпадают. Повторный archive был остановлен при зависании окружения и не считается завершённым. Экспорт официального PDF пытались выполнить по [документации Apple](https://developer.apple.com/documentation/bundleresources/describing-data-use-in-privacy-manifests), но CUA/Xcode UI тайм-аутил даже после bounded recovery. PDF не получен; archive inventory не закрывает этот пункт полностью.

## Пределы готовности

Остаются: real iOS15 runtime/старый toolchain, физические Mail/Settings/StoreKit/overlay, полная lifecycle/iPad resize/VoiceOver/Reduce Motion/layout matrix, general Memory Graph и linguistic review. Пробная migration build/integration tests не равны реальным purchase/restore или полной AppLock device QA. 4.0 остаётся Unreleased; push, merge и tag не выполнялись.

## Итоговая ревизия095e2e9

Полный package-прогон в разрешённой тестовой папке:64 passed/0 failed/0 skipped. Два Mail UI-сценария на Duo после исправления locator:2/0/0. Остальные5 сценариев прошли в исходном7-test прогоне до identifier-only patch. Это не выдаётся за единый последний7/7 run: исходные два locator failures и прерванные инструментальные прогоны сохранены отдельно.

`FINAL-RESULTS.json` рядом с app evidence фиксирует SHA и границы подтверждения. Production code и smoke tests AppLock находятся только в указанной пользователем тестовой папке. Consumer original git index и посторонние незакоммиченные файлы не изменялись. Rollback dry run проверил8 migration files. Signed distribution, push, merge и release tag не выполнялись.
