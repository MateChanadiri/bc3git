import BitChordCore
import PlaybackQueue
import SwiftUI

/// The New tab: YouTube Music's new releases (the "FEmusic_new_releases" feed Home already pulls as
/// a supplement), as Apple Music's New page lays it out — a big title over rows of cards.
struct NewScreen: View {
    @Environment(AppModel.self) private var model
    @State private var state: LoadState<[HomeShelf]> = .loading

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                switch state {
                case .loading:
                    ShelfCardsSkeleton()
                case .error(let message):
                    BrowseMessage(message: message, actionTitle: L10n.retry) { Task { await load() } }
                case .success(let shelves):
                    ForEach(Array(shelves.enumerated()), id: \.offset) { _, shelf in
                        HomeShelfRow(shelf: shelf, onOpen: { item in
                            BrowseNavigator(app: model).openCard(item, source: QueueSource(title: shelf.title, type: .home))
                        }, onMenu: { BrowseNavigator(app: model).openCardMenu($0) })
                    }
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .refreshable { await load() }
        .navigationTitle(AppleMusicText.new)
        .navigationBarTitleDisplayMode(.large)
        .task { if state.isLoading { await load() } }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("screen.new")
    }

    private func load() async {
        let catalog = model.repository
        // Unstructured, so a pull that SwiftUI cancels does not fail the fetch (see HomeFeedModel).
        let result: LoadState<[HomeShelf]> = await Task {
            do {
                let shelves = try await catalog.homeSupplement(browseId: "FEmusic_new_releases").filter { !$0.items.isEmpty }
                return shelves.isEmpty ? .error(L10n.noTracksHere) : .success(shelves)
            } catch {
                return .error(BrowseErrorText.friendly(error))
            }
        }.value
        if case .error = result, state.value != nil { return }
        state = result
    }
}
