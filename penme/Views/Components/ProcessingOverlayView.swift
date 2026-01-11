//
//  ProcessingOverlayView.swift
//  PenMe
//
//  Created on 10/01/2026.
//

import SwiftUI

struct ProcessingOverlayView: View {
    @State private var pulseOpacity: Double = 0.5
    
    var body: some View {
        ZStack {
            // Transparent blurred backdrop
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Spinning progress indicator
                ProgressView()
                    .scaleEffect(2.0)
                    .tint(.blue)
                    .progressViewStyle(.circular)
                
                // Pulsating text
                Text("Running LLM Text Polishing...")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .opacity(pulseOpacity)
            }
        }
        .onAppear {
            // Start pulsating animation
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseOpacity = 1.0
            }
        }
    }
}

#Preview {
    ProcessingOverlayView()
}
