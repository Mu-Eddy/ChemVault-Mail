import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authSession: AuthSession
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @Environment(\.colorScheme) private var colorScheme
    @State private var newPassword = ""
    @State private var errorMessage: String?
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section {
                SettingsProfileCard(user: authSession.currentUser)
                    .listRowInsets(EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            Section("Profile") {
                LabeledContent("Email", value: authSession.currentUser?.email ?? "Not loaded")
                LabeledContent("Name", value: authSession.currentUser?.name ?? "")
                LabeledContent("Role", value: authSession.currentUser?.role?.name ?? "")
                Button {
                    Task { await authSession.refreshUser() }
                } label: {
                    Label("Refresh Profile", systemImage: "arrow.clockwise")
                }
            }

            Section("Connection") {
                TextField("API Base URL", text: $preferences.baseURLString)
                Picker("Language", selection: $preferences.language) {
                    Text("English").tag("en")
                    Text("Chinese").tag("zh")
                }
                Button {
                    preferences.resetBaseURL()
                } label: {
                    Label("Use Production API", systemImage: "network")
                }
            }

            Section("Password") {
                SecureField("New password", text: $newPassword)
                Button {
                    resetPassword()
                } label: {
                    Label("Reset Password", systemImage: "key.fill")
                }
                .disabled(newPassword.count < 6)
            }

            if let statusMessage {
                Section {
                    Label(statusMessage, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            if let errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(ChemVaultTheme.errorText(for: colorScheme))
                }
            }

            Section {
                Button(role: .destructive) {
                    authSession.signOut()
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(ChemVaultWorkspaceBackground())
        .tint(ChemVaultLoadingConfiguration.primaryColor(for: colorScheme))
        .navigationTitle("Settings")
    }

    private func resetPassword() {
        Task {
            do {
                let _: EmptyResponse = try await appEnvironment.apiClient.put("/my/resetPassword", body: PasswordResetRequest(password: newPassword))
                newPassword = ""
                statusMessage = "Password updated."
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct SettingsProfileCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let user: ChemVaultUser?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 13) {
                ChemVaultUserAvatar(user: user, size: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                    Text(user?.email ?? "Profile not loaded")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                SettingsMetric(title: "Received", value: countLabel(user?.receiveEmailCount))
                SettingsMetric(title: "Sent", value: countLabel(user?.sendEmailCount))
                SettingsMetric(title: "Accounts", value: countLabel(user?.accountCount))
            }

            HStack(spacing: 8) {
                Label(user?.role?.name ?? "Standard", systemImage: "checkmark.seal.fill")
                Spacer(minLength: 8)
                Label("Secure", systemImage: "lock.shield.fill")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(ChemVaultLoadingConfiguration.primaryColor(for: colorScheme))
        }
        .padding(16)
        .background(ChemVaultWorkspaceTheme.panelBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(ChemVaultWorkspaceTheme.panelStroke(for: colorScheme), lineWidth: 1)
        }
        .shadow(color: ChemVaultWorkspaceTheme.panelShadow(for: colorScheme), radius: 14, x: 0, y: 8)
    }

    private var displayName: String {
        if let name = user?.name, !name.isEmpty { return name }
        return user?.email ?? "ChemVault User"
    }

    private func countLabel(_ value: Int?) -> String {
        value.map(String.init) ?? "-"
    }
}

private struct SettingsMetric: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.weight(.semibold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(ChemVaultTheme.fieldBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
