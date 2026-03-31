import SwiftUI

#if os(iOS)
struct ItemEditView: View {
    @Bindable var viewModel: AddItemViewModel
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var categories: [Category] = []
    @State private var newTag = ""

    var body: some View {
        Form {
            Section("预览") {
                if let image = viewModel.capturedImage {
                    HStack {
                        Spacer()
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }

            Section("基本信息") {
                TextField("名称", text: $viewModel.itemName)
                TextField("品牌", text: $viewModel.brand)

                Picker("分类", selection: $viewModel.selectedCategory) {
                    Text("未分类").tag(nil as Category?)
                    ForEach(categories) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }

                ColorPicker("颜色", selection: .init(
                    get: { Color(hex: viewModel.color) },
                    set: { newColor in viewModel.color = newColor.toHex() ?? viewModel.color }
                ))
            }

            Section("季节") {
                Picker("适合季节", selection: $viewModel.season) {
                    ForEach(Array(zip(viewModel.seasonOptions, viewModel.seasonLabels)), id: \.0) { value, label in
                        Text(label).tag(value)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("风格标签") {
                FlowLayout(spacing: 6) {
                    ForEach(viewModel.styleTags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.caption)
                            Button {
                                viewModel.styleTags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.indigo.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }

                HStack {
                    TextField("添加标签", text: $newTag)
                    Button("添加") {
                        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty && !viewModel.styleTags.contains(trimmed) {
                            viewModel.styleTags.append(trimmed)
                            newTag = ""
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }

            Section("购买信息") {
                TextField("价格", text: $viewModel.purchasePrice)
                    .keyboardType(.decimalPad)
                DatePicker("购买日期", selection: $viewModel.purchaseDate, displayedComponents: .date)
                TextField("购买链接 (可选)", text: $viewModel.purchaseUrl)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
            }

            if let result = viewModel.classificationResult {
                Section("AI 识别结果") {
                    LabeledContent("分类", value: result.category)
                    LabeledContent("颜色", value: result.color)
                    LabeledContent("置信度", value: String(format: "%.1f%%", result.confidence * 100))
                    if !result.style.isEmpty {
                        LabeledContent("风格") {
                            Text(result.style.joined(separator: ", "))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("编辑衣物")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") {
                    Task {
                        await viewModel.saveItem()
                        if viewModel.errorMessage == nil {
                            onSave()
                        }
                    }
                }
                .fontWeight(.semibold)
                .disabled(viewModel.isSaving)
            }
        }
        .overlay {
            if viewModel.isSaving {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("保存中...")
                            .font(.subheadline)
                    }
                    .padding(24)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .task {
            categories = LocalDataService.shared.fetchCategories()
        }
    }
}

#Preview {
    NavigationStack {
        ItemEditView(viewModel: AddItemViewModel()) { }
    }
}
#endif
