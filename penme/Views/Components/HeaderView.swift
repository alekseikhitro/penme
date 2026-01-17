//
//  HeaderView.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import SwiftUI

struct HeaderView: View {
    let status: SpeechRecognitionState
    
    var statusMessage: String {
        switch status {
        case .idle:
            return "Ready"
        case .requestingPermission:
            return "Requesting permissions..."
        case .recording:
            return "Listening…"
        case .processing:
            return "Polishing…"
        case .completed:
            return "Ready"
        case .error:
            return "Error — try again"
        }
    }
    
    var statusColor: Color {
        switch status {
        case .idle:
            return .gray
        case .requestingPermission:
            return .orange
        case .recording:
            return .blue
        case .processing:
            return .purple
        case .completed:
            return .gray
        case .error:
            return .red
        }
    }
    
    var shouldShowStatus: Bool {
        switch status {
        case .idle, .completed, .recording:
            return false
        default:
            return true
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("PenMe")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Settings button (placeholder for future)
                Button(action: {}) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            if shouldShowStatus {
                Text(statusMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(statusColor)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

#Preview {
    VStack {
        HeaderView(status: .idle)
        HeaderView(status: .recording)
        HeaderView(status: .processing)
    }
}
