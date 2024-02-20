//
//  TagsSuggestion.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 22/07/2023.
//

import SwiftUI


struct TagsSuggestion: View {
    @StateObject var searchState = SearchState.shared
    @StateObject var layoutState = LayoutState.shared
    @State private var scrollViewContentSize: CGSize = .zero
    @Environment(\.colorScheme) var colorScheme
    
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
        if let selectedTag = searchState.selectedTag, let i = searchState.filteredTags.firstIndex(of: selectedTag) {
            if searchState.filteredTags.indices.contains(i + amount) {
                searchState.selectedTag = searchState.filteredTags[i + amount]
            }
        } else {
            searchState.selectedTag = searchState.filteredTags.first
        }
    }
    
    
    var body: some View {
        if searchState.showTagSuggestions {
            GeometryReader { geometry in
                ScrollViewReader { reader in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0){
                            ForEach(searchState.filteredTags) { tag in
                                if tag.id == "Clear All" || tag.type == "content_type" {
                                    HStack {
                                        Text(tag.value)
                                        Spacer()
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.orange)
                                            .opacity(searchState.selectedTag == tag ? (colorScheme == .light ? 0.2 : 0.5) : 0.0000001)
                                        
                                    }
                                    .accessibilityElement()
                                    .accessibility(label: Text(tag.value))
                                    .accessibilityAction {
                                        searchState.selectedTag = tag
                                        searchState.activateSelectedTag()
                                    }
                                    .onTapGesture {
                                        searchState.selectedTag = tag
                                        searchState.activateSelectedTag()
                                    }
                                }
                                
                                if tag.type == "app_name", let icon = layoutState.icons[tag.value] {
                                    HStack {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 24.0, height: 24.0)
                                            .opacity(0.65)
                                        
                                        Text(tag.value)
                                        Spacer()
                                    }
                                    .padding(layoutState.compact ?  4 : 8)
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.orange)
                                            .opacity(searchState.selectedTag == tag ? (colorScheme == .light ? 0.2 : 0.5) : 0.0000001)
                                        
                                    }
                                    .accessibilityElement()
                                    .accessibility(label: Text(tag.value))
                                    .accessibilityAction {
                                        searchState.selectedTag = tag
                                        searchState.activateSelectedTag()
                                    }
                                    .onTapGesture {
                                        searchState.selectedTag = tag
                                        searchState.activateSelectedTag()
                                    }
                                }
                            }
                        }
                        .overlay {
                            GeometryReader { geo -> Color in
                                DispatchQueue.main.async {
                                    scrollViewContentSize = geo.size
                                }
                                return Color.clear
                            }
                        }
                        
                    }
                    .onChange(of: searchState.selectedTag) { tag in
                        if let tag = tag {
                            reader.scrollTo(tag.id, anchor: .center)
                        }
                    }
                    
                }
                .padding(layoutState.compact ?  6 : 10)
                .frame(width: geometry.size.width - 24)
                .frame(maxHeight: min(scrollViewContentSize.height + 20, 215))
                .background(Color("SolidBackground"))
                .background(shortcuts)
                .cornerRadius(4)
                .shadow(color: .gray, radius: 2, x: 0, y: 1)
                .offset(x: 12, y: layoutState.compact ? 48 : 54)
            }
        }
    }
}
