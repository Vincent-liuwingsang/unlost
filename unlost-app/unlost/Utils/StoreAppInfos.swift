//
//  StoreAppInfos.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 25/06/2023.
//

import SwiftUI

public func storeAppIcons(appName: String, image: NSImage?)  {
    guard let image = image else {
        return
    }
    let directory = getDocumentsDirectory()
        .appendingPathComponent("appIcons", conformingTo: .directory)
    let path = directory
        .appendingPathComponent("\(appName).png", conformingTo: .image)
    
    guard !FileManager.default.fileExists(atPath: path.absoluteString) else {
        return
    }
    
    if !FileManager.default.fileExists(atPath: directory.absoluteString) {
        try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
   
    
    Task.detached(priority: .background) {
        let imageRep = NSBitmapImageRep(data: image.tiffRepresentation!)
        let pngData = imageRep?.representation(using: .png, properties: [:])
        do {
            try pngData!.write(to: path)
        } catch {
            log.warning("can't save app icons")
        }
    }
}
