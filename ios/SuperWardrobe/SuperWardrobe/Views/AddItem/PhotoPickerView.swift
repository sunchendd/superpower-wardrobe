import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    let onSelect: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ContentUnavailableView(
                "选择照片",
                systemImage: "photo.on.rectangle",
                description: Text("点击选择一张衣物照片")
            )
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onSelect(image)
                    dismiss()
                }
            }
        }
        .photosPickerStyle(.inline)
        .photosPickerDisabledCapabilities([.collectionNavigation, .stagingArea])
    }
}
