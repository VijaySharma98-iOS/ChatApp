//
//  LiveStatusView.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 08/01/26.
//

import UIKit


class LiveStatusView: UIView {
    private let liveIndicator = UIView()
    private let liveLabel = UILabel()
    private let viewerIcon = UIImageView()
    private let viewerCountLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        layer.cornerRadius = 20
        
        // Live indicator
        liveIndicator.backgroundColor = .systemRed
        liveIndicator.layer.cornerRadius = 4
        liveIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // Live label
        liveLabel.text = "LIVE"
        liveLabel.textColor = .white
        liveLabel.font = .systemFont(ofSize: 12, weight: .bold)
        liveLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Viewer icon
        viewerIcon.tintColor = .white
        viewerIcon.image = UIImage(systemName: "eye.fill")
        viewerIcon.translatesAutoresizingMaskIntoConstraints = false
        
        // Viewer count
        viewerCountLabel.text = "0"
        viewerCountLabel.textColor = .white
        viewerCountLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        viewerCountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        [liveIndicator, liveLabel, viewerIcon, viewerCountLabel].forEach { addSubview($0) }
        
        NSLayoutConstraint.activate([
            liveIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            liveIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            liveIndicator.widthAnchor.constraint(equalToConstant: 8),
            liveIndicator.heightAnchor.constraint(equalToConstant: 8),
            
            liveLabel.leadingAnchor.constraint(equalTo: liveIndicator.trailingAnchor, constant: 6),
            liveLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            viewerIcon.leadingAnchor.constraint(equalTo: liveLabel.trailingAnchor, constant: 12),
            viewerIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            viewerCountLabel.leadingAnchor.constraint(equalTo: viewerIcon.trailingAnchor, constant: 6),
            viewerCountLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            viewerCountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
    }
    
    func startAnimation() {
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse]) {
            self.liveIndicator.alpha = 0.3
        }
    }
    
    func updateViewerCount(_ count: Int) {
        viewerCountLabel.text = "\(count)"
    }
}
