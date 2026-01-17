//
//  SearchFieldView.swift
//  PenMe
//
//  Created on 17/01/2026.
//

import SwiftUI

struct SearchFieldView: View {
    @Binding var searchText: String
    var isFocused: FocusState<Bool>.Binding
    var matchCount: Int
    var totalCount: Int
    
    var body: some View {
        HStack(spacing: 8) {
            // Search icon (always visible)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            // Text field with placeholder
            ZStack(alignment: .leading) {
                // Placeholder (visible when empty)
                if searchText.isEmpty {
                    Text("Search")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                        .allowsHitTesting(false) // Allow taps to pass through to TextField
                }
                
                // Actual text field
                TextField("", text: $searchText)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                    .focused(isFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            
            Spacer()
            
            // Results counter (visible when searching)
            if !searchText.isEmpty {
                Text("\(matchCount)/\(totalCount)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .transition(.opacity)
            }
            
            // Clear button (visible when there's text)
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    isFocused.wrappedValue = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
    }
}

struct SearchFieldPreview: View {
    @State private var text1 = ""
    @State private var text2 = "Hello"
    @FocusState private var focus1: Bool
    @FocusState private var focus2: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            SearchFieldView(searchText: $text1, isFocused: $focus1, matchCount: 0, totalCount: 10)
            SearchFieldView(searchText: $text2, isFocused: $focus2, matchCount: 3, totalCount: 25)
        }
        .padding()
    }
}

#Preview {
    SearchFieldPreview()
}
