import BitChordCore
import PlaybackQueue
import SwiftUI

/// Library → Songs: the songs saved to the account's library, then the liked ones not already in
/// it, in the account's own order. Tapping a row plays the list from there. Read live from the
/// Library's page, so nothing is fetched twice.
struct LibrarySongsScreen: View {
    @Environment(AppModel.self) private var model

    private var store: CollectionsStore { CollectionsStore.shared(for: model) }

    var body: some View {
        let store = store
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                switch store.library {
                case .loading:
                    ForEach(0..<8, id: \.self) { _ in SongRowSkeleton() }
                case .error(let message):
                    MessageState(message: message, actionLabel: L10n.retry) { Task { await store.loadLibrary() } }
                case .success(let page):
                    let songs = Self.songs(in: page)
                    if songs.isEmpty {
                        MessageState(message: L10n.noTracksHere, actionLabel: nil, action: nil)
                    } else {
                        ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                            SongRow(song: song) {
                                model.player.play(songs, startAt: index, source: QueueSource(title: L10n.songs, type: .home))
                            }
                        }
                    }
                }
            }
        }
        .collectionsListBottomInset()
        .navigationTitle(L10n.songs)
        .navigationBarTitleDisplayMode(.large)
        .task(id: store.service.listenerKey) { await store.loadLibraryIfNeeded() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.librarySongs")
    }

    /// Library songs first, then liked songs that are not among them.
    static func songs(in page: LibraryPage) -> [Song] {
        var seen = Set(page.librarySongs.map(\.id))
        return page.librarySongs + page.likedSongs.filter { seen.insert($0.id).inserted }
    }
}
