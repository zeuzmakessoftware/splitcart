import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            SwipeScreen()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
