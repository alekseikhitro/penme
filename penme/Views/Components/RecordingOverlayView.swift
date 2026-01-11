//
//  RecordingOverlayView.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import SwiftUI

struct StopButtonView: View {
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.purple, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 90, height: 90)
            .clipShape(Circle())
            .shadow(color: Color.blue.opacity(0.4), radius: 20, x: 0, y: 10)
            .scaleEffect(pulseScale)
            
            // Pulsating ring
            Circle()
                .stroke(Color.white.opacity(pulseOpacity), lineWidth: 3)
                .frame(width: 90, height: 90)
                .scaleEffect(pulseScale * 1.3)
            
            // Stop icon
            Image(systemName: "stop.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.white)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.12
                pulseOpacity = 0.5
            }
        }
    }
}

struct RecordingOverlayView: View {
    let duration: TimeInterval
    let onCancel: () -> Void
    let onStop: () -> Void
    let onRestart: () -> Void
    @State private var showCancelDialog = false
    @State private var showRestartDialog = false
    
    var body: some View {
        ZStack {
            // Blurred backdrop showing main screen
            Color.clear
                .background(.thinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button (top right)
                HStack {
                    Spacer()
                    Button(action: { showCancelDialog = true }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                
                Spacer()
                
                // Main recording content
                VStack(spacing: 32) {
                    // "Recording in progress" text
                    Text("Recording in progress")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.black)
                    
                    // Timer display
                    Text(formatTime(duration))
                        .font(.system(size: 48, weight: .semibold, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    // Restart button
                    Button(action: { showRestartDialog = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 18, weight: .medium))
                            Text("Restart recording")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
                
                Spacer()
                
                // Stop button at bottom
                Button(action: onStop) {
                    StopButtonView()
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
            
            // Cancel dialog
            .alert("Cancel recording?", isPresented: $showCancelDialog) {
                Button("Yes", role: .destructive) {
                    onCancel()
                }
                Button("No", role: .cancel) { }
            } message: {
                Text("Recorded progress won't be saved. Cancel the recording?")
            }
            
            // Restart dialog
            .alert("Restart recording?", isPresented: $showRestartDialog) {
                Button("Yes", role: .destructive) {
                    onRestart()
                }
                Button("No", role: .cancel) { }
            } message: {
                Text("Recorded progress won't be saved. Restart the recording?")
            }
        }
    }
    
    private func formatTime(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 100)
        
        return String(format: "%02d:%02d:%02d.%02d", hours, minutes, seconds, milliseconds)
    }
}

#Preview {
    RecordingOverlayView(
        duration: 11.97,
        onCancel: {},
        onStop: {},
        onRestart: {}
    )
}
