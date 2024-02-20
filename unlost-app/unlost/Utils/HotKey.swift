//
//  HotKey.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 01/09/2023.
//

import Foundation
import SwiftUI
import HotKey
 
struct Shortcut {
    static var shared = Shortcut()
    
    private init() { }
    
    var closeHotKey = HotKey(key: .escape, modifiers: [], keyDownHandler: {
        NSApp.closeActivity()
    })
    var toggleHotKey = HotKey(key: .m, modifiers: [.control], keyDownHandler: {
        NSApp.toggleActivity()
    })
}

