//
//  DetailsView.swift
//  PenAI
//
//  Created on 10/01/2026.
//

import SwiftUI
import SwiftData
import UIKit

struct DetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var polishedText: String
    @State private var label: String?
    @State private var showingDeleteConfirmation = false
    @State private var showingShareSheet = false
    @State private var isEditingLabel = false
    @State private var labelText = ""
    @State private var showCopyNotification = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isTextFocused: Bool
    @FocusState private var isLabelFocused: Bool
    
    let result: RecordingResult
    var onDelete: ((String) -> Void)?
    
    // Get unique labels from all cards
    init(result: RecordingResult, onDelete: ((String) -> Void)? = nil) {
        self.result = result
        self.onDelete = onDelete
        _title = State(initialValue: result.title)
        _polishedText = State(initialValue: result.polishedText)
        _label = State(initialValue: result.label)
    }
    
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        if Calendar.current.isDateInToday(result.createdAt) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter.string(from: result.createdAt)
        } else {
            formatter.dateStyle = .none
            formatter.timeStyle = .none
            formatter.setLocalizedDateFormatFromTemplate("MMMd")
            return formatter.string(from: result.createdAt)
        }
    }
    
    var body: some View {
        ZStack {
            // Blurred background
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back icon, timestamp, and delete icon (swipeable area)
                HStack(alignment: .center, spacing: 12) {
                    // Back button
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(.darkGray))
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    // Timestamp (centered)
                    Text(formattedTimestamp)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(.darkGray))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    
                    Spacer()
                    
                    // Delete button
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(.darkGray))
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .background(
                    // Swipeable area in header
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .onChanged { value in
                                    if value.translation.height > 0 {
                                        isDragging = true
                                        dragOffset = value.translation.height
                                    }
                                }
                                .onEnded { value in
                                    isDragging = false
                                    if value.translation.height > 100 || (value.translation.height > 50 && abs(value.velocity.height) > 500) {
                                        dismiss()
                                    } else {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                )
                
                // Card container with title and text
                VStack(spacing: 0) {
                    // Title (single line, unscrollable)
                    TextField("Title", text: $title)
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .focused($isTitleFocused)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    
                    // Separator line
                    Divider()
                        .padding(.horizontal, 16)
                    
                    // Text content with label overlay
                    ZStack(alignment: .bottomTrailing) {
                        // Text content (flexible, takes all available space)
                        TextEditor(text: $polishedText)
                            .font(.system(size: 15))
                            .foregroundColor(Color(.darkGray))
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .focused($isTextFocused)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 28) // Space for label button
                        
                        // Label area at bottom right
                        HStack {
                            Spacer()
                            if isEditingLabel {
                                // Inline text field for label
                                HStack(spacing: 4) {
                                    TextField("Label", text: $labelText)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($isLabelFocused)
                                        .frame(minWidth: 60, maxWidth: 120)
                                        .onSubmit {
                                            saveLabel()
                                        }
                                        .onChange(of: labelText) { _, newValue in
                                            // Limit to 15 characters
                                            if newValue.count > 15 {
                                                labelText = String(newValue.prefix(15))
                                            }
                                        }
                                    
                                    Button(action: {
                                        saveLabel()
                                    }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [Color.blue, Color.purple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            } else if let currentLabel = label {
                                // Show current label with remove button
                                HStack(spacing: 4) {
                                    Button(action: {
                                        labelText = currentLabel
                                        isEditingLabel = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            isLabelFocused = true
                                        }
                                    }) {
                                        Text(currentLabel)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button(action: {
                                        label = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            } else {
                                // Show add label button
                                Button(action: {
                                    labelText = ""
                                    isEditingLabel = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isLabelFocused = true
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 12, weight: .medium))
                                        Text("Add label")
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .background(
                            // Gradient fade from white to transparent
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(height: 50)
                            .allowsHitTesting(false),
                            alignment: .bottom
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                // Footer actions
                HStack(spacing: 12) {
                    // Copy button (first)
                    ActionButton(
                        icon: "doc.on.doc",
                        label: "Copy",
                        action: {
                            UIPasteboard.general.string = polishedText
                            withAnimation {
                                showCopyNotification = true
                            }
                            // Hide notification after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation {
                                    showCopyNotification = false
                                }
                            }
                        }
                    )
                    
                    // Share button (second)
                    ActionButton(
                        icon: "square.and.arrow.up",
                        label: "Share",
                        action: {
                            showingShareSheet = true
                        }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
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
            }
        }
        .navigationBarBackButtonHidden(true)
        .offset(y: dragOffset)
        .alert(Text("Delete \"") + Text(result.title).bold() + Text("\"?"), isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                delete()
                dismiss()
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [polishedText])
        }
        .onDisappear {
            save()
        }
        .onChange(of: isLabelFocused) { oldValue, newValue in
            // Save label when focus is lost (tapped outside)
            if oldValue == true && newValue == false && isEditingLabel {
                saveLabel()
            }
        }
    }
    
    private func save() {
        result.title = title
        result.polishedText = polishedText
        result.label = label
        do {
            try modelContext.save()
        } catch {
            print("Error saving edits: \(error)")
        }
    }
    
    private func saveLabel() {
        let trimmed = labelText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            label = trimmed
        }
        isEditingLabel = false
        isLabelFocused = false
    }
    
    private func delete() {
        let titleToNotify = result.title
        modelContext.delete(result)
        do {
            try modelContext.save()
            onDelete?(titleToNotify)
        } catch {
            print("Error deleting result: \(error)")
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(label)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(Color(.darkGray))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        // For iPad
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIView()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

#Preview {
    NavigationStack {
        DetailsView(result: RecordingResult(
            rawTranscript: "This is a test transcript",
            title: "Test Title",
            polishedText: "This is polished text"
        ))
    }
    .modelContainer(for: RecordingResult.self, inMemory: true)
}
