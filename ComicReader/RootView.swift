import SwiftUI

struct RootView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.scenePhase) private var phase

    @State private var locked: Bool
    @State private var showWelcome = true
    @State private var authBusy = false

    init() {
        let d = UserDefaults.standard
        let needLock = d.bool(forKey: AppSettings.Keys.faceID) && d.bool(forKey: AppSettings.Keys.setupDone)
        _locked = State(initialValue: needLock)
    }

    var body: some View {
        ZStack {
            if settings.setupDone {
                LibraryView()
            } else {
                SetupView()
            }

            if settings.setupDone && showWelcome && !locked {
                WelcomeView(name: settings.userName) {
                    withAnimation(.easeInOut(duration: 0.5)) { showWelcome = false }
                }
                .transition(.opacity)
                .zIndex(1)
            }

            if settings.faceIDLock && settings.setupDone && phase != .active && !locked {
                Color.black.ignoresSafeArea().zIndex(2)
            }

            if locked {
                LockView(unlock: authenticate)
                    .zIndex(3)
            }
        }
        .onAppear { authenticate() }
        .onChange(of: phase) { newPhase in
            if newPhase == .background, settings.faceIDLock, settings.setupDone {
                locked = true
            }
            if newPhase == .active {
                authenticate()
            }
        }
        .onChange(of: settings.setupDone) { done in
            if done { showWelcome = false }
        }
    }

    private func authenticate() {
        guard locked, !authBusy else { return }
        guard BiometricAuth.canAuthenticate() else {
            locked = false
            return
        }
        authBusy = true
        BiometricAuth.authenticate(reason: "Ξεκλείδωμα του Comic Reader") { ok in
            authBusy = false
            if ok { locked = false }
        }
    }
}

struct LockView: View {
    let unlock: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.06, blue: 0.2), Color(red: 0.35, green: 0.12, blue: 0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "faceid")
                    .font(.system(size: 70))
                    .foregroundColor(.white)
                Text("Κλειδωμένο")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                Button(action: unlock) {
                    Text("Ξεκλείδωμα")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundColor(.white)
                }
            }
        }
    }
}
