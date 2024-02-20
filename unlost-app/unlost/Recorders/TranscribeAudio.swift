//
//  TranscribeAudio.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 28/07/2023.
//

import AudioKit
import SwiftWhisper
import Foundation
import AVFAudio


class TranscribeAudio {
    private let whisper: Whisper
    
    init() {
        let url = Bundle.main.url(forResource: "ggml-base", withExtension: "bin", subdirectory: "models")!
        let param = WhisperParams.init(strategy: .beamSearch)
        param.suppress_non_speech_tokens = true
        param.suppress_blank = true
        param.print_realtime = true

        whisper = Whisper(fromFileURL: url, withParams: param)
    }
    
    func transcribe(fileURL: URL, completion: ([Segment]) -> Void) async {
        let frames = processMP4AudioFile(url: fileURL)
        
        do {
            let segments = try await whisper.transcribe(audioFrames: frames)
            
            var cleanSegments = [Segment]()
            var lastText = ""
            for segment in segments {
                if lastText == segment.text {
                    continue
                }
                lastText = segment.text
//
//                if hasRepeatingSubstring(segment.text, length: 5) {
//                    continue
//                }
                
                cleanSegments.append(segment)
            }
            completion(cleanSegments)
        } catch {
           log.error("failed to transcribe \(error.localizedDescription)")
        }
    }
}

func hasRepeatingSubstring(_ s: String, length: Int) -> Bool {
    if s.count <= length {
        return false
    }
    
    for i in 0...(s.count - length) {
        let start = s.index(s.startIndex, offsetBy: i)
        let end = s.index(start, offsetBy: length)
        let sub = s[start..<end]
        
        if s.components(separatedBy: sub).count > 7 {
            return true
        }
    }
    return false
}

func processMP4AudioFile(url: URL) -> [Float] {
    guard let audioFile = loadAudioFile(url: url) else {
        return []
    }

    let floatArray = audioFileToFloatArray(audioFile: audioFile)
    return floatArray
}


func loadAudioFile(url: URL) -> AVAudioFile? {
    do {
        log.debug("url \(url)")
        let audioFile = try AVAudioFile(forReading: url)
        return audioFile
    } catch {
        log.error("Error loading audio file: \(error.localizedDescription)")
        return nil
    }
}

func audioFileToFloatArray(audioFile: AVAudioFile) -> [Float] {
    let audioFormat = audioFile.processingFormat
    let audioFrameCount = UInt32(audioFile.length)
    let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)!
    
    do {
        try audioFile.read(into: audioBuffer)
    } catch {
        log.error("Error reading audio file: \(error.localizedDescription)")
        return []
    }

    guard let floatData = audioBuffer.floatChannelData else {
        log.error("Error converting to float data.")
        return []
    }

    let channelCount = Int(audioFormat.channelCount)
    let frames = Int(audioBuffer.frameLength)
    var floatArray = [Float]()

    for frame in 0 ..< frames {
        for channel in 0 ..< channelCount {
            let floatSample = floatData[channel][frame]
            floatArray.append(floatSample)
        }
    }

    return floatArray
}
