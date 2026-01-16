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
    let onOpenDetail: (RecordingResult) -> Void
    @Binding var isScrolling: Bool
    @State private var scrollTask: Task<Void, Never>?
    
    var body: some View {
        ScrollView {
            if results.isEmpty {
                EmptyResultsView()
            } else {
                VStack(spacing: 0) {
                    ForEach(results) { result in
                        ResultItemView(
                            result: result,
                            onTap: {
                                onOpenDetail(result)
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
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    handleScrollStart()
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
        
        // Set task to hide button when scrolling stops
        scrollTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds delay
            
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

#Preview {
    ResultsListView(
        results: [],
        onOpenDetail: { _ in },
        isScrolling: .constant(false)
    )
}
