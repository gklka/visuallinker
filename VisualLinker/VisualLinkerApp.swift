//
//  VisualLinkerApp.swift
//  VisualLinker
//
//  Created by GK on 2023.01.30..
//

import SwiftUI
import HotKey
import UserNotifications

extension Notification.Name {
    static let progressStart = Notification.Name("ProgressStart")
    static let progressEnd = Notification.Name("ProgressEnd")
}

@main
struct VisualLinkerApp: App {
    @State var working: Bool = false
    @State var settingsVisible: Bool = false
    
    init() {
        self.hotKey = HotKey(key: .v, modifiers: [.command, .option, .shift])
        self.hotKey.keyUpHandler = {
            print("Key combo pressed")
            NotificationCenter.default.post(name: .keyCombo, object: nil)
        }
    }
    
    var hotKey: HotKey

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Progress handling
                    NotificationCenter.default.addObserver(forName: .progressStart, object: nil, queue: nil) { _ in
                        print("Progress start...")
                        self.working = true
                    }
                    NotificationCenter.default.addObserver(forName: .progressEnd, object: nil, queue: nil) { _ in
                        print("...progress end")
                        self.working = false
                    }
                    
                    // Notifications
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { success, error in
                        guard error == nil else {
                            print("Error registering notifications: \(error!)")
                            return
                        }
                    }
                }
        }
        
        MenuBarExtra("Visual Linker", systemImage: self.working ? "link.icloud.fill" : "link.badge.plus") {
            Button("Generate Link Preview") {
                NotificationCenter.default.post(name: .keyCombo, object: nil)
            }
            .keyboardShortcut("v", modifiers: [.shift, .option, .command])
            Button("Preferences") {
                
            }
            Divider()
            Button("About VisualLinker") {
                
            }
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
