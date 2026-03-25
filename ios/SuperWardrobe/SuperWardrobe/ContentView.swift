import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var selectedTab = 0
    @State private var showAddItem = false
    @State private var previousTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. Daily Recommendations
            NavigationStack {
                RecommendationView()
            }
            .tabItem {
                Label("推荐", systemImage: "sparkles")
            }
            .tag(0)

            // 2. Wardrobe
            NavigationStack {
                WardrobeView()
            }
            .tabItem {
                Label("衣橱", systemImage: "tshirt")
            }
            .tag(1)

            // 3. Add (center button — triggers sheet)
            Color.clear
                .tabItem {
                    Label("添加", systemImage: "plus.circle.fill")
                }
                .tag(2)

            // 4. Statistics
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("统计", systemImage: "chart.pie")
            }
            .tag(3)

            // 5. Profile
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("我的", systemImage: "person")
            }
            .tag(4)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 2 {
                showAddItem = true
                selectedTab = oldValue
            }
            previousTab = oldValue
        }
        .sheet(isPresented: $showAddItem) {
            NavigationStack {
                AddItemView()
            }
        }
        .tint(.indigo)
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
}
