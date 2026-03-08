import SwiftUI

struct SegmentRowView: View {
    let segment: TranscriptionSegment
    let isActive: Bool
    let showTranslation: Bool
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timecode badge
            Button(action: onTap) {
                Text(segment.displayStartTime)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(isActive ? .white : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(isActive ? Color.accentColor : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .frame(width: 80, alignment: .trailing)

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(segment.text)
                    .font(.body)
                    .textSelection(.enabled)
                    .foregroundStyle(isActive ? .primary : .primary)

                if showTranslation, let translated = segment.translatedText {
                    Text(translated)
                        .font(.body)
                        .foregroundStyle(.blue)
                        .textSelection(.enabled)
                }
            }

            Spacer(minLength: 0)

            // Confidence indicator
            if let confidence = segment.confidence, isHovering {
                ConfidenceBadge(value: confidence)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.accentColor.opacity(0.08) :
                      isHovering ? Color.primary.opacity(0.03) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

struct ConfidenceBadge: View {
    let value: Float

    var body: some View {
        Text("\(Int(normalizedConfidence * 100))%")
            .font(.caption2)
            .foregroundStyle(confidenceColor)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(confidenceColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    // Whisper log probs are negative; -0.0 is perfect, < -1.0 is poor
    private var normalizedConfidence: Double {
        let clamped = max(min(Double(value), 0), -2)
        return 1.0 + clamped / 2.0
    }

    private var confidenceColor: Color {
        if normalizedConfidence > 0.8 { return .green }
        if normalizedConfidence > 0.5 { return .orange }
        return .red
    }
}
