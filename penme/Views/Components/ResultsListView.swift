//
//  ResultsListView.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import SwiftUI
import SwiftData

struct ResultsListView: View {
    let results: [RecordingResult]
    let searchText: String
    let onOpenDetail: (RecordingResult) -> Void
    let onLongPress: (RecordingResult) -> Void
    @Binding var isScrolling: Bool
    @State private var scrollTask: Task<Void, Never>?
    
    // Normalize text - remove newlines and extra whitespace
    private func normalizeText(_ text: String) -> String {
        let components = text.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    // Filter results based on search text
    private var filteredResults: [RecordingResult] {
        if searchText.isEmpty {
            return results
        }
        let lowercasedSearch = searchText.lowercased()
        return results.filter { result in
            result.title.lowercased().contains(lowercasedSearch) ||
            normalizeText(result.polishedText).lowercased().contains(lowercasedSearch)
        }
    }
    
    var body: some View {
        ScrollView {
            if results.isEmpty {
                EmptyResultsView()
            } else if filteredResults.isEmpty {
                NoSearchResultsView()
            } else {
                VStack(spacing: 0) {
                    ForEach(filteredResults) { result in
                        ResultItemView(
                            result: result,
                            searchText: searchText,
                            onTap: {
                                onOpenDetail(result)
                            },
                            onLongPress: {
                                onLongPress(result)
                            }
                        )
                        
                        if result.id != filteredResults.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { value in
                    // Only trigger scrolling if there's actual vertical movement
                    let verticalMovement = abs(value.translation.height)
                    if verticalMovement > 5 {
                        handleScrollStart()
                    }
                }
                .onEnded { _ in
                    handleScrollEnd()
                }
        )
    }
    
    private func handleScrollStart() {
        // Cancel previous task
        scrollTask?.cancel()
        
        // Show scrolling state
        if !isScrolling {
            withAnimation(.easeInOut(duration: 0.2)) {
                isScrolling = true
            }
        }
    }
    
    private func handleScrollEnd() {
        // Cancel previous task
        scrollTask?.cancel()
        
        // Set task to show button after scrolling stops
        scrollTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds delay
            
            if !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isScrolling = false
                }
            }
        }
    }
}

struct EmptyResultsView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("No results yet")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            Text("Tap the microphone to start recording")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 48)
    }
}

struct NoSearchResultsView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            Text("No notes found")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 48)
    }
}

#Preview {
    ResultsListView(
        results: [],
        searchText: "",
        onOpenDetail: { _ in },
        onLongPress: { _ in },
        isScrolling: .constant(false)
    )
}
