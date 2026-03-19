//
//  CopyFeedbackController.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import Combine
import Foundation

@MainActor
final class CopyFeedbackController: ObservableObject {
    @Published private(set) var message: String?

    private var hideTask: Task<Void, Never>?

    func showSuccess(message: String = "复制成功") {
        hideTask?.cancel()
        self.message = message

        hideTask = Task {
            try? await Task.sleep(for: .seconds(1.4))

            guard !Task.isCancelled else {
                return
            }

            self.message = nil
        }
    }
}