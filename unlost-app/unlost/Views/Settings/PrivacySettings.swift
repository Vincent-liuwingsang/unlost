//
//  PrivacySettings.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 08/09/2023.
//

import SwiftUI

let defaultBannedApps = [
    "com.1password.1password",
    "com.lastpass.LastPass",
    "com.dashlane.dashlanephonefinal",
    "com.bitwarden.desktop",
    "com.sibersystems.RoboFormMac",
    "com.callpod.keepermac.lite",
    "com.callpod.keepermac",
    "in.sinew.Enpass-Desktop",
    "com.apple.systempreferences"
].joined(separator: "\n")

let defaultBannedUrls = [
    "https://www.youtube.com/"
].joined(separator: "\n")

struct PrivacySettings: View {
    @AppStorage("bannedUrls") var bannedUrls: String = defaultBannedUrls
    @AppStorage("bannedPrivateBrowsing") var bannedPrivateBrowsing: Bool = true
    @AppStorage("bannedApps") var bannedApps: String = defaultBannedApps
    
    @State var urlInput: String = ""
    @State var ignorableApps = Dictionary<String, (String, NSImage)>()
    
    var bannedAppsSet: Set<String> {
        Set(bannedApps.split(separator: "\n").map {String($0)})
    }
    
    var body: some View {
        ScrollView {
            VStack {
                SettingRow(
                    label: VStack {
                        Text("Exclude Apps")
                        Text("select which apps you do not want to recorded")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color("WeakTitleText"))
                        Spacer()
                    },
                    value: ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(ignorableApps.sorted(by: { $0.value.0 < $1.value.0}), id: \.key) { key, value in
                                HStack() {
                                    Image(nsImage: value.1)
                                        .resizable()
                                        .frame(width: 16.0, height: 16.0)
                                    
                                    Text("\(value.0)")
                                    Spacer()
                                    if bannedAppsSet.contains(key) {
                                        Image(systemName: "stop.circle")
                                            .resizable()
                                            .frame(width: 16.0, height: 16.0)
                                    }
                                }
                                .padding(4)
                                .frame(maxWidth: .infinity)
                                .background( bannedAppsSet.contains(key) ? .red.opacity(0.15) : .white.opacity(0.000001))
                                .cornerRadius(4)
                                .onTapGesture {
                                    var bannedApps = Set(bannedApps.split(separator: "\n").map { String($0) })
                                    if bannedApps.contains(key) {
                                        bannedApps.remove(key)
                                    } else {
                                        bannedApps.insert(key)
                                    }
                                    
                                    bannedAppForCaptureEngineSet = bannedApps
                                    self.bannedApps = bannedApps.joined(separator: "\n")
                                }
                            }
                            
                        }
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color("Selected").opacity(0.4))
                    .cornerRadius(8)
                    
                    
                )
                .onAppear {
                    var apps = Dictionary<String, (String, NSImage)>()
                    let searcher = ApplicationSearcher()
                    
                    for app in searcher.getAllApplications() {
                        if let bundleID = app.bundleId, bundleID != Bundle.main.bundleIdentifier {
                            apps[bundleID] = (app.name, app.icon)
                        }
                    }
                    ignorableApps = apps
                }
                
                SettingRow(
                    label: VStack(alignment: .trailing) {
                        Text("Exclude Private Browser Windows")
                        Text("Do not record Incognito and private windows for Chrome, Safari, ans Arc.")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color("WeakTitleText"))
                        Spacer()
                    },
                    value: VStack(alignment: .leading){
                        HStack {
                            Text("Yes")
                                .padding(8)
                                .background(bannedPrivateBrowsing ? Color("Selected") : .white.opacity(0.0000001))
                                .cornerRadius(4)
                                .onTapGesture {
                                    bannedPrivateBrowsing = true
                                }
                            
                            Text("No")
                                .padding(8)
                                .background(!bannedPrivateBrowsing ? Color("Selected") : .white.opacity(0.0000001))
                                .cornerRadius(4)
                                .onTapGesture {
                                    bannedPrivateBrowsing = false
                                }
                        }
                    })
                
                SettingRow(
                    label: VStack {
                        Text("Exclude Websites")
                        Text("supports Chrome, Safari, Arc currently. If the url contain any of the text, the page won't be capture.")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color("WeakTitleText"))
                        Spacer()
                    },
                    value: VStack(alignment: .leading) {
                        ForEach(bannedUrls.split(separator: "\n"), id: \.self) { x in
                            HStack {
                                Text(x)
                                    
                                Image(systemName: "xmark")
                                    .onTapGesture {
                                        bannedUrls = bannedUrls.split(separator: "\n")
                                            .filter { $0 != x }
                                            .joined(separator: "\n")
                                    }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color("Selected"))
                            .cornerRadius(4)
                        }
                        
                        TextField("url you would like to avoid capturing", text: $urlInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .regular))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 4).stroke(lineWidth: 0.5))
                            .onSubmit {
                                var newBannedUrls = Set(bannedUrls.split(separator: "\n").map(String.init))
                                newBannedUrls.insert(urlInput)
                                
                                
                                bannedUrlsForCaptureEngineSet = newBannedUrls
                                bannedUrls = newBannedUrls.joined(separator: "\n")
                                urlInput = ""
                            }
                    })
                
                
                Spacer()
            }
        }
    }
}
