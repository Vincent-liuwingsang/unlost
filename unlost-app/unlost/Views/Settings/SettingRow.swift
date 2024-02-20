//
//  SettingRow.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 02/09/2023.
//

import SwiftUI

struct SettingRow<KeyView: View, ValueView: View>: View {
        
    var label: KeyView
    var value: ValueView
    
    var body: some View {
        HStack {
            Spacer()
            HStack {
                Spacer()
                label
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("WeakTitleText"))
                    .multilineTextAlignment(.trailing)
            }
            .padding(8)
            .frame(width: 150)

            
            HStack {
                value
                    
                Spacer()
            }
            .padding(8)
            .frame(width: 300)
            
            Spacer()
        }
    }
}
