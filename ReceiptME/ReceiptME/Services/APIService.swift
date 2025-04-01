//
//  APIService.swift
//  ReceiptME
//
//  Created by Jimmy Lancaster on 2/18/25
//

import Foundation
import UIKit

enum APIError: Error {
    case invalidURL
    case noData
}

class APIService {
    static let shared = APIService()
    private init() {}
    
    // MARK: - Helper: Create Authorized Request
    func createAuthorizedRequest(url: URL,
                                 method: String = "POST",
                                 contentType: String? = nil,
                                 body: Data? = nil) -> URLRequest {
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
    
    // MARK: - Base URL
    let baseURL = "https://cse437.graysonmartin.net"
    
    // MARK: - Upload Receipt Image
    func uploadReceipt(image: UIImage, completion: @escaping (Result<ReceiptScanResult, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/receipts/auto") else {
            return
        }
        
        // Convert the image to JPEG data.
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        let request = createAuthorizedRequest(url: url,
                                              method: "POST",
                                              contentType: "image/jpeg",
                                              body: imageData)
        
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
    
    // MARK: - Fetch All Receipts (Preview)
    func fetchReceipts(completion: @escaping (Result<ReceiptList, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/receipts") else {
            return
        }
        
        let request = createAuthorizedRequest(url: url,
                                              method: "GET",
                                              contentType: "application/json")
        
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
    
    // MARK: - Fetch Basic Receipt by ID (Preview)
    //   (If you need a simpler version that only returns the basic `Receipt` data.)
    func fetchReceiptDetails(receiptId: Int, completion: @escaping (Result<ReceiptDetails, Error>) -> Void) {
        // We'll assume GET /receipts/<id> returns the full, detailed ReceiptDetails.
        guard let url = URL(string: "\(baseURL)/receipts/\(receiptId)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let request = createAuthorizedRequest(url: url,
                                              method: "GET",
                                              contentType: "application/json")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let details = try JSONDecoder().decode(ReceiptDetails.self, from: data)
                completion(.success(details))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Update Basic Receipt (Preview)
    func updateReceipt(_ receipt: Receipt, completion: @escaping (Result<Receipt, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/receipts/\(receipt.id)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(receipt)
            let request = createAuthorizedRequest(url: url,
                                                  method: "PATCH",
                                                  contentType: "application/json",
                                                  body: jsonData)
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                do {
                    let updatedReceipt = try JSONDecoder().decode(Receipt.self, from: data)
                    completion(.success(updatedReceipt))
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Update Detailed Receipt
    /// Updates all fields in `ReceiptDetails`, including items, payment_method, merchant name, tax, etc.
    func updateReceiptItem(_ item: ReceiptItem, receipt_id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
//        print("Updating receipt details (b): \(details)\n")
        guard let url = URL(string: "\(baseURL)/receipts/\(receipt_id)/items/\(item.id)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(item)
            let request = createAuthorizedRequest(url: url,
                                                  method: "PATCH",
                                                  contentType: "application/json",
                                                  body: jsonData)
            URLSession.shared.dataTask(with: request) { data, response, error in
//                print("Data object? : \(data)")
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.noData))
                    return
                }
                
                completion(.success(()))

            }.resume()
        } catch { // prints error bc backend doesnt send any success message back -- functionality still works
            completion(.failure(error))
        }
    }
    
    // MARK: - Delete Receipt
    func deleteReceipt(receiptId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/receipts/\(receiptId)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let request = createAuthorizedRequest(url: url,
                                              method: "DELETE")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            // Optionally check for a non-2xx HTTP status code here.
            completion(.success(()))
        }.resume()
    }
    
    func getReceiptItemCroppedImage(receiptId: Int, itemId: Int, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/receipts/\(receiptId)/items/\(itemId)/scan.png") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let request = createAuthorizedRequest(url: url, method: "GET")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
        
            guard let response = response else {
                completion(.failure(APIError.noData))
                return
            }
            
            if response.mimeType != "image/png" {
                completion(.failure(APIError.noData))
                return
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
        
            completion(.success(data))
        }.resume()
    }
}
