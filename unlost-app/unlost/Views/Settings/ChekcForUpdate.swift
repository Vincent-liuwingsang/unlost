//
//  ChekcForUpdate.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 02/09/2023.
//

import SwiftUI
import Sparkle

extension Bundle {
    var buildNumber: String {
        if let b = infoDictionary?["CFBundleVersion"] as? String {
            return b
        }
        return "unknown"
    }
}

// This view model class publishes when new updates can be checked by the user
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}


// This is the view for the Check for Updates menu item
// Note this intermediate view is necessary for the disabled state on the menu item to work properly before Monterey.
// See https://stackoverflow.com/questions/68553092/menu-not-updating-swiftui-bug for more info
struct CheckForUpdatesView: View {
    @ObservedObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel
    private let updater = AppState.shared.updateController.updater
    
    init() {
        // Create our view model for our CheckForUpdatesView
        self.checkForUpdatesViewModel = CheckForUpdatesViewModel(updater: updater)
    }
    
    var body: some View {
        Text("Check for Updates")
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color("ButtonBackground"))
            .cornerRadius(4)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(Color("StrongTitleText"))
            .onTapGesture {
                if checkForUpdatesViewModel.canCheckForUpdates {
                    updater.checkForUpdates()
                }
            }
        
    }
}
