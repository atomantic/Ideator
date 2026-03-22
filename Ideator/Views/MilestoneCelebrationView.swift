import SwiftUI

struct MilestoneCelebrationView: View {
    let achievements: [(id: String, name: String, icon: String)]
    let streak: Int
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    ForEach(achievements, id: \.id) { achievement in
                        VStack(spacing: 8) {
                            Image(systemName: achievement.icon)
                                .font(.system(size: 48))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .symbolEffect(.bounce, value: true)

                            Text(achievement.name)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }

                    if streak > 0 {
                        Text("\(streak)-day streak!")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    Text(motivationalMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 32)

                Button(action: onDismiss) {
                    Text("Keep Going!")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 48)

                Spacer()
            }

            if !reduceMotion {
                ConfettiView()
            }
        }
    }

    private var motivationalMessage: String {
        switch streak {
        case 3: return "You're building a habit. Keep it up!"
        case 7: return "One week of daily ideas. You're on fire!"
        case 14: return "Two weeks strong. Unstoppable!"
        case 30: return "A full month of creativity. Incredible!"
        case 60: return "Two months! You're an idea machine!"
        case 100: return "Triple digits. Legendary status!"
        case 365: return "One full year. You are extraordinary!"
        default:
            if let achievement = achievements.first {
                return "You earned the \(achievement.name) badge!"
            }
            return "Amazing work! Keep those ideas flowing!"
        }
    }
}
