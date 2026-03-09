# Real Estate Mileage Tracker -- MVP Build Plan

## Goal

Release the smallest useful version of the app that can: 1.
Automatically detect trips 2. Let the user tag the trip (showing / open
house / meeting) 3. Export a mileage report for taxes

Target development time: **\~1 week for an experienced iOS developer**

------------------------------------------------------------------------

# Week 1 --- Core Tracking

## Step 1: Trip Detection

Use iOS frameworks:

-   CoreLocation
-   CoreMotion

Basic logic:

Start trip when driving is detected.

Example logic:

speed \> 10 mph → start trip

End trip when stopped for several minutes.

Example:

stopped for 3 minutes → end trip

### Data to Record

Trip object:

-   startTime
-   endTime
-   startLocation
-   endLocation
-   distance

Distance calculation:

CLLocation.distance(from:)

### Storage

Store trips locally using:

-   CoreData (recommended) or
-   SQLite

------------------------------------------------------------------------

## Step 2: Trip Review Screen

When a trip ends, show a review screen.

Example UI:

Trip detected\
Distance: 8.2 miles\
Duration: 18 minutes

Purpose:

-   Showing property
-   Open house
-   Inspection
-   Client meeting
-   Personal

User selects the purpose and saves.

------------------------------------------------------------------------

## Step 3: Property Tagging

Allow attaching a property address.

Simple MVP model:

Property - address - nickname

Example:

123 Main St\
"Downtown Condo"

Trip screen option:

Attach property → select from saved list.

------------------------------------------------------------------------

# Week 2 --- Reports + Export

## Step 4: Mileage Dashboard

Dashboard example:

This Month

Trips: 42\
Miles: 318\
Estimated deduction: \$213

Formula:

miles × IRS mileage rate

Example:

318 miles × \$0.67

------------------------------------------------------------------------

## Step 5: Trip History

Trip list example:

Apr 5\
Showing -- 123 Main St\
8.2 miles

Apr 4\
Open house -- Oak Ave\
14.6 miles

User can tap a trip to view details.

------------------------------------------------------------------------

## Step 6: Export Report

Generate a CSV file for accountants.

Example CSV:

Date,Start Address,End Address,Miles,Purpose,Property
2026-04-05,Home,123 Main St,8.2,Showing,123 Main St

Export options:

-   Email
-   AirDrop
-   Save to Files

Implementation:

Use UIActivityViewController.

------------------------------------------------------------------------

# Background Location Permission

Required for App Store approval.

Recommended permission description:

"Location is used to automatically detect drives and create mileage logs
for tax reporting."

------------------------------------------------------------------------

# Battery Optimization

To reduce battery usage:

Use:

CLActivityType.automotiveNavigation

Only activate location tracking when driving is detected.

------------------------------------------------------------------------

# Minimal UI Structure

Suggested tab layout:

Trips\
Properties\
Reports\
Settings

Keep UI simple for MVP.

------------------------------------------------------------------------

# Suggested App Names

-   Realtor Miles
-   Agent Mileage
-   Realty Miles
-   OpenHouse Miles
-   Property Trip Log

------------------------------------------------------------------------

# Development Time Estimate

Trip detection: 2 days\
Trip UI: 1 day\
Property tagging: 1 day\
Reports + export: 1 day\
Testing + polish: 2 days

Total: **\~7 days**

------------------------------------------------------------------------

# Future Improvements

-   MLS property import
-   Voice tagging for trips
-   Accounting software integration
-   AI auto-classification of trip purposes
