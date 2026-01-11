//
//  DetailsViewModel.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import Foundation
import SwiftData
import Combine
import UIKit

@MainActor
class DetailsViewModel: ObservableObject {
    @Published var title: String
    @Published var polishedText: String
    
    private let result: RecordingResult
    private let modelContext: ModelContext
    
    init(result: RecordingResult, modelContext: ModelContext) {
        self.result = result
        self.modelContext = modelContext
        self.title = result.title
        self.polishedText = result.polishedText
    }
    
    func save() {
        result.title = title
        result.polishedText = polishedText
        do {
            try modelContext.save()
        } catch {
            print("Error saving edits: \(error)")
        }
    }
    
    func copyToClipboard() {
        UIPasteboard.general.string = polishedText
    }
    
    func share() -> [Any] {
        return [polishedText]
    }
    
    func delete() {
        modelContext.delete(result)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting result: \(error)")
        }
    }
}
