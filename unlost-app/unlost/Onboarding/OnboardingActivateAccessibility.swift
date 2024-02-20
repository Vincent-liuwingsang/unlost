//
//  OnboardingActivateAccessibility.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 20/09/2023.
//

import SwiftUI
import AXSwift

struct OnboardingActivateAccessibility: View {
    @AppStorage("onboardingStep") var onboardingStep: OnboardingStep = .start
    
    func checkHasAccess() {
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            if checkIsProcessTrusted(prompt: false){
                onboardingStep = .permissions
            } else {
                checkHasAccess()
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Allow accessibility permission")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color("StrongTitleText"))
                .onAppear {
                    checkHasAccess()
                }
            
            Spacer()
            
            HStack(spacing: 32) {
                VStack(spacing: 16) {
                    if let image = NSImage(contentsOfFile: "\(Bundle.main.bundlePath)/Contents/Resources/onboarding_accessibility.png") {
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
                
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 60)
            
            Spacer()
            
            Text("Allow Accessbility Permission")
                .padding(12)
                .background(.orange.opacity(0.6))
                .cornerRadius(4)
                .foregroundColor(.white)
                .shadow(color: .gray.opacity(0.5), radius: 2, x: 0, y: 1)
                .onTapGesture {
                    checkIsProcessTrusted(prompt: true)
                }
        }
    }
}
