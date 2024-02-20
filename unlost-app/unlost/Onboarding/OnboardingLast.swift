//
//  OnboardingLast.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 21/09/2023.
//

import SwiftUI

struct OnboardingLast: View {
    @AppStorage("onboarded") var onboarded: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 36) {
            Text("Unlost processes your data in batches to make sure optimal energy efficiency. Please allow a couple of minutes for search results to appear.")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color("StrongTitleText"))
                .multilineTextAlignment(.center)
            
            Text("Complete")
                .padding(12)
                .background(.orange.opacity(0.6))
                .cornerRadius(4)
                .foregroundColor(.white)
                .shadow(color: .gray.opacity(0.5), radius: 2, x: 0, y: 1)
                .onTapGesture {
                    onboarded = true
                    NSApp.relaunch()
                }
        }
    }
}

#Preview {
    OnboardingLast()
}
