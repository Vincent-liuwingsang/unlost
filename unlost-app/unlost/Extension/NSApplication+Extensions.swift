//
//  NSApplication+Extensions.swift
//  Wednesday
//
//  Created by Wing Sang Vincent Liu on 22/05/2023.
//

import AppKit
import AsyncAlgorithms

typealias CompletionHandler = () -> Void

enum Direction {
  case onscreen
  case offscreen
}

var open: Bool = false
var loaded = false
let settingManager = SettingsManager()

var contentFrameHack = NSRect()

extension NSApplication {
    func isClientOpen() -> Bool {
        return open
    }
    
    func getWindow() -> FloatingPanel? {
        return self.windows.first! as? FloatingPanel
    }

    func toggleActivity() {
        if open {
            closeActivity()
        } else {
            openActivity()
        }
    }

    
    func openActivity() {
        LayoutState.shared.refreshCompact()
        let panel = getWindow()
//        activate(ignoringOtherApps: true)
        panel?.makeKeyAndOrderFront(panel)
        refreshImageViewRect()
        
        
        panel?.reload(searchInputOnly: SearchState.shared.debouncedQuery.isEmpty)
        
        
        SearchState.shared.syncTags()
        open = true
        PythonServer.shared.ping(onResponse: nil)
        Shortcut.shared.closeHotKey.isPaused = false
    }

    func closeActivity() {
        getWindow()?.close()
        open = false
        PythonServer.shared.ping(onResponse: nil)
        Shortcut.shared.closeHotKey.isPaused = true
    }
    
    func openSettings(_ tab: SettingTabType? = nil) {
        if let tab = tab {
            SettingState.shared.selectedTab = tab
        }
        closeActivity()
        settingManager.showWindow()
    }
    
    func relaunch(afterDelay seconds: TimeInterval = 0.5) -> Never {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep \(seconds); open \"\(Bundle.main.bundlePath)\""]
        task.launch()
        
        NSApp.terminate(self)
        exit(0)
    }

    private func refreshImageViewRect() {
        let awr = UserDefaults.standard.double(forKey: "appWidthRatio")
        let ahr = UserDefaults.standard.double(forKey: "appHeightRatio")
        let swr = UserDefaults.standard.double(forKey: "sidebarWidthRatio")
        if let ss = NSScreen.main?.frame.size {
            let w = Int(ss.width * awr * (1 - swr)) - 12 - 8
            let h = Int(ss.height * ahr) - (LayoutState.shared.compact ? 44 : 62) - 1 - 16
//            let h = Int(ss.height * ahr) - (LayoutState.shared.compact ? 44 : 62) - 1

            if w > 0, h > 0 {
                contentFrameHack = NSRect(x: 0, y: 0, width: w, height: h)
            }
        }
    }
}

