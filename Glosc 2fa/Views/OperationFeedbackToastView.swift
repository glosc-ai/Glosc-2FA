//
//  OperationFeedbackToastView.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import SwiftUI

struct OperationFeedbackToastView: View {
    let feedback: OperationFeedback

    var body: some View {
        Label(feedback.message, systemImage: feedback.symbolName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(backgroundStyle, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            .accessibilityIdentifier(feedback.accessibilityIdentifier)
    }

    private var backgroundStyle: AnyShapeStyle {
        switch feedback.kind {
        case .success:
            return AnyShapeStyle(.green.gradient)
        case .error:
            return AnyShapeStyle(.red.gradient)
        }
    }
}