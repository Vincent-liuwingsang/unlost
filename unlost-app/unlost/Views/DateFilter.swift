//
//  DateFilter.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 15/09/2023.
//

import SwiftUI

let dateFilterFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMM yy"
    return dateFormatter
}()

struct DateFilter: View {
    @StateObject var layoutState = LayoutState.shared
    @StateObject var searchState = SearchState.shared
    @State var today: String = dateFilterFormatter.string(from: Date.now)
    @State var originDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
    
    var body: some View {
        HStack {
            let d: CGFloat = layoutState.compact ? 14 : 16
            Image(systemName: "calendar")
                .resizable()
                .frame(width: d, height: d)
            
            if searchState.queriedFrom == nil, searchState.queriedTo == nil {
                Text("\(dateFilterFormatter.string(from: originDate)) - Now")
            }
            if let from = searchState.queriedFrom, let to = searchState.queriedTo,
               let fromDate = Calendar.current.date(from: from),
               let toDate = Calendar.current.date(from: to) {
                
                let adjustedFromDate = getMaxDate(fromDate, originDate)
                let adjustedToDate = getMinDate(toDate, Date())
                
                let fromString = dateFilterFormatter.string(from: adjustedFromDate)
                let toString = dateFilterFormatter.string(from: adjustedToDate)
                if fromString == toString, toString == today {
                    Text("Today")
                } else if from == to {
                    Text(dateFilterFormatter.string(from: fromDate))
                } else if toString == today {
                    Text("\(fromString) - Now")
                } else {
                    Text("\(fromString) - \(toString)")
                }
            }
        }
        .padding(layoutState.compact ? 4 : 8)
        .font(.system(size: layoutState.compact ? 12 : 14, weight: .none))
        .foregroundColor(Color("TitleText"))
        .cornerRadius(4)
        .onAppear {
            today = dateFilterFormatter.string(from: Date.now)
            setOriginDate()
        }
        .onChange(of: searchState.debouncedQuery) { _ in
            today = dateFilterFormatter.string(from: Date.now)
            setOriginDate()
        }
        .background(
            searchState.queriedDatesLastSetBy == .user &&
            searchState.queriedFrom != nil &&
            searchState.queriedTo != nil ? Color("CTA").opacity(0.5) : .clear)
    }
    
    private func setOriginDate() {
        originDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
    }
}

private func getMaxDate(_ date1: Date, _ date2: Date) -> Date{
    let laterDate: Date

    if date1.compare(date2) == .orderedDescending {
        laterDate = date1
    } else {
        laterDate = date2
    }
    
    return laterDate
}

private func getMinDate(_ date1: Date, _ date2: Date) -> Date{
    let laterDate: Date

    if date1.compare(date2) == .orderedAscending {
        laterDate = date1
    } else {
        laterDate = date2
    }
    
    return laterDate
}
