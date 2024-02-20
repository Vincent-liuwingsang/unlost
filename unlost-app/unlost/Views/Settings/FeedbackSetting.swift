//
//  Feedback.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 21/09/2023.
//

import SwiftUI
import NotionSwift

struct FeedbackSettings: View {
    @StateObject var layoutState = LayoutState.shared
    @AppStorage("feedbackName") var name: String = ""
    @AppStorage("feedbackEmail") var email: String = ""
    @State var message: String = ""
    @State var sending = false
    
    @State var response: String = ""
    
    var valid: Bool {
        name.isNotEmpty && email.isNotEmpty && message.isNotEmpty
    }
    
    var body: some View {
        let padding: CGFloat = 16.0
        let fontSize: CGFloat = 14
        let labelSize: CGFloat = 12
        ScrollViewReader {reader in
            ScrollView(showsIndicators: false) {
                VStack {
                    Text("We'd love to hear how we can make Unlost better for you.")
                        .font(.system(size: fontSize, weight: .regular))
                        .foregroundColor(Color("TitleText"))
                        .padding(.vertical, 8)
                        .padding(.leading, 80)
                    
                    SettingRow(label: VStack(alignment: .trailing) {
                        Text("Name")
                            .font(.system(size: labelSize, weight: .regular))
                            .padding(.top, 2)
                        
                    }, value:  VStack {
                        
                        TextField("Name",text: $name)
                            .textFieldStyle(.plain)
                            .font(.system(size: fontSize, weight: .regular))
                            .padding(.horizontal, padding)
                            .padding(.vertical, padding * 0.75)
                            .background(RoundedRectangle(cornerRadius: 4).stroke(lineWidth: 0.5))
                        
                        Spacer()
                    })
                    .offset(x: -18)
                    
                    SettingRow(label: VStack(alignment: .trailing) {
                        
                        Text("Email")
                            .font(.system(size: labelSize, weight: .regular))
                            .padding(.top, 2)
                        Spacer()
                    }, value:  VStack {
                        
                        TextField("your@email.com",text: $email)
                            .textFieldStyle(.plain)
                            .font(.system(size: fontSize, weight: .regular))
                            .padding(.horizontal, padding)
                            .padding(.vertical, padding * 0.75)
                            .background(RoundedRectangle(cornerRadius: 4).stroke(lineWidth: 0.5))
                        
                        Spacer()
                    })
                    .offset(x: -18)
                    
                    SettingRow(label: VStack(alignment: .trailing) {
                        
                        Text("Message")
                            .font(.system(size: labelSize, weight: .regular))
                            .padding(.top, 2)
                        Spacer()
                    }, value:  VStack {
                        
                        TextEditor(text: $message)
                            .textFieldStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .background(.clear)
                            .font(.system(size: fontSize, weight: .regular))
                            .padding(.horizontal, padding)
                            .padding(.vertical, padding * 0.75)
                            .background(RoundedRectangle(cornerRadius: 4).stroke(lineWidth: 0.5))
                            .frame(height: 100)
                    })
                    .offset(x: -18)
                    
                    Spacer()
                    
                }
            }
            .padding(.top, 16)
            .frame(maxHeight: .infinity)
            
            Divider()
            HStack(alignment: .center) {
                if response == failureMessage {
                    
                    Text("If this persisits please contac us.")
                        .padding(8)
                        .background(Color("Selected").opacity(0.4))
                        .cornerRadius(4)
                        .onTapGesture {
                            NSWorkspace.shared.open(URL(string: "mailto:vince@unlost.ai")!)
                        }
                        .onAppear {
                            reader.scrollTo("errored reponse")
                        }
                        .id("errored reponse")
                    
                }
                Text(response)
                Spacer()
                Text("Submit")
                    .font(.system(size: fontSize, weight: .regular))
                    .padding(8)
                    .background(Color("Selected"))
                    .cornerRadius(4)
                    .opacity(valid && !sending ? 1 : 0.3)
                    .onTapGesture {
                        if !sending {
                            addFeedbackToNotion(name: name, email: email, message: message)
                        }
                    }
            }
            .padding(.horizontal, 16)
            .frame(height: 36)
        }
    }
    
    var successMessage = "Feedback submitted succesfully! We will get back to you as soon as possible."
    var failureMessage = "Failed to submit feedback."
    
    private func addFeedbackToNotion(name: String, email: String, message: String) {
        let notion = NotionClient(accessKeyProvider: StringAccessKeyProvider(accessKey: "secret_nTnlJVVEeC40qX0purXOywG6EnAw7ZMWkqt6JFYOLRL"))
        let token = ""
        let databaseId = NotionSwift.Database.Identifier(token)

        let request = PageCreateRequest(
            parent: .database(databaseId),
            properties: [
                "Name": .init(
                    type: .title([
                        .init(string: name)
                    ])
                ),
                "Email": .init(
                    type: .email(email)
                ),
                "Message": .init(
                    type: .richText([
                        .init(string: message)
                    ])
                ),
                "Date": .init(
                    type: .date(.init(start: .dateOnly(Date.now), end: nil))
                )
            ]
        )
        sending = true
        notion.pageCreate(request: request) { result in
            switch result {
            case .success(let _):
                response = successMessage
                self.message = ""
            case.failure(let _):
                response = failureMessage
            }
            sending = false
        }
    }

}
