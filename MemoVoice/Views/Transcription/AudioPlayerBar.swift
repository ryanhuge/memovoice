import SwiftUI

struct AudioPlayerBar: View {
    let project: TranscriptionProject
    @Bindable var playerVM: AudioPlayerViewModel

    @State private var isDragging = false
    @State private var dragTime: Double = 0

    var body: some View {
        VStack(spacing: 4) {
            // Timeline slider
            Slider(
                value: isDragging ? $dragTime : .init(
                    get: { playerVM.currentTime },
                    set: { dragTime = $0 }
                ),
                in: 0...max(playerVM.duration, 1),
                onEditingChanged: { editing in
                    if editing {
                        isDragging = true
                        dragTime = playerVM.currentTime
                    } else {
                        isDragging = false
                        playerVM.seek(to: dragTime)
                    }
                }
            )
            .padding(.horizontal, 16)

            // Controls
            HStack(spacing: 16) {
                // Current time
                Text(TimeFormatters.displayTime(from: isDragging ? dragTime : playerVM.currentTime))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 60, alignment: .leading)

                Spacer()

                // Playback controls
                HStack(spacing: 12) {
                    Button {
                        playerVM.skipBackward()
                    } label: {
                        Image(systemName: "gobackward.5")
                    }
                    .keyboardShortcut(.leftArrow, modifiers: [])

                    Button {
                        playerVM.togglePlayback()
                    } label: {
                        Image(systemName: playerVM.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                    }
                    .keyboardShortcut(.space, modifiers: [])

                    Button {
                        playerVM.skipForward()
                    } label: {
                        Image(systemName: "goforward.5")
                    }
                    .keyboardShortcut(.rightArrow, modifiers: [])
                }

                Spacer()

                // Speed control + duration
                HStack(spacing: 8) {
                    Menu {
                        ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
                            Button("\(rate, specifier: "%.2g")x") {
                                playerVM.setRate(Float(rate))
                            }
                        }
                    } label: {
                        Text("\(playerVM.playbackRate, specifier: "%.2g")x")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    Text(TimeFormatters.displayTime(from: playerVM.duration))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 60, alignment: .trailing)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(.bar)
        .buttonStyle(.plain)
    }
}
