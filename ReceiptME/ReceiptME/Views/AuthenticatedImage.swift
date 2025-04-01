//
//  AuthenticatedImage.swift
//  ReceiptME
//
//  Created by Grayson Martin on 3/31/25.
//

import SwiftUI

struct AuthenticatedImage: View {
    @State private var imageData: Data? = nil
    @State private var loading = true
    @State private var url: String
    
    private var onLoad: (() -> Void)? = nil
    
    init (url: String) {
        self.url = url
    }
    
    private func fetchImage(url: String) {
        guard let url = URL(string: url) else {
            print("bad url")
            return
        }
        
        let request = APIService.shared.createAuthorizedRequest(url: url, method: "GET")
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                loading = false
                if let error = error {
                    print("Error fetching image: \(error)")
                    return
                }
                
                guard let response = response as? HTTPURLResponse else {
                    print("No response")
                    return
                }
                
                if response.statusCode != 200 {
                    print("Failed to get image")
                    return
                }
                
                if response.mimeType != "image/png" {
                    print("Invalid MIME type \"\(response.mimeType ?? "unknown")\"")
                    return
                }
                
                guard let data = data else {
                    print("No data")
                    return
                }
                
                self.imageData = data
                if let onLoad = onLoad {
                    onLoad()
                }
            }
        }.resume()
    }
    
    var body: some View {
        Group {
            if loading == true {
                ProgressView()
                    .progressViewStyle(.circular)
                    .colorInvert()
            } else {
                if let imageData = imageData {
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .scaleEffect(0.5)
                    } else {
                        error
                    }
                } else {
                    error
                }
            }
        }
            .onAppear() {
                fetchImage(url: url)
            }
    }
    
    var error: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.black)
            Text("Unable to load image")
                .foregroundStyle(.black)
        }
    }
    
    func onLoad(_ action: @escaping () -> Void) -> some View {
        var view = self
        view.onLoad = action
        return view
    }
}
