//
//  LibraryView.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import SwiftUI
import SwiftData
import Combine

struct LibraryView: View {
    @Query(sort: \RecordingResult.createdAt, order: .reverse) private var results: [RecordingResult]
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var speechService = SpeechRecognizerService()
    private let polishService = PolishService()
    @StateObject private var mockTimer = MockRecordingTimer()
    
    @State private var showingPermissionAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var selectedResult: RecordingResult?
    @State private var resultToDelete: RecordingResult?
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var shareText = ""
    @State private var isScrolling = false
    @State private var showCopyNotification = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // Normalize text for search
    private func normalizeText(_ text: String) -> String {
        let components = text.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
    
    // Count of filtered results for search counter
    private var filteredResultsCount: Int {
        if searchText.isEmpty {
            return results.count
        }
        let lowercasedSearch = searchText.lowercased()
        return results.filter { result in
            result.title.lowercased().contains(lowercasedSearch) ||
            normalizeText(result.polishedText).lowercased().contains(lowercasedSearch)
        }.count
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemGray6), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            NavigationStack {
                VStack(spacing: 0) {
                    // Header
                    HeaderView(status: speechService.state)
                    
                    // Search field
                    SearchFieldView(
                        searchText: $searchText,
                        isFocused: $isSearchFocused,
                        matchCount: filteredResultsCount,
                        totalCount: results.count
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                    
                    // Results list
                    ResultsListView(
                        results: results,
                        searchText: searchText,
                        onOpenDetail: { result in
                            isSearchFocused = false // Dismiss keyboard
                            selectedResult = result
                        },
                        onLongPress: { result in
                            isSearchFocused = false // Dismiss keyboard
                            // Copy text to clipboard
                            UIPasteboard.general.string = result.polishedText
                            // Show notification
                            withAnimation {
                                showCopyNotification = true
                            }
                            // Hide notification after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    showCopyNotification = false
                                }
                            }
                        },
                        isScrolling: $isScrolling
                    )
                }
                .navigationDestination(item: $selectedResult) { result in
                    DetailsView(result: result)
                }
            }
            
            // Recording overlay
            if case .recording = speechService.state {
                RecordingOverlayView(
                    duration: mockTimer.duration,
                    onCancel: {
                        Task { @MainActor in
                            // Cancel recording - just stop and reset, don't create record
                            mockTimer.stop()
                            speechService.state = .idle
                        }
                    },
                    onStop: {
                        Task { @MainActor in
                            // Stop recording and complete - create record
                            stopMockRecording()
                        }
                    },
                    onRestart: {
                        // Restart recording from beginning - discard previous
                        Task { @MainActor in
                            mockTimer.stop()
                            speechService.state = .idle
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                            // Start fresh recording
                            speechService.state = .recording
                            mockTimer.start()
                        }
                    }
                )
                .zIndex(100)
                .transition(.opacity)
            }
            
            // Processing overlay
            if case .processing = speechService.state {
                ProcessingOverlayView()
                    .transition(.opacity)
            }
            
            // Copy notification (centered)
            if showCopyNotification {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("Text copied")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .transition(.scale.combined(with: .opacity))
                    Spacer()
                }
                .zIndex(200)
            }
            
                // Mic button (hidden when editing, scrolling, or processing)
                if selectedResult == nil {
                    if case .processing = speechService.state {
                        // Don't show mic button when processing
                    } else {
                        VStack {
                            Spacer()
                            MicButtonView(
                                isRecording: {
                                    if case .recording = speechService.state {
                                        return true
                                    }
                                    return false
                                }(),
                                onTap: {
                                    handleMicTap()
                                }
                            )
                            .offset(y: isScrolling ? 120 : 0)
                            .opacity(isScrolling ? 0 : 1)
                        }
                    }
                }
        }
        .alert("Permissions Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("PenMe needs microphone and speech recognition permissions to record and transcribe your voice. Please enable them in Settings.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Delete Recording", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                resultToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let result = resultToDelete {
                    modelContext.delete(result)
                    do {
                        try modelContext.save()
                    } catch {
                        print("Error deleting result: \(error)")
                    }
                    resultToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this recording? This action cannot be undone.")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareText])
        }
        .onChange(of: speechService.state) { oldValue, newValue in
            handleStateChange(newValue)
        }
        .onChange(of: isScrolling) { oldValue, newValue in
            // Dismiss keyboard when scrolling starts
            if newValue {
                isSearchFocused = false
            }
        }
    }
    
    private func handleMicTap() {
        // Dismiss keyboard
        isSearchFocused = false
        
        // Prevent multiple simultaneous recordings
        guard case .idle = speechService.state else {
            // If not idle, try to stop recording first
            if case .recording = speechService.state {
                stopMockRecording()
            }
            return
        }
        
        // Start recording - user controls when to stop
        Task { @MainActor in
            speechService.state = .recording
            mockTimer.start()
        }
    }
    
    private func stopMockRecording() {
        mockTimer.stop()
        speechService.state = .idle // Close recording screen first
        
        // Show processing screen, then handle transcript after delay
        Task { @MainActor in
            speechService.state = .processing
            
            // Wait 2 seconds to show processing screen
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Simulate completion with mocked transcript
            let mockTranscript = "mock transcript"
            handleTranscript(mockTranscript)
        }
    }
    
    private func handleStateChange(_ state: SpeechRecognitionState) {
        switch state {
        case .error(let error):
            // Reset state on error to allow retry
            Task { @MainActor in
                // Give it a moment, then reset
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                if case .error = speechService.state {
                    speechService.state = .idle
                }
            }
            
            if let speechError = error as? SpeechRecognitionError {
                switch speechError {
                case .permissionDenied:
                    showingPermissionAlert = true
                default:
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            } else {
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
            
        case .completed(let transcript):
            handleTranscript(transcript)
            
        default:
            break
        }
    }
    
    private func handleTranscript(_ transcript: String) {
        // Mock AI transformation - always return the same text
        let mockTitle = "Text tittle"
        let mockPolishedText = "Если хочешь, на следующем шаге можем сделать совсем конкретно: ты пишешь свою идею приложения (или 2–3 варианта), а я помогу её «разжать» в список экранов, коллекций данных и промптов, которые ты прям по шагам будешь копировать в Adalo и в чат со мной."
        
        createRecord(
            rawTranscript: transcript,
            title: mockTitle,
            polishedText: mockPolishedText
        )
    }
    
    private func createRecord(rawTranscript: String, title: String, polishedText: String) {
        let result = RecordingResult(
            rawTranscript: rawTranscript,
            title: title,
            polishedText: polishedText
        )
        modelContext.insert(result)
        
        do {
            try modelContext.save()
            // Open the newly created result immediately and clear recording state
            selectedResult = result
            speechService.state = .idle
        } catch {
            print("Error saving result: \(error)")
            speechService.state = .idle
        }
    }
    
    private func deleteResult(_ result: RecordingResult) {
        resultToDelete = result
        showingDeleteAlert = true
    }
    
    private func shareResult(_ result: RecordingResult) {
        shareText = result.polishedText
        showingShareSheet = true
    }
    
    private func copyResult(_ result: RecordingResult) {
        UIPasteboard.general.string = result.polishedText
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: RecordingResult.self, inMemory: true)
}
