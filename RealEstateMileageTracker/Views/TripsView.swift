//
//  TripsView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import SwiftUI
import MapKit
import CoreLocation

struct TripsView: View {
    @EnvironmentObject var tripStore: TripStore
    @EnvironmentObject var tripManager: TripManager
    @State private var selectedCurrentTrip: Trip?
    @State private var selectedMonth: Date = Date()
    @State private var showingMonthPicker = false
    
    private var filteredTrips: [Trip] {
        let calendar = Calendar.current
        return tripStore.trips.filter { trip in
            calendar.isDate(trip.startTime, equalTo: selectedMonth, toGranularity: .month)
        }
    }
    
    private var monthStats: (count: Int, miles: Double, amount: Double) {
        let count = filteredTrips.count
        let miles = filteredTrips.reduce(0) { $0 + $1.distance }
        let amount = filteredTrips.reduce(0) { $0 + $1.mileageAmount }
        return (count, miles, amount)
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Current trip banner
                    if let currentTrip = tripManager.currentTrip {
                        CurrentTripBanner(trip: currentTrip, tripStore: tripStore)
                            .onTapGesture {
                                selectedCurrentTrip = currentTrip
                            }
                    }
                    
                    // Trip list
                    List {
                        ForEach(filteredTrips) { trip in
                            TripRow(trip: trip, tripStore: tripStore)
                                .id("\(trip.id)-\(tripStore.locationNicknames.count)-\(tripStore.locationNicknames.first?.lastUsed.timeIntervalSince1970 ?? 0)")
                                .background(
                                    NavigationLink(destination: TripDetailView(trip: trip)) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                )
                        }
                        .onDelete(perform: deleteTrips)
                    }
                    .listStyle(.plain)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 70)
                    }
                }
                
                // Floating month picker button
                Button {
                    showingMonthPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                        
                        VStack(spacing: 2) {
                            Text(formatMonthYear(selectedMonth))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(monthStats.count) trips • \(String(format: "%.0f mi", monthStats.miles))")
                                .font(.caption2)
                        }
                        
                        Image(systemName: "chevron.up")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .padding(.bottom, 16)
            }
            .navigationTitle("Trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if tripManager.isTracking {
                            tripManager.stopTracking()
                        } else {
                            tripManager.startTracking()
                        }
                    } label: {
                        Image(systemName: tripManager.isTracking ? "stop.circle.fill" : "play.circle.fill")
                            .foregroundColor(tripManager.isTracking ? .red : .green)
                    }
                }
            }
            .sheet(item: $selectedCurrentTrip) { trip in
                TripDetailView(trip: trip)
            }
            .sheet(isPresented: $showingMonthPicker) {
                MonthPickerView(selectedMonth: $selectedMonth)
            }
        }
    }
    
    private func deleteTrips(at offsets: IndexSet) {
        for index in offsets {
            let tripsToDelete = filteredTrips
            for index in offsets {
                tripStore.deleteTrip(tripsToDelete[index])
            }
        }
    }
    
    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }
}

struct CurrentTripBanner: View {
    let trip: Trip
    let tripStore: TripStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "car.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trip in Progress")
                        .font(.headline)
                    
                    Text(trip.startLocationDisplayName(tripStore: tripStore))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f mi", trip.distance))
                        .font(.headline)
                    
                    if let duration = trip.duration {
                        Text(formatDuration(duration))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct TripRow: View {
    let trip: Trip
    let tripStore: TripStore
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: trip.purposeIcon)
                    .foregroundColor(.blue)
                    .font(.title3)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(formatDate(trip.startTime))
                            .font(.headline)
                        
                        if let purposeName = trip.purposeName {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(purposeName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Start Time and Address
                    HStack(spacing: 4) {
                        Text(formatTime(trip.startTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("-")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(shortAddress(trip.startLocationDisplayName(tripStore: tripStore)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // End Time and Address
                    if let endTime = trip.endTime,
                       let endDisplayName = trip.endLocationDisplayName(tripStore: tripStore) {
                        HStack(spacing: 4) {
                            Text(formatTime(endTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("-")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(shortAddress(endDisplayName))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else if let endTime = trip.endTime {
                        Text(formatTime(endTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1f mi", trip.distance))
                        .font(.headline)
                    
                    Text(String(format: "$%.2f", trip.mileageAmount))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Map Preview
            if let endLocation = trip.endLocation {
                TripMapPreview(
                    startCoordinate: trip.startLocation.coordinate,
                    endCoordinate: endLocation.coordinate
                )
                .frame(height: 120)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func shortAddress(_ address: String) -> String {
        let components = address.components(separatedBy: ", ")
        // Return street address + city (first 3 components: number, street, city)
        // e.g., "123 Main St, San Jose" instead of full "123 Main St, San Jose, CA, 95128"
        if components.count >= 3 {
            return components[0...2].joined(separator: ", ")
        }
        return address
    }
}

struct TripMapPreview: View {
    let startCoordinate: CLLocationCoordinate2D
    let endCoordinate: CLLocationCoordinate2D
    
    @State private var region: MKCoordinateRegion
    
    init(startCoordinate: CLLocationCoordinate2D, endCoordinate: CLLocationCoordinate2D) {
        self.startCoordinate = startCoordinate
        self.endCoordinate = endCoordinate
        
        // Calculate region to show both points
        let centerLat = (startCoordinate.latitude + endCoordinate.latitude) / 2
        let centerLon = (startCoordinate.longitude + endCoordinate.longitude) / 2
        
        let latDelta = abs(startCoordinate.latitude - endCoordinate.latitude) * 1.5
        let lonDelta = abs(startCoordinate.longitude - endCoordinate.longitude) * 1.5
        
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(
                latitudeDelta: max(latDelta, 0.01),
                longitudeDelta: max(lonDelta, 0.01)
            )
        ))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [
            MapPoint(coordinate: startCoordinate, title: "Start"),
            MapPoint(coordinate: endCoordinate, title: "End")
        ]) { point in
            MapMarker(coordinate: point.coordinate, tint: point.title == "Start" ? .green : .red)
        }
        .allowsHitTesting(false) // Disable interaction in list
    }
}

struct MapPoint: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
}

#Preview {
    TripsView()
        .environmentObject(TripStore())
        .environmentObject(TripManager())
}
