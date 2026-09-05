import SwiftUI

struct FilterBar: View {
    @Binding var selectedTypes: Set<GameType>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(GameType.allCases) { type in
                    Button(action: { toggle(type) }) {
                        Text(type.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(selectedTypes.contains(type) ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTypes.contains(type) ? .white : .primary)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(18)
    }

    private func toggle(_ type: GameType) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }
}
