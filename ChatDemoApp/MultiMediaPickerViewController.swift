//
//  MultiMediaPickerViewController.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 02/01/26.
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation
import PDFKit

protocol MultiMediaPickerDelegate: AnyObject {
    func didSelectMedia(_ items: [MediaItem])
}

class MultiMediaPickerViewController: UIViewController {
    
    weak var delegate: MultiMediaPickerDelegate?
    
    // MARK: - Properties
    private var selectedMediaItems: [MediaItem] = []
    private var selectedIdentifiers: Set<String> = []
    private let maxSelection = 10
    
    // Enum for picker mode
    enum PickerMode {
        case photosAndVideos
        case documents // For PDFs
    }
    
    private var currentMode: PickerMode = .photosAndVideos
    
    // MARK: - UI Components
    private let segmentedControl: UISegmentedControl = {
        let items = ["Photos & Videos", "Documents"]
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let topBar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Select Media"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 22
        button.isEnabled = false
        button.alpha = 0.5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let selectedCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0 selected"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var photos: [PHAsset] = []
    private let imageManager = PHImageManager.default()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        checkPhotoLibraryPermission()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(topBar)
        view.addSubview(segmentedControl)
        view.addSubview(collectionView)
        view.addSubview(bottomBar)
        
        topBar.addSubview(cancelButton)
        topBar.addSubview(titleLabel)
        bottomBar.addSubview(selectedCountLabel)
        bottomBar.addSubview(sendButton)
        
        let topBorder = CALayer()
        topBorder.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 0.5)
        topBorder.backgroundColor = UIColor.separator.cgColor
        bottomBar.layer.addSublayer(topBorder)
        
        NSLayoutConstraint.activate([
            // Top bar
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            cancelButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            
            // Segmented Control
            segmentedControl.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Collection view
            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
            
            // Bottom bar
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 80),
            
            selectedCountLabel.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            selectedCountLabel.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            
            sendButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            sendButton.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 100),
            sendButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MediaCell.self, forCellWithReuseIdentifier: "MediaCell")
        collectionView.allowsMultipleSelection = true
    }
    
    // MARK: - Photo Library
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            fetchPhotos()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                if status == .authorized || status == .limited {
                    DispatchQueue.main.async {
                        self?.fetchPhotos()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert()
        @unknown default:
            break
        }
    }
    
    private func fetchPhotos() {
        photos.removeAll()
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let mediaType: PHAssetMediaType = currentMode == .photosAndVideos ? .image : .image
        let fetchResult = PHAsset.fetchAssets(with: mediaType, options: fetchOptions)
        
        if currentMode == .photosAndVideos {
            // Fetch both images and videos
            let imageFetch = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            let videoFetch = PHAsset.fetchAssets(with: .video, options: fetchOptions)
            
            imageFetch.enumerateObjects { asset, _, _ in
                self.photos.append(asset)
            }
            
            videoFetch.enumerateObjects { asset, _, _ in
                self.photos.append(asset)
            }
            
            // Sort by creation date
            photos.sort { ($0.creationDate ?? Date()) > ($1.creationDate ?? Date()) }
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Access Required",
            message: "Please allow access to your photos in Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func updateSelectionUI() {
        let count = selectedMediaItems.count
        selectedCountLabel.text = "\(count) selected"
        
        if count > 0 {
            sendButton.isEnabled = true
            sendButton.alpha = 1.0
            titleLabel.text = "Select Media (\(count)/\(maxSelection))"
        } else {
            sendButton.isEnabled = false
            sendButton.alpha = 0.5
            titleLabel.text = "Select Media"
        }
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func sendTapped() {
        delegate?.didSelectMedia(selectedMediaItems)
        dismiss(animated: true)
    }
    
    @objc private func segmentChanged() {
        currentMode = segmentedControl.selectedSegmentIndex == 0 ? .photosAndVideos : .documents
        
        if currentMode == .documents {
            // Present document picker
            presentDocumentPicker()
        } else {
            fetchPhotos()
        }
    }
    
    private func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image], asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension MultiMediaPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaCell", for: indexPath) as! MediaCell
        
        let asset = photos[indexPath.item]
        let identifier = asset.localIdentifier
        
        // Request image
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        
        let targetSize = CGSize(width: 300, height: 300)
        
        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            cell.configure(with: image, isVideo: asset.mediaType == .video)
        }
        
        // Update selection state
        let isSelected = selectedIdentifiers.contains(identifier)
        let selectionNumber = isSelected ? selectedMediaItems.firstIndex(where: { item in
            switch item {
            case .image(_, let id), .video(_, _, let id), .pdf(_, _, _, let id):
                return id == identifier
            }
        }).map { $0 + 1 } ?? 0 : 0
        
        cell.setSelected(isSelected, number: selectionNumber)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension MultiMediaPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = photos[indexPath.item]
        let identifier = asset.localIdentifier
        
        // Check if already selected
        if selectedIdentifiers.contains(identifier) {
            // Deselect
            selectedIdentifiers.remove(identifier)
            selectedMediaItems.removeAll { item in
                switch item {
                case .image(_, let id), .video(_, _, let id), .pdf(_, _, _, let id):
                    return id == identifier
                }
            }
        } else {
            // Check max selection
            if selectedMediaItems.count >= maxSelection {
                let alert = UIAlertController(
                    title: nil,
                    message: "You can only select up to \(maxSelection) items",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            
            // Select
            selectedIdentifiers.insert(identifier)
            
            // Request full media
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            if asset.mediaType == .video {
                // Request video
                let videoOptions = PHVideoRequestOptions()
                videoOptions.isNetworkAccessAllowed = true
                
                imageManager.requestAVAsset(forVideo: asset, options: videoOptions) { [weak self] avAsset, _, _ in
                    guard let urlAsset = avAsset as? AVURLAsset else { return }
                    let url = urlAsset.url
                    
                    // Generate thumbnail
                    let imageGenerator = AVAssetImageGenerator(asset: avAsset!)
                    imageGenerator.appliesPreferredTrackTransform = true
                    
                    var thumbnail: UIImage?
                    if let cgImage = try? imageGenerator.copyCGImage(at: .zero, actualTime: nil) {
                        thumbnail = UIImage(cgImage: cgImage)
                    }
                    
                    DispatchQueue.main.async {
                        self?.selectedMediaItems.append(.video(url, thumbnail: thumbnail, identifier: identifier))
                        self?.updateSelectionUI()
                        collectionView.reloadItems(at: [indexPath])
                    }
                }
            } else {
                imageManager.requestImage(
                    for: asset,
                    targetSize: PHImageManagerMaximumSize,
                    contentMode: .aspectFill,
                    options: options
                ) { [weak self] image, _ in
                    guard let image = image else { return }
                    
                    DispatchQueue.main.async {
                        self?.selectedMediaItems.append(.image(image, identifier: identifier))
                        self?.updateSelectionUI()
                        collectionView.reloadItems(at: [indexPath])
                    }
                }
            }
        }
        
        updateSelectionUI()
        collectionView.reloadItems(at: [indexPath])
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - UIDocumentPickerDelegate
extension MultiMediaPickerViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        print("📄 Document picker returned \(urls.count) files")
        
        for url in urls {
            processPDFDocument(url)
        }
        
        // Switch back to photos tab after processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.segmentedControl.selectedSegmentIndex = 0
            self?.currentMode = .photosAndVideos
            self?.fetchPhotos()
        }
    }
    
    private func processPDFDocument(_ url: URL) {
        print("📄 Processing PDF: \(url.lastPathComponent)")
        
        // CRITICAL: Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            print("❌ Could not access security-scoped resource")
            showErrorAlert("Cannot access the selected file")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
            print("✅ Stopped accessing security-scoped resource")
        }
        
        do {
            // Create persistent PDFs directory in Documents
            let fileManager = FileManager.default
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let pdfDirectory = documentsPath.appendingPathComponent("PDFs", isDirectory: true)
            
            // Create directory if needed
            if !fileManager.fileExists(atPath: pdfDirectory.path) {
                try fileManager.createDirectory(at: pdfDirectory, withIntermediateDirectories: true)
                print("📁 Created PDFs directory at: \(pdfDirectory.path)")
            }
            
            // Generate unique filename
            let originalFilename = url.lastPathComponent
            let uniqueFilename = generateUniqueFilename(for: originalFilename, in: pdfDirectory)
            let destinationURL = pdfDirectory.appendingPathComponent(uniqueFilename)
            
            // Copy file to persistent location
            try fileManager.copyItem(at: url, to: destinationURL)
            print("✅ Copied PDF to: \(destinationURL.path)")
            
            // Verify file exists
            guard fileManager.fileExists(atPath: destinationURL.path) else {
                print("❌ File doesn't exist after copy")
                return
            }
            
            // Generate thumbnail
            generatePDFThumbnail(for: destinationURL) { [weak self] thumbnail in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    // Add to selected items with unique identifier
                    let identifier = UUID().uuidString
                    let mediaItem = MediaItem.pdf(
                        destinationURL,
                        thumbnail: thumbnail,
                        name: uniqueFilename,
                        identifier: identifier
                    )
                    
                    self.selectedMediaItems.append(mediaItem)
                    self.updateSelectionUI()
                    
                    print("✅ Added PDF to selected items: \(uniqueFilename)")
                }
            }
            
        } catch {
            print("❌ Error processing PDF: \(error.localizedDescription)")
            showErrorAlert("Failed to process PDF: \(error.localizedDescription)")
        }
    }
    
    private func generateUniqueFilename(for filename: String, in directory: URL) -> String {
        let fileManager = FileManager.default
        var uniqueFilename = filename
        var counter = 1
        
        // Fix double .pdf.pdf extension
        if uniqueFilename.hasSuffix(".pdf.pdf") {
            uniqueFilename = String(uniqueFilename.dropLast(4))
            print("🔧 Fixed double extension: \(uniqueFilename)")
        }
        
        // Ensure unique filename
        while fileManager.fileExists(atPath: directory.appendingPathComponent(uniqueFilename).path) {
            let nameWithoutExtension = (uniqueFilename as NSString).deletingPathExtension
            let fileExtension = (uniqueFilename as NSString).pathExtension
            uniqueFilename = "\(nameWithoutExtension)_\(counter).\(fileExtension)"
            counter += 1
        }
        
        return uniqueFilename
    }
    
    private func generatePDFThumbnail(for url: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Method 1: Try PDFKit (most reliable)
            if let pdfDocument = PDFDocument(url: url),
               let page = pdfDocument.page(at: 0) {
                
                let pageRect = page.bounds(for: .mediaBox)
                let thumbnailSize = CGSize(width: 200, height: 280)
                
                // Calculate scale to fit
                let widthScale = thumbnailSize.width / pageRect.width
                let heightScale = thumbnailSize.height / pageRect.height
                let scale = min(widthScale, heightScale)
                
                let scaledSize = CGSize(
                    width: pageRect.width * scale,
                    height: pageRect.height * scale
                )
                
                let renderer = UIGraphicsImageRenderer(size: scaledSize)
                let thumbnail = renderer.image { context in
                    UIColor.white.set()
                    context.fill(CGRect(origin: .zero, size: scaledSize))
                    
                    context.cgContext.translateBy(x: 0, y: scaledSize.height)
                    context.cgContext.scaleBy(x: scale, y: -scale)
                    
                    page.draw(with: .mediaBox, to: context.cgContext)
                }
                
                print("✅ Generated PDF thumbnail using PDFKit")
                completion(thumbnail)
                return
            }
            
            // Method 2: Fallback to placeholder icon
            print("⚠️ Could not generate PDF thumbnail, using placeholder")
            let placeholderConfig = UIImage.SymbolConfiguration(pointSize: 60, weight: .thin)
            let placeholder = UIImage(systemName: "doc.fill", withConfiguration: placeholderConfig)
            completion(placeholder)
        }
    }
    
    private func showErrorAlert(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("📄 Document picker was cancelled")
        
        // Switch back to photos tab
        segmentedControl.selectedSegmentIndex = 0
        currentMode = .photosAndVideos
        fetchPhotos()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MultiMediaPickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let spacing: CGFloat = 2
        let totalSpacing = spacing * (numberOfColumns - 1)
        let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns
        return CGSize(width: width, height: width)
    }
}

extension MultiMediaPickerViewController {
    
    /// Clean up old PDF files (call this periodically, e.g., on app launch)
    func cleanupOldPDFs() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let pdfDirectory = documentsPath.appendingPathComponent("PDFs", isDirectory: true)
        
        guard fileManager.fileExists(atPath: pdfDirectory.path),
              let files = try? fileManager.contentsOfDirectory(
                at: pdfDirectory,
                includingPropertiesForKeys: [.creationDateKey]
              ) else {
            return
        }
        
        // Delete files older than 30 days
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        
        for file in files {
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let creationDate = attributes[.creationDate] as? Date,
               creationDate < thirtyDaysAgo {
                try? fileManager.removeItem(at: file)
                print("🗑️ Deleted old PDF: \(file.lastPathComponent)")
            }
        }
    }
}
