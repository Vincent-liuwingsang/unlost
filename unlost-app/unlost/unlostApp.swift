//
//  unlostApp.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 16/06/2023.
//

import SwiftUI

@main
struct unlostApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("enableRecording") var enableRecording: Bool = true
    @AppStorage("appHeightRatio") var appHeightRatio: Double = 0.8
    @AppStorage("appWidthRatio") var appWidthRatio: Double = 0.8
    
    init() {
    }
    
    var body: some Scene {

        Settings{
            SettingsView()
        }
        .onChange(of: enableRecording) { enable in
            if enable {
                Task {
                    await ScreenRecorder.shared.start()
                }
            } else {
                Task {
                    await ScreenRecorder.shared.stop()
                    await MeetingRecorder.shared.stop()
                }
            }
        }
        .onChange(of: appWidthRatio) { _ in
            NSApp.getWindow()?.reload()
        }
        .onChange(of: appHeightRatio) { _ in
            NSApp.getWindow()?.reload()
        }
    }
}

