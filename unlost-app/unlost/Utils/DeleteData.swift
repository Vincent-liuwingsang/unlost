//
//  DeleteData.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 08/09/2023.
//

import Foundation

func deleteData(retention: String) {
    let r = retentionPeriods.first { $0 == retention }
    switch r {
    case "1 Week":
        let upto = Calendar(identifier: .iso8601).date(byAdding: .weekOfYear, value: -1, to: Date())!
        deleteUpTo(date: upto)
    case "2 Weeks":
        let upto = Calendar(identifier: .iso8601).date(byAdding: .weekOfYear, value: -2, to: Date())!
        deleteUpTo(date: upto)
    case "1 Month":
        let upto = Calendar(identifier: .iso8601).date(byAdding: .month, value: -1, to: Date())!
        deleteUpTo(date: upto)
    case "3 Months":
        let upto = Calendar(identifier: .iso8601).date(byAdding: .month, value: -3, to: Date())!
        deleteUpTo(date: upto)
    case defaultRetentionPeriod:
        let upto = Calendar(identifier: .iso8601).date(byAdding: .month, value: -defaultRetentionPeriodNumber, to: Date())!
        deleteUpTo(date: upto)
    default:
        return
    }
}

func deleteUpTo(date: Date) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let url = getDocumentsDirectory()
        .appendingPathComponent("recordings", conformingTo: .directory)
    let contents: [URL]
    do {
        contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey])
    } catch {
        return
    }
    
    let calendar = Calendar.current
    let startOfDay =
        calendar.date(from: calendar.dateComponents([.year, .month, .day], from: date))!
    
    
    Task.detached(priority: .background) {
        for url in contents {
            let isDirectoryResourceValue: URLResourceValues
            do {
                isDirectoryResourceValue = try url.resourceValues(forKeys: [.isDirectoryKey])
            } catch {
                continue
            }
            
            if isDirectoryResourceValue.isDirectory == true,
               let directoryDate = dateFormatter.date(from: url.lastPathComponent),
               directoryDate < startOfDay {
               removeFile(url: url)
            }
        }
    }
    
   PythonServer.shared.deleteMemory(date: startOfDay)
}


func removeFile(url: URL) {
    let fileManager = FileManager.default

    do {
        log.debug("removing \(url)")
        try fileManager.removeItem(at: url)
    } catch {
        log.warning("Error removing file: \(error.localizedDescription)")
    }
}
