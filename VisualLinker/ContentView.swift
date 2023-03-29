//
//  ContentView.swift
//  VisualLinker
//
//  Created by GK on 2023.01.30..
//

import SwiftUI
import LinkPresentation
import UserNotifications

extension NSImage {
    var cgImage: CGImage {
        get {
            let imageData = self.tiffRepresentation!
            let source = CGImageSourceCreateWithData(imageData as CFData, nil).unsafelyUnwrapped
            let maskRef = CGImageSourceCreateImageAtIndex(source, Int(0), nil)
            return maskRef.unsafelyUnwrapped
        }
    }
}

extension Notification.Name {
    static let keyCombo = Notification.Name("KeyCombo")
}

struct ContentView: View {
    let defaultImage: CGImage = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "!")!.cgImage
    @State var cgImage: CGImage?

    var body: some View {
        VStack {
            Button("DO") {
                self.createLinkPreview()
            }
            Image(self.cgImage ?? self.defaultImage, scale: 1, label: Text("Label"))
                .resizable()
                .frame(width: 350, height: 250)
                .border(Color.red, width: 1)
        }
        .padding()
        .task {
            NotificationCenter.default.addObserver(forName: .keyCombo, object: nil, queue: nil) { _ in
                self.createLinkPreview()
            }
        }
    }
    
    func createLinkPreview() {
        NotificationCenter.default.post(name: .progressStart, object: nil)
        
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let provider = LPMetadataProvider()
        print("new provider created")

        // Get clipboard content
        var urlString = NSPasteboard.general.string(forType: .URL)
        if urlString == nil {
            urlString = NSPasteboard.general.string(forType: .string)
        }
        guard let urlString = urlString else {
            self.showNotification(text: "Pasteboard has no URLs in it")
            NotificationCenter.default.post(name: .progressEnd, object: nil)
            self.cgImage = nil
            return
        }
        
        let clipboardURL: URL? = URL(string: urlString)
        guard let url: URL = clipboardURL else {
            self.showNotification(text: "Cannot paste URL on pasteboard")
            NotificationCenter.default.post(name: .progressEnd, object: nil)
            self.cgImage = nil
            return
        }
        
        // Gather preview metadata
        provider.startFetchingMetadata(for: url) { metadata, error in
            guard error == nil else {
                self.showNotification(text: error!.localizedDescription)
                NotificationCenter.default.post(name: .progressEnd, object: nil)
                self.cgImage = nil
                return
            }
            guard let metadata = metadata else {
                self.showNotification(text: "Metadata is nil")
                NotificationCenter.default.post(name: .progressEnd, object: nil)
                self.cgImage = nil
                return
            }
                        
            // Render in image
            DispatchQueue.main.async {
                // Create key events
                let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: true) // cmd-v down
                keyDownEvent?.flags = CGEventFlags.maskCommand
                let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0x09, keyDown: false) // cmd-v up
                keyUpEvent?.flags = CGEventFlags.maskCommand

                // Create preview
                let linkPreview = LPLinkView(metadata: metadata)
                let size = NSSize(width: 350, height: 250)
                let rect = NSRect(origin: CGPoint.zero, size: size)
                linkPreview.frame.size = size

                // Render into bitmap representation
                guard let bir = linkPreview.bitmapImageRepForCachingDisplay(in: rect) else {
                    self.showNotification(text: "Cannot create image representation")
                    NotificationCenter.default.post(name: .progressEnd, object: nil)
                    self.cgImage = nil
                    return
                }
                bir.size = size
                linkPreview.cacheDisplay(in: rect, to: bir)

                // Create NSImage
                let image = NSImage(size: size)
                image.addRepresentation(bir)

                // Add PNG to pasteboard
                let tiffRepresentation = NSBitmapImageRep(data: image.tiffRepresentation!)
                guard let pngData: Data = tiffRepresentation?.representation(using: .png, properties: [:]) else {
                    self.showNotification(text: "Cannot represent image az PNG")
                    NotificationCenter.default.post(name: .progressEnd, object: nil)
                    self.cgImage = nil
                    return
                }

                // Store previous pasteboard content
                guard let types = NSPasteboard.general.types else {
                    print("No types")
                    return
                }
                var originalPasteboardContent: [NSPasteboard.PasteboardType: Data] = [:]
                for type in types {
                    if let data = NSPasteboard.general.data(forType: type) {
                        originalPasteboardContent[type] = data
                    }
                }

                // Set image to pasteboard
                NSPasteboard.general.clearContents()
                guard NSPasteboard.general.setData(pngData, forType: .png) == true else {
                    self.showNotification(text: "Cannot write PNG")
                    return
                }
                
                // Paste image
                keyDownEvent?.post(tap: CGEventTapLocation.cghidEventTap)
                keyUpEvent?.post(tap: CGEventTapLocation.cghidEventTap)
                Thread.sleep(forTimeInterval: 0.1)

                // Set URL to pasteboard
                NSPasteboard.general.clearContents()
                guard NSPasteboard.general.setString(urlString, forType: .URL) == true else {
                    self.showNotification(text: "Cannot write URL")
                    return
                }
                
                // Paste url
                keyDownEvent?.post(tap: CGEventTapLocation.cghidEventTap)
                keyUpEvent?.post(tap: CGEventTapLocation.cghidEventTap)
                Thread.sleep(forTimeInterval: 0.1)

                // Restore previous content
                NSPasteboard.general.clearContents()
                for (type, data) in originalPasteboardContent {
                    guard NSPasteboard.general.setData(data, forType: type) == true else {
                        self.showNotification(text: "Cannot write \(type.rawValue)")
                        return
                    }
                }
                
                // Debug
                self.cgImage = image.cgImage
                print("done")
                
                NotificationCenter.default.post(name: .progressEnd, object: nil)
            }
        }
    }
    
    func showNotification(text: String) {
        print("Should display: \(text)")
        
        let content = UNMutableNotificationContent()
        content.title = "Visual Linker"
        content.subtitle = text

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
