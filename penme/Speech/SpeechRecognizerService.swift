//
//  SpeechRecognizerService.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import Foundation
import Speech
import AVFoundation
import Combine

enum SpeechRecognitionState: Equatable {
    case idle
    case requestingPermission
    case recording
    case processing
    case completed(String)
    case error(Error)
    
    static func == (lhs: SpeechRecognitionState, rhs: SpeechRecognitionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.requestingPermission, .requestingPermission),
             (.recording, .recording),
             (.processing, .processing):
            return true
        case (.completed(let lhsText), .completed(let rhsText)):
            return lhsText == rhsText
        case (.error, .error):
            // For error cases, just check if both are errors (don't compare Error values)
            return true
        default:
            return false
        }
    }
}

enum SpeechRecognitionError: LocalizedError {
    case permissionDenied
    case recognitionUnavailable
    case audioEngineError(Error)
    case recognitionError(Error)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Speech recognition permission denied"
        case .recognitionUnavailable:
            return "Speech recognition unavailable"
        case .audioEngineError(let error):
            return "Audio engine error: \(error.localizedDescription)"
        case .recognitionError(let error):
            return "Recognition error: \(error.localizedDescription)"
        }
    }
}

@MainActor
class SpeechRecognizerService: NSObject, ObservableObject {
    @Published var state: SpeechRecognitionState = .idle
    @Published var recordingDuration: TimeInterval = 0
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var recordingStartTime: Date?
    private var timer: Timer?
    private var isStopping = false
    private var hasInstalledTap = false
    
    override init() {
        super.init()
        
        // Use device locale for recognition
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        speechRecognizer?.delegate = self
    }
    
    func startRecording() async {
        // Prevent starting if already recording or processing
        guard case .idle = state else {
            return
        }
        
        // Reset state
        recordingDuration = 0
        
        // Check availability
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            state = .error(SpeechRecognitionError.recognitionUnavailable)
            return
        }
        
        // Request permissions
        state = .requestingPermission
        
        let authStatus = await requestPermissions()
        guard authStatus else {
            state = .error(SpeechRecognitionError.permissionDenied)
            return
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            state = .error(SpeechRecognitionError.audioEngineError(error))
            return
        }
        
        // Cancel previous task if exists
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            state = .error(SpeechRecognitionError.recognitionUnavailable)
            return
        }
        
        recognitionRequest.shouldReportPartialResults = false
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        hasInstalledTap = true
        
        // Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            state = .error(SpeechRecognitionError.audioEngineError(error))
            if hasInstalledTap {
                inputNode.removeTap(onBus: 0)
                hasInstalledTap = false
            }
            return
        }
        
        // Start recognition
        state = .recording
        recordingStartTime = Date()
        startTimer()
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
                    self.stopRecording()
                    self.state = .error(SpeechRecognitionError.recognitionError(error))
                }
                return
            }
            
            if let result = result, result.isFinal {
                let transcript = result.bestTranscription.formattedString
                Task { @MainActor in
                    self.stopRecording()
                    self.state = .completed(transcript)
                }
            }
        }
    }
    
    func stopRecording() {
        // Prevent multiple simultaneous stop calls
        guard !isStopping else { return }
        isStopping = true
        defer { 
            isStopping = false
            // Always reset to idle after stopping
            if case .recording = state {
                state = .idle
            } else if case .processing = state {
                state = .idle
            }
        }
        
        // Stop timer first
        timer?.invalidate()
        timer = nil
        recordingStartTime = nil
        
        // Cancel recognition task first to stop processing
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // End the recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Safely remove tap and stop engine
        if hasInstalledTap {
            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        
        // Stop and reset audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.reset()
        
        // Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Ignore deactivation errors
        }
    }
    
    private func requestPermissions() async -> Bool {
        let micStatus = AVAudioSession.sharedInstance().recordPermission
        
        if micStatus == .denied {
            return false
        }
        
        if micStatus == .undetermined {
            let micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            if !micGranted {
                return false
            }
        }
        
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        return speechStatus == .authorized
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            // Since class is @MainActor, this is already on main thread
            self.recordingDuration = Date().timeIntervalSince(startTime)
        }
        // Ensure timer is on main run loop
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    deinit {
        // Clean up synchronously - timer and audio engine cleanup
        timer?.invalidate()
        timer = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

extension SpeechRecognizerService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available, case .recording = state {
            Task { @MainActor in
                stopRecording()
                state = .error(SpeechRecognitionError.recognitionUnavailable)
            }
        }
    }
}
