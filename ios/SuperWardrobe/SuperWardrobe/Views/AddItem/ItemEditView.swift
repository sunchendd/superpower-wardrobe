import SwiftUI
import SwiftData

struct ItemEditView: View {
    @Bindable var viewModel: AddItemViewModel
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themeTokens) private var theme
    @State private var newTag = ""

    private let quickTags = [
        "休闲", "商务", "运动", "日系", "欧美",
        "简约", "复古", "街头", "优雅", "度假"
    ]

    var body: some View {
        ZStack {
            ThemeSurfaceBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    previewCard
                    basicInfoCard
                    seasonCard
                    tagsCard
                    purchaseCard

                    if let result = viewModel.aiResult {
                        aiSummaryCard(result: result)
                    }

                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if viewModel.isSaving {
                ZStack {
                    Color.black.opacity(0.38).ignoresSafeArea()

                    WardrobeGlassCard {
                        VStack(spacing: 14) {
                            ProgressView()
                                .tint(theme.accent)
                                .scaleEffect(1.15)

                            Text("正在保存衣物信息...")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(theme.text)
                        }
                        .frame(width: 180)
                    }
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button("取消") {
                dismiss()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(theme.textMuted)

            Spacer()

            Text("编辑衣物")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.textMuted)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(theme.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(theme.cardBorder, lineWidth: 1))

            Spacer()

            Button("保存") {
                Task {
                    await viewModel.saveItem(context: modelContext)
                    if viewModel.errorMessage == nil { onSave() }
                }
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(theme.accent)
            .disabled(viewModel.isSaving)
        }
    }

    private var previewCard: some View {
        WardrobeGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                WardrobeHeroHeader(
                    title: "细化单品",
                    subtitle: "把名称、分类、季节和标签补完整，衣橱、推荐和统计才会给出更准的结果。",
                    trailingBadge: "步骤 2 / 2"
                )

                if let image = viewModel.processedImage ?? viewModel.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
        }
    }

    private var basicInfoCard: some View {
        WardrobeGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionLabel("基本信息")

                editorTextField("名称", text: $viewModel.itemName)
                editorTextField("品牌", text: $viewModel.brand)

                VStack(alignment: .leading, spacing: 10) {
                    inputLabel("分类")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            categoryChip(category: nil, label: "未分类", icon: "questionmark")

                            ForEach(Category.defaultCategories) { category in
                                categoryChip(
                                    category: category,
                                    label: category.name,
                                    icon: category.icon ?? "hanger"
                                )
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    inputLabel("颜色")

                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hex: viewModel.color))
                            .frame(width: 56, height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(theme.cardBorder, lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.color.uppercased())
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(theme.text)

                            Text("选择最接近的主色，会影响推荐和统计结果。")
                                .font(.caption)
                                .foregroundStyle(theme.textMuted)
                        }

                        Spacer()

                        ColorPicker(
                            "",
                            selection: .init(
                                get: { Color(hex: viewModel.color) },
                                set: { newColor in
                                    let resolved = newColor.resolve(in: .init())
                                    let r = Int(resolved.red * 255)
                                    let g = Int(resolved.green * 255)
                                    let b = Int(resolved.blue * 255)
                                    viewModel.color = String(format: "#%02X%02X%02X", r, g, b)
                                }
                            )
                        )
                        .labelsHidden()
                        .tint(theme.accent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(theme.cardBorder, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var seasonCard: some View {
        WardrobeGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("适合季节")

                FlowLayout(spacing: 10) {
                    ForEach(Array(zip(viewModel.seasonOptions, viewModel.seasonLabels)), id: \.0) { value, label in
                        selectionChip(
                            label: label,
                            isSelected: viewModel.season == value
                        ) {
                            viewModel.season = value
                        }
                    }
                }
            }
        }
    }

    private var tagsCard: some View {
        WardrobeGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionLabel("风格标签")

                if !viewModel.styleTags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(viewModel.styleTags, id: \.self) { tag in
                            HStack(spacing: 6) {
                                Text(tag)
                                    .font(.caption.weight(.semibold))

                                Button {
                                    viewModel.styleTags.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                }
                                .buttonStyle(.plain)
                            }
                            .foregroundStyle(theme.text)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(theme.accent.opacity(0.13))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(theme.accent.opacity(0.45), lineWidth: 1))
                        }
                    }
                }

                HStack(spacing: 10) {
                    editorTextField("添加自定义标签", text: $newTag)

                    Button("添加") {
                        addNewTag()
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(newTag.trimmingCharacters(in: .whitespaces).isEmpty ? theme.textSubtle : theme.accentForeground)
                    .frame(width: 74, height: 54)
                    .background(newTag.trimmingCharacters(in: .whitespaces).isEmpty ? theme.surface : theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(newTag.trimmingCharacters(in: .whitespaces).isEmpty ? theme.cardBorder : theme.accent, lineWidth: 1)
                    )
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                FlowLayout(spacing: 8) {
                    ForEach(quickTags.filter { !viewModel.styleTags.contains($0) }, id: \.self) { tag in
                        selectionChip(label: tag, isSelected: false) {
                            viewModel.styleTags.append(tag)
                        }
                    }
                }
            }
        }
    }

    private var purchaseCard: some View {
        WardrobeGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("购买信息")

                editorTextField("价格（可选）", text: $viewModel.purchasePrice)
                    .keyboardType(.decimalPad)
            }
        }
    }

    private func aiSummaryCard(result: AIClassificationResult) -> some View {
        WardrobeGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                sectionLabel("AI 识别结果")

                infoRow(title: "分类", value: result.category)
                infoRow(title: "颜色", value: result.colorHex.uppercased())
                infoRow(title: "置信度", value: String(format: "%.1f%%", result.confidence * 100))

                if !result.description.isEmpty {
                    infoRow(title: "描述", value: result.description, multiLine: true)
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                await viewModel.saveItem(context: modelContext)
                if viewModel.errorMessage == nil { onSave() }
            }
        } label: {
            HStack {
                Text(viewModel.isSaving ? "保存中..." : "保存到衣橱")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(theme.accentForeground)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(
                LinearGradient(
                    colors: [theme.accent, theme.accent.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
    }

    private func editorTextField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            inputLabel(title)

            TextField(title, text: text)
                .font(.body)
                .foregroundStyle(theme.text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(theme.cardBorder, lineWidth: 1)
                )
        }
    }

    private func categoryChip(category: Category?, label: String, icon: String) -> some View {
        let isSelected = viewModel.selectedCategory == category

        return Button {
            viewModel.selectedCategory = category
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(label)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSelected ? theme.accentForeground : theme.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? theme.accent : theme.surface)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? theme.accent : theme.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func selectionChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? theme.accentForeground : theme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? theme.accent : theme.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? theme.accent : theme.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func infoRow(title: String, value: String, multiLine: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.textMuted)
                .tracking(1.1)

            Text(value)
                .font(multiLine ? .subheadline : .headline)
                .foregroundStyle(theme.text)
                .fixedSize(horizontal: false, vertical: multiLine)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.cardBorder, lineWidth: 1)
        )
    }

    private func inputLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(theme.textMuted)
            .tracking(1.0)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(theme.textMuted)
            .tracking(1.2)
    }

    private func addNewTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces)
        guard !tag.isEmpty, !viewModel.styleTags.contains(tag) else { return }
        viewModel.styleTags.append(tag)
        newTag = ""
    }
}

#Preview {
    NavigationStack {
        ItemEditView(viewModel: AddItemViewModel()) {}
    }
}
