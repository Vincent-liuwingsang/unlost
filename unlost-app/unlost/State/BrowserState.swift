//
//  BrowserState.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 20/09/2023.
//

import Foundation
import SwiftUI
import AXSwift

class BrowserState: ObservableObject {
    static var shared = BrowserState()
    
    private var chrome: Application?
    private var chromeObserver: Observer?
    
    private var brave: Application?
    private var braveObserver: Observer?
    
    private var safari: Application?
    private var safariObserver: Observer?
    
    private var arc: Application?
    private var arcObserver: Observer?
    
    @Published var chromeIncognito = false
    @Published var safariIncognito = false
    @Published var arcIncognito = false
    @Published var braveIncognito = false
    
    private init() {
        if checkIsProcessTrusted(prompt: true) {
            chrome = Application.allForBundleID("com.google.Chrome").first
            if let chrome = chrome {
                chromeObserver = createObserver(chrome) { title in
                    self.chromeIncognito = title.hasSuffix("(Incognito)")
                    Task {
                        await ScreenRecorder.shared.refreshAvailableContent()
                    }
                }
                do {
                    try chromeObserver?.addNotification(.focusedWindowChanged, forElement: chrome)
                    try chromeObserver?.addNotification(.applicationActivated, forElement: chrome)
                } catch {
                    log.error("failed to observe chrome: \(error.localizedDescription)")
                }
            }
            
            brave = Application.allForBundleID("com.brave.Browser").first
            if let brave = brave {
                braveObserver = createObserver(brave) { title in
                    self.braveIncognito = title.hasSuffix("(Private)")
                    Task {
                        await ScreenRecorder.shared.refreshAvailableContent()
                    }
                }
                do {
                    try braveObserver?.addNotification(.focusedWindowChanged, forElement: brave)
                    try braveObserver?.addNotification(.applicationActivated, forElement: brave)
                } catch {
                    log.error("failed to observe brave: \(error.localizedDescription)")
                }
            }
            
            safari = Application.allForBundleID("com.apple.Safari").first
            if let safari = safari {
                safariObserver = createObserver(safari) { title in
                    self.safariIncognito = title.hasSuffix("Private Browsing")
                    Task {
                        await ScreenRecorder.shared.refreshAvailableContent()
                    }
                }
                do {
                    try safariObserver?.addNotification(.focusedWindowChanged, forElement: safari)
                    try safariObserver?.addNotification(.applicationActivated, forElement: safari)
                } catch {
                    log.error("failed to observe safari: \(error.localizedDescription)")
                }
            }
            
            arc = Application.allForBundleID("company.thebrowser.Browser").first
            if let arc = arc {
                arcObserver = createObserver(arc) { _ in
                    self.arcIncognito =  AppleScript.shared.arcCheckIncognito.executeAndReturnError(nil).booleanValue
                    Task {
                        await ScreenRecorder.shared.refreshAvailableContent()
                    }
                }
                do {
                    try arcObserver?.addNotification(.focusedWindowChanged, forElement: arc)
                    try arcObserver?.addNotification(.applicationActivated, forElement: arc)
                } catch {
                    log.error("failed to observe safari: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func createObserver(_ app: Application, onTitleChange: @escaping (String) -> Void) -> Observer? {
        return app.createObserver { (observer: Observer, element: UIElement, event: AXNotification, info: [String: AnyObject]?) in

            if event == .focusedWindowChanged {
                do {
                    if let title = try element.attribute(.title) as String? {
                        onTitleChange(title)
                    }
                } catch {
                    log.error("BrowserObserver failed to get title on window changed \(error.localizedDescription)")
                }
            }
            
            if event == .applicationActivated {
                do {
                    let windows = try app.windows() ?? []
                    for window in windows {
                        if let main = try window.attribute(.main) as Bool?,
                           main == true,
                           let title = try window.attribute(.title) as String? {
                            onTitleChange(title)
                            break
                        }
                        
                    }
                } catch {
                    log.error("BrowserObserver failed to get title on application activated \(error.localizedDescription)")
                }
            }

        }
    }
    
    func isPrivateBrowsing(_ runningApp: NSRunningApplication) -> Bool {
        guard let bundleID = runningApp.bundleIdentifier, let browser = AppleScript.shared.getBrowser(context: bundleID) else { return false }
        
        if browser == .chrome {
            return BrowserState.shared.chromeIncognito
        } else if browser == .safari {
            return BrowserState.shared.safariIncognito
        } else if browser == .arc {
            return BrowserState.shared.arcIncognito
        } else if browser == .brave {
            return BrowserState.shared.braveIncognito
        }
        
        return false
    }
}
