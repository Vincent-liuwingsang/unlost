//
//  FloatingPanel.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 16/06/2023.
//

import SwiftUI
import AppKit
import Combine

func getContentRect(overrideHeight: Double? = nil) -> CGRect {
    let screenSize = NSScreen.main!.frame.size
    
    if !UserDefaults.standard.bool(forKey: "onboarded") {
        let width = 800.0
        let height = 600.0
        let x = (screenSize.width - width) / 2
        let y = (screenSize.height - height) / 2
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    var rw = UserDefaults.standard.double(forKey: "appWidthRatio")
    if rw == 0.0 {
        rw = 0.8
    }

    var rh = UserDefaults.standard.double(forKey: "appHeightRatio")
    if rh == 0.0 {
        rh = 0.8
    }
    
    let width = screenSize.width * rw
    let height = screenSize.height * rh
    let x = (screenSize.width - width) / 2
    let y = (screenSize.height - height) / 2 + (overrideHeight != nil ? height - overrideHeight! : 0)
    let contentRect = CGRect(x: x, y: y, width: width, height: overrideHeight != nil ? overrideHeight! : height)
    return contentRect
}

func getStyleMaskAndLevel() -> (NSWindow.StyleMask, NSWindow.Level) {
    if UserDefaults.standard.bool(forKey: "onboarded") {
        print("nonactivating")
        return ([.nonactivatingPanel], .floating)
    } else {
        print("docmodal")
        return ([.docModalWindow], .normal)
    }
}


let searchInputOnlyHeight = 62.0
let searchInputOnlyHeightCompact = 44.0

/// An NSPanel subclass that implements floating panel traits.
class FloatingPanel: NSPanel {
    private var bag = Set<AnyCancellable>()
    private var prevQueryIsEmpty = true
    
    func reload(searchInputOnly: Bool = false) {
        withAnimation {
            let height = searchInputOnly ? LayoutState.shared.compact ? searchInputOnlyHeightCompact: searchInputOnlyHeight : nil
            let rect = getContentRect(overrideHeight: height)
            self.setFrame(rect, display: true)
            
        }
    }
    
    init() {
        let (mask, level) = getStyleMaskAndLevel()
        super.init(contentRect: getContentRect(overrideHeight: LayoutState.shared.compact ? searchInputOnlyHeightCompact: searchInputOnlyHeight),
                   styleMask: mask,
                   backing: .buffered,
                   defer: false)
                
        /// Allow the panel to be on top of other windows
        isFloatingPanel = true
        self.level = level
         
        /// Allow the pannel to be overlaid in a fullscreen space
        collectionBehavior.insert(.fullScreenAuxiliary)
        collectionBehavior.insert(.canJoinAllSpaces)
 
        /// Don't show a window title, even if it's set
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
 
        /// Since there is no title bar make the window moveable by dragging on the background
        isMovableByWindowBackground = false
 
        /// Hide when unfocused
        hidesOnDeactivate = false
 
        /// Hide all traffic light buttons
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
 
        backgroundColor = .clear
        
        /// Sets animations accordingly
        animationBehavior = .utilityWindow
        
        SearchState.shared.$query.sink { newQuery in
            let newValue = newQuery.isEmpty
            
            if self.prevQueryIsEmpty == newValue {
                return
            }
            
            self.reload(searchInputOnly: newValue)

            self.prevQueryIsEmpty = newValue
        }.store(in: &bag)
    }
         
    /// `canBecomeKey` and `canBecomeMain` are both required so that text inputs inside the panel can receive focus
    override var canBecomeKey: Bool {
        return true
    }
     
    override var canBecomeMain: Bool {
        return true
    }
}

private struct FloatingPanelKey: EnvironmentKey {
    static let defaultValue: NSPanel? = nil
}
 
extension EnvironmentValues {
  var floatingPanel: NSPanel? {
    get { self[FloatingPanelKey.self] }
    set { self[FloatingPanelKey.self] = newValue }
  }
}
