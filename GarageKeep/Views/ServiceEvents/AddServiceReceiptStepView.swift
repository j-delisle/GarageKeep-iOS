import SwiftUI
import PhotosUI

struct AddServiceReceiptStepView: View {
    @Bindable var viewModel: AddServiceViewModel
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    @State private var showSourcePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                header
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                previewCard
                    .padding(.horizontal, Spacing.md)

                if viewModel.pendingAttachments.count > 1 {
                    thumbnailStrip
                        .padding(.horizontal, Spacing.md)
                }

                actionBar
                    .padding(.horizontal, Spacing.md)

                Spacer(minLength: Spacing.xl)
            }
        }
        // Fix: use .photosPicker(isPresented:) — PhotosPicker cannot be nested in a confirmationDialog
        .photosPicker(isPresented: $showPhotosPicker, selection: $photosPickerItem, matching: .images)
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                guard let newItem else { return }
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let compressed = UIImage(data: data)?.jpegData(compressionQuality: 0.8) {
                    let index = viewModel.pendingAttachments.count + 1
                    let name = "receipt_\(index)_\(Int(Date.now.timeIntervalSince1970)).jpg"
                    viewModel.pendingAttachments.append(PendingAttachment(data: compressed, fileName: name))
                }
                photosPickerItem = nil
            }
        }
        .confirmationDialog("Add Receipt", isPresented: $showSourcePicker) {
            Button("Take Photo") { showCamera = true }
            Button("Choose from Library") { showPhotosPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView { data in
                let index = viewModel.pendingAttachments.count + 1
                let name = "receipt_\(index)_\(Int(Date.now.timeIntervalSince1970)).jpg"
                viewModel.pendingAttachments.append(PendingAttachment(data: data, fileName: name))
                showCamera = false
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Upload Receipt")
                .font(.displaySm)
                .foregroundStyle(Color.textPrimary)
            Text("Align the receipt within the frame for best results.")
                .font(.bodyMd)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Large Preview Card

    private var previewCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(Color.appSurface)

            if let latest = viewModel.pendingAttachments.last,
               let uiImage = UIImage(data: latest.data) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: Radius.card))

                    // Corner guides overlay
                    CornerGuideOverlay()
                        .padding(Spacing.md)

                    Button {
                        viewModel.pendingAttachments.removeAll { $0.id == latest.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(Spacing.sm)
                }
            } else {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.appPrimary.opacity(0.5))
                    Text("No receipt selected")
                        .font(.bodyMd)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .frame(height: 300)
    }

    // MARK: - Thumbnail Strip (when > 1 image)

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(viewModel.pendingAttachments) { attachment in
                    if let uiImage = UIImage(data: attachment.data) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Button {
                                viewModel.pendingAttachments.removeAll { $0.id == attachment.id }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 2)
                            }
                            .buttonStyle(.plain)
                            .padding(3)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.md) {
                // Gallery
                Button {
                    showPhotosPicker = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 22))
                        Text("GALLERY")
                            .font(.labelSm)
                    }
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.button))
                }
                .buttonStyle(.plain)

                // Camera (center, prominent)
                Button {
                    showCamera = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.primaryCTA)
                            .frame(width: 72, height: 72)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color.appBackground)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canAddAttachment)
                .opacity(viewModel.canAddAttachment ? 1 : 0.4)

                // Count indicator
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .stroke(Color.appBorder.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 40, height: 40)
                        Text("\(viewModel.pendingAttachments.count)/\(AddServiceViewModel.maxAttachments)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                    }
                    Text("ADDED")
                        .font(.labelSm)
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.button))
            }

            // Choose from Gallery full-width button
            Button {
                showPhotosPicker = true
            } label: {
                Text("Choose from Gallery")
                    .font(.buttonLabel)
                    .foregroundStyle(Color.appPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.button))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canAddAttachment)
            .opacity(viewModel.canAddAttachment ? 1 : 0.4)
        }
    }
}

// MARK: - Corner Guide Overlay

private struct CornerGuideOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let len: CGFloat = 24
            let thick: CGFloat = 2.5

            ZStack {
                // Top-left
                Path { p in
                    p.move(to: CGPoint(x: 0, y: len))
                    p.addLine(to: CGPoint(x: 0, y: 0))
                    p.addLine(to: CGPoint(x: len, y: 0))
                }.stroke(Color.appPrimary, lineWidth: thick)

                // Top-right
                Path { p in
                    p.move(to: CGPoint(x: w - len, y: 0))
                    p.addLine(to: CGPoint(x: w, y: 0))
                    p.addLine(to: CGPoint(x: w, y: len))
                }.stroke(Color.appPrimary, lineWidth: thick)

                // Bottom-left
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h - len))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.addLine(to: CGPoint(x: len, y: h))
                }.stroke(Color.appPrimary, lineWidth: thick)

                // Bottom-right
                Path { p in
                    p.move(to: CGPoint(x: w - len, y: h))
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: w, y: h - len))
                }.stroke(Color.appPrimary, lineWidth: thick)
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
        init(onCapture: @escaping (Data) -> Void) { self.onCapture = onCapture }

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
