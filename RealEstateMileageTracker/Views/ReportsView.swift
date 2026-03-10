//
//  ReportsView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var tripStore: TripStore
    @State private var selectedPeriod: ReportPeriod = .thisMonth
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var showingShareSheet = false
    @State private var csvFileURL: URL?
    @State private var showingExportAlert = false
    @State private var exportMessage = ""
    
    var dateRange: (start: Date, end: Date) {
        switch selectedPeriod {
        case .thisMonth:
            return currentMonth()
        case .lastMonth:
            return lastMonth()
        case .thisQuarter:
            return currentQuarter()
        case .thisYear:
            return currentYear()
        case .custom:
            return (customStartDate, customEndDate)
        }
    }
    
    var filteredTrips: [Trip] {
        tripStore.tripsForDateRange(start: dateRange.start, end: dateRange.end)
    }
    
    var totalMiles: Double {
        filteredTrips.reduce(0) { $0 + $1.distance }
    }
    
    var totalAmount: Double {
        filteredTrips.reduce(0) { $0 + $1.mileageAmount }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Period selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Report Period")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Picker("Period", selection: $selectedPeriod) {
                            ForEach(ReportPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        if selectedPeriod == .custom {
                            VStack(spacing: 12) {
                                DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                                DatePicker("End Date", selection: $customEndDate, displayedComponents: .date)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    
                    // Summary cards
                    HStack(spacing: 16) {
                        SummaryCard(
                            title: "Total Miles",
                            value: String(format: "%.1f", totalMiles),
                            icon: "road.lanes",
                            color: .blue
                        )
                        
                        SummaryCard(
                            title: "Total Amount",
                            value: String(format: "$%.2f", totalAmount),
                            icon: "dollarsign.circle",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    SummaryCard(
                        title: "Total Trips",
                        value: "\(filteredTrips.count)",
                        icon: "car",
                        color: .orange
                    )
                    .padding(.horizontal)
                    
                    // Breakdown by purpose
                    if !filteredTrips.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("By Purpose")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            // Default purposes
                            ForEach(TripPurpose.allCases, id: \.self) { purpose in
                                let purposeTrips = filteredTrips.filter { $0.purposeName == purpose.rawValue }
                                if !purposeTrips.isEmpty {
                                    let tripCount = purposeTrips.count
                                    let miles = purposeTrips.reduce(0.0) { $0 + $1.distance }
                                    let amount = purposeTrips.reduce(0.0) { $0 + $1.mileageAmount }
                                    PurposeRow(
                                        purposeName: purpose.rawValue,
                                        icon: purpose.icon,
                                        trips: tripCount,
                                        miles: miles,
                                        amount: amount
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            
                            // Custom purposes
                            ForEach(tripStore.customPurposes, id: \.self) { purposeName in
                                let purposeTrips = filteredTrips.filter { $0.purposeName == purposeName }
                                if !purposeTrips.isEmpty {
                                    let tripCount = purposeTrips.count
                                    let miles = purposeTrips.reduce(0.0) { $0 + $1.distance }
                                    let amount = purposeTrips.reduce(0.0) { $0 + $1.mileageAmount }
                                    PurposeRow(
                                        purposeName: purposeName,
                                        icon: "tag",
                                        trips: tripCount,
                                        miles: miles,
                                        amount: amount
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // Export button
                    Button {
                        exportCSV()
                    } label: {
                        Label("Export to CSV", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(filteredTrips.isEmpty)
                    
                    if filteredTrips.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No trips in this period")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    }
                }
                .padding(.bottom)
            }
            .navigationTitle("Reports")
            .sheet(isPresented: $showingShareSheet) {
                if let url = csvFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("CSV Exported", isPresented: $showingExportAlert) {
                Button("OK", role: .cancel) { }
                if let url = csvFileURL {
                    Button("Share File") {
                        print("🔘 Share File button tapped")
                        // Delay slightly to let alert dismiss first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            print("📱 Setting showingShareSheet = true")
                            showingShareSheet = true
                        }
                    }
                }
            } message: {
                Text(exportMessage)
            }
        }
    }
    
    private func exportCSV() {
        print("🚀 exportCSV() called - generating CSV for \(filteredTrips.count) trips")
        let csv = tripStore.generateCSV(for: filteredTrips)
        
        let fileName = "mileage_report_\(formatDate(dateRange.start))_to_\(formatDate(dateRange.end)).csv"
        
        // Save to Documents directory (accessible via Files app)
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            exportMessage = "Could not access Documents directory"
            showingExportAlert = true
            return
        }
        
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            csvFileURL = fileURL
            
            // Show alert with options
            exportMessage = "CSV file saved to Documents!\n\nFile: \(fileName)\n\nAccess it via:\n• Files app > On My iPhone > PropertyMiles\n• Or tap 'Share File' below"
            print("⚠️ Setting showingExportAlert = true")
            showingExportAlert = true
            
            print("✅ CSV exported to: \(fileURL.path)")
        } catch {
            exportMessage = "Error saving CSV: \(error.localizedDescription)"
            showingExportAlert = true
            print("❌ Error saving CSV: \(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func currentMonth() -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .month, value: 1, to: start)!
        return (start, end)
    }
    
    private func lastMonth() -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
        let components = calendar.dateComponents([.year, .month], from: lastMonth)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .month, value: 1, to: start)!
        return (start, end)
    }
    
    private func currentQuarter() -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let quarterMonth = ((month - 1) / 3) * 3 + 1
        
        var components = calendar.dateComponents([.year], from: now)
        components.month = quarterMonth
        components.day = 1
        
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .month, value: 3, to: start)!
        return (start, end)
    }
    
    private func currentYear() -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year], from: now)
        let start = calendar.date(from: components)!
        let end = calendar.date(byAdding: .year, value: 1, to: start)!
        return (start, end)
    }
}

enum ReportPeriod: String, CaseIterable {
    case thisMonth = "Month"
    case lastMonth = "Last"
    case thisQuarter = "Quarter"
    case thisYear = "Year"
    case custom = "Custom"
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PurposeRow: View {
    let purposeName: String
    let icon: String
    let trips: Int
    let miles: Double
    let amount: Double
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(purposeName)
                    .font(.headline)
                Text("\(trips) trip\(trips == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f mi", miles))
                    .font(.headline)
                Text(String(format: "$%.2f", amount))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        print("📤 Creating UIActivityViewController with items: \(activityItems)")
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        print("🔄 Updating UIActivityViewController")
    }
}

#Preview {
    ReportsView()
        .environmentObject(TripStore())
}
