//
//  LayoutState.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 04/09/2023.
//

import SwiftUI
import Combine

func getCurrentTimestamp() -> Int {
    return Int(Date().timeIntervalSince1970 * 1000)
}

struct SelectedTag {
    let id = UUID()
    var tags: [RecordResponseTags]
}

class LayoutState: ObservableObject {
    static var shared = LayoutState()
    
    
    @Published var selectedItem: SearchableRecord?

    @Published var selectedTags: [SelectedTag]?
    @Published var selectedTag: SelectedTag?
    
    @Published var selectedTagScrollMainDirtyFlag = 0
    @Published var selectedTagScrollCarouselFlag = 0
    
    // meeting
    @Published var videoImage: NSImage?
    @Published var transcript = [TranscriptResponse]()
    @Published var toHighlight: TranscriptResponse?
    @Published var maxTimestamp = 0.0
    @Published var currentTimestamp = 0.0
    
    @Published var copiedToClipboard = false
    @Published var overlayed = false
    
    @Published var icons = Dictionary<String, NSImage>()
    
    @Published var showCalendar = false
    
    @Published var compact = false
    
    private var bag = Set<AnyCancellable>()
    
    private init() {
        $selectedItem
            .sink { value in
                if let value = value {
                    let sorted = value.records.sorted { $0.captured_at > $1.captured_at }
                    var selectedTags = [SelectedTag]()
                    var current: SelectedTag? = nil
                    for item in sorted {
                        if let last = current?.tags.last {
                            if last.path == item.path, last.time == item.time, last.time_to == item.time_to {
                                current?.tags.append(item)
                            } else {
                                if let current = current {
                                    selectedTags.append(current)
                                }
                                current = SelectedTag(tags: [item])
                            }
                        } else {
                            current = SelectedTag(tags: [item])
                        }
                    }
                    if let current = current {
                        selectedTags.append(current)
                    }
                    
                    self.selectedTags = selectedTags
                    self.selectedTag = selectedTags.first
                    
                } else {
                    self.selectedTags = nil
                    self.selectedTag = nil
                }
            }
            .store(in: &bag)
        
        $selectedTag
            .sink { value in
                if let tag = value, let firstTag = tag.tags.first, firstTag.time_to != nil {
                    PythonServer.shared.getTranscript(path: String(firstTag.path)) { response in
                        DispatchQueue.main.async {
                            self.transcript = response
                            self.transcript.sort { $0.tags.time < $1.tags.time }
                            
                            var max = 0.0
                            var toHighlight:TranscriptResponse? = nil
                            for t in self.transcript {
                                if firstTag == t.tags {
                                    toHighlight = t
                                }
                                
                                if let time = t.tags.time_to, time > max {
                                    max = time
                                }
                            }
                            
                            self.maxTimestamp = max
                            self.currentTimestamp = firstTag.time
                            self.toHighlight = toHighlight
                        }
                    }
                } else {
                    self.transcript = []
                    self.toHighlight = nil
                    self.maxTimestamp = 0
                    self.currentTimestamp = 0
                }
            }
            .store(in: &bag)
    }
    
    func showCopiedtoClipboard() {
        withAnimation {
            copiedToClipboard = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                self.copiedToClipboard = false
            }
        }
    }
    
    func refreshCompact() {
        guard let screenSize = NSScreen.main?.frame.size else { return }
        
        // if laptop
        if screenSize.width < 1730 {
            compact = true
        } else {
            compact = false
        }
    }
}
