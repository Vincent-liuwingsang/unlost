//
//  OnboardingHowItWorks.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 08/09/2023.
//

import SwiftUI

struct OnboardingHowItWorks: View {
    
    @AppStorage("onboardingStep") var onboardingStep: OnboardingStep = .start
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("How it works")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color("StrongTitleText"))
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 32) {
                HStack {
                    Image(systemName:"rectangle.dashed.badge.record")
                        .resizable()
                        .frame(width: 28, height: 24)
                        .padding(.horizontal, 12)
                    
                    Text("Unlost captures your screen in the background and processes visible words with AI. No setup required.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("TitleText"))
                        .padding(.horizontal, 16)
                    
                }
                
                HStack {
                    
                    Image(systemName:"folder")
                        .resizable()
                        .frame(width: 28, height: 24)
                        .padding(.horizontal, 12)
                    Text("All the data is stored locally and only you have access to them.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("TitleText"))
                        .padding(.horizontal, 16)
                }
                
                HStack {
                    HStack(spacing: 4) {
                        Text("^")
                            .frame(width: 16, height: 16)
                            .padding(4)
                            .background(.gray.opacity(0.3))
                            .cornerRadius(4)
                        Text("M")
                            .frame(width: 16, height: 16)
                            .padding(4)
                            .background(.gray.opacity(0.3))
                            .cornerRadius(4)
                    }
                    

                    Text("To recall a memory, simply control + m and search using words that either appeared or related in meaning.")

                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("TitleText"))
                        .padding(.leading, 16)
                }
            }
            .padding(.vertical, 48)
            .frame(maxWidth: 560)
            
            Spacer()
            
            Text("Next")
                .padding(12)
                .background(.orange.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(4)
                .shadow(color: .gray.opacity(0.5), radius: 2, x: 0, y: 1)
                .onTapGesture {
                    onboardingStep = .permissions
                }
        }
        
    }
}
