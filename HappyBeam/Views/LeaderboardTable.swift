import SwiftUI

struct LeaderboardTable: View {
    let scores: [(email: String, score: Int)]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(scores, id: \.email) { score in
                HStack {
                    Text(score.email)
                    Spacer()
                    Text("\(score.score)")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}
