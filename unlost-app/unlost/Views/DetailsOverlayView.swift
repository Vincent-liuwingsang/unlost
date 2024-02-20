//
//  DetailsOverlayView.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 14/09/2023.
//


import SwiftUI


struct DetailsOverlayView: View {
    @StateObject var layoutState = LayoutState.shared
    @StateObject var pythonServerState = PythonServer.shared
    
    @State var hoverOpenWebsite = false
    @State var hoverDragToClipboard = false
    @State var hoverScroll = false
    
    var body: some View {
        let d:CGFloat  = layoutState.compact ? 36 : 40
        let fontSize: CGFloat = layoutState.compact ? 10 : 12
        let iconSize: CGFloat = layoutState.compact ? 12 : 14
        let squarePadding: CGFloat = layoutState.compact ? 6 : 8
        if !layoutState.overlayed {
            VStack {
                HStack(alignment: .top) {
                    if layoutState.copiedToClipboard {
                        HStack(alignment: .center) {
                            Text("Copied to clipboard!")
                                .font(.system(size: fontSize, weight: .semibold))
                                .foregroundColor(Color("TitleText"))
                                .padding(.horizontal, squarePadding)
                                .frame(height: d)
                                .frame(minWidth: d)
                                .background(Color("SolidBackground"))
                                .cornerRadius(4)
                                .shadow()
                        }
                        .transition(.scale)
                    } else {
                        
                        HStack(alignment: .center, spacing: 8) {
                            
                            if let url = layoutState.selectedTag?.tags.first?.url {
                                HStack (alignment: .center, spacing: 8) {
                                    
                                    Image(systemName:"return")
                                        .resizable()
                                        .frame(width: iconSize, height: iconSize)
                                    
                                    
                                    if hoverOpenWebsite {
                                        Text("Open Website")
                                            .font(.system(size: fontSize, weight: .semibold))
                                            .foregroundColor(Color("TitleText"))
                                        
                                    }
                                }
                                .padding(.horizontal, squarePadding)
                                .frame(height: d)
                                .frame(minWidth: d)
                                .background(Color("SolidBackground"))
                                .cornerRadius(4)
                                .shadow()
                                .onTapGesture {
                                    NSWorkspace.shared.open(URL(string: url)!)
                                    NSApp.closeActivity()
                                }
                                .onHover { hover in
                                    withAnimation {
                                        hoverOpenWebsite = hover
                                    }
                                }
                            }
                            if layoutState.selectedTag != nil {
                                HStack (alignment: .center, spacing: 8) {
                                    Image(systemName:"filemenu.and.cursorarrow.rtl")
                                        .resizable()
                                        .frame(width: iconSize, height: iconSize)
                                    
                                    if hoverDragToClipboard {
                                        Text("Drag to copy text")
                                            .font(.system(size: fontSize, weight: .semibold))
                                            .foregroundColor(Color("TitleText"))
                                        
                                    }
                                }
                                .padding(.horizontal, squarePadding)
                                .frame(height: d)
                                .frame(minWidth: d)
                                .background(Color("SolidBackground"))
                                .cornerRadius(4)
                                .shadow()
                                .onHover { hover in
                                    withAnimation {
                                        hoverDragToClipboard = hover
                                    }
                                }
                            }
                            
                            if let selectedTag = layoutState.selectedTag?.tags.first,
                               let date = earliestCapturedAtDateFormatter.date(from: selectedTag.captured_at) {
                                HStack (alignment: .center, spacing: 8) {
                                    Image(systemName:"calendar")
                                        .resizable()
                                        .frame(width: iconSize, height: iconSize)
                                    
                                    
                                    
                                    Text("\(itemFormattedDate(date))")
                                        .font(.system(size: fontSize, weight: .semibold))
                                        .foregroundColor(Color("TitleText"))
                                    
                                }
                                .padding(.horizontal, layoutState.compact ? 6 : 12)
                                .padding(.vertical, layoutState.compact ? 4 : 8)
                                .frame(height: d)
                                .frame(minWidth: d)
                                .background(Color("SolidBackground"))
                                .cornerRadius(4)
                                .shadow()
                            }
                            
                            if pythonServerState.state == "migrating" {
                                Spacer()
                                HStack (alignment: .center, spacing: 4) {
                                    
                                    Text("Unlost is reprocessing your memory for better search accuracy.")
                                        .font(.system(size: fontSize, weight: .semibold))
                                        .foregroundColor(Color("TitleText"))
                                }
                                .padding(.horizontal, layoutState.compact ? 6 : 12)
                                .padding(.vertical, layoutState.compact ? 4 : 8)
                                .background(Color("SolidBackground"))
                                .cornerRadius(4)
                                .shadow()
                            } else if pythonServerState.state == "deleting" {
                                Spacer()
                                HStack (alignment: .center, spacing: 4) {
                                    
                                    Text("Searching is unavailble when deleting old memories. This might take some time.")
                                        .font(.system(size: fontSize, weight: .semibold))
                                        .foregroundColor(Color("TitleText"))
                                }
                                .padding(.horizontal, layoutState.compact ? 6 : 12)
                                .padding(.vertical, layoutState.compact ? 4 : 8)
                                .background(Color("SolidBackground"))
                                .cornerRadius(4)
                                .shadow()
                            }
                            
                        }
                        .transition(.scale)
                        
                        
                    }
                    Spacer()
                    
                    
                    
                    VStack(alignment: .trailing) {
                        CarouselScrollView()
                        TranscriptView()
                    }
                    
                }
                .padding(.vertical, 8)
                .padding(.trailing, 9)
                .padding(.leading, 2)
                
                Spacer()
                HStack {
                    let size: CGFloat = layoutState.compact ? 14 : 18

                    Spacer()
                    if let tags = layoutState.selectedTags, tags.count  > 1 {
                     
                        HStack {
                            Image(systemName: "arrow.down")
                                .resizable()
                                .frame(width: size, height: size)
                            if hoverScroll {
                                Text(
                                    "Scroll for more screenshots with same phrase"
                                )
                                .font(.system(size: fontSize, weight: .semibold))
                                .foregroundColor(Color("TitleText"))
                            }
                        }
                        .frame(height: d)
                        .frame(minWidth: d)
                        .padding(.horizontal, hoverScroll ? 16 : 0)
                        .background(Color("SolidBackground"))
                        .cornerRadius(.infinity)
                        .shadow()
                        .onHover { hover in
                            withAnimation {
                                hoverScroll = hover
                            }
                        }
                    }
                    
                    HStack {
                       Image(systemName: "exclamationmark.bubble")
                           .resizable()
                           .frame(width: size, height: size)
                    }
                    .frame(height: d)
                    .frame(width: d)
                    .background(Color("SolidBackground"))
                    .cornerRadius(.infinity)
                    .shadow()
                    .onTapGesture {
                        NSApp.openSettings(.feedback)
                    }
                }
                .padding(12)
            }
        }
    }
}

