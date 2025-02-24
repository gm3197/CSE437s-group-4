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
    
    func createAuthorizedRequest(url: URL, method: String = "POST", contentType: String? = nil, body: Data? = nil) -> URLRequest {
            var request = URLRequest(url: url)
            
            // Set Authorization header with stored token
            if let token = UserDefaults.standard.string(forKey: "user_permanent_token") {
                request.setValue(token, forHTTPHeaderField: "Authorization")
            }
            
            // Set HTTP method (default is POST)
            request.httpMethod = method
            
            // Set Content-Type header if provided
            if let contentType = contentType {
                request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            }
            
            // Set HTTP body if provided
            request.httpBody = body
            
            return request
        }
        
    
    // Update this with your backend base URL.
    let baseURL = "https://cse437.graysonmartin.net"
    
    
    // Upload receipt image (JPG) to /receipts/auto
    func uploadReceipt(image: UIImage, completion: @escaping (Result<ReceiptScanResult, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/receipts/auto") else {
            return
        }
        
        // Convert the image to JPEG data.
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let request = createAuthorizedRequest(url: url, method: "POST", contentType: "image/jpeg", body: imageData)
        
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
        
        let request = createAuthorizedRequest(url: url, method: "GET", contentType: "application/json")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
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
        
        let request = createAuthorizedRequest(url: url, method: "GET", contentType: "application/json")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
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
