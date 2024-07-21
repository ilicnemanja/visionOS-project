import SwiftUI

struct SoloScore: View {
    @Environment(GameModel.self) var gameModel
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    private var leaderboardService = LeaderboardService()
    @State private var email: String = ""
    @State private var nickname: String = ""
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
                VStack(spacing: 0) { // Adjust spacing here for TextFields
                    TextField("Enter your nickname", text: $nickname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .keyboardType(.default)
                        .frame(width: 360)
                    
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .keyboardType(.emailAddress)
                        .frame(width: 360)
                }
                
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
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Validation Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .navigationDestination(isPresented: $navigateToLeaderboard) {
                LeaderboardView()
            }
        }
        .frame(width: 660, height: 700)
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
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
        guard !nickname.isEmpty else {
            alertMessage = "Please enter your nickname."
            showAlert = true
            return
        }

        guard isValidEmail(email) else {
            alertMessage = "Please enter a valid email."
            showAlert = true
            return
        }

        leaderboardService.addScore(email: email, nickname: nickname, score: gameModel.score) { error in
            if let error = error {
                alertMessage = "Error adding score: \(error.localizedDescription)"
            } else {
                showAlert = false
                alertMessage = "Score added successfully!"
                navigateToLeaderboard = true // Trigger navigation to LeaderboardView
            }
            
        }
    }
}
