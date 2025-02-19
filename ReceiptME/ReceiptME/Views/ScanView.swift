//
//  ScanView.swift
//  ReceiptME
//
//  Created by Jimmy Lancaster on 2/18/25.
//

import SwiftUI

struct ScanView: View {
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var uploadResult: ReceiptScanResult?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
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
                    }) {
                        Text("Camera")
                    }
                    .padding()
                    
                    Button(action: {
                        sourceType = .photoLibrary
                        showImagePicker = true
                    }) {
                        Text("Photo Library")
                    }
                    .padding()
                }
                
                if selectedImage != nil {
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
                    Text(uploadResult.success ? "Upload successful! Receipt ID: \(uploadResult.receipt_id ?? 0)" : "Upload failed.")
                        .foregroundColor(uploadResult.success ? .green : .red)
                        .padding()
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
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
        
        APIService.shared.uploadReceipt(image: image) { result in
            DispatchQueue.main.async {
                isUploading = false
                switch result {
                case .success(let response):
                    uploadResult = response
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
