import StoreKit
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var fitness: FitnessData
    @State private var showResetConfirm = false
    @State private var showImportPicker = false
    @State private var exportDocument: ExportDocument?
    @State private var importInfo: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("App")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                VStack(spacing: 0) {
                    settingsLinkButton(title: "Rate us", icon: "star.fill") {
                        rateApp()
                    }
                    Divider().background(Color.appTextSecondary.opacity(0.2))
                    settingsLinkButton(title: AppExternalLink.privacyPolicy.title, icon: "hand.raised.fill") {
                        AppExternalLink.privacyPolicy.openInBrowser()
                    }
                    Divider().background(Color.appTextSecondary.opacity(0.2))
                    settingsLinkButton(title: AppExternalLink.termsOfUse.title, icon: "doc.text.fill") {
                        AppExternalLink.termsOfUse.openInBrowser()
                    }
                }
                .appChromePanel(style: .elevated, cornerRadius: 18)

                Text("Statistics")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                VStack(alignment: .leading, spacing: 10) {
                    statRow("Sessions completed", value: "\(fitness.sessionsCompleted)")
                    statRow("Streak", value: "\(fitness.enduranceStreak) days")
                    statRow("Active day streak", value: "\(fitness.activeDaysStreak) days")
                    statRow("Calories estimate", value: "\(fitness.totalCaloriesEstimate) kcal")
                    statRow("Reps tracked", value: "\(fitness.totalRepsTracked)")
                    statRow("Achievement band", value: fitness.achievementTitle)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appChromePanel(style: .elevated, cornerRadius: 18)

                Text("Weekly targets")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                VStack(alignment: .leading, spacing: 12) {
                    Stepper(
                        "Session goal: \(fitness.weeklySessionsTarget) / week",
                        value: Binding(
                            get: { fitness.weeklySessionsTarget },
                            set: { fitness.setWeeklySessionTarget($0) }
                        ),
                        in: 1...21,
                        step: 1
                    )
                    .foregroundStyle(Color.appPrimary)

                    Stepper(
                        "Minutes goal: \(fitness.weeklyMinutesTarget) / week",
                        value: Binding(
                            get: { fitness.weeklyMinutesTarget },
                            set: { fitness.setWeeklyMinutesTarget($0) }
                        ),
                        in: 15...900,
                        step: 15
                    )
                    .foregroundStyle(Color.appPrimary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appChromePanel(style: .outlined, cornerRadius: 18)

                Text("Backup")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                VStack(spacing: 12) {
                    Button {
                        exportBackupFile()
                    } label: {
                        Text("Export plans backup")
                            .font(.headline)
                            .foregroundStyle(Color.appTextOnPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                            .appPrimaryButtonChrome()
                    }
                    .buttonStyle(.plain)

                    Button {
                        showImportPicker = true
                    } label: {
                        Text("Import plans backup")
                            .font(.headline)
                            .foregroundStyle(Color.appPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                            .appSecondaryOutlineChrome()
                    }
                    .buttonStyle(.plain)

                    Text("Exports include custom plans, favorites, weekly layout, and weekly target numbers.")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appChromePanel(style: .elevated, cornerRadius: 18)

                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Text("Reset all progress")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.appPrimary)
                .shadow(color: Color.appPrimary.opacity(0.35), radius: 12, x: 0, y: 6)
            }
            .padding(16)
        }
        .appMeshScreenBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                importFromURL(url)
            case .failure:
                importInfo = "Import failed."
            }
        }
        .sheet(item: $exportDocument) { doc in
            ActivityShareView(items: [doc.url])
        }
        .alert("Reset all progress?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                fitness.resetAllProgress()
            }
        } message: {
            Text("This clears sessions, stars, streaks, and unlocks. Custom plans, favorites, weekly layout, and targets are kept.")
        }
        .alert("Backup", isPresented: Binding(
            get: { importInfo != nil },
            set: { if !$0 { importInfo = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importInfo ?? "")
        }
    }

    private func exportBackupFile() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(fitness.makeBackupPayload()) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("training-backup.json")
        do {
            try data.write(to: url, options: .atomic)
            exportDocument = ExportDocument(url: url)
        } catch {
            importInfo = "Could not create export file."
        }
    }

    private func importFromURL(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            importInfo = "Could not access the file."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(TrainingBackupPayload.self, from: data)
            fitness.importBackupPayload(payload)
            importInfo = "Backup imported. Your data was merged."
        } catch {
            importInfo = "Could not read this backup file."
        }
    }

    private func settingsLinkButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 28, alignment: .center)
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func statRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            Text(value)
                .foregroundStyle(Color.appPrimary)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
                .minimumScaleFactor(0.7)
        }
    }
}
