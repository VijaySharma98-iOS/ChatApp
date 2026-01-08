//
//  TokenService.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 05/01/26.
//

import Foundation
import CryptoKit

class TokenService {
    static let shared = TokenService()
    
    // Replace with your LiveKit Cloud credentials
    private let livekitURL = "wss://chatapp-74ccouhb.livekit.cloud" // Get from LiveKit Cloud dashboard
    private let apiKey = "APIYQAoj6PsWCf8"                          // Get from LiveKit Cloud dashboard
    private let apiSecret = "KER0QfQo3NmX0vNrEqMO5n8fe2sAWlOEPOTjTE5tgJfD"                    // Get from LiveKit Cloud dashboard
    
    private init() {}
    
    func fetchToken(identity: String, roomName: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Generate token locally (for testing only - use server-side in production)
        do {
            let token = try generateToken(identity: identity, roomName: roomName)
            completion(.success(token))
            print(token)
        } catch {
            completion(.failure(error))
        }
    }
    
    private func generateToken(identity: String, roomName: String) throws -> String {
        // Using LiveKit's JWT token generation
        // Note: In production, tokens should be generated on your server
        
        let header = [
            "alg": "HS256",
            "typ": "JWT"
        ]
        
        let now = Date()
        let exp = now.addingTimeInterval(6 * 3600) // 6 hours expiry
        
        let payload: [String: Any] = [
            "exp": Int(exp.timeIntervalSince1970),
            "iss": apiKey,
            "nbf": Int(now.timeIntervalSince1970),
            "sub": identity,
            "video": [
                "room": roomName,
                "roomJoin": true,
                "canPublish": true,
                "canSubscribe": true
            ]
        ]
        
        let token = try createJWT(header: header, payload: payload, secret: apiSecret)
        return token
    }
    
    private func createJWT(header: [String: Any], payload: [String: Any], secret: String) throws -> String {
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        
        let headerString = base64URLEncode(headerData)
        let payloadString = base64URLEncode(payloadData)
        
        let signatureInput = "\(headerString).\(payloadString)"
        let signature = hmacSHA256(data: signatureInput, key: secret)
        let signatureString = base64URLEncode(signature)
        
        return "\(signatureInput).\(signatureString)"
    }
    
    private func base64URLEncode(_ data: Data) -> String {
        let base64 = data.base64EncodedString()
        let base64URL = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return base64URL
    }
    
    private func hmacSHA256(data: String, key: String) -> Data {
        let keyData = Data(key.utf8)
        let dataData = Data(data.utf8)
        let symmetricKey = SymmetricKey(data: keyData)
        let authenticationCode = HMAC<SHA256>.authenticationCode(for: dataData, using: symmetricKey)
        return Data(authenticationCode)
    }
    
    func getLiveKitURL() -> String {
        return livekitURL
    }
}

