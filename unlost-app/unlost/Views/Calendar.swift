//
//  Calendar.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 15/09/2023.
//

import SwiftUI
import LRUCache

let daysInWeek = 7
let months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "July",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
]

struct CalendarView: View {
    let data = makeDays()
    let todayCompoents = Date().toCalendarComponent()
    
    let highlightMonth = Date().get(.month) % 2
    let columns = [
            GridItem(spacing: 0),
            GridItem(spacing: 0),
            GridItem(spacing: 0),
            GridItem(spacing: 0),
            GridItem(spacing: 0),
            GridItem(spacing: 0),
            GridItem(spacing: 0),
            GridItem(spacing: 0),
        ]

    @StateObject var searchState = SearchState.shared
    @StateObject var layoutState = LayoutState.shared
    
    @State var dragging = false
    @State var dragFrom: DateComponents? = nil
    @State var dragTo: DateComponents? = nil
    
    var dragMin: DateComponents? {
        guard let dragFrom = dragFrom else {return nil}
        if let dragTo = dragTo {
            return dragFrom <= dragTo ? dragFrom : dragTo
        } else {
            return dragFrom
        }
    }
    
    var dragMax: DateComponents? {
        guard let dragFrom = dragFrom else {return nil}
        if let dragTo = dragTo {
            return dragFrom <= dragTo ? dragTo : dragFrom
        } else {
            return dragFrom
        }
    }
    
    @State var cellsData = [CardPreferenceData]()
    
    private func highlight(_ item: DateComponents, queriedFrom: DateComponents?, queriedTo: DateComponents?) -> (highlight: Bool, isStart: Bool, isEnd: Bool) {
        if !dragging, queriedFrom == nil, queriedTo == nil {
            return (highlight: true, isStart: false, isEnd: item == todayCompoents)
        }
        let min = dragging ? dragMin : queriedFrom
        let max = dragging ? dragMax : queriedTo
        
        let highlight = item.between(min, max)
        let isStart = min != nil && item == min!
        let isEnd = max != nil && item == max!
        return (highlight: highlight, isStart: isStart, isEnd: isEnd)
    }
    
    var body: some View {
        let todayComponent = todayComponent()
        ScrollViewReader {reader in
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 4, pinnedViews: [.sectionHeaders]) {
                    Section(header: VStack(spacing: 0) {
                        HStack {
                            Text("")
                                .dateCell()
                            Text("Mon").dateCell()
                            Text("Tue").dateCell()
                            Text("Wed").dateCell()
                            Text("Thu").dateCell()
                            Text("Fri").dateCell()
                            Text("Sat").dateCell()
                            Text("Sun").dateCell()
                        }
                        .background(Color("SolidBackground"))
                        Divider()
                    }
                        
                        
                    ) {
                        if let weekday = data.first?.weekday, weekday != 1 {
                            ForEach(1...weekday-1, id: \.self) { id in
                                Text("")
                                    .dateCell()
                            }
                        }
                        
                        ForEach(Array(zip(data.indices, data)), id: \.0) { index, item in
                            
                            if let weekday = item.weekday, weekday == 2 {
                                
                                let lastDayIndex = min(index + 6, data.count - 1)
                                if data.indices.contains(lastDayIndex), let newMonth = data[lastDayIndex].month,
                                   newMonth != item.month {
                                    Text(months[newMonth-1])
                                        .font(.system(size: layoutState.compact ? 12 : 16, weight: .bold))
                                        .foregroundColor(Color("StrongTitleText"))
                                        .dateCell()
                                        
                                        
                                } else if let month = item.month, item.day == 1 {
                                    Text(months[month - 1])
                                        .font(.system(size: layoutState.compact ? 12 : 16, weight: .bold))
                                        .foregroundColor(Color("StrongTitleText"))
                                        .dateCell()
                                } else {
                                    Text("")
                                        .dateCell()
                                }
                            }
                            if let day = item.day, let month = item.month, let year = item.year {
                                let result = highlight(item, queriedFrom: searchState.queriedFrom, queriedTo: searchState.queriedTo)
                                let highlight = result.highlight
                                let isStart = result.isStart
                                let isEnd = result.isEnd
                                
                                let highlightMonth = month % 2 == highlightMonth
                                                    
                                Text("\(day)")
                                    .foregroundColor(Color(highlightMonth ? "StrongTitleText" : "WeakTitleText"))
                                    .font(.system(size: layoutState.compact ? 10 : 12, weight: .none))
                                    .dateCell()
                                    .background(
                                        highlight ? Color("CTA").opacity(0.5) : Color("SolidBackground").opacity(0.0001))
                                    .id("\(year)-\(month)-\(day)")
                                    .background(GeometryReader { geometry in
                                        Rectangle()
                                            .fill(Color.clear)
                                            .preference(key: CardPreferenceKey.self,
                                                        value: [CardPreferenceData(dateComponents: item, bounds: geometry.frame(in: .named("CalendarSpace")))])
                                    })
                                    .roundedCorners(radius: isStart ? 16 : 0, corners: [.left])
                                    .roundedCorners(radius: isEnd ? 16 : 0, corners: [.right])
                            }
                            
                        }
                    }
                    
                    
                }
                .padding(4)
                .simultaneousGesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("CalendarSpace")).onChanged { drag in
                        dragging = true
                        if let data = cellsData.first(where: {$0.bounds.contains(drag.location)}) {
                            if dragFrom == nil {
                                dragFrom = data.dateComponents
                            } else {
                                dragTo = data.dateComponents
                            }
                        }
                }.onEnded { _ in
                    // if last set by response and has queriedFrom/To Dates, reset query
                    if searchState.queriedDatesLastSetBy == .response,
                       searchState.queriedFrom != nil,
                       searchState.queriedTo != nil,
                       let clean = searchState.cleanQueryWhenIdentifiedDates {
                        searchState.query = clean
                    }
                        
                    searchState.queriedDatesLastSetBy = .user
                    searchState.queriedFrom = dragMin
                    searchState.queriedTo = dragMax
                    dragging = false
                    dragFrom = nil
                    dragTo = nil
                }
                    
                )
            }
            .frame(height: layoutState.compact ? 160 : 320)
            .onAppear {
                if let year = todayComponent.year, let month = todayComponent.month, let day = todayComponent.day {
                    reader.scrollTo("\(year)-\(month)-\(day)", anchor: .center)
                }
                
            }

            .coordinateSpace(name: "CalendarSpace")
            .onPreferenceChange(CardPreferenceKey.self){ value in
                cellsData = value
            }
        }
    }
    
}

let calendarDatesCache = LRUCache<String, [DateComponents]>(countLimit: 1)

private extension View {
    func dateCell(_ alignment: Alignment = .center) -> some View {
        return self.frame(height: LayoutState.shared.compact ? 26 : 32)
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}

func makeDays() -> [DateComponents] {
    let calendar = Calendar.current
    let today = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    let key = dateFormatter.string(from: today)
    if let dates = calendarDatesCache.value(forKey: key) {
        return dates
    }
    
    if let from = calendar.date(byAdding: .year, value: -1, to: today) {
        let dateInterval = DateInterval(start: from, end: today)
        let dates = calendar.generateDays(for: dateInterval)
        calendarDatesCache.setValue(dates, forKey: key)
        return dates
    }

    return []
}

func todayComponent() -> DateComponents {
    return Date().toCalendarComponent()
}

extension Date {
    func toCalendarComponent() -> DateComponents {
        return Calendar.current.dateComponents([.day,.year,.month, .weekday, .weekOfMonth], from: self)
    }
}


private extension Calendar {
    func generateDates(
        for dateInterval: DateInterval,
        matching components: DateComponents
    ) -> [DateComponents] {
        var dates = [Calendar.current.dateComponents([.day,.year,.month, .weekday, .weekOfMonth], from: dateInterval.start)]

        enumerateDates(
            startingAfter: dateInterval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            guard let date = date else { return }

            guard date < dateInterval.end else {
                stop = true
                return
            }

            
            dates.append(Calendar.current.dateComponents([.day, .year, .month, .weekday, .weekOfMonth], from: date))
        }

        return dates
    }

    func generateDays(for dateInterval: DateInterval) -> [DateComponents] {
        generateDates(
            for: dateInterval,
            matching: dateComponents([.hour, .minute, .second], from: dateInterval.start)
        )
    }
}

extension Date {
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
}

extension DateComponents {
    static func >= (date1: DateComponents, date2: DateComponents) -> Bool {
        if let year1 = date1.year, let month1 = date1.month, let day1 = date1.day,
           let year2 = date2.year, let month2 = date2.month, let day2 = date2.day {
            
            if year1 > year2 {
                return true
            } else if year1 == year2 {
                if month1 > month2 {
                    return true
                } else if month1 == month2 {
                    if day1 >= day2 {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    static func <= (date1: DateComponents, date2: DateComponents) -> Bool {
            if let year1 = date1.year, let month1 = date1.month, let day1 = date1.day,
               let year2 = date2.year, let month2 = date2.month, let day2 = date2.day {
                
                if year1 < year2 {
                    return true
                } else if year1 == year2 {
                    if month1 < month2 {
                        return true
                    } else if month1 == month2 {
                        if day1 <= day2 {
                            return true
                        }
                    }
                }
            }
            
            return false
        }

    
    static func == (date1: DateComponents, date2: DateComponents) -> Bool {
        return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day
    }
    
    func between(_ x1: DateComponents?, _ x2: DateComponents?) -> Bool {
        guard let x1 = x1, let x2 = x2 else { return false }
        return x1 <= self && self <= x2
    }
    
    func toISOString() -> String? {
        guard let year = year, let month = month, let day = day else { return nil }
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0
        dateComponents.nanosecond = 0
        if let date = Calendar.current.date(from: dateComponents) {
            // Create a DateFormatter with the desired format (ISO 8601)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
            
            // Format the Date to an ISO string
            return dateFormatter.string(from: date)
        }
        
        return nil
    }
}

struct CardPreferenceData: Equatable {
    let dateComponents: DateComponents
    let bounds: CGRect
}

struct CardPreferenceKey: PreferenceKey {
    typealias Value = [CardPreferenceData]
    
    static var defaultValue: [CardPreferenceData] = []
    
    static func reduce(value: inout [CardPreferenceData], nextValue: () -> [CardPreferenceData]) {
        value.append(contentsOf: nextValue())
    }
}
func padNumber(_ number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 2
    return formatter.string(from: NSNumber(value: number)) ?? ""
}

struct RectCorner: OptionSet {
    
    let rawValue: Int
        
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomRight = RectCorner(rawValue: 1 << 2)
    static let bottomLeft = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, topRight, .bottomLeft, .bottomRight]
    static let left: RectCorner = [.topLeft, .bottomLeft]
    static let right: RectCorner = [.topRight, .bottomRight]
}

extension View {
    func roundedCorners(radius: CGFloat, corners: RectCorner) -> some View {
        clipShape( RoundedCornersShape(radius: radius, corners: corners) )
    }
}

// draws shape with specified rounded corners applying corner radius
struct RoundedCornersShape: Shape {
    
    var radius: CGFloat = .zero
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let p1 = CGPoint(x: rect.minX, y: corners.contains(.topLeft) ? rect.minY + radius  : rect.minY )
        let p2 = CGPoint(x: corners.contains(.topLeft) ? rect.minX + radius : rect.minX, y: rect.minY )

        let p3 = CGPoint(x: corners.contains(.topRight) ? rect.maxX - radius : rect.maxX, y: rect.minY )
        let p4 = CGPoint(x: rect.maxX, y: corners.contains(.topRight) ? rect.minY + radius  : rect.minY )

        let p5 = CGPoint(x: rect.maxX, y: corners.contains(.bottomRight) ? rect.maxY - radius : rect.maxY )
        let p6 = CGPoint(x: corners.contains(.bottomRight) ? rect.maxX - radius : rect.maxX, y: rect.maxY )

        let p7 = CGPoint(x: corners.contains(.bottomLeft) ? rect.minX + radius : rect.minX, y: rect.maxY )
        let p8 = CGPoint(x: rect.minX, y: corners.contains(.bottomLeft) ? rect.maxY - radius : rect.maxY )

        
        path.move(to: p1)
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY),
                    tangent2End: p2,
                    radius: radius)
        path.addLine(to: p3)
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
                    tangent2End: p4,
                    radius: radius)
        path.addLine(to: p5)
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
                    tangent2End: p6,
                    radius: radius)
        path.addLine(to: p7)
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                    tangent2End: p8,
                    radius: radius)
        path.closeSubpath()

        return path
    }
}
