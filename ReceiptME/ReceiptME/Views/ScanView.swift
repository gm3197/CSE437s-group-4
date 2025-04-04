import SwiftUI

struct ScanView: View {
    @State private var showCameraImagePicker = false
    @State private var showPhotoLibraryImagePicker = false
    @State private var cameraSourceType: UIImagePickerController.SourceType = .camera
    @State private var photoLibrarySourceType: UIImagePickerController.SourceType = .photoLibrary

    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var isUploadButtonHidden = false
    @State private var uploadResult: ReceiptScanResult?
    @State private var errorMessage: String?

    @State private var navigationPath = NavigationPath()
    @AppStorage("fetch_receipts") var hasFetched: Bool?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Animated background
                LinearGradient(
                    gradient: Gradient(colors: [.pink, .purple, .blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.linear(duration: 4).repeatForever(autoreverses: true), value: isUploading)

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Scan Your Receipt")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.25), radius: 3, x: 2, y: 2)
                            .padding(.top, 30)

                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 300)
                                .shadow(color: .black.opacity(0.15), radius: 5, x: 2, y: 4)

                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(16)
                                    .padding()
                            } else {
                                Text("No image selected")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 20)

                        HStack(spacing: 20) {
                            Button(action: {
                                cameraSourceType = .camera
                                DispatchQueue.main.async {
                                    showCameraImagePicker = true
                                }
                                isUploadButtonHidden = false
                                uploadResult = nil
                                errorMessage = nil
                            }) {
                                Text("Camera")
                                    .font(.system(.headline, design: .rounded))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SleekButtonStyle())

                            Button(action: {
                                photoLibrarySourceType = .photoLibrary
                                DispatchQueue.main.async {
                                    showPhotoLibraryImagePicker = true
                                }
                                isUploadButtonHidden = false
                                uploadResult = nil
                                errorMessage = nil
                            }) {
                                Text("Photo Library")
                                    .font(.system(.headline, design: .rounded))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SleekButtonStyle())
                        }
                        .padding(.horizontal, 20)

                        if selectedImage != nil && !isUploadButtonHidden {
                            Button(action: uploadReceipt) {
                                Text("Upload Receipt")
                                    .font(.system(.headline, design: .rounded))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SleekButtonStyle())
                            .padding(.horizontal, 20)
                        }

                        if let uploadResult = uploadResult {
                            Group {
                                if uploadResult.success {
                                    Text("Successful upload! Navigate to receipt page to find your itemized information.")
                                        .foregroundColor(.green)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                } else {
                                    Text("Upload Failed. Please retake picture and try again.")
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 30)
                    }
                }

                // Loading overlay
                if isUploading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        ProgressView(value: 0.5)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .frame(width: 200)

                        Text("Uploading and processing receipt...")
                            .foregroundColor(.white)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                    .shadow(radius: 10)
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Int.self) { receiptId in
                ReceiptDetailWrapper(receiptId: receiptId)
            }
            .sheet(isPresented: $showCameraImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: cameraSourceType)
            }
            .sheet(isPresented: $showPhotoLibraryImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: photoLibrarySourceType)
            }
        }
    }

    func uploadReceipt() {
        guard let image = selectedImage else { return }
        isUploading = true
        errorMessage = nil
        isUploadButtonHidden = true

        let imageToUpload = image

        APIService.shared.uploadReceipt(image: imageToUpload) { result in
            DispatchQueue.main.async {
                isUploading = false
                switch result {
                case .success(let response):
                    uploadResult = response
                    hasFetched = false
                    if response.success, let receipt_id = response.receipt_id {
                        navigationPath.append(receipt_id)
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct SleekButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.pink, .purple, .blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.25), radius: configuration.isPressed ? 2 : 4, x: 2, y: 2)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

func rotateImage(image: UIImage, clockwise: Bool) -> UIImage {
    let rotationAngle = clockwise ? CGFloat.pi/4 : -CGFloat.pi/4
    let size = CGSize(width: image.size.height, height: image.size.width)
    UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
    let context = UIGraphicsGetCurrentContext()!
    context.translateBy(x: size.width/2, y: size.height/2)
    context.rotate(by: rotationAngle)
    let rect = CGRect(x: -image.size.width/2, y: -image.size.height/2, width: image.size.width, height: image.size.height)
    image.draw(in: rect)
    let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return rotatedImage
}
