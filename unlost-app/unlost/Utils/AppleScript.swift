//
//  AppleScript.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 06/08/2023.
//

import Foundation
import AppKit

class AppleScript {
    static let shared = AppleScript()

    private var browsersUsed = Set<Browser>()
    
    private let activeChromeUrl = NSAppleScript(source: """
        tell application "Google Chrome"
            set the_id to ""
            set the_url to ""
            set the_tab to active tab of front window
            set the_id to id of the_tab
            set the_url to URL of the_tab
            return the_id & " " & the_url
        end tell
        """
    )!
    
    private let activeBraveUrl = NSAppleScript(source: """
        tell application "Brave Browser"
            set the_id to ""
            set the_url to ""
            set the_tab to active tab of front window
            set the_id to id of the_tab
            set the_url to URL of the_tab
            return the_id & " " & the_url
        end tell
        """
    )!
    
    private let activeSafariUrl = NSAppleScript(source: """
        tell application "Safari"
            set the_id to "unknown"
            set the_url to URL of front document
            return the_id & " " & the_url
        end tell
        """
    )!

    private let activeArcUrl = NSAppleScript(source: """
        tell application "Arc"
            set currentID to id of active tab of front window
            set currentURL to URL of active tab of front window
            return currentID & " " & currentURL
        end tell
    """
    )!

    private let chromeUrls = NSAppleScript(source: """
        tell application "Google Chrome"
            set ids to ""
            set urls to ""
            set result to ""
            set window_list to every window
            repeat with the_window in window_list
                    set tab_list to every tab in the_window
                    repeat with the_tab in tab_list
                            set temp_id to id of the_tab
                            set temp_url to URL of the_tab
                            set ids to ids & temp_id & " "
                            set urls to urls & temp_url & " "
                    end repeat
            end repeat
            return ids & linefeed & urls
        end tell
        """
    )!
    
    private let braveUrls = NSAppleScript(source: """
        tell application "Brave Browser"
            set ids to ""
            set urls to ""
            set result to ""
            set window_list to every window
            repeat with the_window in window_list
                    set tab_list to every tab in the_window
                    repeat with the_tab in tab_list
                            set temp_id to id of the_tab
                            set temp_url to URL of the_tab
                            set ids to ids & temp_id & " "
                            set urls to urls & temp_url & " "
                    end repeat
            end repeat
            return ids & linefeed & urls
        end tell
        """
    )!
    
    private let safariUrls = NSAppleScript(source: """
        tell application "Safari"
            set ids to ""
            set urls to ""
            set result to ""
            set window_list to every window
            repeat with the_window in window_list
                    set tab_list to every tab in the_window
                    repeat with the_tab in tab_list
                            set temp_id to "unknown"
                            set temp_url to URL of the_tab
                            set ids to ids & temp_id & " "
                            set urls to urls & temp_url & " "
                    end repeat
            end repeat
            return ids & linefeed & urls
        end tell
        """
    )!
    
    private let arcUrls = NSAppleScript(source: """
        tell application "Arc"
            set ids to ""
            set urls to ""
            set result to ""
            set window_list to every window
            repeat with the_tab in tabs of first window
                set temp_id to id of the_tab
                set temp_url to URL of the_tab
                set ids to ids & temp_id & " "
                set urls to urls & temp_url & " "
            end repeat
            return ids & linefeed & urls
        end tell
        """
    )!
    
    let arcCheckIncognito = NSAppleScript(source: """
        tell application "Arc"
            return incognito of front window
        end tell
    """)!
    
    private let chromeCheckContainsCopyrightContent = NSAppleScript(source: """
        tell application "Google Chrome"
            repeat with the_window in every window
                repeat with the_tab in every tab in the_window
                    set the_url to the URL of the_tab # grab the URL
                    if the_url contains "www.netflix.com/watch" or the_url contains "www.disneyplus.com" then
                        return true
                    end if
                end repeat
            end repeat
            return false
        end tell
    """)!
    
    private let braveCheckContainsCopyrightContent = NSAppleScript(source: """
        tell application "Brave Browser"
            repeat with the_window in every window
                repeat with the_tab in every tab in the_window
                    set the_url to the URL of the_tab # grab the URL
                    if the_url contains "www.netflix.com/watch" or the_url contains "www.disneyplus.com" then
                        return true
                    end if
                end repeat
            end repeat
            return false
        end tell
    """)!
    
    private let safariCheckContainsCopyrightContent = NSAppleScript(source: """
        tell application "Safari"
            repeat with the_window in every window
                repeat with the_tab in every tab in the_window
                    set the_url to the URL of the_tab # grab the URL
                    if the_url contains "www.netflix.com/watch" or the_url contains "www.disneyplus.com" then
                        return true
                    end if
                end repeat
            end repeat
            return false
        end tell
    """)!
    
    private let arcCheckContainsCopyrightContent = NSAppleScript(source: """
        tell application "Arc"
            repeat with the_window in every window
                repeat with the_tab in every tab in the_window
                    set the_url to the URL of the_tab # grab the URL
                    if the_url contains "www.netflix.com/watch" or the_url contains "www.disneyplus.com" then
                        return true
                    end if
                end repeat
            end repeat
            return false
        end tell
    """)!
    
    private let chromeGetBody = NSAppleScript(source: """
        tell application "Google Chrome"
            execute front window's active tab javascript "document.body.outerHTML"
        end tell
""")
    
    private init() {
        Task.detached(priority: .high) { [self] in
            let searcher = ApplicationSearcher()
            for app in searcher.getAllApplications() {
                if app.bundleId == "com.apple.Safari" {
                    self.activeSafariUrl.compileAndReturnError(nil)
                    self.safariUrls.compileAndReturnError(nil)
                    self.safariCheckContainsCopyrightContent.compileAndReturnError(nil)
                    log.info("compiled safari applescripts")
                } else if app.bundleId == "com.google.Chrome" {
                    self.activeChromeUrl.compileAndReturnError(nil)
                    self.chromeUrls.compileAndReturnError(nil)
                    self.chromeCheckContainsCopyrightContent.compileAndReturnError(nil)
                    self.chromeGetBody?.compileAndReturnError(nil)
                    log.info("compiled chrome applescripts")
                } else if app.bundleId == "company.thebrowser.Browser" {
                    self.activeArcUrl.compileAndReturnError(nil)
                    self.arcUrls.compileAndReturnError(nil)
                    self.arcCheckContainsCopyrightContent.compileAndReturnError(nil)
                    self.arcCheckIncognito.compileAndReturnError(nil)
                    log.info("compiled arc applescripts")
                } else if app.bundleId == "com.brave.Browser" {
                    self.activeBraveUrl.compileAndReturnError(nil)
                    self.braveUrls.compileAndReturnError(nil)
                    self.braveCheckContainsCopyrightContent.compileAndReturnError(nil)
                }
                
            }
        }
    }
    
    private func checkIsChrome(_ browser: Browser) -> Bool {
        browsersUsed.insert(browser)
        return browser == .chrome
    }
    
    private func checkIsSafari(_ browser: Browser) -> Bool {
        browsersUsed.insert(browser)
        return browser == .safari
    }
    
    private func checkIsArc(_ browser: Browser) -> Bool {
        browsersUsed.insert(browser)
        return browser == .arc
    }
    
    private func checkIsBrave(_ browser: Browser) -> Bool {
        browsersUsed.insert(browser)
        return browser == .brave
    }

    func getBrowserIdAndUrl(browser: Browser) -> (String, String)? {
        var error: NSDictionary? = nil
        var script: NSAppleScript? = nil
        if checkIsChrome(browser) {
            script = activeChromeUrl
        } else if checkIsSafari(browser) {
            script = activeSafariUrl
        } else if checkIsArc(browser) {
            script = activeArcUrl
        } else if checkIsBrave(browser) {
            script = activeBraveUrl
        }
        guard let script = script else { return nil }
        
        if let splitted = script.executeAndReturnError(&error).stringValue?.split(separator: " "),
           splitted.count == 2 {
            return (String(splitted[0]), String(splitted[1]))
        } else {
            log.error("failed to get active url \(error)")
        }
        return nil
    }
    
    func getBrowser(context: String) -> Browser? {
        var browser: Browser? = nil
        if context == "com.apple.Safari" {
            browser = .safari
        } else if context == "com.google.Chrome" {
            browser = .chrome
        } else if context == "company.thebrowser.Browser" {
            browser = .arc
        } else if context == "com.brave.Browser" {
            browser = .brave
        }
        return browser
    }
    
    func getBrowserIdAndUrl(context: String) -> (String, String)? {
        if let browser = getBrowser(context: context) {
            return getBrowserIdAndUrl(browser: browser)
        }
        
        return nil
    }
    
    func isBrowser(context: String) -> Bool {
        return context == "com.apple.Safari" || context == "com.google.Chrome" || context == "company.thebrowser.Browser" || context == "com.brave.Browser"
    }
    
    func getBrowserIdAndUrlList(browser: Browser) -> ([String.SubSequence], [String.SubSequence])? {
        var error: NSDictionary? = nil
        var script: NSAppleScript? = nil
        if checkIsChrome(browser) {
            script = chromeUrls
        } else if checkIsSafari(browser) {
            script = safariUrls
        } else if checkIsArc(browser) {
            script = arcUrls
        } else if checkIsBrave(browser) {
            script = braveUrls
        }
        guard let script = script else { return nil }
        if let splitted = script.executeAndReturnError(&error).stringValue?.split(separator: "\n") {
            return (splitted[0].split(separator: " "), splitted[1].split(separator: " "))
        } else {
            log.error("failed to get urls \(error)")
        }
        return nil
    }
    
    func browsersContainCopyrightContent() -> Bool {
        for browser in browsersUsed {
            if browserContainsCopyrightContent(browser) {
                return true
            }
        }
        
        return false
    }
    
    private func browserContainsCopyrightContent(_ browser: Browser) -> Bool {
        var error: NSDictionary? = nil
        var script: NSAppleScript? = nil
        if  checkIsChrome(browser) {
            script = chromeCheckContainsCopyrightContent
        } else if checkIsSafari(browser) {
            script = safariCheckContainsCopyrightContent
        } else if checkIsArc(browser) {
            script = arcCheckContainsCopyrightContent
        } else if checkIsBrave(browser) {
            script = braveCheckContainsCopyrightContent
        }
        
        guard let script = script else { return false }
        
        return script.executeAndReturnError(&error).booleanValue
    }
}
