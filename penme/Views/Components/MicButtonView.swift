//
//  MicButtonView.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import SwiftUI

struct MicButtonView: View {
    let isRecording: Bool
    let onTap: () -> Void
    @State private var pulseScale: CGFloat = 1.0
    @State private var isVisible = true
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: onTap) {
                    ZStack {
                        // Gradient background
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .shadow(color: isRecording ? Color.blue.opacity(0.5) : Color.blue.opacity(0.3), radius: 20, x: 0, y: 10)
                        .scaleEffect(pulseScale)
                        
                        // Icon
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: isRecording ? 32 : 36, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: isRecording ? 0.8 : 1.5).repeatForever(autoreverses: true), value: pulseScale)
                .onAppear {
                    pulseScale = isRecording ? 1.15 : 1.05
                }
                .onChange(of: isRecording) { _, newValue in
                    withAnimation {
                        pulseScale = newValue ? 1.15 : 1.05
                    }
                }
                
                Spacer()
            }
            .padding(.bottom, 40)
        }
        .allowsHitTesting(isVisible)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
        MicButtonView(isRecording: false) {}
        MicButtonView(isRecording: true) {}
    }
}
