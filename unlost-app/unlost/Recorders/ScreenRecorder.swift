//
//  ScreenRecorder.swift
//  Wednesday
//
//  Created by Wing Sang Vincent Liu on 10/06/2023.
//

import Foundation
import ScreenCaptureKit
import Combine
import OSLog
import SwiftUI
import UniformTypeIdentifiers
import Vision
import AppKit
import CoreImage
import CoreVideo


struct OCRResult: Encodable {
    let value: String
    let location: [Double]
}

func getWindowInfo(windowId: CGWindowID) -> [ String : AnyObject]? {
    let windowInfo = CGWindowListCopyWindowInfo([.optionIncludingWindow], windowId) as? [ [ String : AnyObject] ]
    
    return windowInfo?.first
}

func getWindowAppName(windowInfo: [ String : AnyObject]? ) -> String {
    return windowInfo?["kCGWindowOwnerName"] as? String ?? "Unknown App"
}

func getWindowAppTitle(windowInfo: [ String : AnyObject]? ) -> String {
    return (windowInfo?["kCGWindowName"] as? String ?? getWindowAppName(windowInfo: windowInfo))
}

func getDocumentsDirectory() -> URL {
    // find all possible documents directories for this user
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

    // just send back the first one, which ought to be the only one
    return paths[0].appendingPathComponent("UnlostApp.nosync", conformingTo: .directory)
}

//@MainActor
class ScreenRecorder: ObservableObject {
    static var shared = ScreenRecorder()
    
    @AppStorage("enableRecording") var enableRecording: Bool = true
    @AppStorage("bannedPrivateBrowsing") var bannedPrivateBrowsing: Bool = true
    
    var activeVideoURL: URL?
        
    private(set) var availableWindows = [SCWindow]()

    
    private var contentFilter: SCContentFilter? = nil
//    private var streamConfiguration: SCStreamConfiguration? = nil
    
    
    private var captureEngine: CaptureEngine?
//    private let captureEngine = CaptureEngine(dispatchQueue: DispatchQueue(label: "com.unlost.captureEngine.ScreenRecorder"))
    
    private var displayID: CGDirectDisplayID? = nil
    private var windowID: CGWindowID? = nil
    private var windowBundleID: String? = nil
    private var prevWindowID: CGWindowID? = nil
    
    private init() {
        listenToActiveAppChanges()
        selfStartStop()
        selfRepair()
        checkActiveVideoFile()
    }
    
    func startRetry() {
        Task { [self] in
            try await Task.sleep(nanoseconds: 2_000_000_000)
            await self.start()
        }
    }
    
    /// Starts capturing screen content.
    func start() async {
        log.debug("start")
        
        if !enableRecording {
            return
        }
        
        log.debug("queued start")
        await StartStopQueue.shared.channel.send { [self] in
            // TODO if netflix, stop until its gone?
            log.info("recorder start")
            
            guard activeVideoURL == nil else { return }
            
            await self.refreshAvailableContent()
            
            if displayID == nil {
                startRetry()
                return
            }
        
            if let windowID = windowID, let windowBundleID = windowBundleID, let displayID = displayID, let contentFilter = contentFilter {
                do {
                    captureEngine = try CaptureEngine(displayID: displayID, windowID: windowID, windowBundleID: windowBundleID, filter: contentFilter, audio: false, mic: false, onError: restart)
                    try await captureEngine?.start()
                    
                    activeVideoURL = captureEngine?.videoURL
                } catch {
                    log.error("failed to start screenRecorder \(error.localizedDescription)")
                    startRetry()
                }
            }
        }
    }
    
    func restart() {
        Task {
            await self.stop()
            await self.start()
        }
    }
    
    let sizeLimitInBytes: UInt64 = 5 * 1024 * 1024 // 5Mb of images
    func checkActiveVideoFile() {
        Task.detached(priority: .background) { [self] in
            if let activeVideoURL = activeVideoURL,
               let size = getFileSize(at: activeVideoURL), size > sizeLimitInBytes {
                restart()
            }
                    
            try await Task.sleep(nanoseconds: 5_000_000_000)
            checkActiveVideoFile()
        }
    }
    
    /// Stops capturing screen content.
    func stop() async {
        log.debug("queued stop")
        await StartStopQueue.shared.channel.send { [self] in
            log.info("started")
            guard activeVideoURL != nil, let captureEngine = captureEngine else {
                log.warning("missing activeVideoURL and captureEngine when stopping")
                return
            }
            
            await captureEngine.stop(callback: updateDB)
    
            self.captureEngine = nil
            self.activeVideoURL = nil
            log.info("ended")
        }
    }
    
    private func updateDB(results: [TimestampedResult]) {
        if let videoURL = captureEngine?.videoURL {
            let screenshots = results.map { Screenshot(app_name: $0.appName, app_title: $0.appTitle, created_at: $0.created_at, path: videoURL, minX: $0.minX, minY: $0.minY, width: $0.width, height: $0.height, is_transcription: false, is_mic: false, ocr_result: $0.ocrResult, has_ocr_result: true, screenshot_time: Int($0.time), screenshot_time_to: nil, url: $0.url) }
            
            Task.detached(priority: .background) {
                Database.shared.addScreenshots(allScreenshots: screenshots)
                log.info("added \(screenshots.count) screenshots from ScreenRecorder")
            }
        }
    }
    
    private func updateEngine() {
        if let windowID = windowID, let windowBundleID = windowBundleID, prevWindowID != windowID, let contentFilter = contentFilter, let captureEngine = captureEngine {
            captureEngine.update(filter: contentFilter, windowID: windowID, windowBundleID: windowBundleID)
        } else {
            Task { [self] in
                try! await Task.sleep(nanoseconds: 2_000_000_000)
                self.updateEngine()
            }
        }
        
    }
        
    
    /// - Tag: GetAvailableContent
    func refreshAvailableContent() async {
        do {
            // Retrieve the available screen content to capture.
            let availableContent = try await SCShareableContent.excludingDesktopWindows(true,
                                                                                        onScreenWindowsOnly: true)

            
            let windows = filterWindows(availableContent.windows)
            if windows != availableWindows {
                availableWindows = windows
            }
            
            // front most app
            let frontApp = NSWorkspace.shared.frontmostApplication
            
          
            // find front most window with same process id
            let windowInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly], .min) as? [ [ String : AnyObject] ]

            let firstWindow = windowInfo?.first  {
                var rect = NSRect()
                let bounds = $0["kCGWindowBounds"] as! CFDictionary
                CGRectMakeWithDictionaryRepresentation(bounds, &rect)
                return $0["kCGWindowOwnerPID"] as? Int32 == frontApp?.processIdentifier &&
                    rect.width > 200 &&
                    rect.height > 100
            }
            
            
            // front most scwindow matching windowId
            let newWindow = windows.first {
                if let processId = $0.owningApplication?.processID, processId != frontApp?.processIdentifier {
                    return false
                } else {
                    return $0.windowID == firstWindow?["kCGWindowNumber"] as? UInt32
                }
            }
                
            if let bundleIdentifier = newWindow?.owningApplication?.bundleIdentifier {
                let appName = getWindowAppName(windowInfo: windowInfo?.first { $0["kCGWindowNumber"] as? UInt32 == newWindow?.windowID })
                let icon = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first?.icon
                storeAppIcons(appName: appName, image: icon)
            }
            
            var display: SCDisplay? = nil
            if let bounds = firstWindow?["kCGWindowBounds"] as? NSDictionary,
               let x = bounds["X"] as? Double,
               let y = bounds["Y"] as? Double,
               let w = bounds["Width"] as? Double,
               let h = bounds["Height"] as? Double {
                
               display = availableContent.displays.first(where: { CGDisplayBounds($0.displayID).contains(CGRect(x: x, y: y, width: w, height: h))})
                
                if let display = display {
                    if self.displayID != display.displayID, activeVideoURL != nil {
                        restart()
                        return
                    }
                    self.displayID = display.displayID
                }
            }
            
            
            let newWindowID = newWindow?.windowID
            if windowID != newWindowID, let display = display, let frontApp = frontApp {
                prevWindowID = windowID
                windowID = newWindowID
                windowBundleID = frontApp.bundleIdentifier
                
                var windowsToCapture = [SCWindow]()
                if windowID != nil, 
                   let windowToCapture = newWindow,
                   let bundleId  = frontApp.bundleIdentifier,
                   !bannedAppForCaptureEngineSet.contains(bundleId) {
                    if !bannedPrivateBrowsing ||
                       !BrowserState.shared.isPrivateBrowsing(frontApp) {
                        windowsToCapture.append(windowToCapture)
                    }
                }
                
                contentFilter = SCContentFilter(display: display, including: windowsToCapture)
                updateEngine()
            }
            
        } catch {
            log.error("Failed to get the shareable content: \(error.localizedDescription)")
        }
    }
    
    private func filterWindows(_ windows: [SCWindow]) -> [SCWindow] {
        windows
        // Sort the windows by app name.
            .sorted { $0.owningApplication?.applicationName ?? "" < $1.owningApplication?.applicationName ?? "" }
            .filter {
                // Remove windows that don't have an associated .app bundle.
                $0.owningApplication != nil && $0.owningApplication?.applicationName != ""  &&
                // Remove this app's window from the list.
                $0.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier &&
                // Remove small windows
                $0.frame.height > 100 && $0.frame.width > 200
            }
    }
    
    @objc func onAppChanges(note: NSNotification) {
        log.debug("onAppChanges \(enableRecording)")
        if !enableRecording {
            return
        }
        
        Task {
            await self.refreshAvailableContent()
        }
    }
    
    private func listenToActiveAppChanges() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onAppChanges(note:)),
            name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }
    
    private func selfRepair() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [self] _ in
            Task {
                let recording = captureEngine?.ended == false && captureEngine?.errored == false
                let watchingCopyRightContent = AppleScript.shared.browsersContainCopyrightContent()
                
                if enableRecording, !recording, !watchingCopyRightContent {
                    restart()
                }
                
                if recording, (!enableRecording || watchingCopyRightContent) {
                    await stop()
                    if watchingCopyRightContent {
                        sendNotification(title: "Stopped recording", subtitle: "Copyright content detected on browser. Recording will resume when copy right content is no longer detected.")
                    }
                }
            }
        }
    }
    
    
    @objc private func onWake(note: NSNotification) {
        Task.detached(priority: .background) {
            log.debug("start recording")
            await self.start()
        }
    }
    
    @objc private func onSleep(note: NSNotification) {
        Task {
            log.debug("stop recording")
            await stop()
        }
    }
    
    private func selfStartStop() {
        // wake events
        NSWorkspace.shared.notificationCenter.addObserver(
                self, selector: #selector(onWake(note:)),
                name: NSWorkspace.didWakeNotification, object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onWake(note:)),
            name: NSWorkspace.screensDidWakeNotification, object: nil)

        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main) { _ in
                Task {
                    await self.start()
                }
        }


        // sleep events
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onSleep(note:)),
            name: NSWorkspace.willSleepNotification, object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onSleep(note:)),
            name: NSWorkspace.screensDidSleepNotification, object: nil)

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onSleep(note:)),
            name: NSWorkspace.willPowerOffNotification, object: nil)
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(rawValue: "com.apple.screenIsLocked"),
            object: nil,
            queue: .main) { _ in
                Task {
                    await self.stop()
                }
        }
        
    }
}

func getFileSize(at url: URL) -> UInt64? {
    do {
        // Get file attributes
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        
        // Extract file size from attributes
        if let fileSize = fileAttributes[.size] as? UInt64 {
            return fileSize
        } else {
            // The file size attribute could not be retrieved
            return nil
        }
    } catch {
        // Error occurred while accessing file attributes
        log.error("Error: \(error)")
        return nil
    }
}

extension SCWindow {
    var displayName: String {
        switch (owningApplication, title) {
        case (.some(let application), .some(let title)):
            return "\(application.applicationName): \(title)"
        case (.none, .some(let title)):
            return title
        case (.some(let application), .none):
            return "\(application.applicationName): \(windowID)"
        default:
            return ""
        }
    }
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound,
                                             range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }

    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
         return String(self[start...])
    }
}
