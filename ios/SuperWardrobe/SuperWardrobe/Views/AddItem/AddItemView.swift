import SwiftUI
import PhotosUI
import SwiftData

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeTokens) private var theme
    @State private var viewModel = AddItemViewModel()
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showURLInput = false
    @State private var imageURL = ""
    @State private var showItemEdit = false

    var body: some View {
        ZStack {
            ThemeSurfaceBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    hero

                    if let image = viewModel.capturedImage {
                        capturedSection(image: image)
                    } else {
                        actionPanel
                        helperPanel
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                Task { await viewModel.classifyImage(image) }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView { image in
                Task { await viewModel.classifyImage(image) }
            }
        }
        .alert("输入图片网址", isPresented: $showURLInput) {
            TextField("https://...", text: $imageURL)
            Button("确定") {
                let raw = imageURL.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let url = URL(string: raw) else { return }
                Task {
                    do {
                        // 尝试直接作为图片下载；如果失败则解析页面 og:image（支持京东/淘宝等商品链接）
                        let img = try await Self.loadImageFromURLOrPage(url)
                        await viewModel.classifyImage(img)
                    } catch {
                        await MainActor.run { viewModel.errorMessage = "无法获取图片，请尝试直接复制图片链接" }
                    }
                }
            }
            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $showItemEdit) {
            NavigationStack {
                ItemEditView(viewModel: viewModel) {
                    dismiss()
                }
            }
        }
        .alert("错误", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.text)
                    .frame(width: 40, height: 40)
                    .background(theme.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(theme.cardBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Text("添加衣物")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.textMuted)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(theme.surface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(theme.cardBorder, lineWidth: 1))
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(theme.surface)
                    .frame(width: 84, height: 84)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(theme.cardBorder, lineWidth: 1)
                    )

                Image(systemName: viewModel.capturedImage == nil ? "camera.viewfinder" : "sparkles.rectangle.stack")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(theme.accent)
            }

            WardrobeHeroHeader(
                title: viewModel.capturedImage == nil ? "添加衣物" : "识别完成",
                subtitle: viewModel.capturedImage == nil ? "拍照、选图或贴图链接，系统会先帮你识别，再进入精修保存。" : "先确认识别结果，再补全细节，整体流程会和推荐、衣橱保持同一套信息密度。",
                trailingBadge: viewModel.capturedImage == nil ? "3 种录入方式" : "下一步：编辑"
            )
        }
    }

    private func capturedSection(image: UIImage) -> some View {
        VStack(spacing: 18) {
            WardrobeGlassCard {
                VStack(alignment: .leading, spacing: 16) {
                    cardSectionLabel("预览")

                    Image(uiImage: viewModel.processedImage ?? image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))

                    statusPanel
                }
            }

            HStack(spacing: 12) {
                actionButton(
                    title: "重新选择",
                    icon: "arrow.triangle.2.circlepath",
                    isPrimary: false
                ) {
                    viewModel.resetForm()
                }

                actionButton(
                    title: viewModel.isClassifying ? "识别中..." : "继续编辑",
                    icon: "arrow.right",
                    isPrimary: true
                ) {
                    showItemEdit = true
                }
                .disabled(viewModel.isClassifying)
            }
        }
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(viewModel.isClassifying ? "AI 正在识别" : "识别摘要")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.text)

                Spacer()

                if viewModel.isClassifying {
                    ProgressView()
                        .tint(theme.accent)
                } else {
                    Text(viewModel.selectedCategory?.name ?? viewModel.aiResult?.category ?? "待确认")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.accent.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(theme.textMuted)
                .fixedSize(horizontal: false, vertical: true)

            if !viewModel.styleTags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(viewModel.styleTags.prefix(5), id: \.self) { tag in
                        Text(tag)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.text)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(theme.surfaceRaised)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(theme.cardBorder, lineWidth: 1))
                    }
                }
            }
        }
    }

    private var actionPanel: some View {
        WardrobeGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                cardSectionLabel("采集方式")

                actionButton(title: "拍照录入", icon: "camera", isPrimary: true) {
                    showCamera = true
                }

                actionButton(title: "从相册选择", icon: "photo.on.rectangle", isPrimary: false) {
                    showPhotoPicker = true
                }

                actionButton(title: "粘贴图片链接", icon: "link", isPrimary: false) {
                    showURLInput = true
                }
            }
        }
    }

    private var helperPanel: some View {
        WardrobeGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                cardSectionLabel("录入建议")

                helperRow(
                    icon: "sparkles",
                    title: "尽量拍单品正面",
                    message: "纯色背景、完整轮廓和足够光线，会让分类和颜色识别更准。"
                )

                helperRow(
                    icon: "tag",
                    title: "编辑页再补品牌和标签",
                    message: "入口只负责拿到图，后面的分类、季节、风格标签都能继续精修。"
                )
            }
        }
    }

    private func helperRow(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.accent)
                .frame(width: 34, height: 34)
                .background(theme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.text)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(theme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func actionButton(title: String, icon: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))

                Text(title)
                    .font(.system(size: 18, weight: .bold))

                Spacer()
            }
            .foregroundStyle(isPrimary ? theme.accentForeground : theme.text)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                Group {
                    if isPrimary {
                        LinearGradient(
                            colors: [theme.accent, theme.accent.opacity(0.86)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [theme.surface, theme.surface],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isPrimary ? theme.accent : theme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func cardSectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(theme.textMuted)
            .tracking(1.2)
    }

    private var statusMessage: String {
        if viewModel.isClassifying {
            return "我们正在从图片里提取分类、颜色和风格标签，识别完成后你可以继续补充细节。"
        }

        if let result = viewModel.aiResult {
            return result.description.isEmpty
                ? "已识别出基础分类与色彩信息，建议在下一步补充品牌、季节和风格标签。"
                : result.description
        }

        return "图片已经准备好，你可以直接进入编辑页手动填写信息。"
    }
}

// MARK: - URL Image Loader

extension AddItemView {
    /// 先尝试直接下载图片；若返回的是 HTML 页面则解析 og:image（支持京东/淘宝短链）
    static func loadImageFromURLOrPage(_ url: URL) async throws -> UIImage {
        let session = URLSession.shared
        let (data, response) = try await session.data(from: url)

        // 如果是图片，直接解码
        if let img = UIImage(data: data) { return img }

        // 否则尝试解析 HTML 中的 og:image
        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1),
              let imgURL = Self.extractOGImage(from: html, base: response.url ?? url)
        else { throw URLError(.cannotDecodeContentData) }

        let (imgData, _) = try await session.data(from: imgURL)
        guard let img = UIImage(data: imgData) else { throw URLError(.cannotDecodeContentData) }
        return img
    }

    private static func extractOGImage(from html: String, base: URL) -> URL? {
        let patterns = [
            #"og:image[^>]*content=["\']([^"\']+)["\']"#,
            #"content=["\']([^"\']+)["\'][^>]*og:image"#,
            #"itemprop=["\']image["\'][^>]*content=["\']([^"\']+)["\']"#,
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                  match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: html)
            else { continue }
            let urlStr = String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if urlStr.hasPrefix("http") { return URL(string: urlStr) }
            return URL(string: urlStr, relativeTo: base)?.absoluteURL
        }
        return nil
    }
}

#Preview {
    NavigationStack { AddItemView() }
}
