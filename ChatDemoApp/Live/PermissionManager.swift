//
//  PermissionManager.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 08/01/26.
//

import AVFoundation


class PermissionManager {
    static let shared = PermissionManager()
    
    func checkMediaPermissions(completion: @escaping (Bool) -> Void) {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch (cameraStatus, micStatus) {
        case (.authorized, .authorized):
            completion(true)
            
        case (.notDetermined, _), (_, .notDetermined):
            requestPermissions(completion: completion)
            
        default:
            completion(false)
        }
    }
    
    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { cameraGranted in
            AVCaptureDevice.requestAccess(for: .audio) { micGranted in
                DispatchQueue.main.async {
                    completion(cameraGranted && micGranted)
                }
            }
        }
    }
}
