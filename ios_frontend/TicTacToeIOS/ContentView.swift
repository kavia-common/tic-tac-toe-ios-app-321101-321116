import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text("Tic Tac Toe")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primary)

                    Text(viewModel.statusText)
                        .font(.headline)
                        .foregroundStyle(viewModel.statusColor)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("statusText")
                }

                board

                Button {
                    viewModel.reset()
                } label: {
                    Text("Reset")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.23, green: 0.51, blue: 0.96)) // #3b82f6
                .accessibilityIdentifier("resetButton")

                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: 460)
        }
    }

    private var board: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<9, id: \.self) { idx in
                CellButton(
                    title: viewModel.cellTitle(at: idx),
                    isWinningCell: viewModel.winningLine.contains(idx),
                    action: { viewModel.tapCell(at: idx) }
                )
                .aspectRatio(1, contentMode: .fit)
                .accessibilityIdentifier("cellButton_\(idx)")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
        )
        .accessibilityIdentifier("boardGrid")
    }
}

private struct CellButton: View {
    let title: String
    let isWinningCell: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isWinningCell ? Color(red: 0.02, green: 0.71, blue: 0.83) : Color(.separator).opacity(0.35), lineWidth: isWinningCell ? 3 : 1)
                    )

                Text(title)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(title == "X" ? Color(red: 0.23, green: 0.51, blue: 0.96) : Color(red: 0.39, green: 0.45, blue: 0.55))
                    .accessibilityLabel(title.isEmpty ? "Empty" : title)
            }
        }
        .buttonStyle(.plain)
        .disabled(!title.isEmpty) // Disable already selected cells (view model also guards)
    }
}

#Preview {
    ContentView()
}
