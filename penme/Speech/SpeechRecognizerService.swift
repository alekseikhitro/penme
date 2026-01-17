//
//  SpeechRecognizerService.swift
//  PenMe
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
    case noTranscript
    
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
        case .noTranscript:
            return "No speech detected"
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
    private var hasInstalledTap = false
    
    // Continuation for waiting on transcript result
    private var transcriptContinuation: CheckedContinuation<String?, Never>?
    
    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        speechRecognizer?.delegate = self
    }
    
    // MARK: - Public Methods
    
    /// Start recording and speech recognition
    func startRecording() async {
        // Prevent starting if already recording or processing
        guard case .idle = state else { return }
        
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
        
        // We want final results only (non-live transcription)
        recognitionRequest.shouldReportPartialResults = false
        
        // Enable on-device recognition if available (iOS 13+)
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
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
            cleanupAudioResources()
            return
        }
        
        // Start recognition task
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let error = error {
                    // Check if it's a cancellation (user cancelled)
                    let nsError = error as NSError
                    if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                        // User cancelled - just return nil
                        self.transcriptContinuation?.resume(returning: nil)
                        self.transcriptContinuation = nil
                        return
                    }
                    
                    // Real error
                    self.transcriptContinuation?.resume(returning: nil)
                    self.transcriptContinuation = nil
                    self.state = .error(SpeechRecognitionError.recognitionError(error))
                    return
                }
                
                if let result = result, result.isFinal {
                    let transcript = result.bestTranscription.formattedString
                    self.transcriptContinuation?.resume(returning: transcript)
                    self.transcriptContinuation = nil
                }
            }
        }
        
        // Start recording
        state = .recording
        recordingStartTime = Date()
        startTimer()
    }
    
    /// Stop recording and get the final transcript
    /// Returns the transcript string, or nil if cancelled/error
    func stopRecording() async -> String? {
        guard case .recording = state else { return nil }
        
        // Stop timer
        timer?.invalidate()
        timer = nil
        recordingStartTime = nil
        
        // Stop audio engine and remove tap first
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        
        // Signal end of audio to recognition request
        recognitionRequest?.endAudio()
        
        // Change state to processing while we wait for transcript
        state = .processing
        
        // Wait for the final transcript from the recognition task
        let transcript = await withCheckedContinuation { continuation in
            self.transcriptContinuation = continuation
            
            // Set a timeout - if no result in 5 seconds, return nil
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                if self.transcriptContinuation != nil {
                    self.transcriptContinuation?.resume(returning: nil)
                    self.transcriptContinuation = nil
                }
            }
        }
        
        // Cleanup
        recognitionRequest = nil
        recognitionTask = nil
        deactivateAudioSession()
        
        return transcript
    }
    
    /// Cancel recording without getting transcript
    func cancelRecording() {
        // Stop timer
        timer?.invalidate()
        timer = nil
        recordingStartTime = nil
        
        // Cancel the recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // End audio
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Clean up audio
        cleanupAudioResources()
        deactivateAudioSession()
        
        // Clear any pending continuation
        transcriptContinuation?.resume(returning: nil)
        transcriptContinuation = nil
        
        // Reset state
        state = .idle
    }
    
    // MARK: - Private Methods
    
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
            Task { @MainActor [weak self] in
                guard let self = self, let startTime = self.recordingStartTime else { return }
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func cleanupAudioResources() {
        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.reset()
    }
    
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Ignore deactivation errors
        }
    }
    
    nonisolated deinit {
        // Note: Can't access actor-isolated state in deinit
        // The cleanup will be handled by ARC
    }
}

extension SpeechRecognizerService: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            if !available, case .recording = self.state {
                self.cancelRecording()
                self.state = .error(SpeechRecognitionError.recognitionUnavailable)
            }
        }
    }
}
