//
//  AudioPlayerManager.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 01/01/26.
//

import UIKit
import AVFoundation

// MARK: - Audio Player Manager
class AudioPlayerManager: NSObject {
    
    static let shared = AudioPlayerManager()
    
    var audioPlayer: AVAudioPlayer?
    private var playingURL: URL?
    private var timer: Timer?
    
    // Changed: Now passes the finished URL
    var onPlaybackFinished: ((URL) -> Void)?
    
    private override init() {
        super.init()
    }
    
    func play(url: URL) throws {
        // Stop current playback if any
        stop()
        
        playingURL = url
        
        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)
        
        // Create and play
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.play()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        let stoppedURL = playingURL
        playingURL = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
        
        // Notify that this URL finished
        if let url = stoppedURL {
            onPlaybackFinished?(url)
        }
    }
    
    func pause() {
        audioPlayer?.pause()
    }
    
    func resume() {
        audioPlayer?.play()
    }
    
    func isPlaying(url: URL) -> Bool {
        return playingURL == url && audioPlayer?.isPlaying == true
    }
    
    func getCurrentPlayingURL() -> URL? {
        return playingURL
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let finishedURL = playingURL
        
        timer?.invalidate()
        timer = nil
        audioPlayer = nil
        playingURL = nil
        
        try? AVAudioSession.sharedInstance().setActive(false)
        
        // Notify with the specific URL that finished
        if let url = finishedURL {
            onPlaybackFinished?(url)
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Audio player error: \(error.localizedDescription)")
        }
        stop()
    }
}

