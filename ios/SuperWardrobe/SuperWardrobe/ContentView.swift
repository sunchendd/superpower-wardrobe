import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showAddItem = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                RecommendationView()
            }
            .tabItem { Label("推荐", systemImage: "sparkles") }
            .tag(0)

            NavigationStack {
                WardrobeView()
            }
            .tabItem { Label("衣橱", systemImage: "tshirt") }
            .tag(1)

            // Center add button
            Color.clear
                .tabItem { Label("添加", systemImage: "plus.circle.fill") }
                .tag(2)

            NavigationStack {
                StatisticsView()
            }
            .tabItem { Label("统计", systemImage: "chart.pie") }
            .tag(3)

            NavigationStack {
                SettingsAppView()
            }
            .tabItem { Label("设置", systemImage: "gearshape") }
            .tag(4)
        }
        .onChange(of: selectedTab) { old, new in
            if new == 2 {
                showAddItem = true
                selectedTab = old
            }
        }
        .sheet(isPresented: $showAddItem) {
            NavigationStack { AddItemView() }
        }
        .tint(.indigo)
    }
}

#Preview {
    ContentView()
}
