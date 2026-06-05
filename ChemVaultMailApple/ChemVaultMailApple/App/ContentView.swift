import SwiftUI
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @EnvironmentObject private var authSession: AuthSession
    @State private var launchLoadingComplete = false
    @State private var bootstrapStarted = false

    var body: some View {
        Group {
            if !launchLoadingComplete || authSession.state == .checking {
                startupLoading
            } else {
                switch authSession.state {
                case .checking:
                    startupLoading
                case .signedOut:
                    LoginView()
                case .signedIn:
                    AppShellView()
                }
            }
        }
        .task {
            await bootstrapOnce()
        }
    }

    private var startupLoading: some View {
        ChemVaultLoadingView(
            title: ChemVaultLoadingConfiguration.title,
            subtitle: "Loading secure mailbox",
            size: 72,
            presentation: .startup
        )
        .transition(.opacity)
    }

    @MainActor
    private func bootstrapOnce() async {
        guard !bootstrapStarted else { return }
        bootstrapStarted = true

        async let bootstrap: Void = authSession.bootstrap()
        try? await Task.sleep(nanoseconds: UInt64(ChemVaultLoadingConfiguration.minimumPresentationMilliseconds) * 1_000_000)
        await bootstrap

        withAnimation(.easeInOut(duration: 0.2)) {
            launchLoadingComplete = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppEnvironment().authSession)
        .environmentObject(AppEnvironment())
}

enum ChemVaultLoadingConfiguration {
    static let primaryHex = "#1890FF"
    static let dotCount = 4
    static let rotationDuration = 2.0
    static let pulseDuration = 1.0
    static let minimumPresentationMilliseconds = 650
    static let title = "ChemVault Mail"
    static let primaryColor = Color(red: 24 / 255, green: 144 / 255, blue: 1)

    static func dotDelay(for index: Int) -> Double {
        switch index {
        case 0: return 0
        case 1: return 0.4
        case 2: return 0.8
        default: return 1.2
        }
    }
}

struct ChemVaultLoadingView: View {
    enum Presentation {
        case startup
        case card
        case inline
    }

    var title: String = ChemVaultLoadingConfiguration.title
    var subtitle: String?
    var size: CGFloat = 44
    var presentation: Presentation = .card

    var body: some View {
        switch presentation {
        case .startup:
            ZStack {
                ChemVaultBrandBackground()
                loadingContent
                    .padding(.horizontal, 28)
                    .padding(.vertical, 34)
            }
        case .card:
            loadingContent
                .padding(20)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(ChemVaultLoadingConfiguration.primaryColor.opacity(0.14), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 8)
        case .inline:
            HStack(spacing: 10) {
                ChemVaultLoadingMark(size: size, showsTrack: false)
                Text(subtitle ?? title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var loadingContent: some View {
        VStack(spacing: 16) {
            ChemVaultLoadingMark(size: size)
            VStack(spacing: 5) {
                Text(title)
                    .font(.title2.weight(.semibold))
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(subtitle ?? title)
    }
}

struct ChemVaultLoadingButtonLabel: View {
    var title: String
    var size: CGFloat = 18

    var body: some View {
        HStack(spacing: 8) {
            ChemVaultLoadingMark(size: size, showsTrack: false)
            Text(title)
        }
    }
}

struct ChemVaultLoadingMark: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRotating = false
    @State private var isPulsing = false
    @State private var isHaloVisible = false

    var size: CGFloat = 30
    var showsTrack = true

    var body: some View {
        ZStack {
            if showsTrack {
                Circle()
                    .stroke(ChemVaultLoadingConfiguration.primaryColor.opacity(0.12), lineWidth: max(1, size * 0.04))

                Circle()
                    .stroke(ChemVaultLoadingConfiguration.primaryColor.opacity(isHaloVisible ? 0.24 : 0.05), lineWidth: max(1, size * 0.03))
                    .scaleEffect(isHaloVisible ? 1.18 : 0.88)
                    .animation(haloAnimation, value: isHaloVisible)
            }

            ZStack {
                ForEach(0..<ChemVaultLoadingConfiguration.dotCount, id: \.self) { index in
                    Circle()
                        .fill(ChemVaultLoadingConfiguration.primaryColor)
                        .frame(width: dotSize, height: dotSize)
                        .opacity(isPulsing ? 1 : 0.3)
                        .scaleEffect(isPulsing ? 1 : 0.72)
                        .offset(orbitOffset(for: index))
                        .animation(dotAnimation(for: index), value: isPulsing)
                }
            }
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(rotationAnimation, value: isRotating)

            ChemVaultLogoBadge(size: size * 0.58, shadowRadius: showsTrack ? 8 : 0)
        }
        .frame(width: size, height: size)
        .onAppear {
            if reduceMotion {
                isPulsing = true
            } else {
                isRotating = true
                isPulsing = true
                isHaloVisible = true
            }
        }
        .accessibilityHidden(true)
    }

    private var dotSize: CGFloat {
        size * 0.22
    }

    private func orbitOffset(for index: Int) -> CGSize {
        let radius = size * 0.32
        let angle = (Double(index) / Double(ChemVaultLoadingConfiguration.dotCount)) * 2 * Double.pi
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }

    private func dotAnimation(for index: Int) -> Animation? {
        guard !reduceMotion else { return nil }
        return .easeInOut(duration: ChemVaultLoadingConfiguration.pulseDuration)
            .repeatForever(autoreverses: true)
            .delay(ChemVaultLoadingConfiguration.dotDelay(for: index))
    }

    private var rotationAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .linear(duration: ChemVaultLoadingConfiguration.rotationDuration)
            .repeatForever(autoreverses: false)
    }

    private var haloAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .easeInOut(duration: 1.35)
            .repeatForever(autoreverses: true)
    }
}

enum ChemVaultBrandAssets {
    static let backgroundImageName = "ChemVaultLoginBackground"
    static let logoImageName = "ChemVaultLogo"
    static let loginCardMaxWidth: CGFloat = 430
    static let loginWatermarkOpacity = 0.08
}

struct ChemVaultBrandBackground: View {
    var body: some View {
        GeometryReader { proxy in
            ChemVaultBundleImage(name: ChemVaultBrandAssets.backgroundImageName)
                .aspectRatio(contentMode: .fill)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
                .clipped()

            LinearGradient(
                colors: [
                    .white.opacity(0.18),
                    .white.opacity(0.42),
                    .white.opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

struct ChemVaultLogoBadge: View {
    var size: CGFloat
    var shadowRadius: CGFloat = 8

    var body: some View {
        ChemVaultBundleImage(name: ChemVaultBrandAssets.logoImageName)
            .scaledToFit()
            .frame(width: size, height: size)
            .background(.white.opacity(0.7), in: Circle())
            .shadow(color: .black.opacity(shadowRadius > 0 ? 0.08 : 0), radius: shadowRadius, x: 0, y: shadowRadius * 0.4)
    }
}

struct ChemVaultBundleImage: View {
    var name: String

    var body: some View {
#if os(macOS)
        if let image = ChemVaultBundleImages.nsImage(named: name) {
            Image(nsImage: image)
                .resizable()
        } else {
            Color.clear
        }
#elseif canImport(UIKit)
        if let image = ChemVaultBundleImages.uiImage(named: name) {
            Image(uiImage: image)
                .resizable()
        } else {
            Color.clear
        }
#else
        Color.clear
#endif
    }
}

private enum ChemVaultBundleImages {
#if os(macOS)
    static func nsImage(named name: String) -> NSImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png") {
            return NSImage(contentsOf: url)
        }
        return NSImage(named: NSImage.Name(name))
    }
#elseif canImport(UIKit)
    static func uiImage(named name: String) -> UIImage? {
        if let url = Bundle.main.url(forResource: name, withExtension: "png") {
            return UIImage(contentsOfFile: url.path)
        }
        return UIImage(named: name)
    }
#endif
}
