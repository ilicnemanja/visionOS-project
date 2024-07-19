import SwiftUI

struct SoloScore: View {
    @Environment(GameModel.self) var gameModel
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    private var leaderboardService = LeaderboardService()
    @State private var email: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var navigateToLeaderboard = false  // State to trigger navigation

    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Image("greatJob")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 497, height: 200, alignment: .center)
                    .accessibilityHidden(true)
                Text("Awesome!", comment: "Praise for the player.")
                    .font(.system(size: 36, weight: .bold))
                Text("You collected a total of \(gameModel.score) balls!", comment: "This text describes the results of the players efforts in the game.")
                    .multilineTextAlignment(.center)
                    .font(.headline)
                    .frame(width: 340)
                TextField("Enter your email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.emailAddress)
                    .frame(width: 360)
                Group {
                    Button {
                        addScore()
                    } label: {
                        Text("Submit Score", comment: "An action to submit the player's score to the leaderboard.")
                            .frame(maxWidth: .infinity)
                    }
                    Button {
                        playAgain()
                    } label: {
                        Text("Play Again", comment: "An action the player can take after the game has concluded, to play again.")
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: 260)
            }
            .padding(15)
            .frame(width: 300, height: 450)
            .navigationDestination(isPresented: $navigateToLeaderboard) {
                LeaderboardView()
            }
        }
    }

    func playAgain() {
        let inputChoice = gameModel.inputKind
        gameModel.reset()
        
        if beamIntermediate.parent == nil {
            spaceOrigin.addChild(beamIntermediate)
        }
        
        gameModel.isPlaying = true
        gameModel.isInputSelected = true
        gameModel.isCountDownReady = true
        gameModel.inputKind = inputChoice
    }
    
    func addScore() {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email."
            showAlert = true
            return
        }
        
        leaderboardService.addScore(email: email, score: gameModel.score) { error in
            if let error = error {
                alertMessage = "Error adding score: \(error.localizedDescription)"
            } else {
                alertMessage = "Score added successfully!"
                navigateToLeaderboard = true // Trigger navigation to LeaderboardView
            }
            showAlert = true
        }
    }
}
