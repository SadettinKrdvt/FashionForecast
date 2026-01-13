//
//  Extensions.swift
//  Fashion Forecast
//
//  Genel yardımcı fonksiyonlar ve UI eklentileri.
//

import SwiftUI

// MARK: - Haptic Feedback Helper (Titreşim)
func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    let impact = UIImpactFeedbackGenerator(style: style)
    impact.impactOccurred()
}

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Shapes
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
