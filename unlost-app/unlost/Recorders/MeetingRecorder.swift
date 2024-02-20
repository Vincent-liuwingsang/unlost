//
//  MeetingRecorder.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 25/07/2023.
//

import Foundation
import AppKit
import AVFoundation
import ScreenCaptureKit
import ReplayKit
import Vision
import SwiftUI

enum Browser {
    case chrome
    case brave
    case safari
    case arc
}

enum MeetingType{
    case zoom
    case meet
}

struct TabInRecording {
    let id: String
    let url: String
    let browser: Browser
    let meetingType: MeetingType
}

struct RecordingError: Error, CustomDebugStringConvertible {
    var debugDescription: String
    init(_ debugDescription: String) { self.debugDescription = debugDescription }
}


class MeetingRecorder: ObservableObject {
    static var shared = MeetingRecorder()
    
    @AppStorage("enableMeetingRecording") var enableMeetingRecording: Bool = true
    
    private var captureEngine: CaptureEngine?
    private var contentFilter: SCContentFilter? = nil
    private var displayID: CGDirectDisplayID? = nil
    private var windowID: CGWindowID? = nil
    private var windowBundleID: String? = nil
    private var shouldPollBrowser = false
    private var tabInRecording: TabInRecording?
    
    private init() {
        listenToActiveAppChanges()
    }

    
    func start() async {
        if !enableMeetingRecording {
            return
        }
        
        log.info("queued start")
        await StartStopQueue.shared.channel.send { [self] in
            log.info("started")
            guard self.captureEngine == nil else { return }

            if let filter = contentFilter, let displayID = displayID, let windowID = windowID, let windowBundleID = windowBundleID {
                Task {
                    do {
                        self.captureEngine = try CaptureEngine(displayID: displayID, windowID: windowID, windowBundleID: windowBundleID, filter: filter, audio: true, mic: true, onError: {
                            Task {
                                await self.stop()
                            }
                        })
                        log.info("start meeting recording")
                        try await self.captureEngine?.start()
                    } catch {
                        // TODO stop polling
                        log.error("failed to start meeting recorder \(error)")
                    }
                }
            }
            
            Task {
                pollBrowserToStopRecording()
            }
            log.info("ended")
        }
    }
    
    let regex1 = try! NSRegularExpression(pattern: "\\[.*?\\]", options: [])
    let regex2 = try! NSRegularExpression(pattern: "\\(.*?\\)", options: [])
    func removeSquareBrackets(input: String) -> String {
        let range1 = NSRange(location: 0, length: input.utf16.count)
        let t1 = regex1.stringByReplacingMatches(in: input, options: [], range: range1, withTemplate: "")
        let range2 = NSRange(location: 0, length: t1.utf16.count)
        let t2 = regex2.stringByReplacingMatches(in: t1, options: [], range: range2, withTemplate: "")
        return t2
    }
    
    func stop() async {
        log.info("queued stop")
        await StartStopQueue.shared.channel.send { [self] in
            log.info("started")
            do {
                // make sure its finished writing
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await self.captureEngine?.stop(callback: updateDB)
            } catch {
                log.error("failed to stop meeting recorder \(error.localizedDescription)")
            }
            
            captureEngine = nil
            tabInRecording = nil
            windowID = nil
            windowBundleID = nil
            log.info("stopped")
        }
    }

    func updateDB(results: [TimestampedResult]) {
        if let recorder = captureEngine, let windowID = windowID, let videoURL = recorder.videoURL {
            Task(priority: .low) {
                let info = getWindowInfo(windowId: windowID)
                
                let appName = getWindowAppName(windowInfo: info)
                let appTitle = getWindowAppTitle(windowInfo: info)
                
                let sortedResults = results.sorted {
                    $0.time < $1.time
                }
                
                let created_at = Date.now
                
                let transcriber = TranscribeAudio()
                
                var dimensions = [(time: Int, width: Int64, height: Int64)]()
                
                // ocr video
                var screenshots = [Screenshot]()
                for result in sortedResults {
                    screenshots.append(Screenshot(app_name: appName, app_title: appTitle, created_at: created_at, path: videoURL, minX: result.minX, minY: result.minY, width: result.width, height: result.height, is_transcription: false, is_mic: false, ocr_result: result.ocrResult, has_ocr_result: true, screenshot_time: Int(result.time), screenshot_time_to: nil, url: nil))
                    
                    if let last = dimensions.last {
                        if result.width != last.width, result.height != last.height {
                            dimensions.append((time: Int(result.time), width: result.width, height: result.height))
                        }
                    } else {
                        dimensions.append((time: Int(result.time), width: result.width, height: result.height))
                    }
                }
                
                dimensions.reverse()
                
                // transcribe audio
                if let audioURL = recorder.audioURL  {
                    await transcriber.transcribe(fileURL: audioURL) { segments in
                        for segment in segments {
                            let clean = removeSquareBrackets(input: segment.text)
                                .trimmingCharacters(in: .whitespaces)
                            
                            let dimension = dimensions.first { $0.time < segment.startTime } ?? dimensions.first
                            if !clean.isEmpty {
                                let screenshot = Screenshot(app_name: appName, app_title: appTitle, created_at: created_at, path: videoURL, minX: 0, minY: 0, width: dimension?.width ?? 0, height: dimension?.height ?? 0, is_transcription: true, is_mic: false, ocr_result: clean, has_ocr_result: true, screenshot_time: segment.startTime, screenshot_time_to: segment.endTime, url: nil)
                                screenshots.append(screenshot)
                            }
                        }
                        
                        Task.detached(priority: .background) {
                            removeFile(url: audioURL)
                        }
                    }
                }
                
                
                // transcribe mic
                if let micURL = recorder.micURL {
                    await transcriber.transcribe(fileURL: micURL) { segments in
                        for segment in segments {
                            let clean = removeSquareBrackets(input: segment.text)
                                .trimmingCharacters(in: .whitespaces)
                            if !clean.isEmpty {
                                let dimension = dimensions.first { $0.time < segment.startTime } ?? dimensions.first
                                let screenshot = Screenshot(app_name: appName, app_title: appTitle, created_at: created_at, path: videoURL, minX: 0, minY: 0, width: dimension?.width ?? 0, height: dimension?.height ?? 0, is_transcription: true, is_mic: true, ocr_result: clean, has_ocr_result: true, screenshot_time: segment.startTime, screenshot_time_to: segment.endTime, url: nil)
                                screenshots.append(screenshot)
                            }
                        }
                    }
                    
                    Task.detached(priority: .background) {
                        removeFile(url: micURL)
                    }
                }
                
                if screenshots.count > 0 {
                    Database.shared.addScreenshots(allScreenshots: screenshots)
                }
            }
        }
    }
    
    var teamTaskFlag = 0
    var teamsTask: Task<Void, Error>? = nil
    
    func pollTeam(pid: Int32) async {
        do {
            let availableContent = try await SCShareableContent.excludingDesktopWindows(true,
                                                                                        onScreenWindowsOnly: true)
            let windowInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly], .min) as? [ [ String : AnyObject] ]
            
            let processWindows = windowInfo?.filter {
                var rect = NSRect()
                let bounds = $0["kCGWindowBounds"] as! CFDictionary
                CGRectMakeWithDictionaryRepresentation(bounds, &rect)
                return $0["kCGWindowOwnerPID"] as? Int32 == pid &&
                rect.width > 200 &&
                rect.height > 100
            }
            if let processWindows = processWindows, processWindows.count > 1, isMicActive() {
                let meetingWindow = processWindows.first {
                    $0["kCGWindowName"] as? String != "Calendar | Microsoft Teams" &&
                    $0["kCGWindowName"] as? String != "Chat | Microsoft Teams" &&
                    $0["kCGWindowName"] as? String != "Community | Microsoft Teams" &&
                    $0["kCGWindowName"] as? String != "Activity | Microsoft Teams"
                }
                let meetingWindowSC = availableContent.windows.first {
                    $0.windowID == meetingWindow?["kCGWindowNumber"] as? UInt32
                }
                if let meetingWindowSC = meetingWindowSC,
                   let meetingWindow = meetingWindow,
                   let bounds = meetingWindow["kCGWindowBounds"] as? NSDictionary,
                   let x = bounds["X"] as? Double,
                   let y = bounds["Y"] as? Double,
                   let w = bounds["Width"] as? Double,
                   let h = bounds["Height"] as? Double,
                   let display = availableContent.displays.first(where: { CGDisplayBounds($0.displayID).contains(CGRect(x: x, y: y, width: w, height: h))}){
                    
                    self.windowID = meetingWindowSC.windowID
                    self.displayID = display.displayID
                    self.contentFilter = SCContentFilter(desktopIndependentWindow: meetingWindowSC)
                    Task {
                        await self.start()
                        self.teamsTask?.cancel()
                    }
                }
            }
        } catch {
            log.warning("failed to poll teams \(error.localizedDescription)")
        }
    }
    
    func checkIfActiveAppTriggersRecording(app: NSRunningApplication) {
        Task.detached(priority: .high) {
            let availableContent = try await SCShareableContent.excludingDesktopWindows(true,
                                                                                        onScreenWindowsOnly: true)
            
            let windowInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly], .min) as? [ [ String : AnyObject] ]
            let firstWindow = windowInfo?.first  {
                var rect = NSRect()
                let bounds = $0["kCGWindowBounds"] as! CFDictionary
                CGRectMakeWithDictionaryRepresentation(bounds, &rect)
                return $0["kCGWindowOwnerPID"] as? Int32 == app.processIdentifier &&
                    rect.width > 200 &&
                    rect.height > 100
            }
            
            let newWindow = availableContent.windows.first {
                if let processId = $0.owningApplication?.processID, processId != app.processIdentifier {
                    return false
                } else {
                    return $0.windowID == firstWindow?["kCGWindowNumber"] as? UInt32?
                }
            }
            
            if let windowToCapture = newWindow,
               let firstWindow = firstWindow,
               let bounds = firstWindow["kCGWindowBounds"] as? NSDictionary,
               let x = bounds["X"] as? Double,
               let y = bounds["Y"] as? Double,
               let w = bounds["Width"] as? Double,
               let h = bounds["Height"] as? Double,
               let display = availableContent.displays.first(where: { CGDisplayBounds($0.displayID).contains(CGRect(x: x, y: y, width: w, height: h))}){
                
                self.windowID = windowToCapture.windowID
                self.windowBundleID = windowToCapture.owningApplication?.bundleIdentifier
                
                
                let appName = windowToCapture.owningApplication?.applicationName
                if appName == "zoom.us", windowToCapture.title == "Zoom Meeting"{
                    self.displayID = display.displayID
                    self.contentFilter = SCContentFilter(desktopIndependentWindow: windowToCapture)
                    Task {
                        await self.start()
                    }
                    
                } else if appName == "Microsoft Teams" {
                    self.teamsTask?.cancel()
                    self.teamsTask = Task.detached(priority:.high) {
                        while true {
                            try await Task.sleep(nanoseconds: 1_000_000_000)
                            print("poll")
                            await self.pollTeam(pid: app.processIdentifier)
                        }
                    }
                    self.teamTaskFlag += 1
                } else if appName == "Google Chrome" {
                    self.displayID = display.displayID
                    self.contentFilter = SCContentFilter(desktopIndependentWindow: windowToCapture)
                    self.shouldPollBrowser = true
                    self.pollBrowserToTriggerRecording(browser: .chrome)
                } else if appName == "Safari" {
                    self.displayID = display.displayID
                    self.contentFilter = SCContentFilter(desktopIndependentWindow: windowToCapture)
                    self.shouldPollBrowser = true
                    self.pollBrowserToTriggerRecording(browser: .safari)
                } else if appName == "Arc" {
                    self.displayID = display.displayID
                    self.contentFilter = SCContentFilter(desktopIndependentWindow: windowToCapture)
                    self.shouldPollBrowser = true
                    self.pollBrowserToTriggerRecording(browser: .arc)
                }
            }
        }
    }
    
    @objc func onAppChanges(note: NSNotification) {
        shouldPollBrowser = false
        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        if app?.localizedName != "Microsoft Teams" {
            let oldFlag = teamTaskFlag
            Task {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                print("cancelled")
                if oldFlag == self.teamTaskFlag {
                    self.teamsTask?.cancel()
                }
            }
        }
        
        if !enableMeetingRecording {
            return
        }
        if tabInRecording != nil || captureEngine != nil {
            return
        }
        
        if let app = app {
            self.checkIfActiveAppTriggersRecording(app: app)
        }
    }

//    let test = "YLMtypDhXXI"
    
    func pollBrowserToTriggerRecording(browser: Browser) {
        if let idAndUrl = AppleScript.shared.getBrowserIdAndUrl(browser: browser) {
            let id = idAndUrl.0
            let url = idAndUrl.1
            if url.contains("zoom.us/wc"), !url.contains("/leave") {
                tabInRecording = TabInRecording(id: id, url: url, browser: browser, meetingType: .zoom)
                shouldPollBrowser = false
                Task {
                    await self.start()
                }
            } else if url.contains("meet.google.com/"), !url.hasSuffix("meet.google.com/") {
                tabInRecording = TabInRecording(id: id, url: url, browser: browser, meetingType: .meet)
                shouldPollBrowser = false
                Task {
                    await self.start()
                }
                
            } else if shouldPollBrowser {
                Task {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    self.pollBrowserToTriggerRecording(browser: browser)
                }
            }
        } else {
            shouldPollBrowser = false
        }
    }
    
    func repollBrowserToStopRecording() {
        Task {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            self.pollBrowserToStopRecording()
        }
    }
    
    
    func pollBrowserToStopRecording() {
        if let tab = tabInRecording, let result = AppleScript.shared.getBrowserIdAndUrlList(browser: tab.browser) {
            
            let ids = result.0
            let urls = result.1
            // TODO what about safari?
            if tab.meetingType == .zoom {
                var shouldStop = true
                for url in urls {
                    if url.contains("zoom/"), (url.contains("/start") || url.contains("/join")) {
                        shouldStop = false
                    }
                }
                
                if shouldStop {
                    Task {
                        log.info("stopped")
                        await self.stop()
                    }
                } else {
                    repollBrowserToStopRecording()
                }
            } else {
                if let matchedIndex = ids.firstIndex(where: { $0 == tab.id}) {
                    let matchedUrl = urls[matchedIndex]
                    
                    if (!matchedUrl.contains("meet.google.com/") || matchedUrl.hasSuffix("meet.google.com/")) {
                        Task {
                            log.info("stopped")
                            await self.stop()
                        }
                    } else {
                        repollBrowserToStopRecording()
                    }
                } else {
                    Task {
                        log.info("stopped")
                        await self.stop()
                    }
                }
            }
        }
    }
    
    private func listenToActiveAppChanges() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onAppChanges(note:)),
            name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }
}


public class AudioRecording : NSObject {
  
    static var directory: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    var url: URL
    
    private var recorder: AVAudioRecorder
   
  
    
    init(url: URL) throws {
        self.url = url
        let settings: [String : Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        recorder = try AVAudioRecorder(url: url as URL, settings: settings)
    }
    

    func record() {
        recorder.prepareToRecord()
        recorder.record()
    }

    func stop() {
        recorder.stop()
    }
}


