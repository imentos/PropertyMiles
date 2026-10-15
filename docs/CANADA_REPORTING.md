# Canadian Reporting

Select Canada in Settings > Country & Reporting or on the welcome screen.
Devices using the Canada region default to Canada unless a country was selected.
This follows device region, not the App Store account or GPS location.

- Trip storage and GPS recording remain in miles. Displays and CSV exports
  convert to kilometres using exactly 1 mile = 1.609344 kilometres.
- Canadian mode defaults to distance-only records without monetary estimates.
- An optional custom CAD/km rate calculates reimbursement estimates for selected
  trips. It is not a CRA deduction or a currency conversion. Changing the rate
  recalculates estimates for existing trips too.
- US mode continues using existing date-based IRS calculations, labelled US$.
- Subscription prices come from StoreKit independently of the reporting country.
- Canadian mode does not calculate actual vehicle expenses or business-use
  percentages, and does not claim CRA approval or a complete tax return.

CRA references:

- https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/sole-proprietorships-partnerships/report-business-income-expenses/completing-form-t2125/calculating-motor-vehicle-expenses.html
- https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/rental-income/completing-form-t776-statement-real-estate-rentals/rental-expenses-you-deduct.html

## Automated Checks

Run from the repository root:

```sh
swiftc -module-cache-path /private/tmp/landmile-swift-cache RealEstateMileageTracker/Models/MileageReporting.swift scripts/test-mileage-reporting.swift -o /private/tmp/landmile-reporting-checks
/private/tmp/landmile-reporting-checks
```

## Device Checks Before Release

- Switch US to Canada with existing trips; compare distances with the conversion
  above, and verify original stored trips remain intact after switching back.
- With a zero custom rate, confirm no dollar estimates appear in trip rows,
  details, reports or CSV exports.
- Enter a custom rate and verify CA$ estimates and CAD-labelled CSV amounts.
- Export location names containing commas and quotes and open in a spreadsheet.
- Restart the app and confirm country and rate preferences persist.
- Check onboarding in Canadian mode and StoreKit's Canadian subscription prices.
- Confirm country switching updates all visible trip and report summaries.
