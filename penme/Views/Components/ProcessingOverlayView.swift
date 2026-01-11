//
//  ProcessingOverlayView.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import SwiftUI

struct ProcessingOverlayView: View {
    let stages = [
        "Recognizing speech...",
        "Transforming to text...",
        "Structuring content...",
        "Polishing final result..."
    ]
    
    @State private var currentStage = 0
    
    var body: some View {
        ZStack {
            // Blurred backdrop
            Color.white.opacity(0.4)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Spinner
                ProgressView()
                    .scaleEffect(2.0)
                    .tint(.blue)
                    .progressViewStyle(.circular)
                
                // Current stage text
                Text(stages[currentStage])
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray)
                    .id(currentStage) // Force re-animation
                    .transition(.opacity.combined(with: .move(edge: .top)))
                
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<stages.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentStage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentStage)
                    }
                }
            }
        }
        .onAppear {
            startStageAnimation()
        }
    }
    
    private func startStageAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            withAnimation {
                if currentStage < stages.count - 1 {
                    currentStage += 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}

#Preview {
    ProcessingOverlayView()
}
