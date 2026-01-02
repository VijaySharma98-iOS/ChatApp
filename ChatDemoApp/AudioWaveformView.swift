//
//  AudioWaveformView.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 01/01/26.
//

import Foundation
import UIKit

class AudioWaveformView: UIView {
    
    private let numberOfBars = 30
    private var barLayers: [CAShapeLayer] = []
    private var progress: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBars()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBars()
    }
    
    private func setupBars() {
        for _ in 0..<numberOfBars {
            let bar = CAShapeLayer()
            bar.fillColor = UIColor.systemGray4.cgColor
            bar.cornerRadius = 1
            layer.addSublayer(bar)
            barLayers.append(bar)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBarFrames()
    }
    
    func generateWaveform() {
        // Generate random heights for demo
        // In a real app, you would analyze the audio file
        for bar in barLayers {
            let randomHeight = CGFloat.random(in: 0.3...1.0)
            bar.opacity = Float(randomHeight)
        }
        updateBarFrames()
    }
    
    func updateProgress(_ progress: CGFloat) {
        self.progress = max(0, min(1, progress))
        
        let playedBars = Int(CGFloat(numberOfBars) * self.progress)
        
        for (index, bar) in barLayers.enumerated() {
            if index < playedBars {
                bar.fillColor = UIColor.systemBlue.cgColor
            } else {
                bar.fillColor = UIColor.systemGray4.cgColor
            }
        }
    }
    
    private func updateBarFrames() {
        let barWidth: CGFloat = 2
        let spacing: CGFloat = 3
        let totalWidth = CGFloat(numberOfBars) * (barWidth + spacing) - spacing
        let startX = (bounds.width - totalWidth) / 2
        
        for (index, bar) in barLayers.enumerated() {
            let x = startX + CGFloat(index) * (barWidth + spacing)
            let height = bounds.height * CGFloat(bar.opacity)
            let y = (bounds.height - height) / 2
            
            bar.frame = CGRect(x: x, y: y, width: barWidth, height: height)
        }
    }
}
