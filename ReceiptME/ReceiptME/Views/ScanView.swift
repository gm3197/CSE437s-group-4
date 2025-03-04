//
//  ScanView.swift
//  ReceiptMEranuce

//
//  Created by Jimmy Lancaster on 2/18/25.
//

import SwiftUI

struct ScanView: View {
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
//    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var isUploadButtonHidden = false
    @State private var uploadResult: ReceiptScanResult?
    @State private var errorMessage: String?
    
    @State private var navigationPath = NavigationPath() // new to swiftUI 16
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(10)
                        .padding()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .overlay(Text("No image selected").foregroundColor(.gray))
                        .cornerRadius(10)
                        .padding()
                }
                
                HStack {
                    Button(action: {
                        sourceType = .camera
                        showImagePicker = true
                        isUploadButtonHidden = false
                        uploadResult = nil
                        errorMessage = nil
                    }) {
                        Text("Camera")
                    }
                    .padding()
                    
                    Button(action: {
                        sourceType = .photoLibrary
                        showImagePicker = true
                        isUploadButtonHidden = false
                        uploadResult = nil
                        errorMessage = nil
                    }) {
                        Text("Photo Library")
                    }
                    .padding()
                }
                
                if selectedImage != nil && !isUploadButtonHidden {
                    Button(action: uploadReceipt) {
                        if isUploading {
                            ProgressView()
                        } else {
                            Text("Upload Receipt")
                        }
                    }
                    .padding()
                }
                

                if let uploadResult = uploadResult {
                    Group {
                        if uploadResult.success {
//                            ReceiptDetailView(receiptId: uploadResult.receipt_id ?? 0)
                            Text("Successful upload! Navigate to receipt page to find your itemized information.")
                                .foregroundColor(.green)
                                .padding()
                        } else {
                            
                            Text("Upload Failed. Please retake picture and try again.")
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                }               
                
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .navigationDestination(for: Int.self){
                receiptId in ReceiptDetailWrapper(receiptId: receiptId)
            }
            .navigationTitle("Scan Receipt")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
                    
            }
        }
    }
    
    func uploadReceipt() {
        guard let image = selectedImage else { return }
        isUploading = true
        errorMessage = nil
        
        isUploadButtonHidden = true // hide button so users cant double upload (avoiding bugs)
        
        let image_to_uplaod: UIImage
        
        // rotate pics from camera only
        if sourceType == .camera {
//            image_to_uplaod = rotateImage(image: image, clockwise: true)
            image_to_uplaod = image
        } else {
            image_to_uplaod = image
        }
        
        APIService.shared.uploadReceipt(image: image_to_uplaod) { result in
            DispatchQueue.main.async {
                isUploading = false
                switch result {
                case .success(let response):
                    uploadResult = response
                    
                    // navigation logic
                    if response.success, let receipt_id = response.receipt_id {
                        navigationPath.append(receipt_id)
                    }
                    
                    print("Sucessful upload -- moving view to reciept details")
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    print("Error: \(error)")
                    
                    if let urlError = error as? URLError {
                        print("URL Error: \(urlError)")
                    } else if let decodingError = error as? DecodingError {
                        print("Decoding Error: \(decodingError)")
                    }
                    
                }
            }
        }
    }
    
    func rotateImage(image: UIImage, clockwise: Bool) -> UIImage {
        // Determine the rotation angle in radians
        let rotationAngle = clockwise ? CGFloat.pi/2 : -CGFloat.pi/2
        
        // Calculate the size of the rotated image
        let size = CGSize(width: image.size.height, height: image.size.width)
        
        // Begin a new image context
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move to the center of the context
        context.translateBy(x: size.width/2, y: size.height/2)
        
        // Rotate the context
        context.rotate(by: rotationAngle)
        
        // Draw the image centered in the context, but rotated
        let rect = CGRect(x: -image.size.width/2, y: -image.size.height/2, width: image.size.width, height: image.size.height)
        image.draw(in: rect)
        
        // Get the rotated image from the context
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return rotatedImage
    }
    
    
//    extension UIImage {
//        func fixedOrientation() -> UIImage {
//            // If the image is already upright, return it directly
//            if imageOrientation == .up {
//                return self
//            }
//            
//            // Create a context to draw the correctly oriented image
//            UIGraphicsBeginImageContextWithOptions(size, false, scale)
//            draw(in: CGRect(origin: .zero, size: size))
//            
//            let normalizedImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
//            UIGraphicsEndImageContext()
//            
//            return normalizedImage ?? self
//        }
//    }
}
