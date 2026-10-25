import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(enabled ? 0.28 : 0.1))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

struct SetupView: View {
    @EnvironmentObject var settings: AppSettings

    @State private var step = 0
    @State private var name = ""
    @State private var folderData: Data?
    @State private var folderName = ""
    @State private var useFaceID = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.07, blue: 0.28), Color(red: 0.55, green: 0.16, blue: 0.50)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)

                if step == 0 { nameStep } else { folderStep }
                Spacer()
            }
            .padding(28)
            .frame(maxWidth: 480)
        }
        .animation(.easeInOut, value: step)
    }

    private var nameStep: some View {
        VStack(spacing: 18) {
            Text("Καλώς ήρθες!")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Text("Πώς σε λένε;")
                .foregroundColor(Color.white.opacity(0.8))
            TextField("Το όνομά σου", text: $name)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .submitLabel(.next)
                .onSubmit { if !trimmedName.isEmpty { step = 1 } }
            Button("Συνέχεια") { step = 1 }
                .buttonStyle(PrimaryButtonStyle(enabled: !trimmedName.isEmpty))
                .disabled(trimmedName.isEmpty)
        }
    }

    private var folderStep: some View {
        VStack(spacing: 18) {
            Text("Γεια σου \(trimmedName)!")
                .font(.title.bold())
                .foregroundColor(.white)
            Text("Από ποιον φάκελο θέλεις να διαβάζεις comics;")
                .multilineTextAlignment(.center)
                .foregroundColor(Color.white.opacity(0.8))

            Button {
                FolderPicker.present { url in
                    if let data = FolderAccess.makeBookmark(from: url) {
                        folderData = data
                        folderName = url.lastPathComponent
                    }
                }
            } label: {
                Label(folderName.isEmpty ? "Επιλογή φακέλου" : folderName, systemImage: "folder.fill")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                _ = FolderAccess.appDocumentsURL()
                folderData = FolderAccess.appFolderMarker
                folderName = "Φάκελος εφαρμογής"
            } label: {
                Label("Χρήση φακέλου της εφαρμογής", systemImage: "iphone")
            }
            .buttonStyle(PrimaryButtonStyle())

            Text("Ο φάκελος της εφαρμογής βρίσκεται στο Files → Στο iPhone μου → Comic Reader. Βάλε εκεί τα CBZ/PDF.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.white.opacity(0.65))

            Toggle(isOn: $useFaceID) {
                Label("Κλείδωμα με Face ID", systemImage: "faceid")
                    .foregroundColor(.white)
            }
            .disabled(!BiometricAuth.canAuthenticate())
            .padding(.horizontal, 4)

            Button("Ξεκινάμε") { finish() }
                .buttonStyle(PrimaryButtonStyle(enabled: folderData != nil))
                .disabled(folderData == nil)

            Button("Πίσω") { step = 0 }
                .foregroundColor(Color.white.opacity(0.7))
        }
    }

    private func finish() {
        guard let folderData else { return }
        settings.folderBookmark = folderData
        settings.faceIDLock = useFaceID
        settings.userName = trimmedName
        settings.setupDone = true
    }
}
