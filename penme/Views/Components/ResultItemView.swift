//
//  ResultItemView.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import SwiftUI

struct ResultItemView: View {
    let result: RecordingResult
    let searchText: String
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @State private var isPressed = false
    @State private var showCopyHighlight = false
    
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
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(showCopyHighlight ? Color.green.opacity(0.15) : (isPressed ? Color(.systemGray4).opacity(0.5) : Color.clear))
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: showCopyHighlight)
        .contentShape(Rectangle())
        .onTapGesture {
            // Brief tap highlight
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                onTap()
            }
        }
        .onLongPressGesture(minimumDuration: 0.5, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Show green highlight for copy action
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = false
                showCopyHighlight = true
            }
            
            // Hide highlight after a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showCopyHighlight = false
                }
            }
            
            onLongPress()
        })
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
            searchText: "",
            onTap: {},
            onLongPress: {}
        )
    }
}
