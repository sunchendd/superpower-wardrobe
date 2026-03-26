import SwiftUI

struct TravelPlanView: View {
    var body: some View {
        EmptyStateView(
            icon: "airplane",
            title: "旅行计划暂未开放",
            message: "首测版先聚焦日常推荐和衣橱管理"
        )
        .navigationTitle("旅行计划")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { TravelPlanView() }
}
