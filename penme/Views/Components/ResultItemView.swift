//
//  ResultItemView.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import SwiftUI

struct ResultItemView: View {
    let result: RecordingResult
    let onTap: () -> Void
    
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        if Calendar.current.isDateInToday(result.createdAt) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter.string(from: result.createdAt)
        } else {
            formatter.dateStyle = .none
            formatter.timeStyle = .none
            formatter.setLocalizedDateFormatFromTemplate("MMMd")
            return formatter.string(from: result.createdAt)
        }
    }
    
    private var previewText: String {
        let lines = result.polishedText.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return lines.first ?? result.polishedText
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Title and timestamp in the same row
                HStack(alignment: .center, spacing: 12) {
                    Text(result.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    Text(formattedTimestamp)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // Text preview
                Text(previewText)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    List {
        ResultItemView(
            result: RecordingResult(
                rawTranscript: "Test",
                title: "This is a very long title that should be truncated if it doesn't fit on the screen",
                polishedText: "This is a test note with some text that should be truncated if it's too long."
            ),
            onTap: {}
        )
    }
}
