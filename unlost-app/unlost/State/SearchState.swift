//
//  SearchState.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 04/09/2023.
//

enum QueriedDatesLastSetBy {
case user
case response
}

struct Tag: Equatable, Identifiable, Codable {
    let id: String
    let type: String
    let value: String
    var active: Bool?
}

import SwiftUI
import Combine

class SearchState : ObservableObject {
    static var shared = SearchState()

//    @Published var refreshQueryResultDirtyFlag = 0
//    func refreshQueryResult() {
//        refreshQueryResultDirtyFlag += 1
//    }
    
    // all tags
    @Published var availableTags: [Tag] = []
       
    
    // activated tags
    var activatedTags: [Tag] {
        return availableTags.filter { $0.active == true }
    }
    
    // filtered tags to show in suggestions
    var filteredTags: [Tag] {
        var new = [Tag]()
        if let filterTagText = filterTagText {
            if !filterTagText.isEmpty {
                new = availableTags.filter { $0.value.range(of: filterTagText, options: .caseInsensitive) != nil }
            } else {
                new = availableTags
            }
        }

        return new
    }
    
    // selected tag in suggestions for highlighting
    @Published var selectedTag: Tag?

    @Published var queriedFrom: DateComponents?
    @Published var queriedTo: DateComponents?
    @Published var queriedDatesLastSetBy: QueriedDatesLastSetBy = .response
    @Published var cleanQueryWhenIdentifiedDates: String? = nil
    // string used to filter tags to show in suggestions
    var filterTagText: String? {
        if let i = query.lastIndex(of: "@") {
            return query.substring(from: query.index(i, offsetBy: 1))
        }
        
        return nil
    }
    
    var showTagSuggestions: Bool {
        return filteredTags.isNotEmpty
    }
    
    @Published var query: String = ""
    @Published var lastSearchedQuery: String = ""
    @Published var debouncedQuery: String = "" {
        didSet {
            selectedTag = filteredTags.first
        }
    }
    
    private var bag = Set<AnyCancellable>()
    private var anotherbag = Set<AnyCancellable>()
    
    
    private init() {
        $query
            .removeDuplicates()
            .debounce(for: .seconds(0.2), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] value in
                self?.debouncedQuery = value
            })
            .store(in: &bag)
 
        Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.syncTags()
        }
    }
    
    func activateTag(tag: Tag) {
        if let i = availableTags.firstIndex(of: tag) {
            availableTags[i] = Tag(id: tag.id, type: tag.type, value: tag.value, active: true)
            query = query.replacingOccurrences(of: "@\(filterTagText ?? "")", with: "")
        }
    }
    
    func clearAllTags() {
        availableTags = availableTags.map {
            Tag(id: $0.id, type: $0.type, value: $0.value, active: false)
        }
        query = query.replacingOccurrences(of: "@\(filterTagText ?? "")", with: "")
    }
    
    func resetQueriedDates() {
        queriedFrom = nil
        queriedTo = nil
        queriedDatesLastSetBy = .response
    }
    
    func reset() {
        resetQueriedDates()
        clearAllTags()
    }
    
    func activateSelectedTag()  {
        if let selectedTag = selectedTag {
            if selectedTag.value == "Clear All" {
                clearAllTags()
            } else  {
                activateTag(tag: selectedTag)
            }
        }
    }
    
    func deactivateTag(tag: Tag) {
        if let i = availableTags.firstIndex(of: tag) {
            availableTags[i] = Tag(id: tag.id, type: tag.type, value: tag.value, active: false)
        }
    }
    
    func syncTags() {
        let url = URL(string: "\(baseUrl)/tags")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { [self] data, response, error in
            if let data = data {
                if var tags = try? JSONDecoder().decode([Tag].self, from: data) {
                    for activatedTag in activatedTags {
                        if let i = tags.firstIndex(where: { $0.id == activatedTag.id }) {
                            tags[i].active = true
                        }
                        
                    }
                    
                    DispatchQueue.main.async {
                        self.availableTags = [Tag(id: "Clear All", type: "Client", value: "Clear All")] + tags
                    }
                }
            }
            
            if let error = error {
                log.error("failed to sync tags: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
}
