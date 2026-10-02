import SwiftUI

struct DonutView: View {
    var progress: Double
    var color: Color
    var time: String
    var caption: String

    private let lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(.primary.opacity(0.08), lineWidth: lineWidth)
            // Elapsed time sweeps clockwise from 12 o'clock; the colored arc is what's left.
            Circle()
                .trim(from: 1 - progress, to: 1)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .opacity(progress > 0.001 ? 1 : 0)
                .animation(.linear(duration: 0.25), value: progress)
                .animation(.easeInOut(duration: 0.3), value: color)

            VStack(spacing: 2) {
                Text(time)
                    .font(.system(size: 40, weight: .light))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy(duration: 0.25), value: time)
                Text(caption.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.3)
                    .foregroundStyle(.secondary)
            }
            .offset(y: 3)
        }
        .frame(width: 158, height: 158)
        .padding(lineWidth / 2)
    }
}
