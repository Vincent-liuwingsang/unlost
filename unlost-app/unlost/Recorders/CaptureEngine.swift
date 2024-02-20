//
//  ScreenRecorderTest.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 30/07/2023.
//

import Foundation
import Vision
import AVFoundation
import ScreenCaptureKit
import AsyncAlgorithms
import IOKit.ps

extension String: Error {}
extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

var bannedAppForCaptureEngineSet: Set<String> = Set((UserDefaults.standard.string(forKey: "bannedApps") ?? defaultBannedApps).split(separator: "\n").map {String($0)})

var bannedUrlsForCaptureEngineSet: Set<String> = Set((UserDefaults.standard.string(forKey: "bannedUrls") ?? defaultBannedUrls).split(separator: "\n").map {String($0)})

var differ = DiffMatchPatch()
var prevString = ""
//let capturePadding = 40
//let capturePaddingThreshold = 200

struct TimestampedResult : Equatable {
    let windowID: CGWindowID
    let appName: String
    let appTitle: String
    let time: Double
    let minX: Int64
    let minY: Int64
    let width: Int64
    let height: Int64
    let ocrResult: String
    let created_at: Date
    let url: String?
}

func today() -> String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    let currentDate = Date()
    let formattedDate = dateFormatter.string(from: currentDate)
    return formattedDate
}

func now() ->  String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Customize the format as needed
    let currentDate = Date()
    let dateString = dateFormatter.string(from: currentDate)
    return dateString
}


class CaptureEngine : NSObject, SCStreamDelegate {
    private var videoBufferQueue: DispatchQueue? = nil
    private var audioBufferQueue: DispatchQueue? = nil

    private var videoWriter: AVAssetWriter? = nil
    private var audioWriter: AVAssetWriter? = nil
    private var videoInput: AVAssetWriterInput? = nil
    private var audioInput: AVAssetWriterInput? = nil
    private var output: StreamOutput? = nil

    private var stream: SCStream?
    private var micRecording: AudioRecording? = nil

    
    var videoURL: URL? = nil
    var audioURL: URL? = nil
    var micURL: URL? = nil
    var audio: Bool = false
    var mic: Bool = false
    
    var displayID: CGDirectDisplayID
    var windowID: CGWindowID
    var windowBundleID: String
    var filter: SCContentFilter
    
    
    let onError: () -> Void
    var errored: Bool = false
    var ended: Bool = false
    
    init(displayID: CGDirectDisplayID, windowID: CGWindowID, windowBundleID: String, filter: SCContentFilter, audio: Bool, mic: Bool, onError: @escaping () -> Void) throws {
        self.windowID = windowID
        self.windowBundleID = windowBundleID
        self.filter = filter
        self.audio = audio
        self.mic = mic
        self.displayID = displayID
        self.onError = onError
    }

    private func setup() throws {
        // create recordings directory
        let folder = getDocumentsDirectory().appendingPathComponent("recordings", conformingTo: .folder)
            .appendingPathComponent(today(), conformingTo: .folder)
        if !FileManager.default.fileExists(atPath: folder.absoluteString) {
            try! FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        }
        
        let videoSettings = try getVideoOutputSettings(displayID: displayID)
        
        let id = UUID()
        // init queues and writers
        videoBufferQueue = DispatchQueue(label: "com.unlost.captureEngine.MeetingRecorderVideo.\(id)")
        videoURL = folder.appendingPathComponent("\(id).mp4")
        if let videoURL = videoURL {
            
            let exception = tryBlock {
                // can throw from objectc binding
                self.videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings.outputSettings)
            } 
            
            if let exception = exception {
                throw "failed to init AVAssetWriter Video Input \(exception.description)"
            }
        
            videoWriter = try AVAssetWriter(url: videoURL, fileType: .mp4)
            if let videoWriter =  videoWriter, let videoInput = videoInput {
                videoInput.expectsMediaDataInRealTime = true
                guard videoWriter.canAdd(videoInput) else {
                    throw RecordingError("Can't add video input to asset writer")
                }
                videoWriter.add(videoInput)
                guard videoWriter.startWriting() else {
                    if let error = videoWriter.error {
                        throw error
                    }
                    throw RecordingError("Couldn't start writing to videoWriter")
                }
            }
        }
        
        
        if audio {
            audioBufferQueue = DispatchQueue(label: "com.unlost.captureEngine.MeetingRecorderAudio.\(id)")
            audioURL = folder.appendingPathComponent("\(id)_audio.wav")
            audioWriter = try AVAssetWriter(url: audioURL!, fileType: .wav)
            
            // create audio input and start writer
            let audioSettings: [String : Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 16000.0,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsNonInterleaved: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ]
            let exception = tryBlock {
                // can throw from objectc binding
                self.audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            }
            
            if let exception = exception {
                throw "failed to init AVAssetWriter Audio Input \(exception.description)"
            }
            
            audioInput!.expectsMediaDataInRealTime = true
            guard audioWriter!.canAdd(audioInput!) else {
                throw RecordingError("Can't add audio input to audioWriter")
            }
            audioWriter!.add(audioInput!)
            guard audioWriter!.startWriting() else {
                if let error = audioWriter!.error {
                    throw error
                }
                throw RecordingError("Couldn't start writing to audioWriter")
            }
        }
        
        if mic {
            micURL = folder.appendingPathComponent("\(id)_mic.wav")
            micRecording = try AudioRecording(url: micURL!)
        }
        
        let configuration = SCStreamConfiguration()
        configuration.width = Int(videoSettings.width) * videoSettings.scaleFactor
        configuration.height = Int(videoSettings.height) * videoSettings.scaleFactor
        configuration.showsCursor = false
        configuration.backgroundColor = .clear
        configuration.minimumFrameInterval = CMTime(value: 2, timescale: 1)
        configuration.capturesAudio = audio
        
        // Create SCStream and add local StreamOutput object to receive samples
        stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        if let videoWriter = videoWriter, let videoInput = videoInput {
            output = StreamOutput(videoWriter: videoWriter,videoInput: videoInput, audioWriter: audioWriter, audioInput: audioInput, windowID: windowID, windowBundleID: windowBundleID, scaleFactor: videoSettings.scaleFactor)
        }
        
        if let output = output {
            try stream?.addStreamOutput(output, type: .screen, sampleHandlerQueue: videoBufferQueue)
            
            if audio {
                try stream?.addStreamOutput(output, type: .audio, sampleHandlerQueue: audioBufferQueue)
            }
        }
    }
    
    
    func update(filter: SCContentFilter, windowID: CGWindowID, windowBundleID: String) {
        log.info("queued update")
        if errored {
            log.debug("skipping update as errored")
            return
        }
        if ended {
            log.debug("skipping update as ended")
            return
        }
        Task {
            await StartStopQueue.shared.channel.send {
                log.info("started")
                
                do {
                    try await self.stream?.updateContentFilter(filter)
                    self.output?.update(windowID: windowID, windowBundleID:windowBundleID)
                    self.windowID = windowID
                    self.windowBundleID = windowBundleID
                    self.filter = filter
                    log.debug("updated content filter")
                }
                catch {
                    log.error("failed to update content filter \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    func start() async throws {
        log.debug("start stream capture")
        try setup()
        
        if let stream = stream {
            try await stream.startCapture()

            output?.sessionStarted = true
            micRecording?.record()
        } else {
            log.debug("missing stream")
            throw "missing stream when starting capture"
        }
    }

    func stop(callback: @escaping ([TimestampedResult]) -> Void ) async {
        do {
            ended = true
            micRecording?.stop()
            try await stream?.stopCapture()
            
            videoInput?.markAsFinished()
            audioInput?.markAsFinished()
            await videoWriter?.finishWriting()
            await audioWriter?.finishWriting()
            callback(output?.results ?? [])
        } catch {
            videoInput?.markAsFinished()
            audioInput?.markAsFinished()
            await videoWriter?.finishWriting()
            await audioWriter?.finishWriting()
            callback(output?.results ?? [])
            log.debug("failed to stop stream \(error.localizedDescription)")
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        errored = true
        onError()
    }
    

    
    private class StreamOutput: NSObject, SCStreamOutput {
        let videoWriter: AVAssetWriter
        let videoInput: AVAssetWriterInput
        let audioWriter: AVAssetWriter?
        let audioInput: AVAssetWriterInput?
        var sessionStarted = false

        var firstVideoSampleTime: CMTime = .zero
        var firstAudioSampleTime: CMTime = .zero
        
        var screenshots = [Screenshot]()
        var results = [TimestampedResult]()
        var windowID: CGWindowID
        var windowBundleID: String
        var scaleFactor: Int
        
        var skip: Bool = false
        
        init(videoWriter: AVAssetWriter, videoInput: AVAssetWriterInput, audioWriter: AVAssetWriter?, audioInput:AVAssetWriterInput?, windowID: CGWindowID, windowBundleID: String, scaleFactor: Int) {
            self.videoWriter = videoWriter
            self.videoInput = videoInput
            self.audioWriter = audioWriter
            self.audioInput = audioInput
            self.windowID = windowID
            self.windowBundleID = windowBundleID
            self.scaleFactor = scaleFactor
        }

        func update(windowID: CGWindowID, windowBundleID: String) {
            self.skip = windowID != self.windowID
            self.windowID = windowID
            self.windowBundleID = windowBundleID
        }
        
        func ocr(sampleBuffer: CMSampleBuffer, rect: CGRect, windowHeight: Int64) throws -> String? {
            let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer)
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.regionOfInterest = rect
//            request.recognitionLanguages = ["en-US"]

            do {
              // Perform the text-detection request.
              try requestHandler.perform([request])
            } catch {
                log.warning("Unable to perform the request: \(error).")
            }
            
            
            if let results = request.results {
                var ocrResults = [OCRResult]()
                for result in results {
                    if let candidate = result.topCandidates(1).first, candidate.confidence > 0.45  {
                        let string = candidate.string
                        let stringRange = string.startIndex..<string.endIndex
                        let box = try? candidate.boundingBox(for: stringRange)
                        let boundingBox = box?.boundingBox ?? .zero
                        let scale = CGFloat(scaleFactor)
                        
                        
                        let y = (1 - boundingBox.minY) * scale
                        // ignore tag and urls
                        if y * Double(windowHeight) < 80 {
                            continue
                        }
                        ocrResults.append(OCRResult(value: string, location: [
                            boundingBox.minX,
                            1 - (1 - boundingBox.minY),
                            boundingBox.width,
                            boundingBox.height
                        ]))
                    }
                }
                
                if audioWriter == nil {
                    let dedupOptimisation = UserDefaults.standard.string(forKey: "dedupOptimisation") ?? "Smart"
                    if dedupOptimisation == "Always" ||
                        (dedupOptimisation == "Smart" && IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() != nil) {
                        
                        let newString = ocrResults.map { $0.value }.joined(separator: " ")
                        let diff = differ.diff_main(ofOldString: prevString, andNewString: newString)
                        let score = differ.diff_levenshtein(diff as? [Any])
                        let difference = Float(score) / Float(max(newString.count, prevString.count, 1))
                        if difference < 0.25 {
                            return nil
                        }
                        prevString = newString
                    }
                }
                
                if ocrResults.isEmpty {
                    return nil
                } else {

                    let encodedOCRResultData =  try JSONEncoder().encode(ocrResults)
                    return String(data: encodedOCRResultData, encoding: .utf8)
                }
            }
            
            return nil
        }
        
        func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
            
            // Return early if session hasn't started yet
            guard sessionStarted else { return }

            // Return early if the sample buffer is invalid
            guard sampleBuffer.isValid else { return }

            switch type {
            case .screen:
                if firstVideoSampleTime == .zero {
                    videoWriter.startSession(atSourceTime: sampleBuffer.presentationTimeStamp)
                    firstVideoSampleTime = sampleBuffer.presentationTimeStamp
                }
                
                if self.skip {
                    // skip first frame when changing apps
                    self.skip = false
                    return
                }
                log.info("queued update")
                let windowID = self.windowID
                let windowBundleID = self.windowBundleID
                Task {
                    await StartStopQueue.shared.channel.send {
                        log.info("started")
                        
                        if isValidFrame(for: sampleBuffer),
                           self.videoInput.isReadyForMoreMediaData == true {
                            // if valid frame and capurable
                            
                            // if bannedUrl or empty Url for browser then ignore
                            let url = AppleScript.shared.getBrowserIdAndUrl(context: windowBundleID)?.1
                            if let url = url {
                                var banned = false
                                for s in bannedUrlsForCaptureEngineSet {
                                    banned = banned || url.localizedCaseInsensitiveContains(s)
                                }
                                
                                banned = banned || url.contains("chrome://") || url.contains("favorites://")
                                print("banned", banned)
                                if banned {
                                    log.debug("ignore \(url)")
                                    return
                                }
                            } else if AppleScript.shared.isBrowser(context: windowBundleID) {
                                log.debug("ignoring screenshot as it's a browser but no url found")
                                return
                            }
                            
                            // if bannedApp then ignore
                            if bannedAppForCaptureEngineSet.contains(windowBundleID) {
                                log.debug("ignoring screenshot as it's banned from settings")
                                return
                            }
                            
                            if let info = getWindowInfo(windowId: windowID) {
                                var rect = NSRect()
                                let bounds = info["kCGWindowBounds"] as! CFDictionary
                                CGRectMakeWithDictionaryRepresentation(bounds, &rect)
                                let width = Int64(rect.width)
                                let height = Int64(rect.height)
                                let minX = Int64(rect.minX)
                                let minY = Int64(rect.minY)
                                // mac menubar has 25 height
                                let appName = getWindowAppName(windowInfo: info)
                                
                                if let screenSize = NSScreen.main?.frame.size {
                                    let newWidth = width
                                    let newHeight = height
                                    let newX = Double(minX)
                                    let newY = screenSize.height - Double(rect.maxY)
                                    
                                    let roiRect = CGRect(x: newX/screenSize.width, y: newY/screenSize.height, width: Double(newWidth)/screenSize.width, height: Double(newHeight)/screenSize.height)
                                    do {
                                        if let ocrResult = try self.ocr(sampleBuffer: sampleBuffer, rect: roiRect, windowHeight: newHeight) {
                                            self.videoInput.append(sampleBuffer)
                                            
                                            let appTitle = getWindowAppTitle(windowInfo: info)
                                            let adjustedTime = sampleBuffer.presentationTimeStamp - self.firstVideoSampleTime
                                            let time = adjustedTime.seconds * 1000
                                            
                                            self.results.append(TimestampedResult(windowID: windowID, appName: appName, appTitle: appTitle, time: time, minX: minX * Int64(self.scaleFactor), minY: minY * Int64(self.scaleFactor), width: width * Int64(self.scaleFactor), height: height * Int64(self.scaleFactor), ocrResult: ocrResult, created_at: Date.now, url: url))
                                            Task.detached(priority: .background) {
                                                UserDefaults.standard.set(now(), forKey: "lastScreenshotTime")
                                            }
                                        }
                                    } catch {
                                        log.warning("failed to ocr frame \(error.localizedDescription)")
                                    }
                                }
                            }
                        }
                        log.info("ended")
                    }
                }
                
            case .audio:
                if firstAudioSampleTime == .zero {
                    audioWriter?.startSession(atSourceTime: sampleBuffer.presentationTimeStamp)
                    firstAudioSampleTime = sampleBuffer.presentationTimeStamp
                }
                if audioInput?.isReadyForMoreMediaData == true {
                    audioInput?.append(sampleBuffer)
                } else {
                    log.warning("AVAssetWriterInput audio isn't ready, dropping frame")
                }
                break

            @unknown default:
                break
            }
        }
    }
}

private struct DirtyRect {
    var Height: Int
    var Width: Int
    var X: Int
    var Y: Int
}
private func isValidFrame(for sampleBuffer: CMSampleBuffer) -> Bool {

        // Retrieve the array of metadata attachments from the sample buffer.
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer,
                                                                             createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let attachments = attachmentsArray.first
        else {
            return false
        }

        // Validate the status of the frame. If it isn't `.complete`, return nil.
        guard let statusRawValue = attachments[SCStreamFrameInfo.status] as? Int,
              let status = SCFrameStatus(rawValue: statusRawValue),
              status == .complete
        else {
            return false
        }

        // Get the pixel buffer that contains the image data.
        guard let pixelBuffer = sampleBuffer.imageBuffer else {
            return false
        }

        // Get the backing IOSurface.
        guard let surfaceRef = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else {
            return false
        }


        if attachments[.contentScale] as? CGFloat == nil {
            return false
        }
        if attachments[.scaleFactor] as? CGFloat == nil {
            return false
        }

    
        if let contentRectDict = attachments[.contentRect],
           let rect = CGRect(dictionaryRepresentation: contentRectDict as! CFDictionary) {
            let screenshotArea = rect.width * rect.height
            
            if let dirtyRects = attachments[.dirtyRects] as? [CFDictionary] {
                var totalArea = 0
                for rect in dirtyRects {
                    if let width = (rect as NSDictionary)["Width"] as? Int, let height = (rect as NSDictionary)["Height"] as? Int {
                        totalArea += width * height
                    }
                }
                
                // less than 20% of area changed
                if CGFloat(totalArea) / screenshotArea < 0.2 {
                    return false
                }
            }
        } else {
            return false
        }
    
        return true
    }

private func getVideoOutputSettings(displayID: CGDirectDisplayID) throws -> (outputSettings: [String : Any], width: Int, height: Int, scaleFactor: Int){
    let displaySize = CGDisplayBounds(displayID).size

    // The number of physical pixels that represent a logic point on screen, currently 2 for MacBook Pro retina displays
    let displayScaleFactor: Int
    if let mode = CGDisplayCopyDisplayMode(displayID) {
        displayScaleFactor = mode.pixelWidth / mode.width
    } else {
        displayScaleFactor = 1
    }

    // AVAssetWriterInput supports maximum resolution of 4096x2304 for H.264
    // Downsize to fit a larger display back into in 4K
    let videoSize = downsizedVideoSize(source: displaySize, scaleFactor: displayScaleFactor)
    
    // This preset is the maximum H.264 preset, at the time of writing this code
    // Make this as large as possible, size will be reduced to screen size by computed videoSize
    guard let assistant = AVOutputSettingsAssistant(preset: .preset3840x2160) else {
        throw RecordingError("Can't create AVOutputSettingsAssistant with .preset3840x2160")
    }
    assistant.sourceVideoFormat = try CMVideoFormatDescription(videoCodecType: .h264, width: videoSize.width, height: videoSize.height)

    guard var outputSettings = assistant.videoSettings else {
        throw RecordingError("AVOutputSettingsAssistant has no videoSettings")
    }
    outputSettings[AVVideoWidthKey] = videoSize.width
    outputSettings[AVVideoHeightKey] = videoSize.height
//    outputSettings[AVVideoAverageBitRateKey] = 1_000_000
    
    return (outputSettings: outputSettings, width: videoSize.width, height: videoSize.height, scaleFactor: displayScaleFactor)
}


// AVAssetWriterInput supports maximum resolution of 4096x2304 for H.264
private func downsizedVideoSize(source: CGSize, scaleFactor: Int) -> (width: Int, height: Int) {
    let maxSize = CGSize(width: 4096, height: 2304)

    let w = source.width * Double(scaleFactor)
    let h = source.height * Double(scaleFactor)
    let r = max(w / maxSize.width, h / maxSize.height)

    return r > 1
        ? (width: Int(w / r), height: Int(h / r))
        : (width: Int(w), height: Int(h))
}


func printTimeElapsedWhenRunningCode(title:String, operation:()->()) {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed for \(title): \(timeElapsed) s.")
}

extension Set where Element == String {
    func containsCaseInsensitive(_ element: Element) -> Bool {
        return self.contains { $0.caseInsensitiveCompare(element) == .orderedSame }
    }
}
