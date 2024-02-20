//
//  Database.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 15/07/2023.
//

import Foundation
import SQLite

struct Screenshot: Encodable {
    let app_name : String
    let app_title : String
    let created_at : Date
    let path : URL
    let minX : Int64?
    let minY : Int64?
    let width : Int64?
    let height : Int64?
    let is_transcription: Bool
    let is_mic: Bool
    let ocr_result : String
    let has_ocr_result : Bool
    let screenshot_time: Int
    let screenshot_time_to: Int?
    let url: String?
}

class Database {
    static let shared = Database()
    
    private var db: Connection?
    private var screenshots: Table?
    
    private init() {
        do {
            db = try Connection(getDocumentsDirectory().appendingPathComponent("db.sqlite3").absoluteString)
            screenshots = Table("screenshots")
        } catch {
            log.error("failed to init db \(error.localizedDescription)")
        }
        
        
        runMigration()
    }

    private func runMigration() {
        guard let db = db else { return }
        if db.userVersion == nil || db.userVersion == 0 {
            writeAheadLogging()
            createScreenshotsTable()
            db.userVersion = 1
        }
        
        if db.userVersion == 1, let screenshots = screenshots {
            let minX = Expression<Int64?>("minX")
            let minY = Expression<Int64?>("minY")
            do {
                try db.run(screenshots.addColumn(minX))
                try db.run(screenshots.addColumn(minY))
                db.userVersion = 2
            } catch {
                log.error("failed to run migration 2")
            }
        }

    }
    
    private func writeAheadLogging() {
        do {
            try db?.execute("PRAGMA journal_mode=WAL;")
        } catch {
            log.error("failed to enbale WAL \(error.localizedDescription)")
        }
    }
    
    private func createScreenshotsTable() {
        guard let db = db, let screenshots = screenshots else { return }
        
        let id = Expression<Int64>("id")
        let app_name = Expression<String>("app_name")
        let app_title = Expression<String>("app_title")
        let created_at = Expression<Date>("created_at")
        let path = Expression<URL>("path")
        let width = Expression<Int64?>("width")
        let height = Expression<Int64?>("height")
        let ocr_result = Expression<String>("ocr_result")
        let has_ocr_result = Expression<Bool>("has_ocr_result")
        let is_transcription = Expression<Bool>("is_transcription")
        let is_mic = Expression<Bool>("is_mic")
        let screenshot_time = Expression<Int>("screenshot_time")
        let screenshot_time_to = Expression<Int?>("screenshot_time_to")
        let url = Expression<String?>("url")
        
        do {
            try db.run(
                screenshots.create(ifNotExists: true) { t in
                    t.column(id, primaryKey: .autoincrement)
                    t.column(app_name)
                    t.column(app_title)
                    t.column(created_at)
                    t.column(path)
                    t.column(width)
                    t.column(height)
                    t.column(ocr_result)
                    t.column(has_ocr_result)
                    t.column(is_transcription)
                    t.column(is_mic)
                    t.column(screenshot_time)
                    t.column(screenshot_time_to)
                    t.column(url)
                }
            )
        } catch {
            log.error("failed to create screenshots table")
        }
        
        do {
            try db.run(screenshots.createIndex(created_at, ocr_result))
        } catch {
            log.error("failed to create screenshots index \(error.localizedDescription)")
        }
    }
    
    func addScreenshot(screenshot: Screenshot) {
        guard let db = db, let screenshots = screenshots else { return }
        
        do {
            try db.run(screenshots.insert(screenshot))
        } catch {
            log.error("failed to add screenshot \(error.localizedDescription)")
        }
    }
    
    func addScreenshots(allScreenshots: [Screenshot]) {
        guard let db = db, let screenshots = screenshots, allScreenshots.count > 0 else { return }
        
        do {
            try db.run(screenshots.insertMany(allScreenshots))
        } catch {
            log.error("failed to add screenshots \(error.localizedDescription)")
        }
    }
}
