//
//  MediaPreviewContainerView.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 02/01/26.
//

import UIKit
import PDFKit

class MediaPreviewContainerView: UIView {
    
    // MARK: - Properties
    var mediaItems: [MediaItem] = [] {
        didSet {
            updateUI()
        }
    }
    
    var onRemoveItem: ((String) -> Void)?
    var onTapItem: ((MediaItem) -> Void)?
    
    private let maxVisibleItems = 4
    
    // MARK: - UI Components
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 4
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - Setup
    private func setupViews() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 12
        clipsToBounds = true
        
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    // MARK: - Update UI
    private func updateUI() {
        // Clear existing views
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard !mediaItems.isEmpty else {
            isHidden = true
            return
        }
        
        isHidden = false
        
        let itemsToShow = min(mediaItems.count, maxVisibleItems)
        
        for i in 0..<itemsToShow {
            let item = mediaItems[i]
            let isLast = (i == maxVisibleItems - 1)
            let remainingCount = mediaItems.count - maxVisibleItems
            
            let itemView = MediaPreviewItemView()
            itemView.configure(with: item, showOverlay: isLast && remainingCount > 0, overlayCount: remainingCount + 1)
            itemView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add tap gesture
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(itemTapped(_:)))
            itemView.addGestureRecognizer(tapGesture)
            itemView.tag = i
            
            // Add remove button
            itemView.onRemove = { [weak self] in
                self?.removeItem(at: i)
            }
            
            stackView.addArrangedSubview(itemView)
            
            // Set width constraint
            itemView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        }
    }
    
    private func removeItem(at index: Int) {
        guard index < mediaItems.count else { return }
        
        let item = mediaItems[index]
        let id = item.id
        
        mediaItems.remove(at: index)
        onRemoveItem?(id)
    }
    
    @objc private func itemTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view, view.tag < mediaItems.count else { return }
        let item = mediaItems[view.tag]
        onTapItem?(item)
    }
    
    func addImage(_ image: UIImage) {
        mediaItems.append(.image(image))
    }
    
    func addVideo(url: URL, thumbnail: UIImage?) {
        mediaItems.append(.video(url, thumbnail: thumbnail))
    }
    
    func addPDF(url: URL, name: String) {
        let thumbnail = generatePDFThumbnail(from: url)
        mediaItems.append(.pdf(url, thumbnail: thumbnail, name: name))
    }
    
    func clearAll() {
        mediaItems.removeAll()
    }
    
    private func generatePDFThumbnail(from url: URL) -> UIImage? {
        guard let document = PDFDocument(url: url),
              let page = document.page(at: 0) else {
            return nil
        }
        
        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        
        let image = renderer.image { context in
            UIColor.white.set()
            context.fill(pageRect)
            
            context.cgContext.translateBy(x: 0, y: pageRect.size.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            
            page.draw(with: .mediaBox, to: context.cgContext)
        }
        
        return image
    }
}
