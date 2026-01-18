//
//  HeaderView.swift
//  PenMe
//
//  Created on 10/01/2026.
//

import SwiftUI

struct HeaderView: View {
    @Binding var searchText: String
    var isFocused: FocusState<Bool>.Binding
    var matchCount: Int
    var totalCount: Int
    @Binding var isScrolling: Bool
    
    // Separate state to control expansion (allows TextField to render before focusing)
    @State private var isSearchActive: Bool = false
    
    // Search is expanded when active OR has text
    private var isExpanded: Bool {
        isSearchActive || !searchText.isEmpty
    }
    
    var body: some View {
        ZStack {
            // Center: PenMe text (stays static, gets covered by search)
            Text("PenMe")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            // Left and Right controls
            HStack(spacing: 16) {
                // Left: Search circle OR expanded search field
                if isExpanded {
                    // Expanded search field
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        ZStack(alignment: .leading) {
                            if searchText.isEmpty {
                                Text("Search")
                                    .font(.system(size: 17))
                                    .foregroundColor(.gray)
                                    .allowsHitTesting(false)
                            }
                            
                            TextField("", text: $searchText)
                                .font(.system(size: 17))
                                .foregroundColor(.primary)
                                .focused(isFocused)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        
                        Spacer()
                        
                        if !searchText.isEmpty {
                            Text("\(matchCount)/\(totalCount)")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                searchText = ""
                                // Keep focus so user can type new search
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .leading)),
                        removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .leading))
                    ))
                    .onAppear {
                        // Focus the TextField after it appears
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isFocused.wrappedValue = true
                        }
                    }
                } else {
                    // Collapsed: Search circle button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSearchActive = true
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .frame(width: 40, height: 40)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8)),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
                    
                    Spacer()
                }
                
                // Right: Settings button (always visible)
                Button(action: {}) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
        .onChange(of: isFocused.wrappedValue) { _, newValue in
            // Collapse when focus is lost AND text is empty
            if !newValue && searchText.isEmpty {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isSearchActive = false
                }
            }
        }
        .onChange(of: isScrolling) { _, newValue in
            // Collapse when user starts scrolling AND text is empty
            if newValue && searchText.isEmpty {
                isFocused.wrappedValue = false
                withAnimation(.easeInOut(duration: 0.25)) {
                    isSearchActive = false
                }
            }
        }
    }
}

struct HeaderPreview: View {
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    @State private var isScrolling = false
    
    var body: some View {
        VStack {
            HeaderView(
                searchText: $searchText,
                isFocused: $isFocused,
                matchCount: 5,
                totalCount: 10,
                isScrolling: $isScrolling
            )
            Spacer()
        }
    }
}

#Preview {
    HeaderPreview()
}
