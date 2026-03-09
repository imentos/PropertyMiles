//
//  MonthPickerView.swift
//  RealEstateMileageTracker
//
//  Created by Kuo, Ray on 3/8/26.
//

import SwiftUI

struct MonthPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedMonth: Date
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 3)
    
    @State private var displayedYear: Int
    
    init(selectedMonth: Binding<Date>) {
        self._selectedMonth = selectedMonth
        let year = Calendar.current.component(.year, from: selectedMonth.wrappedValue)
        self._displayedYear = State(initialValue: year)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Year picker
                HStack {
                    Button {
                        displayedYear -= 1
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    Text(String(displayedYear))
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button {
                        displayedYear += 1
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                    }
                    .disabled(displayedYear >= calendar.component(.year, from: Date()))
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Month grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(1...12, id: \.self) { month in
                        MonthButton(
                            month: month,
                            year: displayedYear,
                            isSelected: isSelectedMonth(month: month, year: displayedYear),
                            isCurrentMonth: isCurrentMonth(month: month, year: displayedYear),
                            isFuture: isFutureMonth(month: month, year: displayedYear)
                        ) {
                            selectMonth(month: month, year: displayedYear)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") {
                        selectedMonth = Date()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func isSelectedMonth(month: Int, year: Int) -> Bool {
        let selectedYear = calendar.component(.year, from: selectedMonth)
        let selectedMonthComponent = calendar.component(.month, from: selectedMonth)
        return month == selectedMonthComponent && year == selectedYear
    }
    
    private func isCurrentMonth(month: Int, year: Int) -> Bool {
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        return month == currentMonth && year == currentYear
    }
    
    private func isFutureMonth(month: Int, year: Int) -> Bool {
        let now = Date()
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let monthDate = calendar.date(from: components) else { return false }
        return monthDate > now
    }
    
    private func selectMonth(month: Int, year: Int) {
        guard !isFutureMonth(month: month, year: year) else { return }
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        if let date = calendar.date(from: components) {
            selectedMonth = date
            dismiss()
        }
    }
}

struct MonthButton: View {
    let month: Int
    let year: Int
    let isSelected: Bool
    let isCurrentMonth: Bool
    let isFuture: Bool
    let action: () -> Void
    
    private let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                               "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(monthNames[month - 1])
                    .font(.headline)
                    .foregroundColor(textColor)
                
                if isCurrentMonth {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
            )
        }
        .disabled(isFuture)
        .buttonStyle(.plain)
    }
    
    private var textColor: Color {
        if isFuture {
            return .gray
        } else if isSelected {
            return .white
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else {
            return Color(.systemGray6)
        }
    }
    
    private var borderColor: Color {
        isSelected ? .blue : .clear
    }
}

#Preview {
    MonthPickerView(selectedMonth: .constant(Date()))
}
