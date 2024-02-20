//
//  OnboardingStart.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 08/09/2023.
//

import SwiftUI

struct OnboardingStart: View {
    @AppStorage("onboardingStep") var onboardingStep: OnboardingStep = .start
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(nsImage: NSImage(contentsOfFile: "\(Bundle.main.bundlePath)/Contents/Resources/logo_hd.png")!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(48)
            
            Spacer()
                .frame(height: 32)
            Text("Unlost")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color("StrongTitleText"))
                
            Text("Find what you've forgotten instantly")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color("TitleText"))
            
            Spacer()
                .frame(height: 32)
            
            Text("Get started")
                .padding(12)
                .background(.orange.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(4)
                .shadow(color: .gray.opacity(0.5), radius: 2, x: 0, y: 1)
                .onTapGesture {
                    onboardingStep = .howItWorks
                }
        }
        
    }
}
