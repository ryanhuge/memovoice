import SwiftUI

struct SegmentListView: View {
    let segments: [TranscriptionSegment]
    let showTranslation: Bool
    let currentPlaybackTime: Double
    let onSegmentTap: (TranscriptionSegment) -> Void

    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search transcript...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.bar)

            Divider()

            // Segments
            ScrollViewReader { proxy in
                List {
                    ForEach(filteredSegments) { segment in
                        SegmentRowView(
                            segment: segment,
                            isActive: isSegmentActive(segment),
                            showTranslation: showTranslation,
                            onTap: { onSegmentTap(segment) }
                        )
                        .id(segment.id)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                    }
                }
                .listStyle(.plain)
                .onChange(of: currentPlaybackTime) { _, newTime in
                    if let activeSegment = segments.first(where: { isSegmentActive($0, at: newTime) }) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(activeSegment.id, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private var filteredSegments: [TranscriptionSegment] {
        if searchText.isEmpty {
            return segments
        }
        let query = searchText.lowercased()
        return segments.filter { segment in
            segment.text.lowercased().contains(query) ||
            (segment.translatedText?.lowercased().contains(query) ?? false)
        }
    }

    private func isSegmentActive(_ segment: TranscriptionSegment) -> Bool {
        isSegmentActive(segment, at: currentPlaybackTime)
    }

    private func isSegmentActive(_ segment: TranscriptionSegment, at time: Double) -> Bool {
        time >= segment.startTime && time < segment.endTime
    }
}
