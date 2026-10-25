import SwiftUI

struct WelcomeView: View {
    let name: String
    let onFinish: () -> Void

    @State private var appear = false
    @State private var finished = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.07, blue: 0.28), Color(red: 0.86, green: 0.25, blue: 0.50)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.white)
                    .scaleEffect(appear ? 1 : 0.3)
                    .rotationEffect(.degrees(appear ? 0 : -25))
                    .opacity(appear ? 1 : 0)

                Text("Welcome back")
                    .font(.title3)
                    .foregroundColor(Color.white.opacity(0.85))
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 14)

                Text(name)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(appear ? 1 : 0.7)
                    .opacity(appear ? 1 : 0)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.65)) { appear = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { finish() }
        }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onFinish()
    }
}
