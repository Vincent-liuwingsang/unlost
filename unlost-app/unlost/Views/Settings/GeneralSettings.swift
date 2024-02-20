//
//  General.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 02/09/2023.
//

import SwiftUI

struct GeneralSettings: View {
    @AppStorage("dedupOptimisation") var dedupOptimisation: String = "Smart"
    
    
    var body: some View {
        ScrollView {
            VStack {

                SettingRow(
                    label: VStack(alignment: .trailing) {
                        Text("Detect Similar Screenshots")
                        Text("Great for scroll reading. There will be a small increase in CPU usage but saves storage.")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color("WeakTitleText"))
                        Spacer()
                    },
                    value: VStack(alignment: .leading){
                        HStack {
                            Text("Always")
                                .padding(8)
                                .background(dedupOptimisation == "Always" ? Color("Selected") : .white.opacity(0.0000001))
                                .cornerRadius(4)
                                .onTapGesture {
                                    dedupOptimisation = "Always"
                                }
                            
                            Text("Smart")
                                .padding(8)
                                .background(dedupOptimisation == "Smart" ? Color("Selected") : .white.opacity(0.0000001))
                                .cornerRadius(4)
                                .onTapGesture {
                                    dedupOptimisation = "Smart"
                                }
                            
                            Text("Never")
                                .padding(8)
                                .background(dedupOptimisation == "Never" ? Color("Selected") : .white.opacity(0.0000001))
                                .cornerRadius(4)
                                .onTapGesture {
                                    dedupOptimisation = "Never"
                                }
                        }
                        
                        Text(dedupOptimisation == "Always" ? "Always active" :
                                dedupOptimisation == "Smart" ? "Only active when your device is plugged in" :
                                "Never active")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color("WeakTitleText"))
                            .padding(.leading, 10)
                    })
            }
            .offset(x: 32)
        }
    }
}

