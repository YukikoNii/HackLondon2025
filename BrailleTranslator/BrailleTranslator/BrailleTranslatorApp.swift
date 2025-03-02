//
//  BrailleTranslatorApp.swift
//  BrailleTranslator
//
//  Created by Yukiko Nii on 2025/03/01.
//

import SwiftUI

@main
struct BrailleTranslatorApp: App {
    init () {
        printBundleContents()
        configureAudioSession()

    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    func printBundleContents() {
        if let bundleURL = Bundle.main.resourceURL {
            print("Bundle Resource URL: \(bundleURL)")
            let fileManager = FileManager.default
            if let enumerator = fileManager.enumerator(at: bundleURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
                for case let fileURL as URL in enumerator {
                    print("File: \(fileURL.lastPathComponent) at \(fileURL.path)")
                }
            } else {
                print("Failed to enumerate bundle contents")
            }
        } else {
            print("Failed to get bundle resource URL")
        }
    }

}
