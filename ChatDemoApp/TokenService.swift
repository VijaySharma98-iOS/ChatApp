//
//  TokenService.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 05/01/26.
//


// TokenService.swift
import Foundation

class TokenService {
    static let shared = TokenService()
    
    // IMPORTANT: Replace with your Mac's IP address
    // Find it by running: ifconfig | grep "inet " | grep -v 127.0.0.1
    private let baseURL = "http://192.168.1.8:3000" // ⬅️ CHANGE THIS
    
    private init() {}
    
    func fetchToken(identity: String, roomName: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Validate inputs
        guard !identity.isEmpty, !roomName.isEmpty else {
            completion(.failure(NSError(domain: "TokenService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Identity and room name cannot be empty"
            ])))
            return
        }
        
        // Create URL
        guard let url = URL(string: "\(baseURL)/token") else {
            completion(.failure(NSError(domain: "TokenService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid server URL"
            ])))
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let body: [String: String] = [
            "identity": identity,
            "roomName": roomName
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Make request
        print("🌐 Requesting token from: \(url.absoluteString)")
        print("📝 Identity: \(identity), Room: \(roomName)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network error
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(.failure(NSError(domain: "TokenService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Cannot connect to server. Make sure:\n1. Server is running\n2. You're on the same WiFi\n3. IP address is correct"
                ])))
                return
            }
            
            // Check response
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "TokenService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid server response"
                ])))
                return
            }
            
            print("📡 Response status: \(httpResponse.statusCode)")
            
            // Check status code
            guard httpResponse.statusCode == 200 else {
                let errorMessage = "Server error (Status: \(httpResponse.statusCode))"
                print("❌ \(errorMessage)")
                completion(.failure(NSError(domain: "TokenService", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: errorMessage
                ])))
                return
            }
            
            // Parse response
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["token"] as? String else {
                print("❌ Failed to parse token from response")
                completion(.failure(NSError(domain: "TokenService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid token response"
                ])))
                return
            }
            
            print("✅ Token received successfully")
            completion(.success(token))
            
        }.resume()
    }
}
