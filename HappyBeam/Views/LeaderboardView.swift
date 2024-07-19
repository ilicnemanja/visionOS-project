import SwiftUI
import FirebaseFirestore

struct LeaderboardView: View {
    @Environment(GameModel.self) var gameModel
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @StateObject private var leaderboardService = LeaderboardService()
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading scores...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Text("Leaderboard Table")
                    .font(.largeTitle)
                    .padding(.bottom, 20)
                
                HStack {
                    Text("Email")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10)
                    Text("Score")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 10)
                }
                .padding(.horizontal)
                
                ScrollView {
                    LeaderboardTable(scores: leaderboardService.leaderboard.map { ($0.email, $0.score) })
                }
                .padding(.bottom, 20)
                
                Spacer()
                
                Button {
                    Task {
                        await goBackToStart()
                    }
                } label: {
                    Text("Back to Main Menu")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .frame(width: 260)
            }
        }
        .padding(15)
        .frame(width: 634, height: 634)
        .onAppear {
            loadScores()
        }
        .navigationTitle("Leaderboard")
        .navigationBarHidden(true)
    }
    
    @MainActor
    func goBackToStart() async {
        await dismissImmersiveSpace()
        gameModel.reset()
    }
    
    private func loadScores() {
        leaderboardService.fetchLeaderboard()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Simulate loading delay
            isLoading = false
        }
    }
}
