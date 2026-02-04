import SwiftUI

/// A stepper control with a label showing the current value.
/// Uses custom buttons with 44pt minimum touch targets for accessibility.
struct LabeledStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var accessibilityLabel: String?
    
    private var canDecrement: Bool {
        value > range.lowerBound
    }
    
    private var canIncrement: Bool {
        value < range.upperBound
    }
    
    var body: some View {
        HStack {
            Text("\(title): \(value)")
                .font(.body)
            
            Spacer()
            
            HStack(spacing: 0) {
                Button {
                    if canDecrement {
                        value -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.body.weight(.semibold))
                        .frame(width: AppConstants.UI.minTouchTargetHeight, height: AppConstants.UI.minTouchTargetHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .disabled(!canDecrement)
                .accessibilityLabel("Decrease \(accessibilityLabel ?? title)")
                
                Button {
                    if canIncrement {
                        value += 1
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .frame(width: AppConstants.UI.minTouchTargetHeight, height: AppConstants.UI.minTouchTargetHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.bordered)
                .disabled(!canIncrement)
                .accessibilityLabel("Increase \(accessibilityLabel ?? title)")
            }
        }
        .frame(minHeight: AppConstants.UI.minTouchTargetHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel ?? title)
        .accessibilityValue("\(value)")
    }
}

#Preview {
    List {
        LabeledStepper(title: "Weeks", value: .constant(6), range: 1...99)
        LabeledStepper(title: "Random achievements", value: .constant(2), range: 0...99)
    }
    .listStyle(.insetGrouped)
}
