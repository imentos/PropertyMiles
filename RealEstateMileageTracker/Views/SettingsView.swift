//
//  SettingsView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import SwiftUI
import CoreLocation
import StoreKit

struct SettingsView: View {
    private var preferences = MileagePreferences()
    private var mileage: MileageReporting { preferences.reporting }
    @EnvironmentObject var tripManager: TripManager
    @EnvironmentObject var tripStore: TripStore
    @State private var showingPermissionAlert = false
    @State private var showingPaywall = false
    @State private var tapCount = 0
    @State private var showDebugModeAlert = false
    @State private var showTrackingLogCopiedAlert = false
    @State private var showClearTrackingLogAlert = false
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                if !subscriptionManager.isPro {
                    Section {
                        Button {
                            showingPaywall = true
                        } label: {
                            HStack {
                                Label("Upgrade to Pro", systemImage: "star.fill")
                                    .foregroundColor(.blue)
                                Spacer()
                                Text(subscriptionManager.product(for: .monthly).map {
                                    String(format: NSLocalizedString("%@/mo", comment: "Monthly subscription price"), $0.displayPrice)
                                } ?? NSLocalizedString("View Plans", comment: "Subscription plans"))
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                        }
                    } header: {
                        Text("Subscription")
                    }
                }

                Section("Location Tracking") {
                    HStack {
                        Label("Permission Status", systemImage: "location.circle")
                        Spacer()
                        Text(LocalizedStringKey(permissionStatusText))
                            .foregroundColor(permissionStatusColor)
                    }
                    
                    if tripManager.locationPermissionStatus != .authorizedAlways {
                        Button {
                            showingPermissionAlert = true
                        } label: {
                            Label("Request Permission", systemImage: "location.fill")
                        }
                    }
                    
                    Toggle(isOn: $tripManager.isTracking) {
                        Label("Auto-Track Trips", systemImage: tripManager.isTracking ? "play.circle.fill" : "pause.circle.fill")
                    }
                    .onChange(of: tripManager.isTracking) { newValue in
                        if newValue {
                            tripManager.startTracking()
                        } else {
                            tripManager.stopTracking()
                        }
                    }
                }
                
                Section("Language") {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("App Language", systemImage: "globe")
                    }
                    Text("Follows your iPhone's preferred app language. Language does not change your reporting country, currency or tax settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Country & Reporting") {
                    Picker("Country", selection: preferences.$regionCode) {
                        Text("United States").tag("US")
                        Text("Canada").tag("CA")
                    }
                    if mileage.isCanada {
                        LabeledContent("Distance", value: "Kilometres")
                        LabeledContent("Currency", value: "CAD (CA$)")
                        HStack {
                            Text("Custom reimbursement (CA$/km)")
                            Spacer()
                            TextField("0.00", value: preferences.$canadianRate, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 90)
                                .onChange(of: preferences.canadianRate) { value in
                                    if !value.isFinite || value < 0 { preferences.canadianRate = 0 }
                                }
                        }
                        Text("Leave the rate at zero for distance-only records. A custom rate estimates reimbursement across the selected trips, not a CRA tax deduction. Changing it recalculates existing report estimates.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Canadian vehicle deductions generally require eligible actual expenses and business kilometres relative to total annual kilometres. Rental-property travel has additional eligibility rules. Keep your odometer and expense records for your accountant.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        HStack {
                            Label("Current IRS Business Rate", systemImage: "dollarsign.circle")
                            Spacer()
                            Text("US$0.76/mile")
                                .foregroundColor(.secondary)
                        }

                        Text("Trips before July 1, 2026 use US$0.725/mile. Trips on or after July 1, 2026 use US$0.76/mile.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Vehicles") {
                    NavigationLink {
                        VehiclesManagementView()
                    } label: {
                        HStack {
                            Label("Manage Vehicles", systemImage: "car.fill")
                            Spacer()
                            Text("\(tripStore.vehicles.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Trip Purposes") {
                    NavigationLink {
                        CustomPurposesView()
                    } label: {
                        HStack {
                            Label("Custom Purposes", systemImage: "tag.fill")
                            Spacer()
                            Text("\(tripStore.customPurposes.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if tripManager.debugMode {
                    Section {
                        HStack {
                            Image(systemName: "ant.circle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Debug Mode Active")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                Text("Generate sample trips for testing")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        Button {
                            tripStore.generateSampleTrips()
                        } label: {
                            Label("Generate Sample Trips", systemImage: "text.badge.plus")
                        }

                        Button {
                            tripStore.generateScreenshotTrips()
                        } label: {
                            Label("Generate Screenshot Data (~$1,100)", systemImage: "camera.badge.plus")
                        }

                        Toggle(isOn: Binding(
                            get: { SubscriptionManager.shared.debugProOverride },
                            set: { SubscriptionManager.shared.debugProOverride = $0 }
                        )) {
                            Label("Unlock Pro (Debug)", systemImage: "crown")
                        }

                        Toggle(isOn: $tripManager.debugTrackCycling) {
                            Label("Track Cycling Trips (Debug)", systemImage: "bicycle")
                        }
                        
                        Button(role: .destructive) {
                            tripStore.clearAllTrips()
                        } label: {
                            Label("Clear All Trips", systemImage: "trash")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Tracking Log", systemImage: "waveform.path.ecg")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(tripManager.recentTrackingEvents.count) saved")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("Saved on this device. Keeps the latest 500 tracking events for trip debugging.")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if tripManager.recentTrackingEvents.isEmpty {
                                Text("No tracking events yet.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(tripManager.recentTrackingEvents, id: \.self) { event in
                                    Text(event)
                                        .font(.caption2.monospaced())
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                }
                            }

                            HStack(spacing: 16) {
                                Button {
                                    UIPasteboard.general.string = tripManager.recentTrackingEvents.joined(separator: "\n")
                                    showTrackingLogCopiedAlert = true
                                } label: {
                                    Label("Copy Tracking Log", systemImage: "doc.on.doc")
                                }
                                .disabled(tripManager.recentTrackingEvents.isEmpty)

                                Spacer()

                                Button(role: .destructive) {
                                    showClearTrackingLogAlert = true
                                } label: {
                                    Label("Clear Log", systemImage: "trash")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .disabled(tripManager.recentTrackingEvents.isEmpty)
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Debug Tools")
                    }
                }
                
                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")\(tripManager.debugMode ? " [DEBUG]" : "")")
                            .foregroundColor(tripManager.debugMode ? .orange : .secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tapCount += 1
                        if tapCount >= 7 {
                            tripManager.debugMode.toggle()
                            showDebugModeAlert = true
                            tapCount = 0
                        }
                        // Reset tap count after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            tapCount = 0
                        }
                    }
                    
                    Link(destination: URL(string: mileage.isCanada
                        ? "https://www.canada.ca/en/revenue-agency/services/tax/businesses/topics/rental-income/completing-form-t776-statement-real-estate-rentals/rental-expenses-you-deduct.html"
                        : "https://www.irs.gov/irb/2026-29_irb")!) {
                        Label(LocalizedStringKey(mileage.isCanada ? "CRA Vehicle & Rental Expenses" : "IRS 2026 Rate Update"), systemImage: "link")
                    }
                }
                
                Section {
                    Text("Automatically tracks your driving trips for real estate business mileage. Make sure to enable 'Always Allow' location permission for best results.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                #if DEBUG
                Section("Developer") {
                    Button("Reset Onboarding (Debug)") {
                        tripStore.resetOnboarding()
                    }
                    .foregroundColor(.red)
                }
                #endif
            }
            .navigationTitle("Settings")
            .alert("Location Permission Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please go to Settings and allow 'Always' location access for automatic trip tracking.")
            }
            .alert("Tracking Log Copied", isPresented: $showTrackingLogCopiedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Tracking log copied as plain text.")
            }
            .alert(LocalizedStringKey(tripManager.debugMode ? "Debug Mode Enabled" : "Debug Mode Disabled"), isPresented: $showDebugModeAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if tripManager.debugMode {
                    Text("You can now generate sample trips for testing.")
                } else {
                    Text("Debug mode disabled.")
                }
            }
            .confirmationDialog("Clear Tracking Log?", isPresented: $showClearTrackingLogAlert, titleVisibility: .visible) {
                Button("Clear Log", role: .destructive) {
                    tripManager.clearTrackingLog()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the saved tracking log from this device.")
            }
            .sheet(isPresented: $showingPaywall) {
                OB10PaywallView(vm: OnboardingViewModel()) {
                    showingPaywall = false
                }
            }
        }
    }
    
    private var permissionStatusText: String {
        switch tripManager.locationPermissionStatus {
        case .notDetermined:
            return "Not Set"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Allowed"
        case .authorizedWhenInUse:
            return "When In Use"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var permissionStatusColor: Color {
        switch tripManager.locationPermissionStatus {
        case .authorizedAlways:
            return .green
        case .authorizedWhenInUse:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(TripManager())
        .environmentObject(TripStore())
}
