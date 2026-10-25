import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    private var folderName: String {
        guard let data = settings.folderBookmark else { return "—" }
        if data == FolderAccess.appFolderMarker { return "Φάκελος εφαρμογής" }
        guard let url = FolderAccess.resolve(data) else { return "—" }
        return url.lastPathComponent
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Όνομα") {
                    TextField("Το όνομά σου", text: $settings.userName)
                }

                Section {
                    Picker("Αλλαγή σελίδας", selection: $settings.pageMode) {
                        ForEach(PageMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Τρόπος αλλαγής σελίδας")
                } footer: {
                    Text("Πάτα στη δεξιά πλευρά της οθόνης για επόμενη σελίδα και στην αριστερή για προηγούμενη. Στη μέση εμφανίζεται/κρύβεται το μενού.")
                }

                Section {
                    HStack {
                        Text(folderName)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Αλλαγή") {
                            FolderPicker.present { url in
                                if let data = FolderAccess.makeBookmark(from: url) {
                                    settings.folderBookmark = data
                                }
                            }
                        }
                    }
                    Button("Χρήση φακέλου της εφαρμογής") {
                        _ = FolderAccess.appDocumentsURL()
                        settings.folderBookmark = FolderAccess.appFolderMarker
                    }
                } header: {
                    Text("Φάκελος comics")
                } footer: {
                    Text("Φάκελος εφαρμογής: Files → Στο iPhone μου → Comic Reader.")
                }

                Section("Ασφάλεια") {
                    Toggle("Κλείδωμα με Face ID", isOn: Binding(
                        get: { settings.faceIDLock },
                        set: { newValue in
                            if newValue {
                                BiometricAuth.authenticate(reason: "Ενεργοποίηση κλειδώματος") { ok in
                                    if ok { settings.faceIDLock = true }
                                }
                            } else {
                                settings.faceIDLock = false
                            }
                        }
                    ))
                    .disabled(!BiometricAuth.canAuthenticate())
                }
            }
            .navigationTitle("Ρυθμίσεις")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Έτοιμο") { dismiss() }
                }
            }
        }
    }
}
