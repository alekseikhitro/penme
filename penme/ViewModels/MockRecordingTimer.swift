//
//  MockRecordingTimer.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import Foundation
import Combine

@MainActor
class MockRecordingTimer: ObservableObject {
    @Published var duration: TimeInterval = 0
    
    private var timer: Timer?
    private var startTime: Date?
    
    func start() {
        stop()
        startTime = Date()
        duration = 0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            // Ensure timer updates on the main thread
            RunLoop.main.perform {
                guard let self = self, let startTime = self.startTime else { return }
                self.duration = Date().timeIntervalSince(startTime)
            }
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        startTime = nil
        duration = 0
    }
    
    nonisolated func stopNonisolated() {
        Task { @MainActor in
            self.stop()
        }
    }
    
    deinit {
        stopNonisolated()
    }
}
