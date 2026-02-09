import UIKit
import WebKit

final class EmbeddedBrowserViewController: UIViewController {
    
    private var contentView: WKWebView!
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let loadingOverlay = UIView()
    private var initialLoadDone = false
    
    var loadAddress: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        loadingOverlay.backgroundColor = .black
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingOverlay)
        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor)
        ])
        activityIndicator.startAnimating()
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        contentView = WKWebView(frame: .zero, configuration: config)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.navigationDelegate = self
        contentView.scrollView.contentInsetAdjustmentBehavior = .never
        contentView.allowsBackForwardNavigationGestures = true
        contentView.isOpaque = false
        contentView.backgroundColor = .black
        view.insertSubview(contentView, belowSubview: loadingOverlay)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        if let address = loadAddress, let location = URL(string: address) {
            var request = URLRequest(url: location)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            contentView.load(request)
        }
    }
    
    override var prefersStatusBarHidden: Bool { true }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .portrait }
}

extension EmbeddedBrowserViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if initialLoadDone == false {
            initialLoadDone = true
            activityIndicator.stopAnimating()
            UIView.animate(withDuration: 0.25) {
                self.loadingOverlay.alpha = 0
            } completion: { _ in
                self.loadingOverlay.isHidden = true
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if initialLoadDone == false {
            initialLoadDone = true
            activityIndicator.stopAnimating()
            loadingOverlay.isHidden = true
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if initialLoadDone == false {
            initialLoadDone = true
            activityIndicator.stopAnimating()
            loadingOverlay.isHidden = true
        }
    }
}
