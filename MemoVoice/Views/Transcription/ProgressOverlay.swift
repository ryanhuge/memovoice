import SwiftUI

struct ProgressOverlay: View {
    let status: String
    let progress: Double

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.semibold)
            }

            Text(status)
                .font(.headline)
                .foregroundStyle(.secondary)

            if progress > 0 {
                ProgressView(value: progress)
                    .frame(width: 200)
            } else {
                ProgressView()
                    .progressViewStyle(.linear)
                    .frame(width: 200)
            }
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
