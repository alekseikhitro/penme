//
//  LabelPanelView.swift
//  PenMe
//
//  Created on 17/01/2026.
//

import SwiftUI

struct LabelPanelView: View {
    let labels: [String] // Unique labels from all cards
    let labelCounts: [String: Int] // Count of cards per label
    let totalCount: Int // Total cards count (for "All")
    @Binding var selectedLabel: String? // nil means "All" is selected
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" label (always first)
                LabelChip(
                    name: "All",
                    count: totalCount,
                    isSelected: selectedLabel == nil,
                    onTap: {
                        selectedLabel = nil
                    }
                )
                
                // Other labels
                ForEach(labels, id: \.self) { label in
                    LabelChip(
                        name: label,
                        count: labelCounts[label] ?? 0,
                        isSelected: selectedLabel == label,
                        onTap: {
                            if selectedLabel == label {
                                // Tap on selected label -> select "All"
                                selectedLabel = nil
                            } else {
                                selectedLabel = label
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

struct LabelChip: View {
    let name: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                // Count badge
                Text("\(count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.5))
                    )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color(.systemGray5) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        LabelPanelView(
            labels: ["VibeCoding", "Personal", "Flows"],
            labelCounts: ["VibeCoding": 1, "Personal": 1, "Flows": 3],
            totalCount: 5,
            selectedLabel: .constant(nil)
        )
        
        LabelPanelView(
            labels: ["VibeCoding", "Personal", "Flows"],
            labelCounts: ["VibeCoding": 1, "Personal": 1, "Flows": 3],
            totalCount: 5,
            selectedLabel: .constant("VibeCoding")
        )
    }
}
