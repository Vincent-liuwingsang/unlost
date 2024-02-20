//
//  SettingTab.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 08/09/2023.
//

import SwiftUI

enum SettingTabType {
    case general
    case appearance
    case privacy
    case storage
    case about
    case feedback
}

class SettingState: ObservableObject {
    static var shared = SettingState()
    
    @Published var selectedTab = SettingTabType.general
}

struct SettingTab: View {
    @StateObject var settingState = SettingState.shared
    @State var hover = false
    
    private var w: CGFloat = 80.0
    private var h: CGFloat = 48.0
    
    let settingTab: SettingTabType
    let title: String
    let icon: String
    
    init(settingTab: SettingTabType, title: String, icon: String) {
        self.settingTab = settingTab
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: icon)
                .resizable()
                .frame(width: 20,height: 20)
            Text(title)
        }
        .frame(width: w, height: h)
        .padding(4)
        .background(hover || settingState.selectedTab == settingTab ? Color("Selected") : .white.opacity(0.000001))
        .cornerRadius(8)
        .onHover { hover in
            self.hover = hover
        }
        .onTapGesture {
            settingState.selectedTab = settingTab
        }
    }
}
