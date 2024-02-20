//
//  HighlightView.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 17/09/2023.
//

import SwiftUI
import VisionKit

struct HighlightView: NSViewRepresentable {
    
    
    var image: NSImage
    var boxes: [NSRect]
    
    let imageView = LiveTextImageView()
    let overlayView = ImageAnalysisOverlayView()
    
    func makeNSView(context: Context) -> NSImageView {
        image.backgroundColor = .clear
        imageView.image = image.roundCorners(withRadius:16)
        overlayView.preferredInteractionTypes = .automatic
        overlayView.autoresizingMask = [.width, .height]
        overlayView.frame = imageView.bounds
        overlayView.trackingImageView = imageView
        
        imageView.addSubview(overlayView)
        
        for _ in 0..<boxes.count {
            let highlightView: NSView = NSHostingView(
                rootView: Rectangle().foregroundColor(.yellow)
                    .opacity(0.5)
                    .cornerRadius(2)
            )
            imageView.addSubview(highlightView)
        }
        
        
        return imageView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        if !NSApp.isClientOpen() {
            return
        }
        
        if image != imageView.image {
            nsView.image = image.roundCorners(withRadius:16)
            nsView.subviews[0].frame = nsView.bounds
            for subview in nsView.subviews {
                subview.frame = nsView.bounds
            }
        }
        
        
        var i = 0
        let imageRect = nsView.imageRect()
        for box in boxes {
            let index = 2 + i
            if nsView.subviews.indices.contains(index) {
                let subView = nsView.subviews[index]
                let frame = nsView.withInImageRect(imageRect: imageRect, rect: box)
                
                subView.frame = nsView.withInImageRect(imageRect: imageRect, rect: box)
                subView.layer?.opacity = 1.0
            }
            i += 1
        }
//
        


//
//        let current = count
//        count += 1
        
//        let analysisView = nsView.subviews[1] as? ImageAnalysisOverlayView
//        analysisView?.isHidden = shiftPressed
//        if changedImage || (analysisView != nil && analysisView?.analysis == nil) {
//
//            Task {
//                do {
//                    try await Task.sleep(nanoseconds: 500_000_000)
//
//                    if abs(count - current) < 4 , let imageToAnalyze = nsView.image  {
//                        let configuration = ImageAnalyzer.Configuration([.text])
//                        let analysis = try await analyzer.analyze(imageToAnalyze, orientation: .up, configuration: configuration)
//
//
//                        await MainActor.run {
//                            analysisView?.analysis = analysis
//                        }
//                    }
//
//                } catch {
//                    log.error("failed to add live text analysis", context: error.localizedDescription)
//
//                }
//            }
//        }
    }
    
}


class LiveTextImageView: NSImageView {

    override var intrinsicContentSize: NSSize {
        .zero
    }
}



extension NSImageView {

    func withInImageRect(imageRect: NSRect, rect: NSRect) -> NSRect {
        guard let imageSize = image?.size else { return .zero }
        
        let scale = imageRect.width / imageSize.width
        let padding = 4.0
        return NSRect(
            x: imageRect.minX + rect.origin.x * scale - padding,
            y: imageRect.minY + rect.origin.y * scale - padding,
            width: rect.width * scale + 2 * padding,
            height: rect.height * scale + 2 * padding)
    }
    
    /** Returns an `NSRect` of the drawn image in the view. */
    func imageRect() -> NSRect {
        // Find the content frame of the image without any borders first
//        var contentFrame = self.bounds
//        print("self.bounds", self.bounds)
//        print("image?.size", image?.size)
        guard let imageSize = image?.size else { return .zero }
//        let imageFrameStyle = self.imageFrameStyle
//
//        if imageFrameStyle == .button || imageFrameStyle == .groove {
//            print("imageFrameStyle", "button groove")
//            contentFrame = NSInsetRect(self.bounds, 2, 2)
//        } else if imageFrameStyle == .photo {
//            print("imageFrameStyle", "photo")
//            contentFrame = NSRect(x: contentFrame.origin.x + 1, y: contentFrame.origin.x + 2, width: contentFrame.size.width - 3, height: contentFrame.size.height - 3)
//        } else if imageFrameStyle == .grayBezel {
//            print("imageFrameStyle", "gratBezel")
//            contentFrame = NSInsetRect(self.bounds, 8, 8)
//        }

//        print(contentFrame)
        let contentFrame = contentFrameHack
        // Now find the right image size for the current imageScaling
        let imageScaling = self.imageScaling
        var drawingSize = imageSize

        // Proportionally scaling
        if imageScaling == .scaleProportionallyDown || imageScaling == .scaleProportionallyUpOrDown {
            var targetScaleSize = contentFrame.size
            if imageScaling == .scaleProportionallyDown {
                if targetScaleSize.width > imageSize.width { targetScaleSize.width = imageSize.width }
                if targetScaleSize.height > imageSize.height { targetScaleSize.height = imageSize.height }
            }

            let scaledSize = self.sizeByScalingProportianlly(toSize: targetScaleSize, fromSize: imageSize)
            drawingSize = NSSize(width: scaledSize.width, height: scaledSize.height)
        }

        // Axes independent scaling
        else if imageScaling == .scaleAxesIndependently {
            drawingSize = contentFrame.size
        }


        // Now get the image position inside the content frame (center is default) from the current imageAlignment
        let imageAlignment = self.imageAlignment
        var drawingPosition = NSPoint(x: contentFrame.origin.x + contentFrame.size.width / 2 - drawingSize.width / 2,
                                      y: contentFrame.origin.y + contentFrame.size.height / 2 - drawingSize.height / 2)

        // Top Alignments
        if imageAlignment == .alignTop || imageAlignment == .alignTopLeft || imageAlignment == .alignTopRight {
            drawingPosition.y = contentFrame.origin.y + contentFrame.size.height - drawingSize.height

            if imageAlignment == .alignTopLeft {
                drawingPosition.x = contentFrame.origin.x
            } else if imageAlignment == .alignTopRight {
                drawingPosition.x = contentFrame.origin.x + contentFrame.size.width - drawingSize.width
            }
        }

        // Bottom Alignments
        else if imageAlignment == .alignBottom || imageAlignment == .alignBottomLeft || imageAlignment == .alignBottomRight {
            drawingPosition.y = contentFrame.origin.y

            if imageAlignment == .alignBottomLeft {
                drawingPosition.x = contentFrame.origin.x
            } else if imageAlignment == .alignBottomRight {
                drawingPosition.x = contentFrame.origin.x + contentFrame.size.width - drawingSize.width
            }
        }

        // Left Alignment
        else if imageAlignment == .alignLeft {
            drawingPosition.x = contentFrame.origin.x
        }

        // Right Alginment
        else if imageAlignment == .alignRight {
            drawingPosition.x = contentFrame.origin.x + contentFrame.size.width - drawingSize.width
        }

        return NSRect(x: round(drawingPosition.x), y: round(drawingPosition.y), width: ceil(drawingSize.width), height: ceil(drawingSize.height))
    }


    func sizeByScalingProportianlly(toSize newSize: NSSize, fromSize oldSize: NSSize) -> NSSize {
        let widthHeightDivision = oldSize.width / oldSize.height
        let heightWidthDivision = oldSize.height / oldSize.width

        var scaledSize = NSSize.zero

        if oldSize.width > oldSize.height {
            if (widthHeightDivision * newSize.height) >= newSize.width {
                scaledSize = NSSize(width: newSize.width, height: heightWidthDivision * newSize.width)
            } else {
                scaledSize = NSSize(width: widthHeightDivision * newSize.height, height: newSize.height)
            }
        } else {
            if (heightWidthDivision * newSize.width) >= newSize.height {
                scaledSize = NSSize(width: widthHeightDivision * newSize.height, height: newSize.height)
            } else {
                scaledSize = NSSize(width: newSize.width, height: heightWidthDivision * newSize.width)
            }
        }

        return scaledSize
    }
}


extension NSImage {

    func roundCorners(withRadius radius: CGFloat) -> NSImage {
        let rect = NSRect(origin: NSPoint.zero, size: size)
        if  let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil),
            let context = CGContext(data: nil,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * Int(size.width),
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) {
            context.beginPath()
            context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
            context.closePath()
            context.clip()
            context.draw(cgImage, in: rect)

            
            if let composedImage = context.makeImage() {
                return NSImage(cgImage: composedImage, size: size)
            }
        }

        return self
    }

}



struct Box {
    let x: CGFloat
    let y: CGFloat
    let w: CGFloat
    let h: CGFloat
    let opacity: Double
}

func getBoundingBoxesCoordinates(original: NSImage?, tags: RecordResponseTags?) -> [Box] {
    guard let original = original, let tags = tags else {
        return []
    }
    
    let boxes = tags.location
    if boxes.count < 4 {
        return []
    }
    
    var newBoxes = [Box]()
    
    for box in windowArray(boxes, windowSize: 4) {
        let ow = original.size.width
        let oh = original.size.height
        
        let w = CGFloat(Float(box[2])) * ow
        let h = CGFloat(Float(box[3])) * oh
        let x = CGFloat(Float(box[0])) * ow
        let y = CGFloat(Float(box[1])) * oh
        newBoxes.append(Box(x: x, y: y, w: w, h: h, opacity: Double(1.0)))
    }

    return newBoxes
}

func windowArray(_ array: [Float], windowSize: Int) -> [[Float]] {
    var windows: [[Float]] = []
    
    for startIndex in stride(from: 0, to: array.count, by: windowSize) {
        let endIndex = min(startIndex + windowSize, array.count)
        let window = Array(array[startIndex..<endIndex])
        if window.count == 4 {
            windows.append(window)
        }
    }
    
    return windows
}


extension NSImage {
    func cropping(to rect: CGRect) -> NSImage {
        var imageRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        guard let imageRef = self.cgImage(forProposedRect: &imageRect, context: nil, hints: nil) else {
            return NSImage(size: rect.size)
        }
        guard let crop = imageRef.cropping(to: rect) else {
            return NSImage(size: rect.size)
        }
        return NSImage(cgImage: crop, size: NSZeroSize)
    }
}
