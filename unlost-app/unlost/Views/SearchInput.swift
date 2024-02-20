//
//  SearchInput.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 22/07/2023.
//

import SwiftUI

struct SearchInput: View {
    @StateObject var searchState: SearchState
    @StateObject var layoutState: LayoutState
    
    @State private var hover: Bool = false
    @AppStorage("enableRecording") var enableRecording: Bool = true
    @FocusState private var focusedField: String?
    @Namespace private var namespace
    
    let logo = NSImage(contentsOfFile: "\(Bundle.main.bundlePath)/Contents/Resources/logo.png")!
    let logoBW = NSImage(contentsOfFile: "\(Bundle.main.bundlePath)/Contents/Resources/logo_bw.png")!
    
    var onChange: (Bool) -> Void
    
    private func extractSubstringAfter(_ target: String, in input: String) -> (String, String)? {
        if let range = input.range(of: target) {
            let substring1 = String(input[..<range.upperBound])
            let substring2 = String(input[range.upperBound...])
            return (substring1, substring2)
        }
        return nil
    }
    
    func test() -> Text {
        var attributedString = AttributedString(searchState.query)
        let typing = searchState.query != searchState.lastSearchedQuery
        let loweredQuery = searchState.query.lowercased()
        if !typing,
           let loweredClean = searchState.cleanQueryWhenIdentifiedDates?.lowercased(),
           let result = extractSubstringAfter(loweredClean, in: loweredQuery),
           let range = attributedString.range(of: result.1.trimmingCharacters(in: .whitespaces)) {
            attributedString[range].backgroundColor = Color("CTA").opacity(0.7)
           }
     
        let t = searchState.query.isEmpty ? " " : attributedString
        return Text(t)
    }
    
    var body: some View {
        HStack {
            Image(nsImage: enableRecording ? logo : logoBW)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .shadow(color: enableRecording ? .orange: .gray, radius: 1, x: 0, y: 0.5)
                .onTapGesture {
                    NSApp.openSettings()
                }
            
            ZStack(alignment: .leading) {
                let fontSize: CGFloat = layoutState.compact ? 18 : 22
                if searchState.query.isEmpty {
                    Text("flight ticket last week @chrome")
                        .textFieldStyle(.plain)
                        .font(.system(size: fontSize, weight: .regular))
                        .foregroundColor(Color("PlaceholderText"))
                        .padding(.leading, 8)
                        .disabled(true)
                    //                    .opacity(searchState.query.isEmpty ? 1 : 0)
                }

                test()
                    .font(.system(size: fontSize, weight: .regular))
                    .padding(.leading, 5)
                    .transition(.opacity)
                
                TextEditor(text: Binding(
                    get: {
                        return searchState.query
                    },
                    set: { value in
                        var returned = false
                        var newValue = value
                        if value.contains("\n") {
                            newValue = value.replacingOccurrences(of: "\n", with: "")
                            returned = true
                            
                        }
                        searchState.query = newValue
                        if returned {
                            if searchState.showTagSuggestions {
                                searchState.activateSelectedTag()
                            } else {
                                if let url = layoutState.selectedTag?.tags.first?.url {
                                    NSWorkspace.shared.open(URL(string: url)!)
                                    NSApp.closeActivity()
                                }
                            }
                        }
                    }
                ))
                .textFieldStyle(.plain)
                .font(.system(size: fontSize, weight: .regular))
                .scrollContentBackground(.hidden)
                .background(.clear)
                .opacity(0.2)
//                .opacity(searchState.query.isEmpty ? 0.15 : 0.85)
                .onChange(of: searchState.debouncedQuery) { _ in
                    onChange(false)
                }
                .onAppear {
                    onChange(false)
                    focusedField = "searchInput"
                }
//                .prefersDefaultFocus(in: namespace)
                .focused($focusedField, equals: "searchInput")
            }
        }
        .padding(layoutState.compact ? 12 : 18)
    }
}
