import SwiftUI

struct LevelCompletion: View {
    @Environment(GameModel.self) var gameModel
    var onNextLevel: () -> Void
    var onStartOver: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Level \(gameModel.level) Complete!", comment: "Praise for the player.")
                .font(.system(size: 36, weight: .bold))
            Text("You collected a total of \(gameModel.score) balls!", comment: "This text describes the results of the player's efforts in the game.")
                .multilineTextAlignment(.center)
                .font(.headline)
                .frame(width: 340)
            HStack(spacing: 20) {
                Button("Next Level") {
                    onNextLevel()
                }
                .padding()
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Start Over") {
                    onStartOver()
                }
                .padding()
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.top, 16)
            Spacer()
        }
        .padding(30)
        .cornerRadius(32)
        .frame(width: 634, height: 499)
    }
}

#Preview {
    LevelCompletion(onNextLevel: {}, onStartOver: {})
        .environment(GameModel())
}
