import Foundation
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authSession: AuthSession
    @EnvironmentObject private var preferences: AppPreferences
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegister = false
    @State private var showingEndpointSettings = false
    @State private var hasAppeared = false
    @State private var submitPulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedField: Field?

    var body: some View {
        GeometryReader { proxy in
            let horizontalPadding: CGFloat = proxy.size.width < 390 ? 18 : 28
            let contentWidth = min(ChemVaultBrandAssets.loginCardMaxWidth, max(0, proxy.size.width - horizontalPadding * 2))

            ZStack {
                ChemVaultBrandBackground()

                ScrollView {
                    VStack(spacing: 18) {
                        loginCard(width: contentWidth)
                        connectionBar(width: contentWidth)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 30)
                }
            }
        }
        .onAppear {
            guard !hasAppeared else { return }
            if reduceMotion {
                hasAppeared = true
            } else {
                withAnimation(.spring(response: 0.58, dampingFraction: 0.84)) {
                    hasAppeared = true
                }
            }
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
        }
        .sheet(isPresented: $showingEndpointSettings) {
            NavigationStack {
                APIEndpointSettingsView()
            }
        }
    }

    private func loginCard(width: CGFloat) -> some View {
        VStack(spacing: 22) {
            loginHeader

            VStack(spacing: 14) {
                emailField
                passwordField
            }

            if let lastError = authSession.lastError {
                errorBanner(lastError)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Button {
                submit()
            } label: {
                Group {
                    if authSession.state == .checking {
                        ChemVaultLoadingButtonLabel(title: "Signing In", size: 18)
                    } else {
                        Label("Sign in", systemImage: "arrow.right.circle.fill")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
            }
            .buttonStyle(ChemVaultPrimaryButtonStyle())
            .disabled(isSubmitDisabled)
            .scaleEffect(submitPulse ? 0.985 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.74), value: submitPulse)
            .animation(.easeInOut(duration: 0.22), value: authSession.state)

            loginActions
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(width: width)
        .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.82), lineWidth: 1)
        }
        .shadow(color: LoginStyle.shadow.opacity(0.18), radius: 28, x: 0, y: 18)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 18)
        .scaleEffect(hasAppeared ? 1 : 0.985)
        .animation(reduceMotion ? nil : .spring(response: 0.58, dampingFraction: 0.84), value: hasAppeared)
        .animation(.easeInOut(duration: 0.2), value: authSession.lastError)
    }

    private var loginHeader: some View {
        VStack(spacing: 11) {
            ChemVaultLogoBadge(size: 56, shadowRadius: 10)
                .padding(.bottom, 3)

            Text("ChemVault")
                .font(.system(size: 31, weight: .semibold))
                .foregroundStyle(LoginStyle.brandText)

            Text("Sign in to your account to access email")
                .font(.subheadline)
                .foregroundStyle(LoginStyle.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    private var emailField: some View {
        ChemVaultLoginField(label: "Email", systemImage: "envelope.fill", isFocused: focusedField == .email) {
            HStack(spacing: 10) {
                TextField("Email", text: $email)
                    .focused($focusedField, equals: .email)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .autocorrectionDisabled(true)
                    .onSubmit {
                        focusedField = .password
                    }

                if shouldShowDomainSuffix {
                    Rectangle()
                        .fill(LoginStyle.fieldBorder)
                        .frame(width: 1, height: 22)

                    Text(defaultDomainSuffix)
                        .font(.subheadline)
                        .foregroundStyle(LoginStyle.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LoginStyle.mutedText)
                }
            }
        }
    }

    private var passwordField: some View {
        ChemVaultLoginField(label: "Password", systemImage: "lock.fill", isFocused: focusedField == .password) {
            SecureField("Password", text: $password)
                .focused($focusedField, equals: .password)
                .textFieldStyle(.plain)
                .font(.body)
                .onSubmit {
                    submit()
                }
        }
    }

    private var loginActions: some View {
        HStack(spacing: 14) {
            Button {
                showingRegister = true
            } label: {
                Label("Create Account", systemImage: "person.badge.plus")
            }
            .buttonStyle(ChemVaultLinkButtonStyle())

            Spacer(minLength: 8)

            Button {
                showingEndpointSettings = true
            } label: {
                Label("API", systemImage: "server.rack")
            }
            .buttonStyle(ChemVaultLinkButtonStyle())
        }
    }

    private func connectionBar(width: CGFloat) -> some View {
        Button {
            showingEndpointSettings = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "network")
                    .font(.caption.weight(.semibold))

                Text(preferences.baseURLString)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Image(systemName: "slider.horizontal.3")
                    .font(.caption.weight(.semibold))
            }
            .font(.caption)
            .foregroundStyle(LoginStyle.secondaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(.white.opacity(0.72), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.78), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .frame(width: width)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 12)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.42).delay(0.12), value: hasAppeared)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.subheadline)

            Text(message)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .foregroundStyle(LoginStyle.errorText)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(LoginStyle.errorBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func submit() {
        focusedField = nil
        withAnimation(.spring(response: 0.24, dampingFraction: 0.74)) {
            submitPulse = true
        }
        Task {
            await authSession.login(email: loginEmail, password: password)
            await MainActor.run {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.74)) {
                    submitPulse = false
                }
            }
        }
    }

    private var isSubmitDisabled: Bool {
        trimmedEmail.isEmpty || trimmedPassword.isEmpty || authSession.state == .checking
    }

    private var loginEmail: String {
        guard !trimmedEmail.contains("@") else { return trimmedEmail }
        return trimmedEmail + defaultDomainSuffix
    }

    private var shouldShowDomainSuffix: Bool {
        !trimmedEmail.contains("@")
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedPassword: String {
        password.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var defaultDomainSuffix: String {
        "@chemvault.science"
    }

    private enum Field {
        case email
        case password
    }
}

private struct ChemVaultLoginField<Content: View>: View {
    var label: String
    var systemImage: String
    var isFocused: Bool
    private let content: Content

    init(label: String, systemImage: String, isFocused: Bool, @ViewBuilder content: () -> Content) {
        self.label = label
        self.systemImage = systemImage
        self.isFocused = isFocused
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(LoginStyle.mutedText)

            HStack(spacing: 11) {
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(isFocused ? ChemVaultLoadingConfiguration.primaryColor : LoginStyle.mutedText)
                    .frame(width: 18)

                content
            }
            .frame(minHeight: 48)
            .padding(.horizontal, 14)
            .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isFocused ? ChemVaultLoadingConfiguration.primaryColor.opacity(0.55) : LoginStyle.fieldBorder, lineWidth: 1)
            }
            .shadow(color: ChemVaultLoadingConfiguration.primaryColor.opacity(isFocused ? 0.16 : 0), radius: 10, x: 0, y: 5)
            .scaleEffect(isFocused ? 1.01 : 1)
            .animation(.easeInOut(duration: 0.18), value: isFocused)
        }
    }
}

private struct ChemVaultPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [
                        ChemVaultLoadingConfiguration.primaryColor,
                        Color(red: 14 / 255, green: 103 / 255, blue: 188 / 255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(isEnabled ? (configuration.isPressed ? 0.82 : 1) : 0.54),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .shadow(color: ChemVaultLoadingConfiguration.primaryColor.opacity(configuration.isPressed ? 0.12 : 0.26), radius: 14, x: 0, y: 8)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.76), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

private struct ChemVaultLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote.weight(.semibold))
            .foregroundStyle(configuration.isPressed ? ChemVaultLoadingConfiguration.primaryColor.opacity(0.65) : ChemVaultLoadingConfiguration.primaryColor)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.76), value: configuration.isPressed)
    }
}

private enum LoginStyle {
    static let brandText = Color(red: 35 / 255, green: 70 / 255, blue: 100 / 255)
    static let secondaryText = Color(red: 82 / 255, green: 105 / 255, blue: 123 / 255)
    static let mutedText = Color(red: 114 / 255, green: 132 / 255, blue: 146 / 255)
    static let fieldBorder = Color(red: 206 / 255, green: 220 / 255, blue: 231 / 255)
    static let shadow = Color(red: 28 / 255, green: 66 / 255, blue: 94 / 255)
    static let errorText = Color(red: 156 / 255, green: 48 / 255, blue: 48 / 255)
    static let errorBackground = Color(red: 255 / 255, green: 240 / 255, blue: 239 / 255)
}

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authSession: AuthSession
    @State private var email = ""
    @State private var password = ""
    @State private var code = ""
    @State private var isSubmitting = false
    @State private var successMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                    SecureField("Password", text: $password)
                    TextField("Registration key", text: $code)
                }

                if let lastError = authSession.lastError {
                    Section {
                        Text(lastError)
                            .foregroundStyle(.red)
                    }
                }

                if let successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundStyle(.green)
                    }
                }

                Section {
                    Button {
                        submit()
                    } label: {
                        if isSubmitting {
                            ChemVaultLoadingButtonLabel(title: "Registering")
                        } else {
                            Label("Register", systemImage: "person.badge.plus")
                        }
                    }
                    .disabled(email.isEmpty || password.count < 6 || isSubmitting)
                }
            }
            .navigationTitle("Create Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func submit() {
        isSubmitting = true
        Task {
            let ok = await authSession.register(email: email, password: password, code: code)
            isSubmitting = false
            if ok {
                successMessage = "Registration succeeded. Sign in with the new account."
            }
        }
    }
}

struct APIEndpointSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var preferences: AppPreferences

    var body: some View {
        Form {
            Section("API Server") {
                TextField("Base URL", text: $preferences.baseURLString)
                Button("Use Production") {
                    preferences.resetBaseURL()
                }
            }

            Section("Language") {
                Picker("Language", selection: $preferences.language) {
                    Text("English").tag("en")
                    Text("Chinese").tag("zh")
                }
                .pickerStyle(.segmented)
            }
        }
        .navigationTitle("Connection")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
