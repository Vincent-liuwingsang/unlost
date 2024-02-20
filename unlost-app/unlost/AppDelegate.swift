//
//  AppDelegate.swift
//  Wednesday
//
//  Created by Wing Sang Vincent Liu on 22/05/2023.
//

import AppKit
import SwiftUI
import SwiftyBeaver
import LaunchAtLogin
import ScreenCaptureKit

let log = SwiftyBeaver.self

class AppDelegate: NSObject, NSApplicationDelegate  {
    private var statusBarItem: NSStatusItem!
    private var statusBarMenu: NSMenu!
    private var floatingPanel: FloatingPanel!
    private var hostingView: NSHostingView<AnyView>!
    private var contentView: any View
    
    
    override init() {
        if !LaunchAtLogin.isEnabled {
            LaunchAtLogin.isEnabled = true
        }
        
        self.contentView = ContentView()
    }
    
    init(contentView: some View) {
        self.contentView = contentView
    }
    
    private func initServices() {
        let _ = BrowserState.shared
        let _ = PythonServer.shared
        let _ = ScreenRecorder.shared
        let _ = MeetingRecorder.shared
        let _ = AppleScript.shared
        let _ = StartStopQueue.shared
        let _ = Shortcut.shared
        let _ = AppState.shared
        let _ = LogState.shared
    }
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        hostingView = NSHostingView(rootView: AnyView(contentView.ignoresSafeArea()))
        
        floatingPanel = FloatingPanel()
        floatingPanel.contentView = hostingView
        
        let onboarded = UserDefaults.standard.bool(forKey: "onboarded")
        // unfocus event
        NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: nil, queue: OperationQueue.main) { _ in
            if onboarded {
                NSApp?.closeActivity()
            }
        }
        
        if onboarded {
            initServices()
            Task {
                await ScreenRecorder.shared.start()
            }
        }

        setupMenu()
        
        NSApp.openActivity()
//        NSApp.openSettings()
    }

    func setupLogo() {
        if let button = statusBarItem.button {
            let url = "\(Bundle.main.bundlePath)/Contents/Resources/logo_bw.png"
            let image = NSImage(contentsOfFile: url)!
            image.size.width = 16.0
            image.size.height = 16.0
            button.image = image
        }
    }
    
    private func setupMenu() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        setupLogo()
        statusBarItem.button?.action = #selector(self.statusBarButtonClicked(sender:))
        statusBarItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Search...", action: #selector(didTapSearch) , keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(getScreenCaptureMenuItem())
        menu.addItem(getMeetingCaptureMenuItem())
        
        menu.addItem(NSMenuItem.separator())
 
        menu.addItem(NSMenuItem(title: "Getting Started...", action: #selector(didTapGettingStarted) , keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Help Center...", action: #selector(didTapHelpCenter) , keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Send Feedback...", action: #selector(didTapSendFeedback) , keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(didTapSettings) , keyEquivalent: "settings"))
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusBarMenu = menu
    }
    
    var screenCaptureToggle: NSSwitch? = nil
    private func getScreenCaptureMenuItem() -> NSMenuItem {
        let toggleScreenRecording = NSMenuItem()
        let frame = CGRect(origin: .zero, size: CGSize(width: 200, height: 24))
        let viewHint = NSView(frame: frame)
        
        let label = NSTextField(labelWithString: "Screen Capture")
        label.frame = CGRect(x: 12, y: -4, width: 120, height: 24) // Adjust position and width
        label.alignment = .left
        label.isEditable = false
        label.isSelectable = false
        label.isBordered = false
        viewHint.addSubview(label)

        
        let switchButton = NSSwitch(frame: CGRect(x: 150, y: 0, width: 36, height: 24)) // Adjust position and width
        switchButton.target = self
        switchButton.action = #selector(screenRecordingToggled(_:))
        let enableRecording = UserDefaults.standard.bool(forKey: "enableRecording")
        switchButton.state = enableRecording ? .on : .off
        viewHint.addSubview(switchButton)
        
        screenCaptureToggle = switchButton

        toggleScreenRecording.view = viewHint
        return toggleScreenRecording
    }
    
    var meetingCaptureToggle: NSSwitch? = nil
    private func getMeetingCaptureMenuItem() -> NSMenuItem {
        let toggleScreenRecording = NSMenuItem()
        let frame = CGRect(origin: .zero, size: CGSize(width: 200, height: 24))
        let viewHint = NSView(frame: frame)
        
        let label = NSTextField(labelWithString: "Meeting Capture")
        label.frame = CGRect(x: 12, y:-4, width: 120, height: 24) // Adjust position and width
        label.alignment = .left
        label.isEditable = false
        label.isSelectable = false
        label.isBordered = false
        viewHint.addSubview(label)

        
        let switchButton = NSSwitch(frame: CGRect(x: 150, y: 0, width: 36, height: 24)) // Adjust position and width
        switchButton.layer?.contentsScale = 0.75
        switchButton.target = self
        switchButton.action = #selector(meetingRecordingToggled(_:))
        let enableRecording = UserDefaults.standard.bool(forKey: "enableMeetingRecording")
        switchButton.state = enableRecording ? .on : .off
        viewHint.addSubview(switchButton)
        
        meetingCaptureToggle = switchButton
        
        toggleScreenRecording.view = viewHint
        return toggleScreenRecording
    }
    
    @objc func screenRecordingToggled(_ sender: NSSwitch) {
        // This method will be called when the switch button state changes
        if sender.state == .on {
            UserDefaults.standard.set(true, forKey: "enableRecording")
        } else {
            UserDefaults.standard.set(false, forKey: "enableRecording")
        }
    }
    
    @objc func meetingRecordingToggled(_ sender: NSSwitch) {
        // This method will be called when the switch button state changes
        if sender.state == .on {
            UserDefaults.standard.set(true, forKey: "enableMeetingRecording")
        } else {
            UserDefaults.standard.set(false, forKey: "enableMeetingRecording")
        }
    }
    
    @objc private func didTapSearch() {
        NSApp.openActivity()
    }
    
    @objc private func didTapSendFeedback() {
        NSApp.openSettings(.feedback)

    }
    
    @objc private func didTapGettingStarted() {
        UserDefaults.standard.set(false, forKey: "onboarded")
        UserDefaults.standard.set("start", forKey: "onboardingStep")
        NSApp.getWindow()?.reload()
        Task.detached {
            try await Task.sleep(nanoseconds: 100_000_000)
            await NSApp.openActivity()
        }
    }
    
    @objc private func didTapHelpCenter() {
        let url = "https://liuwingsangvincent.notion.site/Unlost-Guide-4a4051f24cc24b6ab27a934c1c7294de"
        NSWorkspace.shared.open(URL(string: url)!)
    }

    
    @objc private func didTapSettings() {
        NSApp.openSettings()
    }

    @objc private func statusBarButtonClicked(sender: NSStatusBarButton) {
        let enableRecording = UserDefaults.standard.bool(forKey: "enableRecording")
        screenCaptureToggle?.state = enableRecording ? .on : .off
        let enableMeetingRecording = UserDefaults.standard.bool(forKey: "enableMeetingRecording")
        meetingCaptureToggle?.state = enableMeetingRecording ? .on : .off
        statusBarItem.popUpMenu(statusBarMenu)
//        let event = NSApp.currentEvent!
//        if event.type ==  NSEvent.EventType.rightMouseUp {
//            let enableRecording = UserDefaults.standard.bool(forKey: "enableRecording")
//            screenCaptureToggle?.state = enableRecording ? .on : .off
//            let enableMeetingRecording = UserDefaults.standard.bool(forKey: "enableMeetingRecording")
//            meetingCaptureToggle?.state = enableMeetingRecording ? .on : .off
//            statusBarItem.popUpMenu(statusBarMenu)
//        } else {
//            NSApp.openActivity()
//        }
    }
}
