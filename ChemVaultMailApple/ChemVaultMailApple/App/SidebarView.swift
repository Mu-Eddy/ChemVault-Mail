import SwiftUI

struct SidebarView: View {
    @Binding var selection: AppRoute
    @EnvironmentObject private var authSession: AuthSession
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        List {
            Section {
                ChemVaultSidebarHeader(user: authSession.currentUser)
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            ForEach(groupedRoutes, id: \.title) { group in
                Section(group.title) {
                    ForEach(group.routes) { route in
                        Button {
                            withAnimation(reduceMotion ? nil : ChemVaultMotion.rootContent) {
                                selection = route
                            }
                        } label: {
                            SidebarRouteRow(
                                route: route,
                                isSelected: selection == route,
                                isAvailable: route.isAvailable(for: authSession.currentUser)
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                        .listRowSeparator(.hidden)
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selection == route ? ChemVaultWorkspaceTheme.selectedBackground(for: colorScheme) : Color.clear)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                        )
                    }
                }
            }

            Section {
                ChemVaultSidebarFooter()
                    .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("ChemVault Mail")
        .scrollContentBackground(.hidden)
        .background(ChemVaultWorkspaceBackground())
        #if os(macOS)
        .listStyle(.sidebar)
        #endif
    }

    private var groupedRoutes: [(title: String, routes: [AppRoute])] {
        let order = ["Mail", "Personal", "Admin", "Insights"]
        return order.compactMap { title in
            let routes = AppRoute.allCases.filter { $0.groupTitle == title }
            return routes.isEmpty ? nil : (title, routes)
        }
    }
}

private struct ChemVaultSidebarHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    let user: ChemVaultUser?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ChemVaultLogoBadge(size: 42, shadowRadius: 9)

                VStack(alignment: .leading, spacing: 3) {
                    Text("ChemVault")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(ChemVaultTheme.brandText(for: colorScheme))
                    Text("Secure mailbox")
                        .font(.caption)
                        .foregroundStyle(ChemVaultTheme.secondaryText(for: colorScheme))
                }
            }

            HStack(spacing: 10) {
                ChemVaultUserAvatar(user: user, size: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(userDisplayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(user?.email ?? "Signed in")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if let roleName = user?.role?.name, !roleName.isEmpty {
                Label(roleName, systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ChemVaultLoadingConfiguration.primaryColor(for: colorScheme))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ChemVaultLoadingConfiguration.primaryColor(for: colorScheme).opacity(0.12), in: Capsule())
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ChemVaultWorkspaceTheme.panelBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(ChemVaultWorkspaceTheme.panelStroke(for: colorScheme), lineWidth: 1)
        }
    }

    private var userDisplayName: String {
        if let name = user?.name, !name.isEmpty { return name }
        return user?.email ?? "ChemVault User"
    }
}

struct ChemVaultUserAvatar: View {
    @Environment(\.colorScheme) private var colorScheme
    let user: ChemVaultUser?
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(ChemVaultLoadingConfiguration.primaryColor(for: colorScheme).opacity(0.14))
            Text(initials)
                .font(.system(size: max(12, size * 0.36), weight: .semibold))
                .foregroundStyle(ChemVaultLoadingConfiguration.primaryColor(for: colorScheme))
        }
        .frame(width: size, height: size)
        .overlay {
            Circle()
                .stroke(ChemVaultWorkspaceTheme.panelStroke(for: colorScheme), lineWidth: 1)
        }
    }

    private var initials: String {
        let source = user?.name?.nilIfBlank ?? user?.email ?? "CV"
        let parts = source
            .split { !$0.isLetter && !$0.isNumber }
            .prefix(2)
        let value = parts.compactMap(\.first).map { String($0).uppercased() }.joined()
        return value.isEmpty ? "CV" : value
    }
}

private struct ChemVaultSidebarFooter: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.caption.weight(.semibold))
            Text("Encrypted session")
                .font(.caption)
            Spacer(minLength: 0)
            Circle()
                .fill(Color.green)
                .frame(width: 7, height: 7)
        }
        .foregroundStyle(ChemVaultTheme.secondaryText(for: colorScheme))
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(ChemVaultWorkspaceTheme.panelBackground(for: colorScheme), in: Capsule())
    }
}

private struct SidebarRouteRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let route: AppRoute
    let isSelected: Bool
    let isAvailable: Bool

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? ChemVaultLoadingConfiguration.primaryColor(for: colorScheme) : ChemVaultTheme.fieldBackground(for: colorScheme))
                    .frame(width: 30, height: 30)

                Image(systemName: route.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : ChemVaultLoadingConfiguration.primaryColor(for: colorScheme))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(route.title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                Text(route.groupTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !isAvailable {
                Image(systemName: "lock")
                    .foregroundStyle(.secondary)
            } else if isSelected {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ChemVaultLoadingConfiguration.primaryColor(for: colorScheme))
            }
        }
        .foregroundStyle(isSelected ? ChemVaultTheme.brandText(for: colorScheme) : Color.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .contentShape(Rectangle())
    }
}
