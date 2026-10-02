import SwiftUI

/// Flat circular button in the style of Control Center modules.
struct RoundButton: View {
    var symbol: String
    var diameter: CGFloat = 40
    var tint: Color? = nil
    var action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: diameter * 0.36, weight: .semibold))
                .foregroundStyle(tint == nil ? AnyShapeStyle(.primary) : AnyShapeStyle(.white))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: diameter, height: diameter)
                .background {
                    Circle().fill(tint.map { AnyShapeStyle($0) } ?? AnyShapeStyle(.primary.opacity(hovering ? 0.14 : 0.09)))
                }
                .brightness(tint != nil && hovering ? 0.04 : 0)
                .contentShape(Circle())
        }
        .buttonStyle(PressStyle())
        .onHover { hovering = $0 }
    }
}

private struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

/// Two-option capsule switch whose selected pill takes the current session color.
struct ModePicker: View {
    var selection: Mode
    var tint: Color
    var onSelect: (Mode) -> Void

    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Mode.allCases) { mode in
                let selected = mode == selection
                Button { onSelect(mode) } label: {
                    Text(mode.label)
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(selected ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                        .frame(width: 66, height: 24)
                        .background {
                            if selected {
                                Capsule().fill(tint).matchedGeometryEffect(id: "pill", in: pill)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(.primary.opacity(0.07), in: Capsule())
        .animation(.snappy(duration: 0.25), value: selection)
        .animation(.easeInOut(duration: 0.3), value: tint)
    }
}

struct ToggleRow: View {
    var symbol: String
    var title: String
    var detail: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13))
                if let detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Toggle(title, isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
        .frame(minHeight: 30)
    }
}

/// Small borderless button: an icon, a label, or both.
struct PlainButton: View {
    var title: String = ""
    var symbol: String? = nil
    var action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let symbol { Image(systemName: symbol) }
                if !title.isEmpty { Text(title) }
            }
            .font(.system(size: 12))
            .foregroundStyle(hovering ? .primary : .secondary)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(.primary.opacity(hovering ? 0.07 : 0), in: .rect(cornerRadius: 6))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
