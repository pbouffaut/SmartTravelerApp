import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CurrencyView()
                .tabItem {
                    Image(systemName: "coloncurrencysign.circle.fill")
                    Text("Currency")
                }
                .tag(0)

            ClockView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("Clock")
                }
                .tag(1)

            TranslatorView()
                .tabItem {
                    Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    Text("Translate")
                }
                .tag(2)

            NewsView()
                .tabItem {
                    Image(systemName: "newspaper.fill")
                    Text("News")
                }
                .tag(3)

            SafetyView()
                .tabItem {
                    Image(systemName: "shield.checkered")
                    Text("Safety")
                }
                .tag(4)
        }
        .tint(ST.Colors.accent)
        .screenBackground()
    }
}
