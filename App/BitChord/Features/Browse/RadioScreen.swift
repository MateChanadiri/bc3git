import BitChordCore
import SwiftUI

/// The Radio tab: stations, as Apple Music's Radio page offers them. A station here is YouTube
/// Music's own radio for a song (the "Start radio" action the player and song menu already have),
/// so this page lists the songs worth starting one from: what you played last, then the songs on
/// Home's shelves. Tapping a card starts the station.
struct RadioScreen: View {
    @Environment(AppModel.self) private var model
    @State private var state: LoadState<[HomeShelf]> = .loading

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text(AppleMusicText.radioIntro)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, BrowseMetrics.gutter)
                    .padding(.bottom, 12)
                switch state {
                case .loading:
                    ShelfCardsSkeleton()
                case .error(let message):
                    BrowseMessage(message: message, actionTitle: L10n.retry) { Task { await load() } }
                case .success(let shelves):
                    ForEach(Array(shelves.enumerated()), id: \.offset) { _, shelf in
                        HomeShelfRow(shelf: shelf, onOpen: start, onMenu: { BrowseNavigator(app: model).openCardMenu($0) })
                    }
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .refreshable { await load() }
        .navigationTitle(AppleMusicText.radio)
        .navigationBarTitleDisplayMode(.large)
        .task(id: model.accounts.listenerKey) { await load() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.radio")
    }

    private func start(_ item: ShelfItem) {
        guard let song = item.shelfSong else { return }
        Haptics.shared.play(.tap)
        Task { await model.player.startRadio(from: song) }
    }

    /// Recently played (signed in), then every Home shelf's song cards — only shelves with songs.
    private func load() async {
        let catalog = model.repository
        let signedIn = model.accounts.isSignedIn
        let result: [HomeShelf] = await Task {
            var shelves: [HomeShelf] = []
            if signedIn, let recent = try? await catalog.homeRecentlyPlayed() { shelves.append(recent) }
            if let feed = try? await catalog.home() { shelves.append(contentsOf: feed.shelves) }
            return shelves.compactMap { shelf -> HomeShelf? in
                let songs = shelf.items.filter { $0.shelfSong != nil }
                return songs.isEmpty ? nil : HomeShelf(title: shelf.title, items: songs)
            }
        }.value
        if result.isEmpty {
            if state.value == nil { state = .error(L10n.couldntLoadTracks) }
        } else {
            state = .success(result)
        }
    }
}
