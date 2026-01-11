//
//  penmeApp.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import SwiftUI
import SwiftData

@main
struct PenAIApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            RecordingResult.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            LibraryView()
        }
        .modelContainer(sharedModelContainer)
    }
}
