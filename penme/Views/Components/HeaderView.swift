//
//  HeaderView.swift
//  PenMe
//
//  Created on 10/01/2026.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
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
    }
}

#Preview {
    HeaderView()
}
