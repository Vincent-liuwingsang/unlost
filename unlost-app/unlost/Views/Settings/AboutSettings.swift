//
//  AboutSettings.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 02/09/2023.
//

import SwiftUI
import Sparkle
import AXSwift

struct AboutSettings: View {
    @AppStorage("lastScreenshotTime") var lastScreenshotTime: String = ""
    @AppStorage("bannedUrls") var bannedUrls: String = defaultBannedUrls
    
    
    var body: some View {
        
        VStack {
            let offset = CGFloat(76.0)
            ScrollView {
                VStack {
                    
                    SettingRow(
                        label: VStack(alignment: .trailing) {
                            Text("Screen Recording Permission")
                            Spacer()
                        },
                        value: VStack {
                            Text("\(CGPreflightScreenCaptureAccess().description)")
                            Spacer()
                        }
                    )
                    
                    SettingRow(
                        label: VStack(alignment: .trailing) {
                            Text("Accessibility Permission")
                            Spacer()
                        },
                        value: VStack {
                            Text("\(checkIsProcessTrusted(prompt: false).description)")
                            Spacer()
                        }
                    )
                    
                    SettingRow(
                        label: VStack(alignment: .trailing) {
                            Text("Last Screenshot At")
                            Spacer()
                        },
                        value: VStack {
                            Text("\(lastScreenshotTime)")
                            Spacer()
                        }
                    )
                    
                    SettingRow(
                        label: VStack(alignment: .trailing) {
                            Text("Version")
                            Spacer()
                        },
                        value: VStack {
                            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                            Text("\(version)")
                            Spacer()
                        }
                    )
                    
                    Spacer()
                }
            }
            .offset(x: offset)
            
            
            

            Divider()
            HStack(alignment: .center) {
                CheckForUpdatesView()
                Text("Latest Releases")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color("ButtonBackground"))
                    .cornerRadius(4)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("StrongTitleText"))
                    .onTapGesture {
                        NSWorkspace.shared.open(URL(string: "https://unlost.ai/updates")!)
                    }
                Spacer()
                Text("Reddit")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color("ButtonBackground"))
                    .cornerRadius(4)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("StrongTitleText"))
                    .onTapGesture {
                        NSWorkspace.shared.open(URL(string: "https://www.reddit.com/r/UnlostAI/")!)
                    }
                Text("Slack")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color("ButtonBackground"))
                    .cornerRadius(4)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("StrongTitleText"))
                    .onTapGesture {
                        NSWorkspace.shared.open(URL(string: "https://join.slack.com/t/unlostgroup/shared_invite/zt-21mb199ma-q8uEmUR5kHhDS0NI6q2ROw")!)
                    }
                Text("Visit Website")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color("ButtonBackground"))
                    .cornerRadius(4)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("StrongTitleText"))
                    .onTapGesture {
                        NSWorkspace.shared.open(URL(string: "https://unlost.ai/")!)
                    }
            }
            .padding(.horizontal, 16)
            .frame(height: 36)
        }
        .frame(maxHeight: .infinity)
        
    }
}
