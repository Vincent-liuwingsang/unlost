//
//  ImageFromVideo.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 03/09/2023.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImageFromVideo: View {
    @State private var image: NSImage? = nil
    @State var tags: RecordResponseTags? = nil
    @StateObject var layoutState = LayoutState.shared
    
    var hightlight: Bool
    let onTap: ((RecordResponseTags?) -> Void)
    
    var body: some View {

        if let image = image {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
//                .frame(height: 180)
                .border(hightlight ? .orange : .clear, width: 4)
                .onTapGesture {
                    onTap(tags)
                }
        } else {
            Text("")
                .onAppear {
                    if let selectedTags = tags {
                        let url = getDocumentsDirectory()
                            .appendingPathComponent(String(selectedTags.path), conformingTo: UTType.video)
                        // TODO video is a bit off not sure why 100
                        let at = selectedTags.time + 100
                        let ow = selectedTags.width
                        let oh = selectedTags.height
                        let minX = selectedTags.minX
                        let minY = selectedTags.minY

                        imageFromVideo(url: url, at: at, minX: minX, minY: minY, ow: ow, oh: oh) { [self] image in
                            self.image = image
                        }
                    }
                }
        }
    }
}
