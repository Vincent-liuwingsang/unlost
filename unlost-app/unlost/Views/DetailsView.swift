//
//  DetailsView.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 31/07/2023.
//

import SwiftUI

var blockScrollListener = false


struct DetailsView: View {
  
    @StateObject var layoutState = LayoutState.shared
    @AppStorage("appHeightRatio") var appHeightRatio = 0.8
    
    var body: some View {
        VStack(spacing: 0) {
            
            ZStack(alignment: layoutState.selectedItem == nil ? .center: .top) {

                if layoutState.selectedItem == nil  {
                    
                    VStack(alignment: .center, spacing: 16) {
                        let fontSize: CGFloat = layoutState.compact ? 12 : 16
                        Text("No matching results")
                            .font(.system(size: fontSize, weight: .semibold))
                            .foregroundColor(Color("TitleText"))
                    }
                    .padding(layoutState.compact ? 16 : 8)
                    .background(Color("SolidBackground"))
                    .shadow()
                    
                }
                HStack {
                    if let tags = layoutState.selectedTags {
                        GeometryReader { geometry in
                            ScrollViewReader { reader in
                                ScrollView(.vertical) {
                                    LazyVStack(spacing: 0) {
                                        
                                        ForEach(tags, id: \.id) { tagsOfSameInstant in
                                            
                                            GeometryReader { inner in
                                                LazyHStack {
                                                    
                                                    if let videoImage = layoutState.videoImage {
                                                        DragToCopyView(image: videoImage, boxes: [])
                                                            .onDisappear {
                                                                layoutState.videoImage = nil
                                                            }
                                                            .frame(width: inner.size.width, height: inner.size.height)
                                                    } else {
                                                        LiveTextViewForInstant(tags: tagsOfSameInstant.tags)
                                                            .frame(width: inner.size.width, height: inner.size.height)
                                                    }
                                                    
                                                }
                                                .onChange(of: inner.frame(in: .named("ScrollableImages")).midY) { y in
                                                    if blockScrollListener {
                                                        return
                                                    }
                                                    let mid = geometry.size.height / 2
                                                    let quarter: CGFloat = mid / 2
                                                    if y > mid - quarter && y < mid + quarter, tagsOfSameInstant.id != layoutState.selectedTag?.id {
                                                        
                                                        layoutState.selectedTag = tagsOfSameInstant
                                                        layoutState.selectedTagScrollCarouselFlag += 1
                                                        
                                                    }
                                                }
                                                
                                            }
                                            .frame(width: geometry.size.width, height: geometry.size.height)
                                            .id(tagsOfSameInstant.id)
                                            
                                        }
                                    }
                                    .onChange(of: layoutState.selectedItem) { selectedItems in
                                        if let firstTag = layoutState.selectedTags?.first {
                                            reader.scrollTo(firstTag.id)
                                        }
                                    }
                                    .onChange(of: layoutState.selectedTagScrollMainDirtyFlag) { _ in
                                        if let tag = layoutState.selectedTag {
                                            withAnimation {
                                                reader.scrollTo(tag.id, anchor: .center)
                                            }
                                        }
                                    }
                                    
                                    
                                }
                                .coordinateSpace(name: "ScrollableImages")
                            }
                            
                        }
                        
                        
                    }
                }
                .padding(.trailing, 8)
                .frame(maxHeight: .infinity)
                
                
                DetailsOverlayView()
                      
            }
            
            .frame(maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)

    }
}


