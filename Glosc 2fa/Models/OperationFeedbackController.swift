//
//  OperationFeedbackController.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import Combine
import Foundation

struct OperationFeedback: Equatable {
    enum Kind: Equatable {
        case success
        case error
    }

    let kind: Kind
    let message: String

    var accessibilityIdentifier: String {
        switch kind {
        case .success:
            return "operationSuccessToast"
        case .error:
            return "operationErrorToast"
        }
    }

    var symbolName: String {
        switch kind {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
}

@MainActor
final class OperationFeedbackController: ObservableObject {
    @Published private(set) var currentFeedback: OperationFeedback?

    private var hideTask: Task<Void, Never>?

    func showSuccess(message: String, autoHideAfter delay: Duration = .seconds(1.4)) {
        show(.init(kind: .success, message: message), autoHideAfter: delay)
    }

    func showError(message: String, autoHideAfter delay: Duration = .seconds(2)) {
        show(.init(kind: .error, message: message), autoHideAfter: delay)
    }

    private func show(_ feedback: OperationFeedback, autoHideAfter delay: Duration) {
        hideTask?.cancel()
        currentFeedback = feedback

        hideTask = Task {
            try? await Task.sleep(for: delay)

            guard !Task.isCancelled else {
                return
            }

            currentFeedback = nil
        }
    }
}