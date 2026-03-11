# Property Miles - App Store Submission Plan

## App Information

**App Name:** Property Miles  
**Subtitle:** Mileage Tracker for Real Estate  
**Category:** Primary: Productivity | Secondary: Finance  
**Price:** Free (with optional in-app purchases for future premium features)

---

## ASO (App Store Optimization)

### App Name Strategy
**Property Miles** - Short, memorable, includes primary keyword "Miles"

### Subtitle (30 characters max)
**Option 1:** `Mileage Tracker for Real Estate` (30 chars) [RECOMMENDED]  
**Option 2:** `Real Estate Mileage Logger` (27 chars)  
**Option 3:** `Auto Track Agent Drives` (23 chars)

### Keywords (100 characters max)
```
mileage,tracker,real estate,agent,tax,deduction,irs,property,driving,log,automatic,trip,expense,reimbursement,realtor
```

**Character count:** 99

**Keyword Research:**
- High volume: mileage tracker, tax deduction, irs mileage
- Niche: real estate agent, realtor, property visits
- Long-tail: automatic mileage log, driving expense tracker

### Promotional Text (170 characters max)
```
Automatic trip detection for real estate professionals
IRS-compliant mileage logs at $0.67/mile
Tag trips to properties for easy tax reporting
```

---

## App Description

### Short Description (First 3 lines - critical for ASO)
```
Property Miles automatically tracks your driving mileage and creates IRS-compliant reports for real estate professionals. Never miss a tax deduction again.

Save time and maximize deductions with automatic trip detection, property tagging, and one-tap CSV exports for your accountant.
```

### Full Description
```
AUTOMATIC MILEAGE TRACKING FOR REAL ESTATE AGENTS

Property Miles is designed specifically for real estate agents, property managers, and real estate professionals who need accurate mileage logs for tax deductions.

KEY FEATURES:

AUTOMATIC TRIP DETECTION
• Detects drives automatically when you exceed 10 mph
• Works in the background - no need to remember to start tracking
• Ends trips after 3 minutes stopped
• Tracks both driving and cycling

PROPERTY & LOCATION TAGGING
• Tag trips to specific properties
• Save frequent locations (office, staging warehouse, etc.)
• Auto-assign trips to saved locations
• Organize trips by purpose: showings, open houses, inspections

IRS-COMPLIANT REPORTING
• Built-in IRS standard mileage rate ($0.67/mile for 2026)
• Generate period reports (monthly, quarterly, yearly)
• One-tap CSV export for tax filing
• Detailed trip history with dates, times, and distances

VEHICLE MANAGEMENT
• Track multiple vehicles
• Add vehicle details (make, model, year, VIN)
• Assign trips to specific vehicles

SMART ANALYTICS
• View total miles and tax deductions
• Filter by date range
• Breakdown by trip purpose
• Track personal vs. business miles

PERFECT FOR:
• Real estate agents tracking property showings
• Property managers visiting rental units
• Real estate photographers traveling to listings
• Home inspectors visiting multiple properties
• Anyone in real estate who drives for business

PRIVACY & SECURITY:
• All data stored locally on your device
• No account required
• Location data never shared or sold
• Export your data anytime

TAX DEDUCTION EXAMPLE:
Drive 1,000 miles per month for property visits = $670/month in tax deductions = $8,040/year saved!

Download Property Miles today and start maximizing your mileage deductions.

BACKGROUND LOCATION USAGE:
Property Miles uses location services in the background to automatically detect and track your trips. This allows the app to work seamlessly without needing to open it before each drive. You can disable automatic tracking anytime in Settings.

NOTE: Continued use of GPS running in the background can dramatically decrease battery life. Property Miles is optimized for automotive navigation to minimize battery impact.
```

---

## Screenshots Plan

### iPhone (Required: 3-10 screenshots, 6.7" display - iPhone 15 Pro Max)

**Screenshot 1: Hero/Main Feature**
- Trips list with current trip banner
- Caption: "Automatic Trip Tracking - Works in Background"

**Screenshot 2: Trip Detail**
- Trip detail view with map, distance, purpose
- Caption: "Tag Trips to Properties & Purposes"

**Screenshot 3: Location Nicknames**
- Location management screen
- Caption: "Save Frequent Locations for Quick Tagging"

**Screenshot 4: Reports**
- Reports screen showing monthly summary
- Caption: "IRS-Compliant Reports & CSV Export"

**Screenshot 5: Vehicle Management**
- Vehicles list
- Caption: "Track Multiple Vehicles"

**Screenshot 6: Export Preview**
- Export share sheet or CSV preview
- Caption: "One-Tap Export for Your Accountant"

### Design Guidelines:
- Use device frames
- Add text overlays with key benefits
- Show realistic data (not empty states)
- Consistent color scheme matching app
- Professional, clean aesthetic
- Consider adding before/after comparison (manual tracking vs. automatic)

---

## App Icon Checklist

- [ ] 1024x1024 PNG (no transparency, no alpha channel)
- [ ] Professional design
- [ ] Recognizable at small sizes
- [ ] No text (or minimal/large text only)
- [ ] Follows iOS design guidelines
- [ ] Represents core function (car/route/map/miles)

**Icon Concept Ideas:**
- Car icon with location pin
- Road with mile markers
- Speedometer with property icon
- Route path forming house shape

---

## App Store Connect Checklist

### App Information
- [ ] App name: Property Miles
- [ ] Subtitle: Mileage Tracker for Real Estate
- [ ] Primary category: Productivity
- [ ] Secondary category: Finance
- [ ] Keywords (100 char limit)
- [ ] Promotional text (170 char)
- [ ] Description (4000 char max)

### Pricing & Availability
- [ ] Free
- [ ] Available in all territories
- [ ] No pre-order

### App Privacy
**Data Collection:**
- [ ] Location data (for trip tracking) - NOT linked to user
- [ ] Usage data (crashes) - NOT linked to user

**Privacy Policy URL:** Required
- [ ] Create privacy policy page
- [ ] Host at: `https://[your-domain]/privacy-policy-property-miles.html`

**Privacy Practices:**
- Location: Used for mileage tracking
- Data not sold to third parties
- Data not used for tracking across apps
- User can delete data anytime

### Age Rating
- [ ] 4+ (No objectionable content)

### App Review Information
**Contact Information:**
- [ ] First name
- [ ] Last name
- [ ] Phone number
- [ ] Email address

**Demo Account:** Not required (no login)

**Notes for Review:**
```
Property Miles is a mileage tracking app for real estate professionals.

KEY TESTING POINTS:
1. Grant "Always Allow" location permission when prompted
2. Enable "Auto-Track Trips" in Settings tab
3. Simulate location in Xcode (Freeway Drive or City Run) to trigger trip detection
   - Or drive in a real vehicle for authentic testing
4. Wait 3 minutes after stopping to see trip save automatically
5. Tap a saved trip to edit purpose, add property, view on map

BACKGROUND LOCATION JUSTIFICATION:
The app requires background location to automatically detect trips without user intervention. This is the core value proposition - agents don't need to remember to start/stop tracking manually. Location data is stored only on the device and never transmitted to servers.

The app uses CLLocationManager with:
- .authorizedAlways permission
- .automotiveNavigation activity type (battery optimized)
- Significant location change monitoring for background wake
- Speed-based trip detection (>10 mph to start)

No sensitive or personal data beyond location coordinates is collected.
```

### Build Details
- [ ] Version: 1.0
- [ ] Build number: 1
- [ ] Export compliance: No (not using encryption)

---

## Privacy Policy (Required)

### Create Privacy Policy Page

**URL:** `https://imentos.github.io/PropertyMiles/privacy-policy.html`

**Key Sections:**
1. Information Collection
   - Location data (latitude/longitude, timestamps)
   - Trip details (distance, duration, addresses)
   - User-entered data (property names, vehicle info, notes)

2. How We Use Information
   - Enable automatic trip tracking
   - Calculate mileage and deductions
   - Generate reports and exports
   - All processing happens on-device

3. Data Storage
   - Stored locally on user's device using iOS UserDefaults
   - No cloud sync or backup
   - Not transmitted to any servers
   - User can delete all data via Settings

4. Third-Party Services
   - Apple Maps (for reverse geocoding addresses)
   - No analytics or tracking SDKs

5. Data Sharing
   - Data is NOT shared, sold, or transmitted
   - User can export their own data via CSV

6. Children's Privacy
   - Not intended for children under 13
   - No knowingly collected children's data

7. Changes to Privacy Policy
   - Will notify via app update notes

8. Contact
   - Email for privacy questions

---

## TestFlight Beta Testing (Optional but Recommended)

### Beta Testing Plan
1. **Internal Testing** (1-2 days)
   - Test on personal devices
   - Verify all features work
   - Check for crashes

2. **External Beta** (1 week)
   - Invite 10-20 real estate agents
   - Collect feedback on:
     - Trip detection accuracy
     - Battery impact
     - Report usefulness
     - Missing features
   - Iterate based on feedback

3. **Beta Feedback Questions:**
   - Did the app accurately detect your trips?
   - Were there any false positives (non-driving trips)?
   - How was the battery impact?
   - Is the 3-minute stop threshold right, or too long/short?
   - What features are missing?
   - Would you pay for premium features? Which ones?

---

## Launch Strategy

### Pre-Launch (2 weeks before)
- [ ] Prepare all screenshots
- [ ] Write/host privacy policy
- [ ] Submit for App Review
- [ ] Create landing page (optional)
- [ ] Prepare social media posts

### Launch Day
- [ ] Monitor for App Review approval (usually 24-48 hours)
- [ ] Reply promptly to any review questions
- [ ] Once approved, announce on:
  - Real estate Facebook groups
  - LinkedIn
  - Real estate forums (BiggerPockets, reddit.com/r/realtors)
  - Twitter/X with hashtags: #realestate #mileagetracker #taxdeductions

### Post-Launch (First Week)
- [ ] Monitor reviews and respond
- [ ] Track downloads in App Store Connect
- [ ] Fix any critical bugs immediately
- [ ] Collect user feedback for v1.1

### Post-Launch (First Month)
- [ ] Request reviews from happy users (via in-app prompt)
- [ ] Analyze which keywords are driving traffic
- [ ] A/B test screenshots if needed
- [ ] Plan next features based on feedback

---

## Target Keywords to Rank For

### Primary Keywords (High Priority)
1. mileage tracker
2. real estate mileage
3. mileage log
4. irs mileage tracker
5. tax deduction tracker

### Secondary Keywords
6. realtor mileage app
7. automatic mileage log
8. property mileage tracker
9. real estate expense tracker
10. driving log for taxes

### Long-Tail Keywords
11. real estate agent mileage tracker
12. irs compliant mileage log
13. automatic trip detection
14. property visit tracker
15. real estate tax deduction app

---

## Future Premium Features Ideas (IAP)

Consider for v1.1 or v2.0:
- Cloud sync across devices
- Team/brokerage sharing
- Advanced analytics & charts
- Photo attachments for trips
- Expense tracking (gas, tolls, parking)
- Integration with accounting software (QuickBooks, FreshBooks)
- Geofencing for automatic property detection
- Voice notes for trips
- Client contact integration

**Pricing Ideas:**
- Free: Basic tracking + reports (100 trips/year)
- Pro ($4.99/month or $39.99/year): Unlimited trips + cloud sync + advanced reports
- Team ($14.99/month): Multi-user for brokerages

---

## Pre-Submission Checklist

### Technical Requirements
- [ ] Build compiles without errors
- [ ] No crashes during testing
- [ ] Tested on iOS 16+ devices (iPhone only)
- [ ] Location permission prompt has clear explanation
- [ ] Background location justified in Info.plist
- [ ] App works without internet (offline first)
- [ ] Proper error handling for permission denials

### Content Requirements
- [ ] App icon (1024x1024)
- [ ] 6 iPhone screenshots (6.7" display)
- [ ] Optional: App preview video (15-30 seconds)
- [ ] Privacy policy hosted and accessible
- [ ] Support URL or email
- [ ] Marketing URL (optional)

### Metadata
- [ ] App name (max 30 chars)
- [ ] Subtitle (max 30 chars)
- [ ] Keywords (max 100 chars)
- [ ] Promotional text (max 170 chars)
- [ ] Description (max 4000 chars)
- [ ] Copyright notice
- [ ] What's new in this version

### Legal
- [ ] Trademark search for "Property Miles"
- [ ] Privacy policy complies with Apple's requirements
- [ ] No misleading screenshots or descriptions
- [ ] Accurate feature descriptions

### Review Guidelines Compliance
- [ ] No placeholder content
- [ ] No unfinished features
- [ ] Clear explanation of background location usage
- [ ] No requests for unnecessary permissions
- [ ] Follows iOS Human Interface Guidelines

---

## Support Plan

### Support Channels
1. **In-App:** Settings → Help & Support (mailto link)
2. **Email:** support@[your-domain].com
3. **Website:** FAQ page with common questions

### FAQ to Prepare
1. How does automatic trip detection work?
2. Why does the app need "Always Allow" location permission?
3. How does this affect my battery life?
4. Can I edit or delete trips?
5. How do I export my mileage report?
6. What's the IRS mileage rate for [current year]?
7. Can I use this for non-real estate purposes?
8. Is my data private and secure?
9. How do I add a property/location?
10. Why didn't a trip get recorded?

---

## Success Metrics

### Week 1 Goals
- 100 downloads
- 4+ star average rating
- <5% crash rate
- 50%+ users grant "Always" location permission

### Month 1 Goals
- 500 downloads
- 20+ written reviews (4+ stars)
- Rank in top 200 for "mileage tracker"
- 10%+ Daily Active Users (DAU)

### Month 3 Goals
- 2,000 downloads
- Feature in "New Apps We Love" or similar
- Organic growth from App Store search
- User testimonials for website

---

## App Preview Video Script (Optional)

**Length:** 15-30 seconds

**Scene 1 (0-5s):** 
- Show phone in pocket, map view zooming along route
- Text: "Automatically tracks your drives"

**Scene 2 (5-10s):**
- Trip saves, user taps to open trip detail
- Text: "Tag trips to properties"

**Scene 3 (10-15s):**
- Reports screen, CSV export
- Text: "Export for taxes instantly"

**Scene 4 (15-20s):**
- App icon + name
- Text: "Property Miles - Mileage Tracker for Real Estate"

---

## Timeline

### Week 1: Preparation
- Day 1-2: Create all screenshots
- Day 3: Write privacy policy
- Day 4: Prepare all metadata
- Day 5: Final testing
- Day 6-7: Submit to App Review

### Week 2: Review & Launch
- Day 8-10: Waiting for review (typical: 24-48 hours)
- Day 11: Respond to any review questions
- Day 12: LAUNCH DAY
- Day 13-14: Monitor reviews, fix urgent bugs

### Week 3-4: Post-Launch
- Collect feedback
- Plan v1.1 features
- Optimize ASO based on analytics
- Reach out to real estate influencers/bloggers

---

## URLs Needed

1. **Privacy Policy:** `https://imentos.github.io/PropertyMiles/privacy-policy.html`
2. **Support/Help:** `https://imentos.github.io/PropertyMiles/support.html`
3. **Marketing Site (optional):** `https://imentos.github.io/PropertyMiles/`
4. **Terms of Service (optional):** `https://imentos.github.io/PropertyMiles/terms.html`

---

## Notes

- Real estate is a competitive niche but underserved in App Store
- Key differentiator: Automatic tracking + property-specific features
- Target both new agents (need to track everything) and experienced agents (want to optimize)
- Consider testimonials from beta testers for website
- Update IRS mileage rate annually (currently $0.67/mile for 2026)
- Monitor competitors: MileIQ, Everlance, TripLog

---

## Launch Announcement Template

### Social Media Post
```
Introducing Property Miles! 

The mileage tracker built specifically for real estate agents.

• Automatic trip detection
• Property tagging
• IRS-compliant reports
• One-tap CSV export

Available now on the App Store!

[Link]

#RealEstate #MileageTracker #TaxDeductions #RealEstateAgent #PropTech
```

### Email to Real Estate Contacts
```
Subject: Save time on mileage tracking

Hi [Name],

As a real estate professional, you're probably driving to showings, open houses, and property visits every day. Are you tracking all those miles for tax deductions?

I built Property Miles to solve this exact problem. It automatically tracks your drives, lets you tag them to properties, and exports IRS-compliant reports for your accountant.

No more manual logging or forgotten trips. Just install, grant location permission, and let it work in the background.

Check it out: [App Store Link]

Best regards,
[Your name]

P.S. The app is completely free and your data stays private on your device.
```

---

**Last Updated:** March 11, 2026  
**Status:** Ready for App Store submission after creating screenshots and privacy policy
