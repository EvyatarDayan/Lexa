//
//  SettingsView.swift
//  Lexa
//

import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("dailyNotificationEnabled") private var dailyNotificationEnabled = false
    @AppStorage("dailyNotificationHour") private var dailyNotificationHour = 9
    @AppStorage("dailyNotificationMinute") private var dailyNotificationMinute = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @State private var showingExportFavoritesSheet = false
    @State private var showingNotificationSettings = false
    @State private var exportItems: [Any] = []
    @State private var isExportingFavorites = false
    @State private var exportFavoritesMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            settingsTopBar

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    settingsSection(title: "Preferences") {
                        HStack(spacing: 12) {
                            settingsRow(
                                icon: "moon.fill",
                                iconColor: .purple,
                                title: "Dark mode",
                                subtitle: "Use dark appearance"
                            ) {
                                Toggle("", isOn: $isDarkMode)
                                    .labelsHidden()
                                    .scaleEffect(0.75)
                            }
                        }
                    }

                    settingsSection(title: "Notifications") {
                        Button {
                            showingNotificationSettings = true
                        } label: {
                            settingsRow(
                                icon: "bell.fill",
                                iconColor: .orange,
                                title: "Schedule notifications",
                                subtitle: "Choose your daily reminder time"
                            ) {
                                HStack(spacing: 4) {
                                    Text(dailyNotificationEnabled ? formattedNotificationTime : "Off")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    settingsSection(title: "Export Data") {
                        Button {
                            exportFavorites()
                        } label: {
                            settingsRow(
                                icon: "square.and.arrow.up.fill",
                                iconColor: .green,
                                title: "Export favorites",
                                subtitle: "Save favorite words to a document"
                            ) {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(favoritesManager.favoriteIDs.isEmpty || isExportingFavorites)
                        .opacity(favoritesManager.favoriteIDs.isEmpty ? 0.45 : 1)
                    }

                    settingsSection(title: "Support") {
                        settingsNavigationRow(
                            destination: HelpSupportView(),
                            icon: "questionmark.circle.fill",
                            iconColor: .blue,
                            title: "Help and support",
                            subtitle: "Get help and contact support"
                        )

                        settingsDivider

                        settingsNavigationRow(
                            destination: TermsPrivacyView(),
                            icon: "lock.fill",
                            iconColor: .green,
                            title: "Terms and privacy",
                            subtitle: "View terms and privacy policy"
                        )

                        settingsDivider

                        settingsNavigationRow(
                            destination: AboutLexaView(),
                            icon: "info.circle.fill",
                            iconColor: .orange,
                            title: "About",
                            subtitle: "App version and information"
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationScheduleView()
        }
        .sheet(isPresented: $showingExportFavoritesSheet) {
            ShareSheet(activityItems: exportItems)
        }
        .alert("Export Favorites", isPresented: Binding(
            get: { exportFavoritesMessage != nil },
            set: { if !$0 { exportFavoritesMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                exportFavoritesMessage = nil
            }
        } message: {
            Text(exportFavoritesMessage ?? "")
        }
    }

    private var settingsTopBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer()

            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(settingsCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var settingsDivider: some View {
        Divider()
            .background(Color(.separator))
            .padding(.leading, 60)
    }

    private func settingsRow<Trailing: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            settingsIcon(icon: icon, color: iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func settingsNavigationRow<Destination: View>(
        destination: Destination,
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String
    ) -> some View {
        NavigationLink {
            destination
        } label: {
            settingsRow(icon: icon, iconColor: iconColor, title: title, subtitle: subtitle) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var settingsCardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color(.systemBackground)
    }

    private var formattedNotificationTime: String {
        var components = DateComponents()
        components.hour = dailyNotificationHour
        components.minute = dailyNotificationMinute

        guard let date = Calendar.current.date(from: components) else {
            return String(format: "%02d:%02d", dailyNotificationHour, dailyNotificationMinute)
        }

        return date.formatted(date: .omitted, time: .shortened)
    }

    private func settingsIcon(icon: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 32, height: 32)
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
        }
    }

    private func exportFavorites() {
        let favoriteIDs = favoritesManager.favoriteIDs
        guard !favoriteIDs.isEmpty else {
            exportFavoritesMessage = "You do not have any favorites to export yet."
            return
        }

        isExportingFavorites = true
        let favoriteOrder = favoritesManager.favoriteOrder

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let entries = try Self.loadVocabularyEntries()
                let favoriteEntries = Self.orderedFavoriteEntries(
                    from: entries,
                    favoriteIDs: favoriteIDs,
                    favoriteOrder: favoriteOrder
                )

                guard !favoriteEntries.isEmpty else {
                    DispatchQueue.main.async {
                        isExportingFavorites = false
                        exportFavoritesMessage = "Could not find the favorite word details in the vocabulary file."
                    }
                    return
                }

                let fileName = "Lexa_Favorites_\(Self.exportDateStamp()).pdf"
                let fileURL = try Self.createFavoritesPDF(entries: favoriteEntries, fileName: fileName)

                DispatchQueue.main.async {
                    exportItems = [fileURL]
                    isExportingFavorites = false
                    showingExportFavoritesSheet = true
                }
            } catch {
                DispatchQueue.main.async {
                    isExportingFavorites = false
                    exportFavoritesMessage = "Could not export favorites: \(error.localizedDescription)"
                }
            }
        }
    }

    private static func loadVocabularyEntries() throws -> [VocabularyEntry] {
        guard let url = Bundle.main.url(forResource: "vocabulary", withExtension: "json") else {
            throw ExportFavoritesError.missingVocabulary
        }

        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode([VocabularyEntry].self, from: data)
        var seenWords = Set<String>()
        return decoded.filter { entry in
            seenWords.insert(entry.word).inserted
        }
    }

    private static func orderedFavoriteEntries(
        from entries: [VocabularyEntry],
        favoriteIDs: Set<String>,
        favoriteOrder: [String]
    ) -> [VocabularyEntry] {
        let favorites = entries.filter { favoriteIDs.contains($0.id) }
        let byID = Dictionary(uniqueKeysWithValues: favorites.map { ($0.id, $0) })
        let orderedRecent = favoriteOrder.reversed().compactMap { byID[$0] }
        let orderedRecentIDs = Set(orderedRecent.map(\.id))
        let untracked = favorites
            .filter { !orderedRecentIDs.contains($0.id) }
            .sorted { $0.word.localizedCompare($1.word) == .orderedAscending }

        return orderedRecent + untracked
    }

    private static func exportDateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }

    private static func createFavoritesPDF(entries: [VocabularyEntry], fileName: String) throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 48
        let contentWidth = pageRect.width - (margin * 2)
        let bottomLimit = pageRect.height - margin
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        try renderer.writePDF(to: fileURL) { context in
            var y = margin

            func beginPage() {
                context.beginPage()
                y = margin
            }

            func drawText(
                _ text: String,
                font: UIFont,
                color: UIColor = .label,
                indent: CGFloat = 0,
                spacingAfter: CGFloat = 8
            ) {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                let rect = NSString(string: text).boundingRect(
                    with: CGSize(width: contentWidth - indent, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )

                if y + ceil(rect.height) > bottomLimit {
                    beginPage()
                }

                NSString(string: text).draw(
                    in: CGRect(x: margin + indent, y: y, width: contentWidth - indent, height: ceil(rect.height)),
                    withAttributes: attributes
                )
                y += ceil(rect.height) + spacingAfter
            }

            func drawDivider() {
                if y + 18 > bottomLimit {
                    beginPage()
                }

                y += 6
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: y))
                path.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
                UIColor.separator.setStroke()
                path.lineWidth = 1
                path.stroke()
                y += 18
            }

            beginPage()
            drawText("Lexa Favorites", font: .systemFont(ofSize: 28, weight: .bold), color: .systemBlue, spacingAfter: 6)
            drawText(
                "Exported \(Date().formatted(date: .abbreviated, time: .shortened)) • \(entries.count) word\(entries.count == 1 ? "" : "s")",
                font: .systemFont(ofSize: 12),
                color: .secondaryLabel,
                spacingAfter: 24
            )

            for (index, entry) in entries.enumerated() {
                if y > bottomLimit - 140 {
                    beginPage()
                }

                drawText("\(index + 1). \(entry.wordForDisplay)", font: .systemFont(ofSize: 20, weight: .semibold), color: .systemBlue, spacingAfter: 6)
                drawText("Translation: \(entry.translationForDisplay)", font: .systemFont(ofSize: 14), spacingAfter: 5)
                drawText("Grammar: \(entry.grammarTypeForDisplay)", font: .systemFont(ofSize: 14), spacingAfter: 10)

                if !entry.grammarBreakdown.isEmpty {
                    drawText("Grammar Breakdown", font: .systemFont(ofSize: 14, weight: .semibold), spacingAfter: 5)
                    for item in entry.grammarBreakdown {
                        drawText("• \(item)", font: .systemFont(ofSize: 12), color: .secondaryLabel, indent: 12, spacingAfter: 4)
                    }
                    y += 4
                }

                if !entry.data.isEmpty {
                    drawText("Examples", font: .systemFont(ofSize: 14, weight: .semibold), spacingAfter: 5)
                    for sentence in entry.data {
                        drawText("SV: \(sentence.swedish)", font: .systemFont(ofSize: 12), indent: 12, spacingAfter: 3)
                        drawText("EN: \(sentence.english)", font: .systemFont(ofSize: 12), color: .secondaryLabel, indent: 12, spacingAfter: 8)
                    }
                }

                if index < entries.count - 1 {
                    drawDivider()
                }
            }
        }

        return fileURL
    }

    private enum ExportFavoritesError: LocalizedError {
        case missingVocabulary

        var errorDescription: String? {
            switch self {
            case .missingVocabulary:
                return "Could not find vocabulary.json in the app bundle."
            }
        }
    }
}

private final class FileActivityItemSource: NSObject, UIActivityItemSource {
    private let fileURL: URL
    private let fileName: String

    init(fileURL: URL) {
        self.fileURL = fileURL
        self.fileName = fileURL.lastPathComponent
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        fileURL
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        fileURL
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        fileName
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        "com.adobe.pdf"
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let wrappedItems = activityItems.map { item in
            guard let url = item as? URL else { return item }
            return FileActivityItemSource(fileURL: url) as Any
        }

        let controller = UIActivityViewController(activityItems: wrappedItems, applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first
            popover.sourceRect = CGRect(
                x: UIScreen.main.bounds.midX,
                y: UIScreen.main.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct NotificationScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("dailyNotificationEnabled") private var dailyNotificationEnabled = false
    @AppStorage("dailyNotificationHour") private var dailyNotificationHour = 9
    @AppStorage("dailyNotificationMinute") private var dailyNotificationMinute = 0
    @State private var selectedTime: Date
    @State private var notificationsEnabled: Bool
    @State private var alertMessage: String?

    init() {
        let storedHour = UserDefaults.standard.object(forKey: "dailyNotificationHour") as? Int ?? 9
        let storedMinute = UserDefaults.standard.object(forKey: "dailyNotificationMinute") as? Int ?? 0
        let storedEnabled = UserDefaults.standard.bool(forKey: "dailyNotificationEnabled")
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = storedHour
        components.minute = storedMinute
        _selectedTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
        _notificationsEnabled = State(initialValue: storedEnabled)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily reminder")
                                .foregroundStyle(.primary)
                            Text("Get a reminder to learn with Lexa")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $notificationsEnabled)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    if notificationsEnabled {
                        Divider()
                            .padding(.leading, 16)

                        DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text("Lexa will send one local notification every day at the selected time.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                Spacer()
            }
            .padding(16)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveNotificationSettings()
                    }
                }
            }
            .alert("Notifications", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
                    alertMessage = nil
                }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private func saveNotificationSettings() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
        let hour = components.hour ?? 9
        let minute = components.minute ?? 0

        if notificationsEnabled {
            LexaNotificationScheduler.scheduleDailyReminder(hour: hour, minute: minute) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        dailyNotificationHour = hour
                        dailyNotificationMinute = minute
                        dailyNotificationEnabled = true
                        dismiss()
                    case .failure(let error):
                        dailyNotificationEnabled = false
                        alertMessage = error.localizedDescription
                    }
                }
            }
        } else {
            LexaNotificationScheduler.cancelDailyReminder()
            dailyNotificationEnabled = false
            dailyNotificationHour = hour
            dailyNotificationMinute = minute
            dismiss()
        }
    }
}

private enum LexaNotificationScheduler {
    private static let reminderIdentifier = "lexa.daily-learning-reminder"

    static func scheduleDailyReminder(
        hour: Int,
        minute: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard granted else {
                completion(.failure(NotificationScheduleError.permissionDenied))
                return
            }

            center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

            let content = UNMutableNotificationContent()
            content.title = "Time for Lexa"
            content.body = "Learn a Swedish word today."
            content.sound = .default

            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: reminderIdentifier,
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    static func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }

    private enum NotificationScheduleError: LocalizedError {
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Notification permission is turned off. Enable notifications for Lexa in Settings to use daily reminders."
            }
        }
    }
}

private struct PlainBackHeader: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            Color.clear
                .frame(width: 36, height: 36)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

private struct HelpSupportView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var subject = ""
    @State private var description = ""
    @State private var showForm = false
    @State private var showError = false
    @State private var alertType: AlertType = .none

    enum AlertType {
        case none
        case messageSent
    }

    var allFieldsFilled: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !subject.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            PlainBackHeader(title: showForm ? "Contact us" : "Help and support")

            Group {
                if showForm {
                    Form {
                        Section(header: Text("Your full name")) {
                            TextField("Full name", text: $fullName)
                        }

                        Section(header: Text("Your Email")) {
                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                        }

                        Section(header: Text("Subject")) {
                            TextField("", text: $subject)
                                .onChange(of: subject) { _, newValue in
                                    if newValue.count > 100 {
                                        subject = String(newValue.prefix(100))
                                    }
                                }
                            HStack {
                                Spacer()
                                Text("\(subject.count)/100")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Section(header: Text("Description")) {
                            TextEditor(text: $description)
                                .frame(height: 120)
                                .onChange(of: description) { _, newValue in
                                    if newValue.count > 400 {
                                        description = String(newValue.prefix(400))
                                    }
                                }
                            HStack {
                                Spacer()
                                Text("\(description.count)/400")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        if showError && !allFieldsFilled {
                            Section {
                                Text("All fields are required.")
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                            }
                        }

                        Section {
                            Button(action: {
                                if allFieldsFilled {
                                    alertType = .messageSent
                                    showError = false
                                } else {
                                    showError = true
                                }
                            }) {
                                Text("Send")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(allFieldsFilled ? Color.green : Color.gray)
                                    .cornerRadius(12)
                            }
                            .disabled(!allFieldsFilled)
                        }
                        .listRowBackground(Color.clear)
                    }
                } else {
                    VStack {
                        Spacer(minLength: 0)
                        VStack(alignment: .center, spacing: 32) {
                            VStack(alignment: .center, spacing: 16) {
                                Text("We'd love to hear from you!")
                                    .font(.title3)
                                    .fontWeight(.bold)

                                Text("Whether you have questions,")
                                    .font(.body)

                                Text("feedback, or just want to say hi,")
                                    .font(.body)

                                Text("feel free to reach out.")
                                    .font(.body)

                                Divider()
                                    .padding(.vertical, 8)
                                    .padding(.top, 32)
                                    .padding(.bottom, 32)

                                Text("Email: abashelariprod@gmail.com")
                                    .font(.subheadline)

                                Text("Website: https://abashelari.com")
                                    .font(.subheadline)

                                Divider()
                                    .padding(.vertical, 8)
                                    .padding(.top, 32)
                            }
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 32)

                            Text("OR")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)

                            Button(action: {
                                showForm = true
                            }) {
                                Text("Contact form")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.green)
                                    .cornerRadius(12)
                                    .padding(.horizontal, 32)
                            }

                            Text("We aim to respond within 24 hours.")
                                .font(.body)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.vertical, 32)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: Binding(
            get: { alertType != .none },
            set: { if !$0 { alertType = .none } }
        )) {
            switch alertType {
            case .messageSent:
                return Alert(
                    title: Text("Message Sent"),
                    message: Text("Thanks for reaching out!"),
                    dismissButton: .default(Text("OK"))
                )
            case .none:
                return Alert(title: Text(""), message: Text(""), dismissButton: .default(Text("")))
            }
        }
    }
}

private struct TermsPrivacyView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            PlainBackHeader(title: "Terms & Privacy")

            Picker("Section", selection: $selectedTab) {
                Text("Terms").tag(0)
                Text("Privacy").tag(1)
                Text("Disclaimer").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(contentText)
                        .font(.body)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }

    private var contentText: String {
        switch selectedTab {
        case 0:
            return termsContent
        case 1:
            return privacyContent
        default:
            return disclaimerContent
        }
    }

    private let termsContent = """
    TERMS OF USE

    Last Updated: May 7, 2026

    Welcome to Lexa. These Terms of Use ("Terms") govern your access to and use of the Lexa mobile application ("App"). By using the App, you agree to be bound by these Terms.

    1. ACCEPTANCE OF TERMS
    By downloading, installing, or using Lexa, you acknowledge that you have read, understood, and agree to be bound by these Terms and our Privacy Policy.

    2. DESCRIPTION OF SERVICE
    Lexa is a Swedish-English dictionary app designed to help users search and understand vocabulary. The App allows users to:
    - Search Swedish and English vocabulary entries
    - View grammar breakdowns and usage examples
    - Use voice dictation for search input
    - Listen to pronunciation audio for words and example sentences
    - Customize interface settings such as dark mode

    3. USER ACCOUNTS
    You may use the App without creating an account. Lexa currently works as an offline-first app experience.

    4. ACCEPTABLE USE
    You agree to use the App only for lawful purposes and in accordance with these Terms. You agree not to:
    - Use the App for any illegal or unauthorized purpose
    - Attempt to gain unauthorized access to any part of the App
    - Interfere with or disrupt the App's functionality
    - Use automated systems to abuse or overload the App

    5. INTELLECTUAL PROPERTY
    The App and its content, including but not limited to text, graphics, logos, and software, are the property of Lexa and are protected by copyright and other intellectual property laws.

    6. LIMITATION OF LIABILITY
    Lexa is provided "as is" without warranties of any kind. We do not guarantee that the App will be error-free or uninterrupted. In no event shall Lexa be liable for any indirect, incidental, or consequential damages.

    7. MODIFICATIONS TO TERMS
    We reserve the right to modify these Terms at any time. Your continued use of the App after any changes constitutes acceptance of the modified Terms.

    8. CONTACT INFORMATION
    If you have questions about these Terms, please contact us through the App's support section.
    """

    private let privacyContent = """
    PRIVACY POLICY

    Last Updated: May 7, 2026

    At Lexa, we are committed to protecting your privacy. This Privacy Policy explains how we handle your information when you use our mobile application.

    1. LOCAL-FIRST APP USAGE
    Lexa is designed primarily as an offline dictionary experience. Search and dictionary content are handled inside the app.

    2. MICROPHONE AND SPEECH FEATURES
    Lexa can request microphone and speech recognition permissions to support voice dictation in the search field. This permission is used only to process your spoken input for search.

    3. TEXT-TO-SPEECH AUDIO
    Lexa can generate pronunciation playback for words and example sentences. Temporary audio files may be created on-device during playback and cleaned up by the app.

    4. DATA STORAGE
    App preferences, such as dark mode, are stored locally on your device. Lexa does not require a user account.

    5. DATA SHARING
    Lexa does not sell your personal data. Some voice or audio-related requests may rely on Apple or third-party service infrastructure and are subject to those providers' terms and privacy policies.

    6. DATA SECURITY
    Your data is protected by your device's built-in security features. We use iOS-provided storage and permission systems.

    7. CHILDREN'S PRIVACY
    Lexa is a language-learning utility suitable for broad audiences. Since Lexa does not require account creation, personal data collection is limited.

    8. CHANGES TO THIS POLICY
    We may update this Privacy Policy from time to time. Changes will be reflected in this section.

    9. CONTACT US
    If you have any questions about this Privacy Policy, please contact us through the App's support section.
    """

    private let disclaimerContent = """
    DISCLAIMER

    Last Updated: May 7, 2026

    1. NO WARRANTY
    Lexa is provided "as is" and "as available" without warranties, express or implied. We do not guarantee that the App will be error-free, uninterrupted, or free from defects.

    2. ACCURACY OF CONTENT
    While we strive to provide accurate translations, grammar notes, and examples, we cannot guarantee absolute completeness or correctness in every entry.

    3. LIMITATION OF LIABILITY
    To the fullest extent permitted by law, Lexa shall not be liable for indirect, incidental, special, consequential, or punitive damages, including loss of data or use, arising from use of the App.

    4. USER RESPONSIBILITY
    Users are responsible for:
    - Verifying language information when accuracy is critical
    - Using the app as a supplementary learning tool
    - Maintaining security and access control of their own device

    5. THIRD-PARTY SERVICES
    Lexa may use third-party services for features such as speech recognition and pronunciation playback. These services are governed by their own terms and privacy policies.

    6. CHANGES TO THE APP
    We reserve the right to modify, suspend, or discontinue Lexa features at any time without prior notice.

    7. NO PROFESSIONAL ADVICE
    Lexa is intended for educational and reference purposes only and does not constitute professional language certification or instruction.

    8. ACCEPTANCE
    By using Lexa, you acknowledge that you have read, understood, and agree to this Disclaimer.
    """
}

private struct AboutLexaView: View {
    var body: some View {
        VStack(spacing: 0) {
            PlainBackHeader(title: "About")

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About Lexa")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Lexa is a comprehensive Swedish-English dictionary app designed to help you search, understand, and pronounce vocabulary with ease. Explore words, grammar breakdowns, and practical examples while keeping your learning flow simple and fast.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("About ABASHELARI")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("At ABASHELARI, we believe in creating software that makes everyday life simpler, smarter, and more enjoyable. Our mission is to develop innovative digital solutions that blend creativity with technology, offering users tools that are intuitive, reliable, and engaging.")
                            .font(.body)
                            .multilineTextAlignment(.leading)

                        Text("Whether it's educational apps, lifestyle tools, or entertainment experiences, ABASHELARI is dedicated to delivering high-quality products that inspire learning, spark curiosity, and bring value to people around the world.")
                            .font(.body)
                            .multilineTextAlignment(.leading)

                        Text("Driven by passion and guided by innovation, ABASHELARI is committed to continuous improvement and to building software that connects people with what matters most.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
