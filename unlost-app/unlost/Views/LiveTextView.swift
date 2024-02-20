//
//  LiveTextView.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 19/06/2023.
//

import Foundation
import SwiftUI
import VisionKit
import Vision
import UniformTypeIdentifiers

var count = 0

let analyzer = ImageAnalyzer()

struct LiveTextViewForInstant: View {
    @State private var image: NSImage?
    @State private var boxes: [NSRect] = []
    
    var tags: [RecordResponseTags]
    @State var searchState = SearchState.shared

    var body: some View {
        if let image = image {
            DragToCopyView(image: image, boxes: boxes)
        } else {
            Text("")
                .onAppear {
                    if let firstTag = tags.first {
                        let url = getDocumentsDirectory()
                            .appendingPathComponent(String(firstTag.path), conformingTo: UTType.video)
                        // TODO video is a bit off not sure why 100
                        let at = firstTag.time + 100
                        let ow = firstTag.width
                        let oh = firstTag.height
                        let minX = firstTag.minX
                        let minY = firstTag.minY
                        
                        imageFromVideo(url: url, at: at, minX: minX, minY: minY, ow: ow, oh: oh) { image in
                            
                            if searchState.debouncedQuery != "" {
                                var newBoxes = [NSRect]()
                                for tag in tags {
                                    let boxes = getBoundingBoxesCoordinates(original: image, tags: tag)
                                    newBoxes.append(contentsOf: boxes.map({ NSRect(x: $0.x, y: $0.y, width: $0.w, height: $0.h) }))
                                }
                                
                                self.boxes = newBoxes
                            } else {
                                self.boxes = []
                            }
                            self.image = image
                        }
                    }
                }
        }
    }
}

