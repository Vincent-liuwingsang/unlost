//
//  FloatingPanelSearchLayout.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 17/06/2023.
//

import SwiftUI
import Combine


struct MatchingMemoryResposne: Decodable {
    let text: String
    let score: Float
    let rows: String
}

struct RecordResponseTags: Decodable, Equatable {
    let location: [Float]
    let captured_at: String
    let path: String
    let time: Double
    let time_to: Double?
    let minX: Double?
    let minY: Double?
    let width: Double
    let height: Double
    let app_name: String
    let window_name: String
    let url: String?
}

struct SearchableRecord: Identifiable, Equatable {
    static func == (lhs: SearchableRecord, rhs: SearchableRecord) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id: String
    let title: String
    let matchingText: String
    let timestamp: String
    let appName: String
    let score: Float
    let records: [RecordResponseTags]
}

struct DateCondition: Decodable {
    let range_type: String
    let parsed_date: String
    let clean_text: String
    let from_date: String
    let to_date: String
}

struct MemoryQueryResponse: Decodable {
    let memories: [MatchingMemoryResposne]
    let scanned_count: Int64
    let date_condition: DateCondition?
}

let baseUrl = "http://localhost:58000"


let decoder = JSONDecoder()

struct FloatingPanelSearchLayout<ItemView: View, DetailsView: View>: View {
    @ViewBuilder let itemView: (Binding<Dictionary<String, (records: [SearchableRecord], maxScore: Float)>>, String, Int) -> (ItemView)
    @ViewBuilder let detailsView: () -> (DetailsView)
    
    
    @State var queryUsed = ""
    @State var queryResultCount: Int64 = 0
    
    @State var items = [SearchableRecord]()
    
    @StateObject var layoutState = LayoutState.shared
    @StateObject var searchState = SearchState.shared
    
    @State var currentTask: URLSessionDataTask?
        
    @State var itemsPerGroup = Dictionary<String, (records: [SearchableRecord], maxScore: Float)>()
    
    
    var shortcuts: some View {
        ZStack {
            Button(action: {
                jump(amount: 1)
            }, label: {})
                .keyboardShortcut(.downArrow, modifiers: [])
     
            Button(action: {
                jump(amount: -1)
            }, label: {})
                .keyboardShortcut(.upArrow, modifiers: [])
            
        }
        .opacity(0.0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
    
    func jump(amount: Int) {
        if let selectedItem = layoutState.selectedItem {
            if let index = items.firstIndex(of: selectedItem) {
                if items.indices.contains(index+amount) {
                    layoutState.selectedItem = items[index+amount]
                }
            }
        } else {
            layoutState.selectedItem = items.first
        }
    }
    
    func refresh(loadMore: Bool = false) {
        if loadMore, currentTask != nil {
            return
        }
        
        if searchState.showTagSuggestions {
            return
        }

        currentTask?.cancel()
        layoutState.selectedItem = items.first

        
        var tags = "[]"
        do {
            var activeTags = searchState.activatedTags
            if searchState.queriedDatesLastSetBy == .user,
               let queriedFrom = searchState.queriedFrom,
               let queriedTo = searchState.queriedTo,
               let fromISO = queriedFrom.toISOString(),
               let toISO = queriedTo.toISOString() {
                activeTags.append(Tag(id: "date_between", type: "date_between", value: "\(fromISO)#\(toISO)"))
            }
            
            let encodedTags = try JSONEncoder().encode(activeTags)
            tags = String(decoding: encodedTags, as: UTF8.self)
        } catch {
            log.warning("failed to encode activated tags")
        }
        
        let activeQuery = searchState.debouncedQuery
        if activeQuery.isEmpty {
            return
        }
        
        var url = URL(string: "\(baseUrl)/memory")!
        var queryItems = [
            URLQueryItem(name: "query", value: activeQuery),
            URLQueryItem(name: "tags", value: tags)
        ]
        
        if loadMore {
            queryItems.append(URLQueryItem(name: "offset", value: String(queryResultCount)))
        }
        
        
        
        url.append(queryItems: queryItems)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        Task { @MainActor in
            searchState.cleanQueryWhenIdentifiedDates = ""
            searchState.lastSearchedQuery = activeQuery
        }
        currentTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let response = try? decoder.decode(MemoryQueryResponse.self, from: data) {
                    
                    var searchableRecords = [SearchableRecord]()
                    
                    for memories in response.memories {
                        // NOTE same text can be from multiple apps
                        var responseTags = [RecordResponseTags]()
                        
                        if let responseTagsStrings = try? decoder.decode([String].self, from: Data(memories.rows.utf8)) {
                            for responseTagsString in responseTagsStrings {
                                if let tags = try? decoder.decode(RecordResponseTags.self, from: Data(responseTagsString.utf8)) {
                                    responseTags.append(tags)
                                }
                            }
                        }
                        
                        if let firstTags = responseTags.first {
                            let appName = firstTags.app_name
                            let windowName = firstTags.window_name
                            let timestamp = firstTags.captured_at
                            
                            let searchableRecord = SearchableRecord(id: "\(memories.text)#\(memories.score)", title: windowName, matchingText: memories.text, timestamp: timestamp, appName: appName, score: memories.score,records: responseTags)
                            searchableRecords.append(searchableRecord)
                            
                            if layoutState.icons[appName] == nil {
                                let path = getDocumentsDirectory()
                                    .appendingPathComponent("appIcons", conformingTo: .directory)
                                    .appendingPathComponent("\(appName).png", conformingTo: .image)
                                layoutState.icons[appName] = NSImage(contentsOf: path)
                            }
                        }
                        
                    }
                    
                    queryUsed = activeQuery
                    if loadMore {
                        queryResultCount += response.scanned_count
                    } else {
                        queryResultCount = response.scanned_count
                    }
                    
                    var newItems = loadMore ? items + searchableRecords : searchableRecords
                    
    
                    
                    var d = Dictionary<String, (records: [SearchableRecord], maxScore: Float)>()
                    for item in newItems {
                        
                        let score = item.score
                        if d[item.appName] == nil {
                            d[item.appName] = (records: [], score)
                        }
                        
                        d[item.appName]?.records.append(item)
                        if score > (d[item.appName]?.maxScore ?? 0.0) {
                            d[item.appName]?.maxScore = score
                        }
                    }
                    
                    let sortedEntries = Array(d).sorted { $0.value.maxScore > $1.value.maxScore }
                    var sortedItems = [SearchableRecord]()
                    for (_,v) in sortedEntries {
                        sortedItems.append(contentsOf: v.records)
                    }
                    
                    items = sortedItems
                    itemsPerGroup = d
                    
                    if searchState.queriedDatesLastSetBy == .response {
                        
                        var queriedFrom: DateComponents? = nil
                        var queriedTo: DateComponents? = nil
                        if let parsedDate = response.date_condition {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                            if let fromDate = dateFormatter.date(from: parsedDate.from_date),
                               let toDate = dateFormatter.date(from: parsedDate.to_date) {
                                
                                queriedFrom = fromDate.toCalendarComponent()
                                queriedTo = toDate.toCalendarComponent()
                            }
                            
                        }
                        
                        Task { @MainActor in
                            withAnimation {

                                searchState.queriedDatesLastSetBy = .response
                                searchState.queriedFrom = queriedFrom
                                searchState.queriedTo = queriedTo
                            }
                        }
                        
                    }
                    
                    Task { @MainActor in
//                        withAnimation {
                            if let parsedDate = response.date_condition {
                                
                                searchState.cleanQueryWhenIdentifiedDates = parsedDate.clean_text
                                
                            } else {
                                searchState.cleanQueryWhenIdentifiedDates = activeQuery
                            }
//                        }
                        layoutState.selectedItem = items.first
                    }
                    
                } else {
                    log.error("invalid response")
                }
            } else if let error = error {
                log.warning("query failed", context: error)
            }
        }
        currentTask?.resume()
    }
    
    var body: some View {
        FloatingPanelExpandableLayout(toolbar: {
            SearchInput(searchState: searchState, layoutState: layoutState, onChange: refresh)
        }, sidebar: {
            VStack(spacing: 0) {
                FilterView()
                
                Divider()
                    
                    
                ScrollViewReader { reader in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 8) {
                            
                            let sortedGroups = itemsPerGroup.sorted {$0.value.maxScore > $1.value.maxScore }.map { $0.key }
                                                        
                            ForEach(sortedGroups, id: \.self) { group in
                                LazyVStack(alignment: .leading, spacing: 4) {
                                    HStack {

                                        if let nsImage = layoutState.icons[group] {
                                            Image(nsImage: nsImage)
                                                .resizable()
                                                .frame(width: 24.0, height: 24.0)
                                        } else {
                                            Image(systemName: "app")
                                        }

                                        Text(group)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color("WeakTitleText").opacity(0.8))
                                    }
                                    .padding(6)


                                    let array = (itemsPerGroup[group]?.records ?? [])
                                    ForEach(array.indices, id: \.self) { index in
                                        itemView($itemsPerGroup, group, index)
                                            .id(array[index].id)
                                    }
                                }
                                .padding(8)
                                .cornerRadius(8)
                                .background(Color("SolidBackground"))
                            }
                            
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        
                        
                    }
                    .frame(maxWidth: .infinity)
                    .background(searchState.showTagSuggestions ? nil : shortcuts)
                    .onChange(of: layoutState.selectedItem) { newValue in
                        
                        if let newValue = newValue, let id = items.first?.id {
                            if id != newValue.id {
                                reader.scrollTo(newValue.id, anchor: .center)
                            } else {
                                reader.scrollTo(newValue.id, anchor: .bottom)
                            }
                            
                        }
                    }
                    .onChange(of: searchState.activatedTags) { _ in
                        refresh()
                    }
                    .onChange(of: searchState.queriedFrom) { _ in
                        refresh()
                    }
                    .onChange(of: searchState.queriedTo) { _ in
                        refresh()
                    }
                    
                }
            }
        }, content: {
            detailsView()
        })
    }
}

