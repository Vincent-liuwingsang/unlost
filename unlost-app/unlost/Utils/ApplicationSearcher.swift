//
//  ApplicationSearcher.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 11/09/2023.
//

import SwiftUI

class ApplicationSearcher: NSObject {

    func getInsatlledApplications() -> [ApplicationSearched] {

        let localApplicationUrls = getApplicationUrlsAt(directory: .applicationDirectory, domain: .localDomainMask)
        let systemApplicationsUrls = getApplicationUrlsAt(directory: .applicationDirectory, domain: .systemDomainMask)
        let systemUtilitiesUrls = getApplicationUrlsAt(directory: .applicationDirectory, domain: .systemDomainMask, subpath: "/Utilities")
        
        let allApplicationUrls = localApplicationUrls + systemApplicationsUrls + systemUtilitiesUrls
        
        var applications = [ApplicationSearched]()
        
        for url in allApplicationUrls {
            do {
                let resourceKeys : [URLResourceKey] = [.isExecutableKey, .isApplicationKey]
                let resourceValues = try url.resourceValues(forKeys: Set(resourceKeys))
                if resourceValues.isApplication! && resourceValues.isExecutable! {
                    let name = url.deletingPathExtension().lastPathComponent
                    let icon = NSWorkspace.shared.icon(forFile: url.path)
                    let bundleId = Bundle(url: url)?.bundleIdentifier
                    applications.append(ApplicationSearched(bundleId: bundleId, name: name, icon: icon))
                }
            } catch {}
        }
        
        return applications
    }
    
    func getAllApplications() -> [ApplicationSearched] {
        var applications = [ApplicationSearched]()
        
        for app in NSWorkspace.shared.runningApplications {
            if let icon = app.icon, let name = app.localizedName {
                let searched = ApplicationSearched(bundleId: app.bundleIdentifier, name: name, icon: icon)
                applications.append(searched)
            }
        }
        
        let installed = getInsatlledApplications()
        let total = applications + installed
        return total.sorted { $0.name < $1.name }
    }
    
    private func getApplicationUrlsAt(directory: FileManager.SearchPathDirectory, domain: FileManager.SearchPathDomainMask, subpath: String = "") -> [URL] {
        let fileManager = FileManager()
        
        do {
            let folderUrl = try FileManager.default.url(for: directory, in: domain, appropriateFor: nil, create: false)
            let folderUrlWithSubpath = NSURL.init(string: folderUrl.path + subpath)! as URL
            
            let applicationUrls = try fileManager.contentsOfDirectory(at: folderUrlWithSubpath, includingPropertiesForKeys: [], options: [FileManager.DirectoryEnumerationOptions.skipsPackageDescendants, FileManager.DirectoryEnumerationOptions.skipsSubdirectoryDescendants])
            
            return applicationUrls
        } catch {
            return []
        }
    }
    

}


struct ApplicationSearched {
    var bundleId: String?
    var name: String
    var icon: NSImage
}
