import Foundation
import SwiftVerificarBiblioteca

/// Service layer wrapping SwiftVerificar-biblioteca for PDF validation.
///
/// `ValidationService` provides an `@Observable` interface for the UI to
/// track validation state, progress, and results. It delegates to
/// `SwiftVerificar.shared` for actual validation operations.
///
/// Since SwiftVerificar-biblioteca v0.1.0 has stub implementations, the
/// service handles errors gracefully and exposes them through the `error`
/// property rather than throwing.
@Observable
final class ValidationService: @unchecked Sendable {

    // MARK: - Published State

    /// Whether a validation operation is currently in progress.
    var isValidating: Bool = false

    /// Current validation progress (0.0 to 1.0).
    var progress: Double = 0.0

    /// The result of the last validation operation, if any.
    var lastResult: ValidationResult?

    /// The error from the last validation operation, if any.
    var error: (any Error)?

    // MARK: - Private

    /// The currently running validation task, if any.
    private var validationTask: Task<Void, Never>?

    // MARK: - Validation Methods

    /// Validates a PDF document using the default PDF/UA-2 profile.
    ///
    /// - Parameter url: The file URL of the PDF document to validate.
    func validate(url: URL) async {
        await validate(url: url, profile: "PDF/UA-2")
    }

    /// Validates a PDF document against a specific validation profile.
    ///
    /// This method updates `isValidating`, `progress`, `lastResult`, and
    /// `error` properties as the validation progresses. The UI can observe
    /// these changes to display appropriate state.
    ///
    /// - Parameters:
    ///   - url: The file URL of the PDF document to validate.
    ///   - profile: The name of the validation profile (e.g., "PDF/UA-2").
    func validate(url: URL, profile: String) async {
        // Cancel any in-progress validation
        cancelValidation()

        isValidating = true
        progress = 0.0
        error = nil
        lastResult = nil

        let task = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let result = try await SwiftVerificar.shared.validate(
                    url,
                    profile: profile,
                    progress: { [weak self] fraction, _ in
                        Task { @MainActor in
                            self?.progress = fraction
                        }
                    }
                )
                guard !Task.isCancelled else { return }
                self.lastResult = result
                self.progress = 1.0
            } catch {
                guard !Task.isCancelled else { return }
                self.error = error
            }

            self.isValidating = false
        }

        validationTask = task
        await task.value
    }

    /// Extracts features from a PDF document.
    ///
    /// Uses the full processing pipeline with feature extraction enabled.
    ///
    /// - Parameter url: The file URL of the PDF document.
    func extractFeatures(url: URL) async {
        isValidating = true
        progress = 0.0
        error = nil

        do {
            var config = ProcessorConfig()
            config.tasks = [.extractFeatures]
            let _ = try await SwiftVerificar.shared.process(url, config: config)
            progress = 1.0
        } catch {
            self.error = error
        }

        isValidating = false
    }

    /// Cancels any in-progress validation operation.
    func cancelValidation() {
        validationTask?.cancel()
        validationTask = nil
        isValidating = false
    }
}
