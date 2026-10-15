import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const appRoot = path.join(root, 'RealEstateMileageTracker');
const catalog = JSON.parse(fs.readFileSync(path.join(appRoot, 'Localizable.xcstrings'), 'utf8'));
const languages = ['en', 'zh-Hans', 'zh-Hant'];
const placeholders = text => (text.match(/%(?:\d+\$)?(?:lld|ld|d|@|f)/g) ?? []).sort();

for (const [key, entry] of Object.entries(catalog.strings)) {
    for (const language of languages) {
        const unit = entry.localizations[language]?.stringUnit;
        assert.equal(unit?.state, 'translated', `${language}: ${key}`);
        assert.ok(unit.value.length > 0, `${language}: empty ${key}`);
        assert.deepEqual(placeholders(unit.value), placeholders(key), `${language}: placeholders for ${key}`);
    }
}

for (const language of ['zh-Hans', 'zh-Hant']) {
    const permissionFile = path.join(appRoot, `${language}.lproj`, 'InfoPlist.strings');
    execFileSync('plutil', ['-lint', permissionFile]);
    const permissions = JSON.parse(execFileSync('plutil', ['-convert', 'json', '-o', '-', permissionFile], { encoding: 'utf8' }));
    for (const key of ['NSLocationWhenInUseUsageDescription', 'NSLocationAlwaysAndWhenInUseUsageDescription', 'NSLocationAlwaysUsageDescription', 'NSMotionUsageDescription']) {
        assert.ok(permissions[key]?.length > 0, `${language}: ${key}`);
    }
}

// Exercise the actual persisted-purpose enum without requiring GPS or app data.
const tripSource = fs.readFileSync(path.join(appRoot, 'Models', 'Trip.swift'), 'utf8');
const purposeSource = tripSource.slice(tripSource.indexOf('enum TripPurpose:'));
const checks = `
for purpose in TripPurpose.allCases {
    precondition(TripPurpose.fromStoredValue(purpose.rawValue) == purpose)
    precondition(!purpose.reportName.isEmpty)
}
precondition(TripPurpose.fromStoredValue("Repair/Maintenance") == .repair)
precondition(TripPurpose.fromStoredValue("Personal") == .bankingDeposit)
precondition(TripPurpose.fromStoredValue("Banking/Deposits") == .bankingDeposit)
precondition(TripPurpose.bankingDeposit.rawValue == "bankingDeposit")
precondition(TripPurpose.bankingDeposit.reportName == "Banking & Deposits")
precondition(TripPurpose.migratedStoredValue("My custom purpose") == "My custom purpose")
precondition(TripPurpose.migratedStoredValue("我的物業") == "我的物業")
`;
execFileSync('swift', ['-module-cache-path', '/private/tmp/landmile-swift-cache', '-'], {
    input: 'import Foundation\n' + purposeSource + '\n' + checks,
    encoding: 'utf8'
});

const builtApp = process.argv[2];
if (builtApp) {
    for (const language of ['zh-Hans', 'zh-Hant']) {
        const file = path.join(builtApp, `${language}.lproj`, 'Localizable.strings');
        const built = JSON.parse(execFileSync('plutil', ['-convert', 'json', '-o', '-', file], { encoding: 'utf8' }));
        for (const key of ['Trips', 'Settings', 'Country & Reporting', 'Banking & Deposits', 'Every business mile\ncan be worth up to $0.76.']) {
            assert.equal(built[key], catalog.strings[key].localizations[language].stringUnit.value);
        }
        assert.ok(fs.existsSync(path.join(builtApp, `${language}.lproj`, 'InfoPlist.strings')));
    }
}

console.log(`PASS: ${Object.keys(catalog.strings).length} keys in three languages, placeholders, permissions, stable purpose IDs and legacy migration${builtApp ? ', compiled resources' : ''}`);
