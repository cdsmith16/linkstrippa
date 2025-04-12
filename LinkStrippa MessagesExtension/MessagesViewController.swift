import Messages
import UIKit

class MessagesViewController: MSMessagesAppViewController {
    
    // Known tracking parameters to remove    
    private let trackingParams = [
        // UTM & general analytics
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
        "_ga", "_gl", "_gid", "gclid", "dclid", "msclkid", "yclid",

        // Facebook/Meta
        "fbclid", "fb_action_ids", "fb_action_types", "fb_source",
        "action_object_map", "action_type_map", "action_ref_map", "fb_ref", "fb_sig", "fref",

        // Twitter/X, TikTok, Instagram
        "twclid", "ttclid", "igshid", "ig_cache_key", "ig_rid", "ig_mid",
        "xid", "s", "t", "si", "st", "smid",

        // LinkedIn
        "li_fat_id",

        // Microsoft Ads / Yahoo / Bing
        "ocid", "bclid", "rb_clickid",

        // Marketing platforms
        "mc_cid", "mc_eid", "_hsenc", "_hsmi", "mkt_tok",
        "elqTrackId", "elqTrack", "trk_contact", "trk_msg", "trk_module", "trk_sid",

        // Piwik / Matomo
        "pk_campaign", "pk_kwd", "pk_source", "pk_medium", "pk_content", "pk_cpm",

        // Affiliate & Ad Networks
        "clickid", "adid", "adgroupid", "campaignid", "creative", "matchtype",
        "network", "placement", "device", "keyword", "adposition", "s_kwcid",
        "aff_id", "aff_sub", "aff_sub2", "aff_sub3", "aff_sub4", "aff_sub5",
        "affiliate_id", "utm_affiliate", "irgwc", "irclickid", "irsid",
        "tag", "ascsubtag", "cjevent", "impactclkid", "cmpid", "mkwid", "mktid", "mkcid", "mktsrc", "mkevt", "mkrid",
        "u1", "u2", "u3", "u4", "u5",

        // AMP / redirect / click layers
        "amp", "amp_js_v", "amp_gsa", "amp_r", "amp_lite", "ampcachebust", "ampcid",
        "redirect", "redirect_uri", "redirect_log_mongo_id", "redirect_mongo_id",
        "ref", "ref_src", "ref_url", "source", "src", "from", "via", "r", "rtd", "original_referer",

        // iMessage / deep link / share clutter
        "is_copy_url", "entry_point", "share_id", "share_token", "share_link_id",
        "sender_device", "sender_web_id", "session_id", "session_key",
        "click_time", "shortlink", "deep_link_id", "app_id",

        // Shopify / content platforms
        "vercelAnalytics", "page", "position", "feeditemid",

        // Newsletter / personalization trackers
        "vero_conv", "vero_id", "ga_source", "ga_medium", "ga_term", "ga_content", "ga_campaign",
        "sc_campaign", "sc_channel", "sc_content", "sc_medium", "sc_outcome", "sc_geo", "sc_country", "sc_device",

        // Navigation noise
        "usp", "dti", "ns_mchannel", "ns_source", "ns_campaign", "ns_linkname", "ns_fee",
        "ei", "ved", "ct", "icid", "hash"
    ]

    
    // Stats tracking
    private var totalParamsRemoved = 0
    
    // Flag to track view state
    private var isViewReady = false
    
    // MARK: - UI Components
    private lazy var headerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [appIconView, headerLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10
        return stack
    }()
    
    private lazy var appIconView: UIImageView = {
        let imageView = UIImageView()
        // Try to load the app icon from the main bundle
        if let iconImage = UIImage(named: "AppIcon") {
            imageView.image = iconImage
        } else {
            // Fallback to a system image if app icon isn't available
            imageView.image = UIImage(systemName: "link.badge.plus")
            imageView.tintColor = .systemBlue
        }
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        
        // Set size constraints
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 30),
            imageView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return imageView
    }()
    
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Share links without the tracking"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var urlField: UITextField = {
        let field = UITextField()
        field.placeholder = "Paste link here..."
        field.borderStyle = .roundedRect
        field.returnKeyType = .done
        field.delegate = self
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.keyboardType = .URL
        field.clearButtonMode = .whileEditing
        return field
    }()
    
    private lazy var cleanButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Clean & Share"
        configuration.baseBackgroundColor = .systemBlue
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        configuration.cornerStyle = .medium
        
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(cleanAndInsertURL), for: .touchUpInside)
        return button
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    // Results comparison view
    private lazy var resultsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()
    
    private lazy var beforeLabel: UILabel = {
        let label = UILabel()
        label.text = "Original URL:"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        return label
    }()
    
    private lazy var beforeURL: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.numberOfLines = 3
        return label
    }()
    
    private lazy var afterLabel: UILabel = {
        let label = UILabel()
        label.text = "Cleaned URL:"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        return label
    }()
    
    private lazy var afterURL: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGreen
        label.numberOfLines = 3
        return label
    }()
    
    private lazy var statsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.text = "Total tracking parameters removed: 0"
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("DEBUG: viewDidLoad called")
        setupUI()
        isViewReady = true
        
        // Load saved stats
        loadStats()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("DEBUG: viewDidAppear called")
        DispatchQueue.main.async { [weak self] in
            self?.isViewReady = true
            print("DEBUG: isViewReady explicitly set to true in viewDidAppear")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("DEBUG: viewWillDisappear called")
        isViewReady = false
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        print("DEBUG: Setting up UI")
        
        // Set up the results container with before/after URL views
        let beforeStack = UIStackView(arrangedSubviews: [beforeLabel, beforeURL])
        beforeStack.axis = .vertical
        beforeStack.spacing = 4
        
        let afterStack = UIStackView(arrangedSubviews: [afterLabel, afterURL])
        afterStack.axis = .vertical
        afterStack.spacing = 4
        
        let resultsStack = UIStackView(arrangedSubviews: [beforeStack, afterStack])
        resultsStack.axis = .vertical
        resultsStack.spacing = 12
        resultsStack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
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
            urlField,
            cleanButton,
            statusLabel,
            resultsContainer,
            statsLabel
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.setCustomSpacing(20, after: headerStack)
        mainStack.setCustomSpacing(16, after: statusLabel)
        mainStack.setCustomSpacing(20, after: resultsContainer)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            mainStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16)
        ])
        
        updateStatsDisplay()
        print("DEBUG: UI setup complete")
    }
    
    // MARK: - URL Processing
    @objc private func cleanAndInsertURL() {
        print("DEBUG: Button tapped!")
        
        // Check if view is still valid
        guard isViewReady else {
            print("DEBUG: View not ready")
            return
        }
        
        guard let urlText = urlField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !urlText.isEmpty else {
            print("DEBUG: URL text empty")
            showStatus(message: "Please enter a URL", isError: true)
            return
        }
        
        print("DEBUG: Processing URL: \(urlText)")
        
        // Check if activeConversation exists
        guard let conversation = activeConversation else {
            print("DEBUG: No active conversation")
            showStatus(message: "No active conversation", isError: true)
            return
        }
        
        guard var urlComponents = URLComponents(string: urlText) else {
            print("DEBUG: Invalid URL format")
            showStatus(message: "Invalid URL format", isError: true)
            return
        }
        
        // Store original URL for display
        let originalURL = urlText
        
        // Store original query count for feedback
        let originalQueryItems = urlComponents.queryItems?.count ?? 0
        print("DEBUG: Original query items: \(originalQueryItems)")
        
        // Remove tracking parameters
        var removedCount = 0
        if var queryItems = urlComponents.queryItems {
            let originalCount = queryItems.count
            
            queryItems.removeAll { item in
                let shouldRemove = trackingParams.contains(item.name.lowercased())
                if shouldRemove {
                    print("DEBUG: Removing param: \(item.name)")
                    removedCount += 1
                }
                return shouldRemove
            }
            
            // If all query items were tracking params, remove the query completely
            urlComponents.queryItems = queryItems.isEmpty ? nil : queryItems
            print("DEBUG: Removed \(originalCount - queryItems.count) tracking parameters")
        }
        
        guard let cleanURL = urlComponents.url?.absoluteString else {
            print("DEBUG: Error creating clean URL")
            showStatus(message: "Error processing URL", isError: true)
            return
        }
        
        print("DEBUG: Clean URL: \(cleanURL)")
        
        // Update the comparison view
        updateComparisonView(original: originalURL, cleaned: cleanURL)
        
        // Update stats
        totalParamsRemoved += removedCount
        saveStats()
        updateStatsDisplay()
        
        // Insert into conversation
        print("DEBUG: Inserting into conversation...")
        conversation.insertText(cleanURL) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else {
                    print("DEBUG: Self is nil in callback")
                    return
                }
                
                guard self.isViewReady else {
                    print("DEBUG: View not ready in callback")
                    return
                }
                
                if let error = error {
                    print("DEBUG: Error inserting: \(error.localizedDescription)")
                    self.showStatus(message: "Failed to insert URL", isError: true)
                } else {
                    print("DEBUG: Insert successful")
                    if removedCount > 0 {
                        self.showStatus(message: "✓ Removed \(removedCount) tracking parameters", isError: false)
                    } else {
                        self.showStatus(message: "✓ URL is clean!", isError: false)
                    }
                    
                    // Don't clear the URL field so users can see the comparison
                    
                    // Collapse after successful insertion - but check if still active
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                        guard let self = self, self.isViewReady else {
                            print("DEBUG: View not ready for compact mode")
                            return
                        }
                        print("DEBUG: Requesting compact presentation")
                        self.requestPresentationStyle(.compact)
                    }
                }
            }
        }
    }
    
    private func updateComparisonView(original: String, cleaned: String) {
        beforeURL.text = original
        afterURL.text = cleaned
        resultsContainer.isHidden = false
    }
    
    private func showStatus(message: String, isError: Bool) {
        print("DEBUG: Show status: \(message), isError: \(isError)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isViewReady else {
                print("DEBUG: View not ready for status update")
                return
            }
            
            self.statusLabel.text = message
            self.statusLabel.textColor = isError ? .systemRed : .systemGreen
            self.statusLabel.isHidden = false
            
            if !isError {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    guard let self = self, self.isViewReady else {
                        print("DEBUG: View not ready for hiding status")
                        return
                    }
                    self.statusLabel.isHidden = true
                }
            }
        }
    }
    
    // MARK: - Stats Management
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
    
    // Cancel any pending operations when extension dismisses
    private func cancelPendingOperations() {
        print("DEBUG: Canceling pending operations")
    }
}

// MARK: - UITextFieldDelegate
extension MessagesViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("DEBUG: TextField return pressed")
        textField.resignFirstResponder()
        cleanAndInsertURL()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Hide previous results when user starts typing
        resultsContainer.isHidden = true
        
        // Hide status message when user starts typing
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isViewReady else { return }
            self.statusLabel.isHidden = true
        }
        return true
    }
}

// MARK: - Presentation Style Handling
extension MessagesViewController {
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        print("DEBUG: willBecomeActive called with conversation: \(conversation)")
        
        // Only update UI if view is loaded
        if isViewLoaded {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    print("DEBUG: Self is nil in willBecomeActive")
                    return
                }
                // Don't clear the field to allow for comparing URLs
                // self.urlField.text = ""
                self.resultsContainer.isHidden = true
                self.statusLabel.isHidden = true
                self.isViewReady = true
                print("DEBUG: willBecomeActive UI updated")
            }
        }
    }
    
    override func willResignActive(with conversation: MSConversation) {
        super.willResignActive(with: conversation)
        print("DEBUG: willResignActive called")
        
        // Mark view as not ready when resigning
        isViewReady = false
        cancelPendingOperations()
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        print("DEBUG: didStartSending called")
        // Extension is about to close/minimize after sending
        isViewReady = false
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        print("DEBUG: didTransition to style: \(presentationStyle)")
        // If compact, mark as not ready
        if presentationStyle == .compact {
            isViewReady = false
        } else if presentationStyle == .expanded {
            // When expanding, ensure we're ready
            DispatchQueue.main.async { [weak self] in
                self?.isViewReady = true
            }
        }
    }
}
