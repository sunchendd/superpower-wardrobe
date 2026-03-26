import SwiftUI
import PhotosUI
import SwiftData

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AddItemViewModel()
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showURLInput = false
    @State private var imageURL = ""
    @State private var showItemEdit = false

    var body: some View {
        VStack(spacing: 24) {
            if let image = viewModel.capturedImage {
                capturedSection(image: image)
            } else {
                promptSection
            }
        }
        .navigationTitle("添加衣物")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { dismiss() }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in Task { await viewModel.classifyImage(image) } }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView { image in Task { await viewModel.classifyImage(image) } }
        }
        .alert("输入图片网址", isPresented: $showURLInput) {
            TextField("https://...", text: $imageURL)
            Button("确定") {
                guard let url = URL(string: imageURL) else { return }
                Task {
                    if let data = try? Data(contentsOf: url),
                       let img = UIImage(data: data) {
                        await viewModel.classifyImage(img)
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

    // MARK: - Subviews

    @ViewBuilder
    private func capturedSection(image: UIImage) -> some View {
        VStack(spacing: 16) {
            Image(uiImage: viewModel.processedImage ?? image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 8)

            if viewModel.isClassifying {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("AI 识别中...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button("继续编辑") { showItemEdit = true }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
            }

            HStack(spacing: 16) {
                Button("重新拍照") { viewModel.resetForm() }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private var promptSection: some View {
        VStack {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.indigo.opacity(0.15), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 120)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 52))
                        .foregroundStyle(.indigo.opacity(0.7))
                }

                VStack(spacing: 8) {
                    Text("添加新衣物")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("拍照或从相册选择，AI 将自动识别分类")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button { showCamera = true } label: {
                    Label("拍照", systemImage: "camera")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)

                Button { showPhotoPicker = true } label: {
                    Label("从相册选择", systemImage: "photo.on.rectangle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)

                Button { showURLInput = true } label: {
                    Label("输入网址", systemImage: "link")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    NavigationStack { AddItemView() }
}
