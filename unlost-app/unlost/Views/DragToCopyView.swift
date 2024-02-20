//
//  DragToCopyView.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 16/09/2023.
//

import SwiftUI
import Vision

struct DragToCopyView : View {
    @State var image: NSImage
    @State var boxes: [NSRect] = []
    
    @State var positionX: CGFloat = 0
    @State var positionY: CGFloat = 0
    @State var selectionWidth: CGFloat = 0
    @State var offsetX: CGFloat = 0
    @State var offsetY: CGFloat = 0
    @State var selectionHeight: CGFloat = 0
//    @StateObject var keyboardState = KeyboardState.shared
    
    @State var geoHeight: CGFloat = 0
    @State var geoWidth: CGFloat = 0
    
    @State var dragging = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                HighlightView(image: image, boxes: boxes)
                    .simultaneousGesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("ScrollabeImages")).onChanged { dragGesture in
                        LayoutState.shared.overlayed = true
                        withAnimation {
                            dragging = true
                        }
                        
                        //                            if !keyboardState.shiftPressed {
                        //                                return
                        //                            }
                        positionX = dragGesture.startLocation.x
                        positionY = dragGesture.startLocation.y
                        // tl -> br, -,-
                        // bl -> tr  -, +
                        
                        let deltaX = dragGesture.startLocation.x - dragGesture.location.x
                        let deltaY = dragGesture.startLocation.y - dragGesture.location.y
                        
                        selectionWidth = 1 + abs(deltaX)
                        offsetX = -deltaX / 2
                        
                        selectionHeight = 1 + abs(deltaY)
                        offsetY = -deltaY / 2
                        
                        geoWidth = geo.size.width
                        geoHeight = geo.size.height
                        
                    }.onEnded { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                LayoutState.shared.overlayed = false
                            }
                        }
                        dragging = false
                        
                        //                            if !keyboardState.shiftPressed {
                        //                                return
                        //                            }
                        
                        copyToClipboard()
                    })
                
                ZStack {
                    Rectangle()
                        .fill(.black)
                        .opacity(dragging ? 0.6 : 0)
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: selectionWidth, height: selectionHeight)
                        .position(x: positionX, y: positionY)
                        .offset(x: offsetX, y: offsetY)
                        .opacity(dragging ? 1 : 0)
                        .blendMode(.destinationOut)
                }
                .compositingGroup()
                
            }
            .padding(.vertical, 8)
        }
    }
    
    private func resetHighlight() {
        positionX = 0
        positionY = 0
        selectionWidth = 0
        offsetX = 0
        offsetY = 0
        selectionHeight = 0
    }
    
    private func copyToClipboard() {
        let originalWidth = CGFloat(image.size.width)
        let originalHeight = CGFloat(image.size.height)
        let aspectRatio = originalWidth / originalHeight
        print(originalWidth, originalHeight)
        let screenRatio = geoWidth / geoHeight

        var paddingX = CGFloat(0)
        var paddingY = CGFloat(0)
        var newHeight = CGFloat(0)
        var newWidth = CGFloat(0)

        
        let widthRatio = originalWidth / geoWidth
        let heightRatio = originalHeight / geoHeight
        if widthRatio < heightRatio {
            newHeight = geoHeight
            newWidth = newHeight * aspectRatio
            paddingX = (geoWidth - newWidth) / 2
        } else {
            newWidth = geoWidth
            newHeight = newWidth / aspectRatio
            paddingY = (geoHeight - newHeight) / 2
        }

        let cropWidth = (selectionWidth / newWidth) * originalWidth
        let cropHeight = (selectionHeight / newHeight) * originalHeight
        
        let adjustedX = offsetX > 0 ? positionX : positionX - selectionWidth
        let adjustedY = offsetY > 0 ? positionY : positionY - selectionHeight
        let cropX = ((adjustedX - paddingX) / newWidth) * originalWidth
        // trailing 8 padding? not sure
        let cropY = ((adjustedY - paddingY + 8) / newHeight) * originalHeight
        
        print(originalWidth, originalHeight, cropWidth, cropHeight, cropX, cropY)
        
        let padding = CGFloat(4)
        let width = max(cropWidth + 2 * padding, 0)
        let height = max(cropHeight + 2 * padding, 0)
        let x = max(cropX - padding, 0)
        let y = max(cropY - padding, 0)
        
        if width.isNaN || height.isNaN || x.isNaN || y.isNaN {
            return
        }
        
        if width < 5 || height < 5 {
            return
        }
        
        let cropped = image.cropping(to: CGRect(x: x, y: y, width: width, height: height))
        var imageRect = CGRect(x: 0, y: 0, width: cropped.size.width, height: cropped.size.height)
        
        if let cgImage = cropped.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage)
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            do {
                // Perform the text-detection request.
                try requestHandler.perform([request])
            } catch {
                log.warning("Unable to perform the request: \(error).")
            }
            
            var toCopy = [String]()
            if let results = request.results {
                for result in results {
                    if let candidate = result.topCandidates(1).first, candidate.confidence > 0.30  {
                        toCopy.append(candidate.string)
                    }
                }
            }
            
            
            if toCopy.count > 0 {
                LayoutState.shared.showCopiedtoClipboard()
//                self.image = cropped
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(toCopy.joined(separator: "\n"), forType: .string)
            }
        }
        
        resetHighlight()
    }
}
