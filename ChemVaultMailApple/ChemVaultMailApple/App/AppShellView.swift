import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AppShellView: View {
    @EnvironmentObject private var authSession: AuthSession
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var selection: AppRoute = .mail

    var body: some View {
        ZStack {
            ChemVaultWorkspaceBackground()

            #if os(macOS)
            splitLayout
                .frame(minWidth: 980, minHeight: 680)
            #else
            if horizontalSizeClass == .compact {
                compactLayout
            } else {
                splitLayout
            }
            #endif
        }
        .tint(ChemVaultLoadingConfiguration.primaryColor(for: colorScheme))
        .animation(reduceMotion ? nil : ChemVaultMotion.rootContent, value: selection)
    }

    private var splitLayout: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            routeContent(selection)
                .id(selection)
                .transition(.opacity.combined(with: .scale(scale: 0.992)))
        }
        .scrollContentBackground(.hidden)
    }

    private var compactLayout: some View {
        TabView(selection: $selection) {
            ForEach(compactRoutes) { route in
                NavigationStack {
                    routeContent(route)
                        .id(route)
                }
                .tabItem {
                    Label(route.title, systemImage: route.systemImage)
                }
                .tag(route)
            }
        }
        #if os(iOS)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.regularMaterial, for: .tabBar)
        #endif
        .onChange(of: selection) { _, _ in
            selectionFeedback()
        }
    }

    private var compactRoutes: [AppRoute] {
        AppRoute.allCases.filter { route in
            route.groupTitle != "Admin" || route.isAvailable(for: authSession.currentUser)
        }
    }

    @ViewBuilder
    private func routeContent(_ route: AppRoute) -> some View {
        if route.isAvailable(for: authSession.currentUser) {
            switch route {
            case .mail:
                MailListView(mode: .inbox)
            case .starred:
                MailListView(mode: .starred)
            case .accounts:
                AccountsView()
            case .settings:
                SettingsView()
            case .adminUsers:
                AdminUsersView()
            case .adminRoles:
                AdminRolesView()
            case .adminRegistrationKeys:
                AdminRegistrationKeysView()
            case .adminAllMail:
                AdminAllMailView()
            case .adminSystemSettings:
                SystemSettingsView()
            case .analytics:
                AnalyticsView()
            }
        } else {
            PermissionDeniedView(route: route)
        }
    }

    private func selectionFeedback() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}

struct PermissionDeniedView: View {
    @Environment(\.colorScheme) private var colorScheme
    let route: AppRoute

    var body: some View {
        ZStack {
            ChemVaultWorkspaceBackground()
            VStack(spacing: 18) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(ChemVaultLoadingConfiguration.primaryColor(for: colorScheme))
                    .symbolEffect(.pulse)

                VStack(spacing: 6) {
                    Text("No Access")
                        .font(.title2.weight(.semibold))
                    Text("Your ChemVault role does not include permission for \(route.title).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(28)
            .frame(maxWidth: 380)
            .background(ChemVaultWorkspaceTheme.panelBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(ChemVaultWorkspaceTheme.panelStroke(for: colorScheme), lineWidth: 1)
            }
            .shadow(color: ChemVaultWorkspaceTheme.panelShadow(for: colorScheme), radius: 22, x: 0, y: 14)
            .padding()
        }
        .navigationTitle(route.title)
    }
}

struct ChemVaultWorkspaceBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: ChemVaultWorkspaceTheme.backgroundColors(for: colorScheme),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            ChemVaultWorkspaceGrid()
                .stroke(ChemVaultWorkspaceTheme.gridStroke(for: colorScheme), lineWidth: 0.7)
                .frame(width: 260, height: 260)
                .padding(.top, 18)
                .padding(.trailing, -34)
                .opacity(colorScheme == .dark ? 0.34 : 0.22)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

private struct ChemVaultWorkspaceGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let step = max(rect.width / 5, 1)
        for index in 0...5 {
            let x = rect.minX + CGFloat(index) * step
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - CGFloat(index) * step * 0.22, y: rect.maxY))
        }
        for index in 0...5 {
            let y = rect.minY + CGFloat(index) * step
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - CGFloat(index) * step * 0.18))
        }
        return path
    }
}

enum ChemVaultWorkspaceTheme {
    static func backgroundColors(for colorScheme: ColorScheme) -> [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 4 / 255, green: 12 / 255, blue: 18 / 255),
                Color(red: 8 / 255, green: 22 / 255, blue: 32 / 255),
                Color(red: 4 / 255, green: 9 / 255, blue: 14 / 255)
            ]
        }
        return [
            Color(red: 244 / 255, green: 249 / 255, blue: 252 / 255),
            Color(red: 1, green: 1, blue: 1),
            Color(red: 232 / 255, green: 242 / 255, blue: 248 / 255)
        ]
    }

    static func panelBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 10 / 255, green: 24 / 255, blue: 34 / 255).opacity(0.86)
            : .white.opacity(0.88)
    }

    static func panelStroke(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 112 / 255, green: 184 / 255, blue: 222 / 255).opacity(0.18)
            : Color(red: 199 / 255, green: 220 / 255, blue: 232 / 255).opacity(0.8)
    }

    static func panelShadow(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? .black.opacity(0.34)
            : Color(red: 28 / 255, green: 66 / 255, blue: 94 / 255).opacity(0.14)
    }

    static func gridStroke(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 88 / 255, green: 172 / 255, blue: 218 / 255)
            : Color(red: 72 / 255, green: 126 / 255, blue: 158 / 255)
    }

    static func selectedBackground(for colorScheme: ColorScheme) -> Color {
        ChemVaultLoadingConfiguration.primaryColor(for: colorScheme).opacity(colorScheme == .dark ? 0.18 : 0.12)
    }
}
