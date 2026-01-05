//
//  MultiImagePickerViewController.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 02/01/26.
//

import UIKit
import PhotosUI

protocol MultiImagePickerDelegate: AnyObject {
    func didSelectImages(_ images: [UIImage])
}

class MultiImagePickerViewController: UIViewController {
    
    weak var delegate: MultiImagePickerDelegate?
    
    // MARK: - Properties
    private var selectedImages: [UIImage] = []
    private var selectedIdentifiers: Set<String> = []
    private let maxSelection = 10
    
    // MARK: - UI Components
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
        label.text = "Select Photos"
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
            
            // Collection view
            collectionView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
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
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
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
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        fetchResult.enumerateObjects { asset, _, _ in
            self.photos.append(asset)
        }
        
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Photo Access Required",
            message: "Please allow access to your photos in Settings to select images.",
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
        let count = selectedImages.count
        selectedCountLabel.text = "\(count) selected"
        
        if count > 0 {
            sendButton.isEnabled = true
            sendButton.alpha = 1.0
            titleLabel.text = "Select Photos (\(count)/\(maxSelection))"
        } else {
            sendButton.isEnabled = false
            sendButton.alpha = 0.5
            titleLabel.text = "Select Photos"
        }
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func sendTapped() {
        delegate?.didSelectImages(selectedImages)
        dismiss(animated: true)
    }
}
extension MultiImagePickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
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
            cell.configure(with: image)
        }
        
        // Update selection state
        let isSelected = selectedIdentifiers.contains(identifier)
        let selectionNumber: Int = {
            guard isSelected else { return 0 }
            // Create a stable order for display by sorting identifiers deterministically
            let ordered = Array(selectedIdentifiers).sorted()
            if let idx = ordered.firstIndex(of: identifier) {
                return idx + 1
            }
            return 0
        }()
        cell.setSelected(isSelected, number: selectionNumber)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension MultiImagePickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = photos[indexPath.item]
        let identifier = asset.localIdentifier
        
        // Check if already selected
        if selectedIdentifiers.contains(identifier) {
            // Deselect
            selectedIdentifiers.remove(identifier)
            
            // Remove image from selectedImages array
            if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell,
               let image = cell.imageView.image {
                selectedImages.removeAll { $0 === image }
            }
        } else {
            // Check max selection
            if selectedImages.count >= maxSelection {
                let alert = UIAlertController(
                    title: nil,
                    message: "You can only select up to \(maxSelection) photos",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            
            // Select
            selectedIdentifiers.insert(identifier)
            
            // Request full image
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            imageManager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFill,
                options: options
            ) { [weak self] image, _ in
                guard let image = image else { return }
                self?.selectedImages.append(image)
                
                DispatchQueue.main.async {
                    self?.updateSelectionUI()
                    collectionView.reloadItems(at: [indexPath])
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

// MARK: - UICollectionViewDelegateFlowLayout
extension MultiImagePickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let spacing: CGFloat = 2
        let totalSpacing = spacing * (numberOfColumns - 1)
        let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns
        return CGSize(width: width, height: width)
    }
}

