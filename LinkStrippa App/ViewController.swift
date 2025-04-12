//
//  ViewController.swift
//  LinkStrippa App
//
//  Created by Christian M2P on 4/12/25.
//  Copyright © 2025 Smith Labs, LLC. All rights reserved.
//
//  Enhanced by Claude Code on 2025-07-31
//  - Complete standalone iOS app implementation
//  - Unified experience with iMessage extension
//  - Shared statistics and URL cleaning logic
//

import UIKit
import LinkStrippa_Common

class ViewController: UIViewController {
    
    // Stats tracking - shared with Messages extension via UserDefaults
    private var totalParamsRemoved = 0
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var headerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [appIconView, headerLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        return stack
    }()
    
    private lazy var appIconView: UIImageView = {
        let imageView = UIImageView()
        if let iconImage = UIImage(named: "AppIcon") {
            imageView.image = iconImage
        } else {
            imageView.image = UIImage(systemName: "link.badge.plus")
            imageView.tintColor = .systemBlue
        }
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 15
        imageView.layer.masksToBounds = true
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        return imageView
    }()
    
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Share links without the tracking"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Remove tracking parameters from URLs to protect your privacy and make links cleaner."
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var urlField: UITextField = {
        let field = UITextField()
        field.placeholder = "Paste your link here..."
        field.borderStyle = .roundedRect
        field.returnKeyType = .done
        field.delegate = self
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.keyboardType = .URL
        field.clearButtonMode = .whileEditing
        field.font = .systemFont(ofSize: 16)
        return field
    }()
    
    private lazy var cleanButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Clean URL"
        configuration.baseBackgroundColor = .systemBlue
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        configuration.cornerStyle = .medium
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
            return outgoing
        }
        
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(cleanURL), for: .touchUpInside)
        return button
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    // Results comparison view
    private lazy var resultsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()
    
    private lazy var beforeLabel: UILabel = {
        let label = UILabel()
        label.text = "Original URL:"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private lazy var beforeURL: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var afterLabel: UILabel = {
        let label = UILabel()
        label.text = "Cleaned URL:"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private lazy var afterURL: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .systemGreen
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var shareButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Share Clean URL"
        configuration.baseBackgroundColor = .systemGreen
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        configuration.cornerStyle = .medium
        configuration.image = UIImage(systemName: "square.and.arrow.up")
        configuration.imagePadding = 8
        
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(shareCleanURL), for: .touchUpInside)
        return button
    }()
    
    private lazy var copyButton: UIButton = {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = "Copy to Clipboard"
        configuration.baseBackgroundColor = .systemBlue
        configuration.baseForegroundColor = .systemBlue
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        configuration.cornerStyle = .medium
        configuration.image = UIImage(systemName: "doc.on.doc")
        configuration.imagePadding = 8
        
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(copyCleanURL), for: .touchUpInside)
        return button
    }()
    
    private lazy var actionButtonsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [shareButton, copyButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        return stack
    }()
    
    private lazy var statsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.text = "Total tracking parameters removed: 0"
        return label
    }()
    
    // Store the last cleaned URL for sharing/copying
    private var lastCleanedURL: String?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadStats()
        
        // Set up navigation
        title = "LinkStrippa"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Add keyboard handling
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadStats()
        updateStatsDisplay()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Set up scroll view
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Set up the results container with before/after URL views
        let beforeStack = UIStackView(arrangedSubviews: [beforeLabel, beforeURL])
        beforeStack.axis = .vertical
        beforeStack.spacing = 6
        
        let afterStack = UIStackView(arrangedSubviews: [afterLabel, afterURL])
        afterStack.axis = .vertical
        afterStack.spacing = 6
        
        let resultsStack = UIStackView(arrangedSubviews: [beforeStack, afterStack, actionButtonsStack])
        resultsStack.axis = .vertical
        resultsStack.spacing = 16
        resultsStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        resultsStack.isLayoutMarginsRelativeArrangement = true
        
        resultsContainer.addSubview(resultsStack)
        resultsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resultsStack.leadingAnchor.constraint(equalTo: resultsContainer.leadingAnchor),
            resultsStack.trailingAnchor.constraint(equalTo: resultsContainer.trailingAnchor),
            resultsStack.topAnchor.constraint(equalTo: resultsContainer.topAnchor),
            resultsStack.bottomAnchor.constraint(equalTo: resultsContainer.bottomAnchor)
        ])
        
        // Main layout
        let mainStack = UIStackView(arrangedSubviews: [
            headerStack,
            descriptionLabel,
            urlField,
            cleanButton,
            statusLabel,
            resultsContainer,
            statsLabel
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.setCustomSpacing(12, after: headerStack)
        mainStack.setCustomSpacing(24, after: descriptionLabel)
        mainStack.setCustomSpacing(16, after: urlField)
        mainStack.setCustomSpacing(16, after: statusLabel)
        mainStack.setCustomSpacing(24, after: resultsContainer)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        updateStatsDisplay()
    }
    
    // MARK: - URL Processing
    @objc private func cleanURL() {
        guard let urlText = urlField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !urlText.isEmpty else {
            showStatus(message: "Please enter a URL", isError: true)
            return
        }
        
        guard let result = URLTrackingParams.cleanURL(urlText) else {
            showStatus(message: "Invalid URL format", isError: true)
            return
        }

        let originalURL = result.original
        let cleanURL = result.cleaned
        let removedCount = result.paramsRemoved
        
        // Store for sharing/copying
        lastCleanedURL = cleanURL
        
        // Update the comparison view
        updateComparisonView(original: originalURL, cleaned: cleanURL)
        
        // Update stats
        totalParamsRemoved += removedCount
        saveStats()
        updateStatsDisplay()
        
        // Show success message
        if removedCount > 0 {
            showStatus(message: "✓ Removed \(removedCount) tracking parameters", isError: false)
        } else {
            showStatus(message: "✓ URL is already clean!", isError: false)
        }
        
        // Dismiss keyboard
        urlField.resignFirstResponder()
    }
    
    @objc private func shareCleanURL() {
        guard let cleanURL = lastCleanedURL else { return }
        
        let activityVC = UIActivityViewController(activityItems: [cleanURL], applicationActivities: nil)
        
        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    @objc private func copyCleanURL() {
        guard let cleanURL = lastCleanedURL else { return }
        
        UIPasteboard.general.string = cleanURL
        
        // Show brief feedback
        let originalTitle = copyButton.configuration?.title
        var config = copyButton.configuration
        config?.title = "Copied!"
        copyButton.configuration = config
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            var config = self?.copyButton.configuration
            config?.title = originalTitle
            self?.copyButton.configuration = config
        }
    }
    
    private func updateComparisonView(original: String, cleaned: String) {
        beforeURL.text = original
        afterURL.text = cleaned
        resultsContainer.isHidden = false
    }
    
    private func showStatus(message: String, isError: Bool) {
        statusLabel.text = message
        statusLabel.textColor = isError ? .systemRed : .systemGreen
        statusLabel.isHidden = false
        
        if !isError {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.statusLabel.isHidden = true
            }
        }
    }
    
    // MARK: - Stats Management (shared with Messages extension)
    private func updateStatsDisplay() {
        statsLabel.text = "Total tracking parameters removed: \(totalParamsRemoved)"
    }
    
    private func saveStats() {
        let defaults = UserDefaults.standard
        defaults.set(totalParamsRemoved, forKey: "totalParamsRemoved")
    }
    
    private func loadStats() {
        let defaults = UserDefaults.standard
        totalParamsRemoved = defaults.integer(forKey: "totalParamsRemoved")
        updateStatsDisplay()
    }
    
    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - UITextFieldDelegate
extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        cleanURL()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Hide previous results when user starts typing
        resultsContainer.isHidden = true
        statusLabel.isHidden = true
        return true
    }
}

