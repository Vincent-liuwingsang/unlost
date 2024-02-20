//
//  OnboardingActivatePermission.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 08/09/2023.
//

import SwiftUI
import ScreenCaptureKit

struct OnboardingActivateScreenRecording: View {
    @AppStorage("onboardingStep") var onboardingStep: OnboardingStep = .start

      var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Allow screen recording permission")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color("StrongTitleText"))
            
            Spacer()
            
            HStack(spacing: 32) {
                VStack(spacing: 16) {
                    if let image = NSImage(contentsOfFile: "\(Bundle.main.bundlePath)/Contents/Resources/onboarding_1.png") {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(14)
                            .padding(2)
                            .background(.gray)
                            .cornerRadius(16)
                    }

                    Text("Enable Unlost")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color("TitleText"))
                }
                
                VStack(spacing: 16) {
                    if let image = NSImage(contentsOfFile: "\(Bundle.main.bundlePath)/Contents/Resources/onboarding_2.png") {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(14)
                            .padding(2)
                            .background(.gray)
                            .cornerRadius(16)
                    }
                    Text("Authenticate")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color("TitleText"))
                }
                
                VStack(spacing: 16) {
                    if let image = NSImage(contentsOfFile: "\(Bundle.main.bundlePath)/Contents/Resources/onboarding_3.png") {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(14)
                            .padding(2)
                            .background(.gray)
                            .cornerRadius(16)
                    }
                              
                    Text("Quite & Reopen")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color("TitleText"))
                }
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 60)
            
            Spacer()
            
            Text("Allow Screen Recording Permission")
                .padding(12)
                .background(.orange.opacity(0.6))
                .cornerRadius(4)
                .foregroundColor(.white)
                .shadow(color: .gray.opacity(0.5), radius: 2, x: 0, y: 1)
                .onTapGesture {
                    Task {
                        do {
                            try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                            
                            log.error("access to screen recording")
                        } catch {
                            log.error("no access to screen recording")
                        }
                    }
                }
        }
    }
}
