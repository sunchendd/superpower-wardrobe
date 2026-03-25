import SwiftUI
import SwiftData

struct ItemEditView: View {
    @Bindable var viewModel: AddItemViewModel
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let quickTags = [
        "休闲", "商务", "运动", "日系", "欧美",
        "简约", "复古", "街头", "优雅", "度假"
    ]

    var body: some View {
        Form {
            // Preview
            Section("预览") {
                if let image = viewModel.processedImage ?? viewModel.capturedImage {
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

            // Basic Info
            Section("基本信息") {
                TextField("名称", text: $viewModel.itemName)
                TextField("品牌", text: $viewModel.brand)

                Picker("分类", selection: $viewModel.selectedCategory) {
                    Text("未分类").tag(nil as Category?)
                    ForEach(Category.defaultCategories) { cat in
                        Text(cat.name).tag(cat as Category?)
                    }
                }

                ColorPicker("颜色", selection: .init(
                    get: { Color(hex: viewModel.color) },
                    set: { newColor in
                        let resolved = newColor.resolve(in: .init())
                        let r = Int(resolved.red * 255)
                        let g = Int(resolved.green * 255)
                        let b = Int(resolved.blue * 255)
                        viewModel.color = String(format: "#%02X%02X%02X", r, g, b)
                    }
                ))
            }

            // Season
            Section("季节") {
                Picker("适合季节", selection: $viewModel.season) {
                    ForEach(Array(zip(viewModel.seasonOptions, viewModel.seasonLabels)), id: \.0) { value, label in
                        Text(label).tag(value)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Style Tags
            Section("风格标签") {
                if !viewModel.styleTags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(viewModel.styleTags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag).font(.caption)
                                Button {
                                    viewModel.styleTags.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "xmark.circle.fill").font(.caption2)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.indigo.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }

                HStack {
                    @State var newTag = ""
                    TextField("添加标签", text: $newTag)
                    Button("添加") {
                        let t = newTag.trimmingCharacters(in: .whitespaces)
                        if !t.isEmpty && !viewModel.styleTags.contains(t) {
                            viewModel.styleTags.append(t)
                            newTag = ""
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                FlowLayout(spacing: 6) {
                    ForEach(quickTags.filter { !viewModel.styleTags.contains($0) }, id: \.self) { tag in
                        Button(tag) { viewModel.styleTags.append(tag) }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Purchase Info
            Section("购买信息（可选）") {
                TextField("价格", text: $viewModel.purchasePrice)
                    .keyboardType(.decimalPad)
            }

            // AI result
            if let result = viewModel.aiResult {
                Section("AI 识别结果") {
                    LabeledContent("分类", value: result.category)
                    LabeledContent("颜色", value: result.colorHex)
                    LabeledContent("置信度", value: String(format: "%.1f%%", result.confidence * 100))
                    if !result.description.isEmpty {
                        LabeledContent("描述", value: result.description)
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
                        await viewModel.saveItem(context: modelContext)
                        if viewModel.errorMessage == nil { onSave() }
                    }
                }
                .fontWeight(.semibold)
                .disabled(viewModel.isSaving)
            }
        }
        .overlay {
            if viewModel.isSaving {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView().scaleEffect(1.5)
                        Text("保存中...").font(.subheadline)
                    }
                    .padding(24)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ItemEditView(viewModel: AddItemViewModel()) {}
    }
}
