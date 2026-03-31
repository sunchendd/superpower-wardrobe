import SwiftUI

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filterColors: [String]
    @Binding var filterSeasons: [String]
    @Binding var filterStyles: [String]
    @State private var selectedBrand: String = ""

    private let colorOptions = [
        ("黑色", "#000000"), ("白色", "#FFFFFF"), ("红色", "#FF0000"),
        ("蓝色", "#0000FF"), ("绿色", "#00FF00"), ("黄色", "#FFFF00"),
        ("粉色", "#FFC0CB"), ("灰色", "#808080"), ("棕色", "#8B4513"),
        ("紫色", "#800080"), ("橙色", "#FFA500"), ("米色", "#F5F5DC")
    ]

    private let seasonOptions = [
        ("春", "spring"), ("夏", "summer"), ("秋", "autumn"), ("冬", "winter"), ("四季", "all")
    ]

    private let styleOptions = ["休闲", "正式", "运动", "街头", "复古", "简约", "甜美", "中性"]

    var body: some View {
        NavigationStack {
            Form {
                Section("颜色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colorOptions, id: \.1) { name, hex in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        Circle().stroke(.gray.opacity(0.3), lineWidth: 1)
                                    }
                                    .overlay {
                                        if filterColors.contains(hex) {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(hex == "#FFFFFF" || hex == "#FFFF00" ? .black : .white)
                                        }
                                    }
                                Text(name)
                                    .font(.caption2)
                            }
                            .onTapGesture {
                                if filterColors.contains(hex) {
                                    filterColors.removeAll { $0 == hex }
                                } else {
                                    filterColors.append(hex)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("季节") {
                    HStack(spacing: 8) {
                        ForEach(seasonOptions, id: \.1) { label, value in
                            let isSelected = filterSeasons.contains(value)
                            Button {
                                if isSelected {
                                    filterSeasons.removeAll { $0 == value }
                                } else {
                                    filterSeasons.append(value)
                                }
                            } label: {
                                Text(label)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.indigo : Color.gray.opacity(0.12))
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Section("风格") {
                    FlowLayout(spacing: 8) {
                        ForEach(styleOptions, id: \.self) { style in
                            let isSelected = filterStyles.contains(style)
                            Button {
                                if isSelected {
                                    filterStyles.removeAll { $0 == style }
                                } else {
                                    filterStyles.append(style)
                                }
                            } label: {
                                Text(style)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Color.indigo : Color.gray.opacity(0.12))
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Section("品牌") {
                    TextField("输入品牌名称", text: $selectedBrand)
                }
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("重置") {
                        filterColors = []
                        filterSeasons = []
                        filterStyles = []
                        selectedBrand = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("确定") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    FilterSheet(
        filterColors: .constant([]),
        filterSeasons: .constant([]),
        filterStyles: .constant([])
    )
}
