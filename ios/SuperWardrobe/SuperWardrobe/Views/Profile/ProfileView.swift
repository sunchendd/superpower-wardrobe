import SwiftUI

struct ProfileView: View {
    var body: some View {
        List {
            NavigationLink("穿搭日历", destination: OutfitCalendarView())
            NavigationLink("穿搭日记", destination: OutfitDiaryView())
            NavigationLink("设置", destination: SettingsAppView())
        }
        .navigationTitle("我的")
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
