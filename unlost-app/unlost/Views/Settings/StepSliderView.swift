//
//  Slider.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 02/09/2023.
//

import SwiftUI

struct StepSliderView: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    @State var innerValue: Double = 0

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Slider(value: $innerValue, in: range)
                    .frame(width: geometry.size.width)
                Spacer()
            }
            
        }
        .onAppear {
            innerValue = value
        }
        .onChange(of: innerValue) { innerValue in
            value = round(innerValue * 100) / 100
            
        }
    }

}
