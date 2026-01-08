//
//  StreamControlsView.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 08/01/26.
//

import UIKit

protocol StreamControlsDelegate: AnyObject {
    func didTapMuteButton()
    func didTapVideoButton()
    func didTapSwitchCamera()
    func didTapEndStream()
}

class StreamControlsView: UIView {
    weak var delegate: StreamControlsDelegate?
    
    private lazy var muteButton = createButton(icon: "mic.fill", background: .systemGray)
    private lazy var videoButton = createButton(icon: "video.fill", background: .systemGray)
    private lazy var switchButton = createButton(icon: "arrow.triangle.2.circlepath.camera.fill", background: .systemGray)
    private lazy var endButton = createButton(icon: "xmark", background: .systemRed)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        let stack = UIStackView(arrangedSubviews: [muteButton, videoButton, switchButton, endButton])
        stack.axis = .horizontal
        stack.spacing = 20
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.heightAnchor.constraint(equalToConstant: 64)
        ])
        
        muteButton.addTarget(self, action: #selector(muteTapped), for: .touchUpInside)
        videoButton.addTarget(self, action: #selector(videoTapped), for: .touchUpInside)
        switchButton.addTarget(self, action: #selector(switchTapped), for: .touchUpInside)
        endButton.addTarget(self, action: #selector(endTapped), for: .touchUpInside)
    }
    
    private func createButton(icon: String, background: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = background
        button.layer.cornerRadius = 32
        button.tintColor = .white
        
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        
        button.widthAnchor.constraint(equalToConstant: 64).isActive = true
        button.heightAnchor.constraint(equalToConstant: 64).isActive = true
        
        return button
    }
    
    @objc private func muteTapped() { delegate?.didTapMuteButton() }
    @objc private func videoTapped() { delegate?.didTapVideoButton() }
    @objc private func switchTapped() { delegate?.didTapSwitchCamera() }
    @objc private func endTapped() { delegate?.didTapEndStream() }
    
    func updateMuteButton(isMuted: Bool) {
        let icon = isMuted ? "mic.slash.fill" : "mic.fill"
        let bg = isMuted ? UIColor.systemRed : .systemGray
        updateButton(muteButton, icon: icon, background: bg)
    }
    
    func updateVideoButton(isOff: Bool) {
        let icon = isOff ? "video.slash.fill" : "video.fill"
        let bg = isOff ? UIColor.systemRed : .systemGray
        updateButton(videoButton, icon: icon, background: bg)
    }
    
    private func updateButton(_ button: UIButton, icon: String, background: UIColor) {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        button.backgroundColor = background
    }
}
