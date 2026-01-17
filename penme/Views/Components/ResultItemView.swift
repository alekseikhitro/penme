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
    
    // Check if search matches in the text content (not just title)
    private var hasTextMatch: Bool {
        guard !searchText.isEmpty else { return false }
        let normalizedText = normalizeText(result.polishedText)
        return normalizedText.localizedCaseInsensitiveContains(searchText)
    }
    
    // Check if search matches in the title
    private var hasTitleMatch: Bool {
        guard !searchText.isEmpty else { return false }
        return result.title.localizedCaseInsensitiveContains(searchText)
    }
    
    // Build highlighted title
    @ViewBuilder
    private var highlightedTitle: some View {
        if hasTitleMatch {
            highlightedText(result.title, search: searchText, baseColor: .primary, isBold: true)
        } else {
            Text(result.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
    
    // Build preview text with context around match
    @ViewBuilder
    private var previewContent: some View {
        if hasTextMatch {
            highlightedPreviewWithContext
        } else {
            Text(previewText)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
    }
    
    // Normalize text - remove newlines and extra whitespace
    private func normalizeText(_ text: String) -> String {
        // Replace newlines and multiple spaces with single space
        let components = text.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    // Compute context text with ellipsis around the match
    // Shows match at the beginning of 2nd row (~45 chars before match for 1 row)
    // Total ~180 chars for 4 rows - always tries to show 4 full rows if text is long enough
    private func getContextAroundMatch() -> String? {
        // Normalize text first - remove line breaks and extra whitespace
        let text = normalizeText(result.polishedText)
        let searchLower = searchText.lowercased()
        let textLower = text.lowercased()
        
        guard let range = textLower.range(of: searchLower) else { return nil }
        
        let matchStart = text.distance(from: text.startIndex, to: range.lowerBound)
        let textLength = text.count
        
        // Approximately 45 chars per row, we want match at start of 2nd row
        // So show ~45 chars before match (1 row), unless match is near the beginning
        let charsBeforeMatch = 45
        let totalChars = 180 // ~4 rows worth of text
        
        var startPos: Int
        var endPos: Int
        
        // First, try to position match at start of 2nd row
        if matchStart <= charsBeforeMatch {
            // Match is near the beginning, start from 0
            startPos = 0
        } else {
            // Position match at start of 2nd row
            startPos = matchStart - charsBeforeMatch
        }
        
        // Calculate end position
        endPos = min(textLength, startPos + totalChars)
        
        // If we can't show 4 full rows after startPos, adjust startPos backwards
        // to ensure we show as much content as possible (up to 4 rows)
        let actualContentLength = endPos - startPos
        if actualContentLength < totalChars && textLength >= totalChars {
            // We have enough text but not showing 4 full rows
            // Move startPos back to show more content before the match
            startPos = max(0, textLength - totalChars)
            endPos = textLength
        } else if actualContentLength < totalChars && startPos > 0 {
            // Text is shorter than 4 rows but we're not starting from beginning
            // Move startPos back as much as possible
            let additionalNeeded = totalChars - actualContentLength
            let canMoveBack = min(startPos, additionalNeeded)
            startPos = startPos - canMoveBack
        }
        
        let startIndex = text.index(text.startIndex, offsetBy: startPos)
        let endIndex = text.index(text.startIndex, offsetBy: endPos)
        
        // Extract context
        var contextText = String(text[startIndex..<endIndex])
        
        // Add ellipsis
        if startPos > 0 {
            contextText = "..." + contextText
        }
        if endPos < textLength {
            contextText = contextText + "..."
        }
        
        return contextText
    }
    
    // Create preview with "..." context around the match
    @ViewBuilder
    private var highlightedPreviewWithContext: some View {
        if let contextText = getContextAroundMatch() {
            highlightedText(contextText, search: searchText, baseColor: .secondary, isBold: false)
        } else {
            Text(previewText)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
    }
    
    // Helper to create highlighted text
    private func highlightedText(_ text: String, search: String, baseColor: Color, isBold: Bool) -> some View {
        let parts = splitTextBySearch(text: text, search: search)
        
        return parts.reduce(Text("")) { result, part in
            if part.isMatch {
                return result + Text(part.text)
                    .font(.system(size: isBold ? 17 : 15, weight: .bold))
                    .foregroundColor(.orange)
            } else {
                return result + Text(part.text)
                    .font(.system(size: isBold ? 17 : 15, weight: isBold ? .semibold : .regular))
                    .foregroundColor(baseColor)
            }
        }
        .lineLimit(isBold ? 1 : 4)
        .multilineTextAlignment(.leading)
    }
    
    // Split text into parts (matched and non-matched)
    private func splitTextBySearch(text: String, search: String) -> [(text: String, isMatch: Bool)] {
        guard !search.isEmpty else { return [(text: text, isMatch: false)] }
        
        var parts: [(text: String, isMatch: Bool)] = []
        let textLower = text.lowercased()
        let searchLower = search.lowercased()
        
        var currentIndex = text.startIndex
        var currentIndexLower = textLower.startIndex
        
        while currentIndexLower < textLower.endIndex {
            // Find next match in lowercased string
            let searchRange = currentIndexLower..<textLower.endIndex
            if let matchRange = textLower.range(of: searchLower, range: searchRange) {
                // Calculate offset to convert between strings
                let offsetToMatch = textLower.distance(from: currentIndexLower, to: matchRange.lowerBound)
                let matchLength = search.count
                
                // Get corresponding indices in original string
                let matchStartInOriginal = text.index(currentIndex, offsetBy: offsetToMatch)
                let matchEndInOriginal = text.index(matchStartInOriginal, offsetBy: matchLength)
                
                // Add non-matching part before the match
                if currentIndex < matchStartInOriginal {
                    let beforeMatch = String(text[currentIndex..<matchStartInOriginal])
                    parts.append((text: beforeMatch, isMatch: false))
                }
                
                // Add the matching part (preserve original case)
                let matchText = String(text[matchStartInOriginal..<matchEndInOriginal])
                parts.append((text: matchText, isMatch: true))
                
                // Move indices forward
                currentIndex = matchEndInOriginal
                currentIndexLower = textLower.index(matchRange.lowerBound, offsetBy: matchLength)
            } else {
                // No more matches, add the rest
                if currentIndex < text.endIndex {
                    let rest = String(text[currentIndex...])
                    parts.append((text: rest, isMatch: false))
                }
                break
            }
        }
        
        return parts
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and timestamp in the same row
            HStack(alignment: .center, spacing: 12) {
                highlightedTitle
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                
                Text(formattedTimestamp)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            // Text preview (with context if searching)
            previewContent
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
    VStack(spacing: 0) {
        // Without search
        ResultItemView(
            result: RecordingResult(
                rawTranscript: "Test",
                title: "Meeting Notes",
                polishedText: "This is a test note with some important text that should demonstrate the search highlighting feature when searching."
            ),
            searchText: "",
            onTap: {},
            onLongPress: {}
        )
        
        Divider()
        
        // With search matching in text
        ResultItemView(
            result: RecordingResult(
                rawTranscript: "Test",
                title: "Meeting Notes",
                polishedText: "This is a test note with some important text that should demonstrate the search highlighting feature when searching."
            ),
            searchText: "important",
            onTap: {},
            onLongPress: {}
        )
        
        Divider()
        
        // With search matching in title
        ResultItemView(
            result: RecordingResult(
                rawTranscript: "Test",
                title: "Important Meeting Notes",
                polishedText: "This is a test note with some text."
            ),
            searchText: "important",
            onTap: {},
            onLongPress: {}
        )
    }
}
