import SwiftUI

// Apple Music's look: Liquid Glass where the SDK has it (iOS 26+), the system material before.
// One place, so every screen asks for the same treatment.

extension View {
    /// Liquid Glass in `shape` on iOS 26+; a regular material before.
    @ViewBuilder
    func appGlass<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            self.background(.regularMaterial, in: shape)
        }
    }
}

/// A press that dips the row the way Apple's lists do: a quick scale and dim, a spring back.
/// Reduce Motion drops the scale and keeps the dim.
struct PressRowStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
