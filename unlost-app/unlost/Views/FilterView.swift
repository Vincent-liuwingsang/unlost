//
//  FilterView.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 15/09/2023.
//

import SwiftUI

struct FilterView: View {
    @StateObject var searchState = SearchState.shared
    @StateObject var layoutState = LayoutState.shared
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        let tagsToShow = searchState.activatedTags.count > 0 ? searchState.activatedTags : searchState.availableTags
                        let d: CGFloat = layoutState.compact ? 20 : 26
                        let padding: CGFloat = layoutState.compact ? 2 : 4
                        ForEach(tagsToShow, id: \.id) { tag in
                            if tag.type == "content_type" {
                                HStack {
                                    Image(systemName: "video.fill")
                                        .resizable()
                                        .frame(width: layoutState.compact ? 14 : 18, height: layoutState.compact ? 10 : 12.0)
                                        .opacity(0.45)
                                }
                                .padding(padding)
                                .cornerRadius(padding)
                                .id(tag.id)
                                .onTapGesture {
                                    withAnimation {
                                        if tag.active == true {
                                            searchState.deactivateTag(tag: tag)
                                        } else {
                                            searchState.activateTag(tag: tag)
                                        }
                                    }
                                }
                            }
                            if tag.type == "app_name", let icon = layoutState.icons[tag.value] {
                                HStack {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: d, height: d)
                                        .opacity(0.65)
                                }
                                .padding(4)
                                .cornerRadius(4)
                                .id(tag.id)
                                .onTapGesture {
                                    withAnimation {
                                        if tag.active == true {
                                            searchState.deactivateTag(tag: tag)
                                        } else {
                                            searchState.activateTag(tag: tag)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.leading, layoutState.compact ? 8 : 18)
                }
 
                

                Divider()
                DateFilter()
                    .background(Color("SolidBackground").opacity(0.00001))
                    .onTapGesture { hover in
                        withAnimation {
                            layoutState.showCalendar = !layoutState.showCalendar
                        }
                    }
                    .layoutPriority(1)
                Divider()
                
                let d: CGFloat = layoutState.compact ? 28 : 32
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .resizable()
                        .frame(width: layoutState.compact ? 12 : 16, height: layoutState.compact ? 14 : 18)
                }
                .frame(width: d, height: d)
                .onTapGesture {
                    withAnimation {
                        searchState.reset()
                    }
                }
            }
            .padding(4)
            .onChange(of: searchState.availableTags) { tags in
                for tag in tags {
                    if layoutState.icons[tag.value] == nil {
                        let path = getDocumentsDirectory()
                            .appendingPathComponent("appIcons", conformingTo: .directory)
                            .appendingPathComponent("\(tag.value).png", conformingTo: .image)
                        layoutState.icons[tag.value] = NSImage(contentsOf: path)
                    }
                }
            }
            .frame(height: layoutState.compact ? 36 : 40)
            
            if layoutState.showCalendar {
                CalendarView()
                    .padding(.trailing, 16)
            }

        }
        
    }
}
