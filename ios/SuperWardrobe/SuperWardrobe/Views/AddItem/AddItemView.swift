import SwiftUI
import PhotosUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddItemViewModel()
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showURLInput = false
    @State private var imageURL = ""
    @State private var showItemEdit = false

    var body: some View {
        VStack(spacing: 24) {
            if let image = viewModel.capturedImage {
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
                    } else if viewModel.classificationResult != nil {
                        Button("继续编辑") {
                            showItemEdit = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                    }

                    HStack(spacing: 16) {
                        Button("重新拍照") {
                            viewModel.resetForm()
                        }
                        .buttonStyle(.bordered)

                        if viewModel.processedImage == nil && !viewModel.isRemovingBackground {
                            Button("去除背景") {
                                Task { await viewModel.removeBackground(image) }
                            }
                            .buttonStyle(.bordered)
                        }

                        if viewModel.isRemovingBackground {
                            ProgressView()
                                .padding(.horizontal)
                        }
                    }
                }
                .padding()
            } else {
                Spacer()

                VStack(spacing: 32) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 72))
                        .foregroundStyle(.indigo.opacity(0.6))

                    Text("添加新衣物")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("拍照或从相册选择，AI 将自动识别分类")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("拍照", systemImage: "camera")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)

                    Button {
                        showPhotoPicker = true
                    } label: {
                        Label("从相册选择", systemImage: "photo.on.rectangle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        showURLInput = true
                    } label: {
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
        .navigationTitle("添加衣物")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { dismiss() }
            }
        }
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
                guard let url = URL(string: imageURL) else { return }
                Task {
                    if let data = try? Data(contentsOf: url),
                       let image = UIImage(data: data) {
                        await viewModel.classifyImage(image)
                    }
                }
            }
            Button("取消", role: .cancel) { }
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
}

#Preview {
    NavigationStack {
        AddItemView()
    }
}
