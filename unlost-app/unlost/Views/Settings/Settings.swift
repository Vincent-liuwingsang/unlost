//
//  GeneralSettings.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 04/08/2023.
//

import SwiftUI
import Sparkle

struct SettingsView: View {
    @StateObject private var settingState = SettingState.shared

    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 16) {
                SettingTab(settingTab: .general, title: "General", icon: "gearshape")
                SettingTab(settingTab: .appearance, title: "Appearance", icon: "circle.lefthalf.fill")
                SettingTab(settingTab: .privacy, title: "Privacy", icon: "hand.raised.slash")
                SettingTab(settingTab: .storage, title: "Storage", icon: "opticaldiscdrive")
                SettingTab(settingTab: .feedback, title: "Feedback", icon: "exclamationmark.bubble")
                SettingTab(settingTab: .about, title: "About", icon: "info.circle")
            }
            .padding(.top, 10)
            .frame(maxWidth: .infinity)

            Divider()
           
            
            switch settingState.selectedTab {
            case .general:
                GeneralSettings()
            case .appearance:
                AppearanceSettings()
            case .privacy:
                PrivacySettings()
            case .storage:
                StorageSettings()
            case .about:
                AboutSettings()
            case .feedback:
                FeedbackSettings()
            }
            
            Spacer()
      
        }
        .frame(width: 800, height: 500)

    }
}

class SettingsManager: NSWindowController, NSWindowDelegate {
    convenience init() {
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentViewController: hostingController
        )
        
        self.init(window: window)
        window.delegate = self
        window.title = "Settings"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 450, height: 350))
    }
    
    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func windowWillClose(_ notification: Notification) {
        // Clean up if needed
    }
}
