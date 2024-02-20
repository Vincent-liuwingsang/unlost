//
//  ListItemView.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 04/08/2023.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

func getRelative(_ d: String) -> String {
    let f1 = ISO8601DateFormatter()
    f1.formatOptions.insert(.withFractionalSeconds)

    let f2 = RelativeDateTimeFormatter()
    f2.unitsStyle = .full
    
    if let to = f1.date(from: "\(d)Z") {
        return f2.localizedString(for: to, relativeTo: Date.now)
    }
    
    return ""
}

//func countUniqueItems(_ items: [RecordResponseTags]) -> Int {
//    let keys = items.map { item in "\(item.path)#\(item.time)#\(item.time_to)" }
//    print(keys)
//    return NSSet(array: keys).count
//}

func countUniqueItems(_ items: [RecordResponseTags]) -> Int {
    // Create a Set to store unique objects based on their properties
    var uniqueObjects = Set<String>()

    
    // Iterate through the array and add unique object properties to the Set
    for item in items {
        let key = "\(item.path)#\(item.time)#\(item.time_to)"
        uniqueObjects.insert(key)
    }

    // Return the count of unique objects
    return uniqueObjects.count
}
let earliestCapturedAtDateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    return dateFormatter
}()
func earliestCapturedAt(_ items: [RecordResponseTags]) -> Date? {
    guard let minCapturedAt = items.min(by: { $0.captured_at < $1.captured_at }) else {
        return nil
    }
    
    return earliestCapturedAtDateFormatter.date(from: minCapturedAt.captured_at)
}

let itemDateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()


    
func itemFormattedDate(_ date: Date) -> String {
    let locale = Locale.current
    let formattedDate = itemDateFormatter.string(from: date)
    
    if locale.languageCode == "en" {
        let components = formattedDate.split(separator: " ")
        if components.count == 3 {
            return "\(components[0]) \(components[1])"
        }
    }
    
    return formattedDate
}

struct ListItemView : View {
    @State var image: NSImage?
    @State var appName: String
    @State var index: Int
    
    @Binding var itemsPerGroup: Dictionary<String, (records: [SearchableRecord], maxScore: Float)>
    @Environment(\.colorScheme) var colorScheme
    @StateObject var layoutState = LayoutState.shared
    let formatter = RelativeDateTimeFormatter()
    
    var body: some View {
        if let items = itemsPerGroup[appName]?.records, items.indices.contains(index) {
            let item = items[index]
            VStack(alignment: .leading, spacing: layoutState.compact ? 2 : 4) {
                HStack() {
                    
                    
                    Text(item.title).lineLimit(1)
                        .font(.system(size: layoutState.compact ? 12: 14, weight: .semibold))
                        .foregroundColor(Color("WeakTitleText").opacity(0.8))
                    
                    
                    Spacer()
                    
                    
                    let meetingRecord = item.records.first { $0.time_to != nil }
                    if meetingRecord != nil {
                        Image(systemName: "video.fill")
                    }
                    
                    
                    let count = countUniqueItems(item.records)
                    if count > 1 {
                        Text("\(count)+")
                            .foregroundColor(Color("WeakTitleText"))
                            .font(.system(size: layoutState.compact ? 10 : 12, weight: .regular))
                            .padding(.vertical, layoutState.compact ? 2 : 3)
                            .padding(.horizontal, layoutState.compact ? 3 : 5)
                            .background(.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    if let earliest = earliestCapturedAt(item.records) {
                        let date = isDateLessThanTwoDaysAgo(earliest) ? itemFormattedDate(earliest) : formatter.localizedString(for: earliest, relativeTo: Date.now)
                        Text("from \(date)")
                            .foregroundColor(Color("WeakTitleText"))
                            .font(.system(size: layoutState.compact ?  10 : 12, weight: .regular))
                            .padding(.vertical, layoutState.compact ?  2 : 3)
                            .padding(.horizontal, layoutState.compact ? 3 : 5)
                    }
                    
                }
                HStack() {
                    Text(item.matchingText).lineLimit(1)
                        .font(.system(size: layoutState.compact ?  14 : 16, weight: Font.Weight.medium))
                        .foregroundColor(Color("StrongTitleText"))
                    Spacer()
                }
                
            }
            .padding(.vertical, layoutState.compact ? 2 : 4)
            .padding(.horizontal, layoutState.compact ? 4 : 8)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.orange)
                    .opacity(item.id == layoutState.selectedItem?.id ? (colorScheme == .light ? 0.2 : 0.5) : 0.0001)
                
            }
            .onTapGesture {
                blockScrollListener = true
                
                layoutState.selectedItem = item
                Task {
                    try await Task.sleep(nanoseconds: 200_000_000)
                    blockScrollListener = false
                }
                
            }
            .onAppear {
                formatter.unitsStyle = .full
                formatter.locale = Locale.current
            }
        }
    }
}

func isDateLessThanTwoDaysAgo(_ targetDate: Date) -> Bool {
    // Get the current date
    let currentDate = Date()

    // Create a calendar instance
    let calendar = Calendar.current

    // Calculate the date that was 2 days ago
    if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: currentDate) {
        // Compare targetDate with twoDaysAgo
        return targetDate < twoDaysAgo
    } else {
        // Handle the case where calculation fails
        return false
    }
}
