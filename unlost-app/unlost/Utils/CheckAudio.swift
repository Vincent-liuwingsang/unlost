//
//  CheckAudio.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 07/09/2023.
//

import AVFoundation
import AudioToolbox
import AppKit

func getMicState(device: AVCaptureDevice) throws -> Bool {
    // Status variable
    var status: OSStatus = -1
    
    // Device ID
    var deviceID: AudioObjectID = 0
    
    // Running flag
    var isRunning: UInt32 = 0
    
    // Get device ID
    deviceID = getAVObjectID(device: device)

    // Query to get 'kAudioDevicePropertyDeviceIsRunningSomewhere' status
    var address = AudioObjectPropertyAddress(
        mSelector: AudioObjectPropertySelector(kAudioDevicePropertyDeviceIsRunningSomewhere),
        mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeOutput),
        mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain)
    )
    
    var propertySize: UInt32 = UInt32(MemoryLayout.size(ofValue: isRunning))
    
    status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &propertySize, &isRunning)
    
    if status != noErr {
        // Set error
        throw "getting status of audio device failed with \(status)"
    }
    
    return isRunning == 1
}

// Helper function to get AudioObjectID from AVCaptureDevice
func getAVObjectID(device: AVCaptureDevice) -> AudioObjectID {
    var deviceID: AudioObjectID = 0
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDevices,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )
    
    var propsize: UInt32 = 0
    var result: OSStatus = AudioObjectGetPropertyDataSize(
        AudioObjectID(kAudioObjectSystemObject),
        &address,
        0,
        nil,
        &propsize
    )

    
    if result == noErr {
        let deviceCount = Int(propsize) / MemoryLayout<AudioObjectID>.size
        var devices = [AudioObjectID](repeating: 0, count: deviceCount)
        
        result = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propsize,
            &devices
        )

        if result == noErr {
            for i in 0..<deviceCount {
                var name: CFString? = nil
                var size: UInt32 = UInt32(MemoryLayout<CFString?>.size)
                var deviceAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioObjectPropertyName,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )
                
                result = AudioObjectGetPropertyData(
                    devices[i],
                    &deviceAddress,
                    0,
                    nil,
                    &size,
                    &name
                )
                
                if result == noErr {
                    if let deviceName = name as String? {
                        if deviceName == device.localizedName {
                            deviceID = devices[i]
                            break
                        }
                    }
                }
            }
        }
    }
    
    return deviceID
}

func isMicActive() -> Bool {
    for microphone in AVCaptureDevice.devices(for: AVMediaType.audio) {
        if microphone.uniqueID == "MSLoopbackDriverDevice_UID" {
            continue
        }
        
        
        do {
//            let active = try getMicState(device: microphone)
//            print(microphone.uniqueID, active)
            if try getMicState(device: microphone) {
                return true
            }
        } catch {
            log.error("failed to check is mic active: \(error.localizedDescription)")
        }

    }
    
    log.warning("no mic detected")
    return false
}
