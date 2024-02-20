//
//  OnboardingPermission.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 08/09/2023.
//

import SwiftUI
import AXSwift

struct OnboardingPermission: View {
    @AppStorage("onboardingStep") var onboardingStep: OnboardingStep = .start
    
    private var hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()
    private var hasAccessibilityPermission = checkIsProcessTrusted(prompt: false)
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Unlost needs your permission to work correctly")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color("StrongTitleText"))
            
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName:"rectangle.dashed.badge.record")
                        .resizable()
                        .frame(width: 28, height: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Screen recording permission")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("TitleText"))
                            
                        Text("This allows Unlost to take screenshots to analyse visible text and result is stored in a local database on your computer. Only you have access.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color("TitleText"))
                            
                            
                    }
                    Spacer()
                    
                }
                .opacity(!hasScreenRecordingPermission ? 1 : 0.5)
                
                HStack(spacing: 16) {
                    Image(systemName:"accessibility")
                        .resizable()
                        .frame(width: 24, height: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accessibility permission")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("TitleText"))
 
                        Text("This allows Unlost to detect and exclude capturing incognito/private browser windows.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color("TitleText"))
                    }
                    Spacer()
                }
                .opacity(hasScreenRecordingPermission && !hasAccessibilityPermission ? 1 : 0.5)
                
                HStack(spacing: 16) {
                    Image(systemName:"gamecontroller")
                        .resizable()
                        .frame(width: 28, height: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Automation permission")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("TitleText"))
 
                        Text("When you next activate your browser, Unlost will ask for automation permission so it can store additional information like web address to exclude capturing certain websites and enhance search accuracy.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color("TitleText"))
                        
                        
                    }
                    Spacer()
                }
                .opacity(hasScreenRecordingPermission && hasAccessibilityPermission ? 1 : 0.5)
                
                HStack(spacing: 16) {
                    Image(systemName:"mic")
                        .resizable()
                        .frame(width: 20, height: 24)
                        .padding(.horizontal, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Microphone permission (Optional)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("TitleText"))

                        Text("When you next have a meeting, Unlost will ask for permission to record your microphone and transcribe meetings content. Audio data will be deleted every time transcription is complete.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color("TitleText"))
                    }
                    Spacer()
                }
                .opacity(hasScreenRecordingPermission && hasAccessibilityPermission ? 1 : 0.5)
                
            }
            .padding(.vertical, 24)
            .frame(maxWidth: 560)
            
            Spacer()
            
            Text(!hasScreenRecordingPermission ? "Allow Screen Recording Permission" :
                    !hasAccessibilityPermission ? "Allow Accessibility Permission" :
                    "Next")
                .padding(12)
                .background(.orange.opacity(0.6))
                .cornerRadius(4)
                .foregroundColor(.white)
                .shadow(color: .gray.opacity(0.5), radius: 2, x: 0, y: 1)
                .onTapGesture {
                    if !hasScreenRecordingPermission {
                        onboardingStep = .activateScreenRecordingPerission
                    } else if !hasAccessibilityPermission {
                        onboardingStep = .activateAccessibilityPermission
                    } else {
                        onboardingStep = .oneLastThing
                    }
                }
        }
    }
}
