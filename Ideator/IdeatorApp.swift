//
//  IdeatorApp.swift
//  Ideator
//
//  Created by Adam Eivy on 8/11/25.
//

import SwiftUI

@main
struct IdeatorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
