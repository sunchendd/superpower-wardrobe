import SwiftUI

struct TravelPlanView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var showNewPlan = false
    @State private var newTitle = ""
    @State private var newDestination = ""
    @State private var newStartDate = Date()
    @State private var newEndDate = Date().addingTimeInterval(86400 * 3)

    var body: some View {
        Group {
            if viewModel.travelPlans.isEmpty {
                EmptyStateView(
                    icon: "airplane",
                    title: "还没有旅行计划",
                    message: "创建旅行计划，提前规划每日穿搭"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.travelPlans) { plan in
                            TravelPlanCard(plan: plan)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("旅行计划")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewPlan = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewPlan) {
            NavigationStack {
                Form {
                    Section("基本信息") {
                        TextField("旅行标题", text: $newTitle)
                        TextField("目的地", text: $newDestination)
                    }

                    Section("日期") {
                        DatePicker("出发日期", selection: $newStartDate, displayedComponents: .date)
                        DatePicker("返回日期", selection: $newEndDate, in: newStartDate..., displayedComponents: .date)
                    }

                    Section {
                        let days = Calendar.current.dateComponents([.day], from: newStartDate, to: newEndDate).day ?? 0
                        LabeledContent("旅行天数", value: "\(days + 1) 天")
                    }
                }
                .navigationTitle("新旅行计划")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("取消") { showNewPlan = false }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("创建") {
                            Task {
                                guard let userId = await SupabaseService.shared.currentUserId else { return }
                                let plan = TravelPlan(
                                    id: UUID(),
                                    userId: userId,
                                    title: newTitle,
                                    destination: newDestination.isEmpty ? nil : newDestination,
                                    startDate: newStartDate,
                                    endDate: newEndDate
                                )
                                await viewModel.createTravelPlan(plan)
                                showNewPlan = false
                                newTitle = ""
                                newDestination = ""
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(newTitle.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .task {
            await viewModel.loadTravelPlans()
        }
    }
}

struct TravelPlanCard: View {
    let plan: TravelPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.headline)
                    if let destination = plan.destination {
                        Label(destination, systemImage: "mappin.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "airplane.departure")
                    .font(.title2)
                    .foregroundStyle(.indigo)
            }

            HStack(spacing: 8) {
                Label(plan.startDate.formattedDate, systemImage: "calendar")
                    .font(.caption)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                Text(plan.endDate.formattedDate)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            let days = Calendar.current.dateComponents([.day], from: plan.startDate, to: plan.endDate).day ?? 0
            Text("\(days + 1) 天行程")
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.indigo.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding()
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        TravelPlanView()
    }
}
