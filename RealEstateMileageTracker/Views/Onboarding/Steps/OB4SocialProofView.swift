//
//  OB4SocialProofView.swift
//  RealEstateMileageTracker
//

import SwiftUI

struct OB4SocialProofView: View {
    @ObservedObject var vm: OnboardingViewModel

    private let testimonials: [(name: String, tag: String, review: String)] = [
        ("Marcus T.", "Portfolio Manager", "\"I used to guess at tax time. Now I just hand my accountant the CSV. Saved me hours of stress.\""),
        ("Sandra K.", "Property Manager", "\"Paid for itself in the first week. I had no idea how many miles I was logging each month.\""),
        ("David L.", "Landlord", "\"Finally an app that works in the background. I don't have to remember to open it.\"")
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(LocalizedStringKey(MileageReporting.current.isCanada ? "Your property trips.\nTogether in one place." : "Property managers save\nan average of $3,200/year"))
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text(LocalizedStringKey(MileageReporting.current.isCanada ? "Track kilometres, locations and trip purposes." : "By tracking every business mile."))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 16) {
                    if MileageReporting.current.isCanada {
                        VStack(alignment: .leading, spacing: 24) {
                            Label("Automatic driving records", systemImage: "car.fill")
                            Label("Named property locations", systemImage: "mappin.and.ellipse")
                            Label("Trip purposes and notes", systemImage: "tag.fill")
                            Label("CSV records for your accountant", systemImage: "doc.text.fill")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    } else {
                        ForEach(testimonials, id: \.name) { t in
                            TestimonialCard(name: t.name, tag: t.tag, review: t.review)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            Button(action: { vm.advance() }) {
                Text("Sounds like me →")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

private struct TestimonialCard: View {
    let name: String
    let tag: String
    let review: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                }
            }
            Text(LocalizedStringKey(review))
                .font(.subheadline)
                .italic()
            HStack {
                Text(name).font(.caption.bold())
                Text("•").foregroundColor(.secondary).font(.caption)
                Text(LocalizedStringKey(tag)).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}
