//
//  CarouselScrollView.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 14/09/2023.
//

import SwiftUI

struct CarouselScrollView: View {
    @StateObject var layoutState = LayoutState.shared
    @State var hover = false
    
    var body: some View {
        let fontSize: CGFloat = layoutState.compact ? 10 : 12
        let d:CGFloat  = layoutState.compact ? 36 : 40
        
        
        let tags = layoutState.selectedTags ?? []
        
        
        if tags.count > 1 {
            VStack(spacing: 0) {
                if hover {
                    Text("Phrase also appears in")
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(Color("TitleText"))
                        .frame(height: d)
                    Divider()
                }
                HStack(alignment: .top) {
                    ScrollViewReader { reader in
                        ScrollView(.vertical) {
                            LazyVStack(spacing: 8) {
                                ForEach(tags, id: \.id) { tagsOfSameInstant in
                                    if let tag = tagsOfSameInstant.tags.first {
                                        let highlight = layoutState.selectedTag?.id == tagsOfSameInstant.id
                                        if hover {
                                            ImageFromVideo(tags: tag, hightlight: highlight, onTap: { _ in
                                                blockScrollListener = true
                                                
                                                layoutState.selectedTag = tagsOfSameInstant
                                                layoutState.selectedTagScrollMainDirtyFlag += 1
                                                
                                                Task {
                                                    try await Task.sleep(nanoseconds: 200_000_000)
                                                    blockScrollListener = false
                                                }
                                            })
                                            .id(tagsOfSameInstant.id)
                                        } else {
                                            Rectangle()
                                                .foregroundColor(Color(highlight ? "Selected": "NotSelected"))
                                                .cornerRadius(4)
                                                .frame(height: 4)
                                                .frame(maxWidth: .infinity)
                                                .id(tagsOfSameInstant.id)
                                        }
                                    }
                                }
                            }
                            .padding(8)
                            .onChange(of: layoutState.selectedTagScrollCarouselFlag) { _ in
                                if let tag = layoutState.selectedTag {
                                    withAnimation {
                                        reader.scrollTo(tag.id, anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                }
                
            }
            
            .frame(width: hover ? 200 : 72, height: hover ? 400 : layoutState.compact ? 100 : 144)
            .background(Color("SolidBackground"))
            .cornerRadius(4)
            .shadow()
            .onHover { hover in
                withAnimation {
                    self.hover = hover
                }
            }
        }
    }
}
