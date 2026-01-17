//
//  RecordingResult.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import Foundation
import SwiftData

@Model
final class RecordingResult {
    var id: UUID
    var createdAt: Date
    var rawTranscript: String
    var title: String
    var polishedText: String
    var label: String?
    
    init(id: UUID = UUID(), createdAt: Date = Date(), rawTranscript: String, title: String, polishedText: String, label: String? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.rawTranscript = rawTranscript
        self.title = title
        self.polishedText = polishedText
        self.label = label
    }
}
