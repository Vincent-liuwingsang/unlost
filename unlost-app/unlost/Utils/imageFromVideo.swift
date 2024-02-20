//
//  imageFromVidro.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 16/09/2023.
//

import SwiftUI
import LRUCache
import AVFoundation

let imageCache = LRUCache<String, NSImage>(countLimit: 30)

func imageFromVideo(url: URL, at time: TimeInterval, minX: Double?, minY: Double?, ow: Double, oh: Double, completion: @escaping (NSImage?) -> Void) {
    
    let key = "\(url.absoluteString)#\(time)#\(minX)#\(minY)#\(ow)#\(oh)"
    if let image = imageCache.value(forKey: key) {
        completion(image)
        return
    }
    
    let asset = AVURLAsset(url: url)

    let assetIG = AVAssetImageGenerator(asset: asset)
    assetIG.appliesPreferredTrackTransform = true
    assetIG.apertureMode = AVAssetImageGenerator.ApertureMode.encodedPixels
    assetIG.requestedTimeToleranceAfter = .zero
    assetIG.requestedTimeToleranceBefore = .zero
    Task.detached(priority:.high) {
        
        let cmTime = CMTime(seconds: time/1000, preferredTimescale: 60)
        let thumbnailImageRef: CGImage
        
        do {
            thumbnailImageRef = try assetIG.copyCGImage(at: cmTime, actualTime: nil)
        } catch let error {
            log.warning("failed to copy image from video. \(error.localizedDescription). \(url.absoluteString):\(cmTime.seconds)")
            return completion(nil)
        }
        
        if let cgImage = thumbnailImageRef.cropping(to: CGRect(x: minX ?? 0, y: minY ?? 0, width: ow, height: oh)) {
            let image = NSImage(cgImage: cgImage, size: NSSize(width: ow, height: oh))
            imageCache.setValue(image, forKey: key)
            completion(image)
        }
        
    }
}
