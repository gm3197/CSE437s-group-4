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
                print("Receipt scan result data: \(result)")
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
//                print("Receipt list data: \(list)")
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
    func updateReceiptDetails(_ details: ReceiptDetails, completion: @escaping (Result<ReceiptDetails, Error>) -> Void) {
//        print("Updating receipt details (b): \(details)\n")
        guard let url = URL(string: "\(baseURL)/receipts/\(details.id)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(details)
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
                
                do {
//                    print("Raw response data:", String(data: data, encoding: .utf8) ?? "Invalid response")
                    let updatedDetails = try JSONDecoder().decode(ReceiptDetails.self, from: data)
                    completion(.success(updatedDetails))
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        } catch { // prints error bc backend doesnt send any success message back -- functionality still works
            completion(.failure(error))
        }
    }
    
    // MARK: - Add Receipt Item
    func addReceiptItem(_ item: NewReceiptItemRequest, to_receipt_with_id receipt_id: Int, completion: @escaping (Result<ReceiptItem, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/receipts/\(receipt_id)/items") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(item)
            let request = createAuthorizedRequest(url: url, method: "POST", contentType: "application/json", body: jsonData)
            
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
                    let responseData = try JSONDecoder().decode(NewReceiptItemResponse.self, from: data)
                    
                    let receiptItem = ReceiptItem(description: item.description, price: item.price, id: responseData.item_id, category: item.category)
                    
                    completion(.success(receiptItem))
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Delete Receipt Item
    func deleteReceiptItem(_ item_id: Int, within_receipt_with_id receiptId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/receipts/\(receiptId)/items/\(item_id)") else {
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

    ///
    // MARK: - Update Receipt Item
    func updateReceiptItem(_ item: ReceiptItem, receipt_id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
//        print("Updating receipt details (b): \(details)\n")


//        print("I. APIService starting updateReceiptDetails")
//        print(" --> with the following details: \(details)\n")
        guard let url = URL(string: "\(baseURL)/receipts/\(receipt_id)/items/\(item.id)") else {
//            print("II. Invalid URL error")
            completion(.failure(APIError.invalidURL))
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(item)
            let request = createAuthorizedRequest(url: url,
                                                  method: "PATCH",
                                                  contentType: "application/json",
                                                  body: jsonData)
            print("III. About to start URLSession task")
            URLSession.shared.dataTask(with: request) { data, response, error in
                print("III. About to start URLSession task")
                
                if let error = error {
                    print("V. Network error: \(error)")
                    completion(.failure(error))
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    print("VI. HTTP Status: \(httpResponse.statusCode)")
                } // new
                
                guard let data = data else {
                    print("VII. No data received") // if failing here
                    
                    print("VIII. Returning success with original details due to no data")
//                    completion(.success(details))
                    
                    completion(.failure(APIError.noData))
                    return
                }
                print("IX. Raw response data: \(String(data: data, encoding: .utf8) ?? "Invalid response")")
                
                
            completion(.success(()))

            }.resume()
                
                print("IV. URLSession task started")
                
            } catch { // prints error bc backend doesnt send any success message back -- functionality still works
                print("XIV. JSON encoding error: \(error)")
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
    
    // MARK: - Categories
  
    // set year and month to nil to get categories for current month
    func getCategories(year: Int?, month: Int?, completion: @escaping (Result<[Category], Error>) -> Void) {
        var url: URL
        if year == nil && month == nil {
            guard let defaultUrl = URL(string: "\(baseURL)/categories") else {
                completion(.failure(APIError.invalidURL))
                return
            }
            url = defaultUrl
        } else if year != nil && month != nil {
            guard let specificUrl = URL(string: "\(baseURL)/categories/\(year!)/\(month!)") else {
                completion(.failure(APIError.invalidURL))
                return
            }
            url = specificUrl
        } else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        let request = createAuthorizedRequest(url: url, method: "GET")
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
                let responseData = try JSONDecoder().decode(GetCategoriesResponse.self, from: data)
                completion(.success(responseData.categories))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func createCategory(name: String, spending_goal: Double, completion: @escaping (Result<Category, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/categories") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(CreateCategoryRequest(name: name, monthly_goal: spending_goal))
            let request = createAuthorizedRequest(url: url, method: "POST", contentType: "application/json", body: jsonData)
            
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
                    let responseData = try JSONDecoder().decode(Category.self, from: data)
                    completion(.success(responseData))
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: – Delete Category
    func deleteCategory(categoryId: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/categories/\(categoryId)") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        let request = createAuthorizedRequest(url: url, method: "DELETE")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                return completion(.failure(error))
            }
            guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
                return completion(.failure(APIError.invalidURL))
            }
            completion(.success(()))
        }
        .resume()
    }
}
