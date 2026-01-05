//
//  PDFViewerViewController.swift
//  ChatDemoApp
//
//  Created by Vijay Sharma on 02/01/26.
//

import UIKit
import PDFKit

class PDFViewerViewController: UIViewController {
    
    // MARK: - Properties
    private let pdfURL: URL
    private let fileName: String
    
    // MARK: - UI Components
    private let pdfView: PDFView = {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let toolbar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        button.setImage(UIImage(systemName: "square.and.arrow.up", withConfiguration: config), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let pageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .systemGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Init
    init(pdfURL: URL, fileName: String) {
        self.pdfURL = pdfURL
        self.fileName = fileName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPDF()
        
        // Observer for page changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pageChanged),
            name: .PDFViewPageChanged,
            object: pdfView
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(toolbar)
        view.addSubview(pdfView)
        view.addSubview(pageLabel)
        
        toolbar.addSubview(closeButton)
        toolbar.addSubview(fileNameLabel)
        toolbar.addSubview(shareButton)
        
        fileNameLabel.text = fileName
        
        // Add border to toolbar
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x: 0, y: 43.5, width: view.bounds.width, height: 0.5)
        bottomBorder.backgroundColor = UIColor.separator.cgColor
        toolbar.layer.addSublayer(bottomBorder)
        
        NSLayoutConstraint.activate([
            // Toolbar
            toolbar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),
            
            closeButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            
            fileNameLabel.centerXAnchor.constraint(equalTo: toolbar.centerXAnchor),
            fileNameLabel.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            fileNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 8),
            fileNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: shareButton.leadingAnchor, constant: -8),
            
            shareButton.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -16),
            shareButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            shareButton.widthAnchor.constraint(equalToConstant: 44),
            shareButton.heightAnchor.constraint(equalToConstant: 44),
            
            // PDF View
            pdfView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Page Label
            pageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
    }
    
    private func loadPDF() {
        guard let document = PDFDocument(url: pdfURL) else {
            showError("Unable to load PDF")
            return
        }
        
        pdfView.document = document
        updatePageLabel()
    }
    
    private func updatePageLabel() {
        guard let document = pdfView.document,
              let currentPage = pdfView.currentPage else {
            pageLabel.text = ""
            return
        }
        
        let pageIndex = document.index(for: currentPage)
        let totalPages = document.pageCount
        pageLabel.text = "Page \(pageIndex + 1) of \(totalPages)"
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func shareTapped() {
        let activityVC = UIActivityViewController(activityItems: [pdfURL], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    @objc private func pageChanged() {
        updatePageLabel()
    }
}

