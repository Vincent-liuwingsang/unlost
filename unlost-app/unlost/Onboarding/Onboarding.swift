//
//  Onboarding.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 21/08/2023.
//

import SwiftUI
import Combine
import AVKit
import AXSwift

enum OnboardingStep: String {
    case start
    case howItWorks
    case permissions
    case activateScreenRecordingPerission
    case activateAccessibilityPermission
    case oneLastThing
    case last
}

struct OnboardingView: View {
    @AppStorage("onboardingStep") var onboardingStep: OnboardingStep = .start
    
    private var hasScreenRecordingPermission = CGPreflightScreenCaptureAccess()
    private var hasAccessibilityPermission = checkIsProcessTrusted(prompt: false)
    
    var body: some View {
        
        ZStack {
            VisualEffectView()
            
            VStack(alignment: .center) {
                if onboardingStep == .start {
                    OnboardingStart()
                } else if onboardingStep == .howItWorks {
                    OnboardingHowItWorks()
                } else if onboardingStep == .permissions || 
                            (onboardingStep == .activateAccessibilityPermission && hasAccessibilityPermission ) ||
                            (onboardingStep == .activateScreenRecordingPerission && hasScreenRecordingPermission )
                {
                    OnboardingPermission()
                } else if onboardingStep == .activateAccessibilityPermission, !hasAccessibilityPermission {
                    OnboardingActivateAccessibility()
                } else if onboardingStep == .activateScreenRecordingPerission, !hasScreenRecordingPermission {
                    OnboardingActivateScreenRecording()
                } else if onboardingStep == .oneLastThing {
                    OnboardingOneMoreThing()
                } else if onboardingStep == .last {
                    OnboardingLast()
                }
            }
            .padding(56)
            .animation(.spring())
        }
        .cornerRadius(8)
    }

}
