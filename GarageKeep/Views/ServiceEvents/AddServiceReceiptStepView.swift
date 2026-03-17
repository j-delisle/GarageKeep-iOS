import SwiftUI
import PhotosUI

struct AddServiceReceiptStepView: View {
    @Bindable var viewModel: AddServiceViewModel
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                subtitle
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                imagePreviewArea
                    .padding(.horizontal, Spacing.md)

                actionButtons
                    .padding(.horizontal, Spacing.md)

                Spacer(minLength: Spacing.xl)
            }
        }
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                guard let newItem else { return }
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    viewModel.selectedImageData = data
                    viewModel.selectedImageName = "receipt_\(Int(Date.now.timeIntervalSince1970)).jpg"
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView { data in
                viewModel.selectedImageData = data
                viewModel.selectedImageName = "receipt_\(Int(Date.now.timeIntervalSince1970)).jpg"
                showCamera = false
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Subtitle

    private var subtitle: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Attach a receipt or document to this service record.")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("This step is optional — you can skip it.")
                .font(.system(size: 12))
                .foregroundStyle(Color.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Image Preview Area

    private var imagePreviewArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(Color.appSurface)
                .frame(height: 240)

            if let data = viewModel.selectedImageData,
               let uiImage = UIImage(data: data) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.card))

                    Button {
                        viewModel.selectedImageData = nil
                        photosPickerItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(Spacing.sm)
                }
            } else {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "doc.text.image")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.appPrimary.opacity(0.4))
                    Text("No receipt selected")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                // Camera
                Button {
                    showCamera = true
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                        Text("Camera")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color.appPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.button)
                            .stroke(Color.appPrimary, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)

                // Library
                PhotosPicker(
                    selection: $photosPickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 16))
                        Text("Library")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Color.appPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.button)
                            .stroke(Color.appPrimary, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Camera Picker

private struct CameraPickerView: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (Data) -> Void

        init(onCapture: @escaping (Data) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                onCapture(data)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {}
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        let vm = AddServiceViewModel(vehicle: .stubWithVin)
        AddServiceReceiptStepView(viewModel: vm)
    }
}
