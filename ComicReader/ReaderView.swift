import SwiftUI

struct ReaderView: View {
    let item: ComicItem

    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var session: ComicSession?
    @State private var page = 0
    @State private var showChrome = true
    @State private var failed = false

    private var pageKey: String { "page:" + item.id }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let session {
                ComicPager(
                    session: session,
                    page: $page,
                    animated: settings.pageMode == .book,
                    onToggleChrome: { withAnimation(.easeInOut(duration: 0.2)) { showChrome.toggle() } }
                )
                .ignoresSafeArea()

                if showChrome {
                    VStack {
                        topBar
                        Spacer()
                        bottomBar(count: session.pageCount)
                    }
                    .transition(.opacity)
                }
            } else if failed {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                    Text("Δεν μπόρεσα να ανοίξω αυτό το αρχείο.")
                    Button("Πίσω") { dismiss() }
                }
                .foregroundColor(.white)
            } else {
                ProgressView().tint(.white)
            }
        }
        .statusBarHidden(!showChrome)
        .onAppear(perform: open)
        .onChange(of: page) { newPage in
            UserDefaults.standard.set(newPage, forKey: pageKey)
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }
            Text(item.name)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Menu {
                Picker("Αλλαγή σελίδας", selection: $settings.pageMode) {
                    ForEach(PageMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.icon).tag(mode)
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func bottomBar(count: Int) -> some View {
        VStack(spacing: 6) {
            Text("\(page + 1) / \(count)")
                .font(.footnote.monospacedDigit())
            Slider(
                value: Binding(
                    get: { Double(page) },
                    set: { page = Int($0.rounded()) }
                ),
                in: 0...Double(max(count - 1, 1)),
                step: 1
            )
            .disabled(count <= 1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func open() {
        guard session == nil else { return }
        let url = item.url
        let saved = UserDefaults.standard.integer(forKey: pageKey)
        DispatchQueue.global(qos: .userInitiated).async {
            let doc = ComicLoader.open(url: url)
            DispatchQueue.main.async {
                if let doc {
                    page = min(max(saved, 0), doc.pageCount - 1)
                    session = ComicSession(doc: doc)
                } else {
                    failed = true
                }
            }
        }
    }
}
