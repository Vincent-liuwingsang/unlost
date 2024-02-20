//
//  Notification.swift
//  unlost
//
//  Created by Wing Sang Vincent Liu on 19/09/2023.
//

import Foundation
import UserNotifications

let un = UNUserNotificationCenter.current()

private func requestAuth() {
    un.requestAuthorization(options: [.alert, .sound]) { authorised, error in
        
    }
}

func sendNotification(title: String, subtitle: String) {
    requestAuth()
    
    let content = UNMutableNotificationContent()
    content.title = title
    content.subtitle = subtitle
    content.sound = .none
    
    let request = UNNotificationRequest(
        identifier: "copyright content notification",
        content: content,
        trigger: nil)
    
    un.add(request) { error in
        print("failed to notify \(error?.localizedDescription)")
    }
    
}
