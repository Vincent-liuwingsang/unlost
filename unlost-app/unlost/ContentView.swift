//
//  ContentView.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 16/06/2023.
//

import SwiftUI
import HotKey
import Combine

struct ContentView: View {
    @AppStorage("onboarded") var onboarded: Bool = false
    //    @ObservedObject var keyResponder = KeyResponder()

    
    var body: some View {
        if !onboarded {
                   OnboardingView()
        } else {
            ZStack {
                
                FloatingPanelSearchLayout(
                    itemView: { itemsPerGroup, appName, index  in
                        ListItemView(appName: appName, index: index, itemsPerGroup: itemsPerGroup)
                    },
                    detailsView: {
                        DetailsView()
                    }
                )
                .cornerRadius(8)
                
                TagsSuggestion()
                
            }
        }
    }
}


//class KeyResponder: ObservableObject {
//    private var cancellable: AnyCancellable?
//
//    init() {
//        self.cancellable = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyUp, .keyDown]) { event in
//            self.handleKeyEvent(event)
//            return event
//        } as? AnyCancellable
//    }
//
//    func handleKeyEvent(_ event: NSEvent) {
//        if event.keyCode == 56 {
//            KeyboardState.shared.shiftPressed = event.modifierFlags.contains(.shift)
//        }
//    }
//
//    deinit {
//        cancellable?.cancel()
//    }
//}
