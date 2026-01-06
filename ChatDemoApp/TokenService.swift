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
    private let baseURL = "http://192.168.1.8:3000"
    
    private init() {}
    
    // MARK: - Token Fetching
    
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
    
    // MARK: - Room Link Generation
    
    /// Generates a video room link that can be shared with other participants
    /// - Parameters:
    ///   - roomName: The name of the room (e.g., "room-1767609451456")
    ///   - userName: The user identifier (e.g., "user456")
    /// - Returns: A shareable URL for the video room
    func createVideoRoomLink(roomName: String, userName: String) -> URL? {
        var components = URLComponents()
        
        // Parse baseURL to get scheme and host
        guard let baseURL = URL(string: baseURL) else { return nil }
        
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = "/"
        
        components.queryItems = [
            URLQueryItem(name: "room", value: roomName),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "user", value: userName)
        ]
        print("roomLinks \(components.url)")
        return components.url
    }
    
    /// Generates a room name with timestamp
    /// - Returns: A unique room name (e.g., "room-1767609451456")
    func generateRoomName() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        return "room-\(timestamp)"
    }
    
    /// Creates a video room link with auto-generated room name
    /// - Parameter userName: The user identifier
    /// - Returns: A shareable URL with a unique room name
    func createVideoRoomLink(userName: String) -> URL? {
        let roomName = generateRoomName()
        return createVideoRoomLink(roomName: roomName, userName: userName)
    }
    
    /// Converts a URL to a shareable string
    /// - Parameter url: The room URL
    /// - Returns: A formatted string for sharing
    func getShareableLink(_ url: URL) -> String {
        return url.absoluteString
    }
}
