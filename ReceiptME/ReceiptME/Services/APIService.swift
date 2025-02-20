//
//  APIService.swift
//  ReceiptME
//
//  Created by Jimmy Lancaster on 2/18/25.
//

import Foundation
import UIKit

class APIService {
    static let shared = APIService()
    private init() {}
    
    // Update this with your backend base URL.
    let baseURL = "https://yourbackendapi.com"
    
    // Upload receipt image (JPG) to /receipts/auto
    func uploadReceipt(image: UIImage, completion: @escaping (Result<ReceiptScanResult, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/receipts/auto") else {
            return
        }
        
        // Convert the image to JPEG data.
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else { return }
            
            do {
                let result = try JSONDecoder().decode(ReceiptScanResult.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Fetch all receipts from /receipts
    func fetchReceipts(completion: @escaping (Result<ReceiptList, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/receipts") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else { return }
            
            do {
                let list = try JSONDecoder().decode(ReceiptList.self, from: data)
                completion(.success(list))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Fetch receipt details from /receipts/<id>
    func fetchReceiptDetails(receiptId: Int, completion: @escaping (Result<ReceiptDetails, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/receipts/\(receiptId)") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else { return }
            
            do {
                let details = try JSONDecoder().decode(ReceiptDetails.self, from: data)
                completion(.success(details))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
