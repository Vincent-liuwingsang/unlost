//
//  AppearanceSettings.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 08/09/2023.
//

import SwiftUI

struct HeightSetting: View {
    @AppStorage("appHeightRatio") var appHeightRatio: Double = 0.8
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text("Height")
            Text("\(Int(appHeightRatio * 100))% of screen")
            Spacer()
        }
    }
}

struct WidthSetting: View {
    @AppStorage("appWidthRatio") var appWidthRatio: Double = 0.8
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text("Width")
            Text("\(Int(appWidthRatio * 100))% of screen")
            Spacer()
        }
    }
}

struct SidebarWidthSetting: View {
    @AppStorage("sidebarWidthRatio") var sidebarWidthRatio: Double = 0.25
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text("Sidebar Width")
            Text("\(Int(sidebarWidthRatio * 100))% of app")
            Spacer()
        }
    }
}

struct AppearanceSettings: View {
    
    @AppStorage("appHeightRatio") var appHeightRatio: Double = 0.8
    @AppStorage("appWidthRatio") var appWidthRatio: Double = 0.8
    @AppStorage("sidebarWidthRatio") var sidebarWidthRatio: Double = 0.25
    
    var body: some View {
        ScrollView {
            VStack {
                SettingRow(
                    label: HeightSetting(),
                    value: StepSliderView(
                        value: $appHeightRatio,
                        range: 0.2...1,
                        step: 0.01)
                )
                
                SettingRow(
                    label:WidthSetting(),
                    value: StepSliderView(
                        value: $appWidthRatio,
                        range: 0.2...1,
                        step: 0.01)
                )
                
                SettingRow(
                    label: SidebarWidthSetting(),
                    value: StepSliderView(value: $sidebarWidthRatio, range: 0.1...0.5, step: 0.01)
                )
                
                Spacer()
            }
        }
    }
}
