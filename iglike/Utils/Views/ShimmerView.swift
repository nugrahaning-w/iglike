//
//  ShimmerView.swift
//  iglike
//
//  Created by Aji Nugrahaning WIdhi on 24/04/25.
//

import SwiftUI

struct ShimmerView: View {
    @State private var phase: CGFloat = -UIScreen.main.bounds.width

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1), Color.gray.opacity(0.3)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.2), Color.black, Color.black.opacity(0.4)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase)
            )
            .background(Color.white)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = UIScreen.main.bounds.width * 2
                }
            }
            .clipped()
    }
}
