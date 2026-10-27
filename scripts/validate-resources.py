#!/usr/bin/env python3
"""Validate resource structure, not translation quality or App Store compliance."""
from collections import Counter
import json
from pathlib import Path
import plistlib
import re

root = Path(__file__).resolve().parents[1]
source = root / 'Sources/SettingsController'
catalog = json.loads((source / 'Resources/Localizable.xcstrings').read_text())
used = set()
for path in source.rglob('*.swift'):
    text = path.read_text()
    used.update(re.findall(r'NSLocalizedString\(\s*"((?:\\.|[^"\\])*)"', text))
    assert 'UserDefaults.globalDomain' not in text, f'Global preferences access: {path}'
    assert 'persistentDomain(forName:' not in text, f'Unexpected preferences access: {path}'
keys = set(catalog['strings'])
assert not used - keys, f'Missing localization keys: {sorted(used - keys)}'
assert not keys - used, f'Orphan localization keys: {sorted(keys - used)}'
locales = {locale for item in catalog['strings'].values() for locale in item.get('localizations', {})}
placeholder = re.compile(r'%(?:\d+\$)?(?:@|[diuoxXfFeEgGcs])')
for key, item in catalog['strings'].items():
    if item.get('shouldTranslate') is False:
        continue
    assert item.get('comment', '').strip(), f'Missing translator context: {key}'
    translations = item.get('localizations', {})
    assert set(translations) >= locales, f'Missing locales for {key}: {locales-set(translations)}'
    for locale, translation in translations.items():
        unit = translation.get('stringUnit', {})
        value = unit.get('value')
        assert isinstance(value, str) and value.strip(), f'Empty translation: {key}/{locale}'
        assert Counter(placeholder.findall(value)) == Counter(placeholder.findall(key)), f'Placeholder mismatch: {key}/{locale}'
with (source / 'Resources/PrivacyInfo.xcprivacy').open('rb') as handle:
    privacy = plistlib.load(handle)
assert isinstance(privacy.get('NSPrivacyTracking'), bool)
for name in ['NSPrivacyTrackingDomains', 'NSPrivacyCollectedDataTypes', 'NSPrivacyAccessedAPITypes']:
    assert isinstance(privacy.get(name), list), f'Invalid privacy key: {name}'
assert not (source / 'UI/Controllers/Preferences/LanguageController.swift').exists()
assert 'SwiftBoost' not in (root / 'Package.swift').read_text()
print(f'Validated {len(keys)} localization keys, {len(locales)} locales, placeholders and privacy plist structure.')
print('This does not certify translation accuracy, runtime accessibility or the host archive privacy report.')
