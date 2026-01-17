//
//  ResultsListView.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import SwiftUI
import SwiftData

struct ResultsListView: View {
    let results: [RecordingResult] // Already filtered by LibraryView
    let searchText: String // Used for highlighting in ResultItemView
    let totalResultsCount: Int // Total count to determine if we show "no results" or "no matches"
    let onOpenDetail: (RecordingResult) -> Void
    let onLongPress: (RecordingResult) -> Void
    @Binding var isScrolling: Bool
    @State private var scrollTask: Task<Void, Never>?
    
    var body: some View {
        ScrollView {
            if totalResultsCount == 0 {
                // No cards at all
                EmptyResultsView()
            } else if results.isEmpty {
                // Cards exist but none match filter
                NoSearchResultsView()
            } else {
                VStack(spacing: 0) {
                    ForEach(results) { result in
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
                        
                        if result.id != results.last?.id {
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
        totalResultsCount: 0,
        onOpenDetail: { _ in },
        onLongPress: { _ in },
        isScrolling: .constant(false)
    )
}
