//
//  SettingsView.swift
//  Verificar
//
//  Created by TOM STOVALL on 2/7/26.
//

import SwiftUI

/// The macOS Settings window with tabbed preferences for Validation and Display.
///
/// All preferences are persisted using `@AppStorage` so they survive app restarts.
/// The settings are organized into two tabs:
/// - **Validation**: Default profile, auto-validate, max violations to display
/// - **Display**: Default zoom, view mode, page numbers in thumbnails, highlight color
struct SettingsView: View {

    var body: some View {
        TabView {
            ValidationSettingsTab()
                .tabItem {
                    Label("Validation", systemImage: "checkmark.shield")
                }

            DisplaySettingsTab()
                .tabItem {
                    Label("Display", systemImage: "paintbrush")
                }
        }
        .frame(width: 450, height: 320)
    }
}

// MARK: - Validation Settings Tab

/// Validation-related preferences: default profile, auto-validate, max violations.
struct ValidationSettingsTab: View {

    @AppStorage("defaultValidationProfile") private var defaultProfile: String = "PDF/UA-2"
    @AppStorage("autoValidateOnOpen") private var autoValidateOnOpen: Bool = true
    @AppStorage("maxViolationsToDisplay") private var maxViolationsToDisplay: Double = 500

    var body: some View {
        Form {
            Section {
                Picker("Default Validation Profile:", selection: $defaultProfile) {
                    ForEach(SettingsHelper.availableProfiles, id: \.self) { profile in
                        Text(profile).tag(profile)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Default validation profile")
            }

            Section {
                Toggle("Auto-validate on open", isOn: $autoValidateOnOpen)
                    .accessibilityLabel("Automatically validate when a PDF is opened")
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Max violations to display: \(Int(maxViolationsToDisplay))")
                    Slider(value: $maxViolationsToDisplay, in: 50...2000, step: 50) {
                        Text("Max violations")
                    }
                    .accessibilityLabel("Maximum violations to display: \(Int(maxViolationsToDisplay))")
                    Text("Limits the number of violations shown in the panel to improve performance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Display Settings Tab

/// Display-related preferences: zoom level, view mode, thumbnails, highlight color.
struct DisplaySettingsTab: View {

    @AppStorage("defaultZoomLevel") private var defaultZoomLevel: Double = 1.0
    @AppStorage("defaultViewMode") private var defaultViewMode: String = "Continuous"
    @AppStorage("showPageNumbersInThumbnails") private var showPageNumbers: Bool = true
    @AppStorage("highlightColorName") private var highlightColorName: String = "red"

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Default Zoom: \(Int(defaultZoomLevel * 100))%")
                    Slider(value: $defaultZoomLevel, in: 0.25...4.0, step: 0.25) {
                        Text("Default zoom level")
                    }
                    .accessibilityLabel("Default zoom level: \(Int(defaultZoomLevel * 100)) percent")
                }
            }

            Section {
                Picker("Default View Mode:", selection: $defaultViewMode) {
                    ForEach(SettingsHelper.viewModes, id: \.self) { mode in
                        Text(mode).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Default view mode")
            }

            Section {
                Toggle("Show page numbers in thumbnails", isOn: $showPageNumbers)
                    .accessibilityLabel("Show page numbers in thumbnail sidebar")
            }

            Section {
                Picker("Violation Highlight Color:", selection: $highlightColorName) {
                    ForEach(SettingsHelper.highlightColors, id: \.self) { color in
                        Text(color.capitalized).tag(color)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Violation highlight color")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Settings Helper (for testing)

/// Testable helper for settings-related constants and conversions.
enum SettingsHelper {

    /// Available validation profiles.
    static let availableProfiles: [String] = [
        "PDF/UA-1",
        "PDF/UA-2",
        "PDF/A-1a",
        "PDF/A-1b",
        "PDF/A-2a",
        "PDF/A-2b",
        "PDF/A-2u",
        "PDF/A-3a",
        "PDF/A-3b",
        "PDF/A-3u",
        "PDF/A-4",
    ]

    /// Available view modes.
    static let viewModes: [String] = [
        "Single Page",
        "Continuous",
        "Two-Up",
    ]

    /// Available highlight colors.
    static let highlightColors: [String] = [
        "red",
        "orange",
        "yellow",
        "blue",
        "purple",
        "green",
    ]

    /// Default values for all settings.
    static let defaults: [String: Any] = [
        "defaultValidationProfile": "PDF/UA-2",
        "autoValidateOnOpen": true,
        "maxViolationsToDisplay": 500.0,
        "defaultZoomLevel": 1.0,
        "defaultViewMode": "Continuous",
        "showPageNumbersInThumbnails": true,
        "highlightColorName": "red",
    ]

    /// Validates that a profile name is in the list of available profiles.
    static func isValidProfile(_ profile: String) -> Bool {
        availableProfiles.contains(profile)
    }

    /// Validates that a view mode name is in the list of available modes.
    static func isValidViewMode(_ mode: String) -> Bool {
        viewModes.contains(mode)
    }

    /// Validates that a highlight color name is in the list of available colors.
    static func isValidHighlightColor(_ color: String) -> Bool {
        highlightColors.contains(color)
    }

    /// Clamps a zoom level to the valid range [0.25, 4.0].
    static func clampZoomLevel(_ zoom: Double) -> Double {
        max(0.25, min(zoom, 4.0))
    }

    /// Clamps max violations to the valid range [50, 2000].
    static func clampMaxViolations(_ count: Double) -> Double {
        max(50, min(count, 2000))
    }
}

#Preview {
    SettingsView()
}
