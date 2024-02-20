//
//  FloatingPanelExpandableLayout.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 16/06/2023.
//

import SwiftUI
 
extension View {
    func shadow() -> some View {
        self.shadow(color: Color("Shadow"), radius: 4, x: 0, y: 1)
    }
    
    func border() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color("Border"), lineWidth: 0.5)
        )
    }
}


/// This SwiftUI view provides basic modular capability to a `FloatingPanel`.
public struct FloatingPanelExpandableLayout<Toolbar: View, Sidebar: View, Content: View>: View {
    @ViewBuilder let toolbar: () -> Toolbar
    @ViewBuilder let sidebar: () -> Sidebar
    @ViewBuilder let content: () -> Content
    @AppStorage("sidebarWidthRatio") var sidebarWidthRatio: Double = 0.25
    @AppStorage("appHeightRatio") var appHeightRatio: Double = 0.25
    
    @StateObject var searchState = SearchState.shared
    @StateObject var layoutState = LayoutState.shared
    /// Stores a reference to the parent panel instance
    @Environment(\.floatingPanel) var panel
    
    
    public var body: some View {
        GeometryReader { geo in
            
            VisualEffectView()
            
            VStack(spacing: 0) {
                /// Display toolbar and toggle button

                toolbar()
                    .frame(height: layoutState.compact ? 44 : 62)

                Divider()
                
                
                let sidebarWidth = geo.size.width * sidebarWidthRatio
                if let ss = NSScreen.main?.frame.size {
                    
                    HStack(spacing: 0) {
                        
                        
                        let h = max(ss.height * appHeightRatio - (layoutState.compact ? 44 : 62) - 8 * 2, 0)
                        VStack {
                            sidebar()
                                .frame(maxHeight: h-2)
                        }
                        .frame(width: sidebarWidth, height: h)
                        .background(Color("SolidBackground"))
                        .cornerRadius(8)
                        .padding(8)
                        .shadow()
                        
                        
                        
                        content()
                            .frame(maxWidth: .infinity)
                    }
                    .background(.gray.opacity(0.06))
                    .opacity(searchState.query.isEmpty ? 0 : 1)
                    
                }
                
            }
        }
        
    }
}
