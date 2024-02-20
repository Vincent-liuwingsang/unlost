//
//  AppState.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 08/09/2023.
//

import Foundation
import Sparkle

class SparkleUpdateDelegate: NSObject, SPUUpdaterDelegate {
    
}

class AppState : ObservableObject {
    static var shared = AppState()
    
    @Published var updateController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    
    private init() {  }
}
