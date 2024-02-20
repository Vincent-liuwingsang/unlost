//
//  TranscriptView.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 16/09/2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct TranscriptView : View {
    @StateObject var layoutState = LayoutState.shared
    @State var show = true
    @State var hover = false
    var body: some View {
        let transcript = layoutState.transcript
        
        if transcript.count>0, !show {
            HStack (alignment: .center, spacing: 8) {
                Image(systemName:"chevron.left")
                    .resizable()
                    .frame(width: 10, height: 14)
                
                
                if hover {
                    Text("Show Transcript")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color("TitleText"))
                    
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 40)
            .frame(minWidth: 40)
            .background(Color("SolidBackground"))
            .cornerRadius(4)
            .shadow()
            .onTapGesture {
                withAnimation {
                    show = true
                }
            }
            .onHover { hover in
                withAnimation {
                    self.hover = hover
                }
            }

        }
        
        
        if transcript.count > 0, show {
            GeometryReader { geometry in
                let maxWidth = max(0, geometry.size.width * 0.3)
                let maxHeight = max(0, geometry.size.height * 0.8)
                HStack(alignment: .center) {
                    Spacer()
                    VStack(spacing: 0) {
                        HStack {
                            Text("Transcript")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color("StrongTitleText"))
                            Spacer()
                            HStack (alignment: .center, spacing: 8) {
                                Image(systemName:"chevron.right")
                                    .resizable()
                                    .frame(width: 10, height: 14)
                            }
                            .padding(.horizontal, 8)
                            .frame(height: 40)
                            .frame(minWidth: 40)
                            .background(Color("SolidBackground"))
                            .cornerRadius(4)
                            .onTapGesture {
                                withAnimation {
                                    show = false
                                }
                            }
                        }
                        .padding(.leading, 16)
                        .frame(height: 40)
                        
                        
                        Divider()
                        ScrollViewReader { reader in
                            ScrollView {
                                LazyVStack(alignment: .trailing) {
                                    ForEach(transcript) { item in
                                        
                                        HStack {
                                            
                                            let isAudio = item.id.contains("#audio")
                                            let isActive = item.id == layoutState.toHighlight?.id
                                            
                                            Text(item.text)
                                                .padding(8)
                                                .foregroundColor(isAudio ? Color("Text") : Color("InverseText"))
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(
                                                            isAudio
                                                            ? Color("SolidBackground")
                                                            : Color("InverseSolidBackground")
                                                        )
                                                        .shadow(color: isActive ? .yellow : Color("Shadow"), radius: isActive ? 8 : 4, x: 0, y: 2)
                                                )
                                                .onTapGesture {
                                                    layoutState.currentTimestamp = item.tags.time
                                                }
                                            
                                            if isAudio {
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                            }
                            .onChange(of: layoutState.toHighlight) { item in
                                if let item = item {
                                    reader.scrollTo(item.id, anchor: .center)
                                }
                            }
                            .onAppear {
                                if let item = layoutState.toHighlight {
                                    Task {
                                        try await Task.sleep(nanoseconds: 100_000_000)
                                        reader.scrollTo(item.id, anchor: .center)
                                    }
                                    
                                }
                            }
                            
                        }
                        
                        
                    }
                        .background(Color("SolidBackground"))
                        .cornerRadius(4)
                        .frame(maxWidth: maxWidth, maxHeight: maxHeight)
                        
                        .shadow()
                        
                    
                    
                    
                }

            }
            
            
            
            Slider(
                value: $layoutState.currentTimestamp,
                in: 0...layoutState.maxTimestamp
            )
            .padding(.horizontal, 12)
            .offset(x: 0, y: -18)
            .tint(.orange)
            .animation(.spring())
            .onChange(of: layoutState.currentTimestamp) { x in
                let toHighlight = transcript.first(where: {
                    x <= $0.tags.time
                }) ?? transcript.last
                
                layoutState.toHighlight = toHighlight
                
                if let toHighlight = toHighlight {
                    let url = getDocumentsDirectory()
                        .appendingPathComponent(String(toHighlight.tags.path), conformingTo: UTType.video)
                    
                    
                    let ow = toHighlight.tags.width
                    let oh = toHighlight.tags.height
                    let minX = toHighlight.tags.minX
                    let minY = toHighlight.tags.minY
                    imageFromVideo(url: url, at: x, minX: minX, minY: minY,ow: ow, oh: oh) { image in
                        Task { @MainActor in
                            layoutState.videoImage = image
                        }
                    }
                }
            }
            .onAppear {
                if let tag = layoutState.selectedTag?.tags.first {
                    let url = getDocumentsDirectory()
                        .appendingPathComponent(String(tag.path), conformingTo: UTType.video)
                    // TODO video is a bit off not sure why 100
                    let at = tag.time + 100
                    let ow = tag.width
                    let oh = tag.height
                    let minX = tag.minX
                    let minY = tag.minY
                    
                    imageFromVideo(url: url, at: at, minX: minX, minY: minY, ow: ow, oh: oh) { image in
                        Task { @MainActor in
                            layoutState.videoImage = image
                        }
                    }
                }
            }
        }
    }
}
