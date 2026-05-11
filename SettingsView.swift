//
//  SettingsView.swift
//  Lexa
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            settingsTopBar

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("MODE")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        HStack {
                            settingsRow(
                                icon: "moon.fill",
                                iconColor: .purple,
                                title: "Dark Mode",
                                subtitle: "Enable dark mode"
                            )
                            Spacer()
                            Toggle("", isOn: $isDarkMode)
                                .labelsHidden()
                                .scaleEffect(0.8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(settingsCardBackground)
                        )
                        .padding(.horizontal, 20)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("SUPPORT")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        settingsNavigationRow(
                            destination: HelpSupportView(),
                            icon: "questionmark",
                            iconColor: .blue,
                            title: "Help & Support",
                            subtitle: "Get help and contact support"
                        )

                        settingsNavigationRow(
                            destination: TermsPrivacyView(),
                            icon: "doc.text",
                            iconColor: .blue,
                            title: "Terms & Privacy",
                            subtitle: "View terms and privacy policy"
                        )

                        settingsNavigationRow(
                            destination: AboutLexaView(),
                            icon: "info",
                            iconColor: .blue,
                            title: "About",
                            subtitle: "App version and information"
                        )
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .background(Color(.systemGroupedBackground))
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

    private func settingsRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            settingsIcon(icon: icon, color: iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
        }
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
            HStack(spacing: 12) {
                settingsRow(icon: icon, iconColor: iconColor, title: title, subtitle: subtitle)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(settingsCardBackground)
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }

    private var settingsCardBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color(.systemBackground)
    }

    private func settingsIcon(icon: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
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
