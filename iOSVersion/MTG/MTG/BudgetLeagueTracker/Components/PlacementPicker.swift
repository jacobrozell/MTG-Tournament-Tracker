import SwiftUI

/// A segmented picker for selecting placement (1st through 4th).
/// Ensures accessibility and disabled state support.
struct PlacementPicker: View {
    let playerName: String
    @Binding var selection: Int
    var isDisabled: Bool = false
    
    var body: some View {
        Picker("Placement", selection: $selection) {
            ForEach(1...4, id: \.self) { place in
                Text("\(place)")
                    .tag(place)
            }
        }
        .pickerStyle(.segmented)
        .disabled(isDisabled)
        .accessibilityLabel("Placement for \(playerName)")
        .accessibilityValue(placementLabel)
    }
    
    private var placementLabel: String {
        switch selection {
        case 1: return "First place"
        case 2: return "Second place"
        case 3: return "Third place"
        case 4: return "Fourth place"
        default: return "\(selection)"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PlacementPicker(playerName: "Alice", selection: .constant(1))
        PlacementPicker(playerName: "Bob", selection: .constant(2), isDisabled: true)
    }
    .padding()
}
