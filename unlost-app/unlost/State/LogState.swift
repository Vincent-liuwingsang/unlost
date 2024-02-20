//
//  Log.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 11/09/2023.
//

import Foundation
import SwiftyBeaver

class LogState {
    static var shared = LogState()
    var timer: Timer? = nil
    var lastDate: String
    var lastDestination: FileDestination
    let path = getDocumentsDirectory()
        .appendingPathComponent("logs", conformingTo: .directory)
        .appendingPathComponent("app", conformingTo: .directory)
    
    private init() {
        lastDate = today()
        
        let logFileName = self.path.appendingPathComponent("\(today()).log", conformingTo: .utf8PlainText)
        lastDestination = FileDestination(logFileURL: logFileName)
        let console = ConsoleDestination()
        log.addDestination(lastDestination)
        log.addDestination(console)
        
                    
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {_ in
            let now = today()
            if now != self.lastDate {
                log.removeDestination(self.lastDestination)
                let logFileName = self.path.appendingPathComponent("\(today()).log", conformingTo: .utf8PlainText)
                let newDestination = FileDestination(logFileURL: logFileName)
                log.addDestination(newDestination)
                
                self.lastDestination = newDestination
                self.lastDate = now
            }
            
            let fileManager = FileManager.default
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: self.path, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                for url in fileURLs {
                    if isDateMoreThan2DaysAgo(url.lastPathComponent) {
                        removeFile(url: url)
                    }
                }
                
            } catch {
                return
            }
        }
            
        let legacyLogPath = getDocumentsDirectory()
            .appendingPathComponent("logs", conformingTo: .directory)
            .appendingPathComponent("app.log", conformingTo: .utf8PlainText)
        removeFile(url: legacyLogPath)
    }

}



func isDateMoreThan2DaysAgo(_ dateString: String) -> Bool {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    if let date = dateFormatter.date(from: dateString) {
        // Get the current date
        let currentDate = Date()
        
        // Calculate the time interval between currentDate and the parsed date
        let timeInterval = currentDate.timeIntervalSince(date)
        
        // Calculate the equivalent of 2 days in seconds
        let twoDaysInSeconds: TimeInterval = 2 * 24 * 60 * 60
        
        // Compare the time interval with 2 days
        if timeInterval > twoDaysInSeconds {
            return true
        }
    }
    
    return false
}
