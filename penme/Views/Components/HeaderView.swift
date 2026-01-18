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
    
    var body: some View {
        HStack(spacing: 12) {
            Text("PenMe")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            // Search field in the middle
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                ZStack(alignment: .leading) {
                    if searchText.isEmpty {
                        Text("Search")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .allowsHitTesting(false)
                    }
                    
                    TextField("", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .focused(isFocused)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                if !searchText.isEmpty {
                    Text("\(matchCount)/\(totalCount)")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        searchText = ""
                        isFocused.wrappedValue = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
            
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
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

struct HeaderPreview: View {
    @State private var searchText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            HeaderView(
                searchText: $searchText,
                isFocused: $isFocused,
                matchCount: 5,
                totalCount: 10
            )
            Spacer()
        }
    }
}

#Preview {
    HeaderPreview()
}
