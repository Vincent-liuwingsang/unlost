//
//  OnboardingOneMoreThing.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 08/09/2023.
//

import SwiftUI



struct OnboardingOneMoreThing: View {
    @AppStorage("onboardingStep") var onboardingStep: OnboardingStep = .start
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Couple of Tips")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color("StrongTitleText"))
            
            Spacer()
            HStack(alignment:.top, spacing: 32) {
                VStack(spacing: 16) {
                    if let image = NSImage(contentsOfFile: "\(Bundle.main.bundlePath)/Contents/Resources/onboarding_hotkey.png") {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(14)
                            .padding(2)
                            .background(.gray)
                            .cornerRadius(16)
                    }

                    Text("Shortcut key")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color("TitleText"))
                }
                
                VStack(spacing: 16) {
                    if let image = NSImage(contentsOfFile: "\(Bundle.main.bundlePath)/Contents/Resources/onboarding_settings.png") {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(14)
                            .padding(2)
                            .background(.gray)
                            .cornerRadius(16)
                    }
                    Text("Turn capture on/off in settings. If you're cautious about CPU/energy usage, check out settings for similar screenshots detections.")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color("TitleText"))
                }
                
                VStack(spacing: 16) {
                    if let image = NSImage(contentsOfFile: "\(Bundle.main.bundlePath)/Contents/Resources/onboarding_filter.png") {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(14)
                            .padding(2)
                            .background(.gray)
                            .cornerRadius(16)
                    }
                              
                    Text("Use @ to add and clear filters")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color("TitleText"))
                }
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 60)
//            VStack(alignment: .leading, spacing: 32) {
//                Spacer()
//                Text("😉 Ctrl + M")
//                    .font(.system(size: 14, weight: .regular))
//                    .foregroundColor(Color("TitleText"))
//
//
//                Text("🔎 Use @ to add/clear tag filters to search query")
//                    .font(.system(size: 14, weight: .regular))
//                    .foregroundColor(Color("TitleText"))
//
//
//                Text("⚙️ Tap unlost's icon or right click system icon to open settings. You can temprarily disable recording, check updates, set app size.")
//                    .font(.system(size: 14, weight: .regular))
//                    .foregroundColor(Color("TitleText"))
//                Spacer()
//            }
        }.padding(40)
        Spacer()
        
        Text("Complete")
            .padding(12)
            .background(.orange.opacity(0.6))
            .foregroundColor(.white)
            .cornerRadius(4)
            .shadow(color: .gray.opacity(0.5), radius: 2, x: 0, y: 1)
            .onTapGesture {
                onboardingStep = .last
            }
    }
    
}


