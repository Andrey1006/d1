import SwiftUI
@preconcurrency import WebKit

struct WebContentView: View {
    let targetUrl: String
    
    var body: some View {
        NavigationView {
            WebKitContainer(targetUrl: targetUrl)
                .navigationBarHidden(true)
                .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .background(Color.black.ignoresSafeArea(.all))
    }
}

struct WebKitContainer: View {
    let targetUrl: String
    @State private var webView = WKWebView()
    @State private var canGoBack = false
    @State private var canGoForward = false
    @AppStorage("place") var point: String = ""
    @AppStorage("placesaved") var placesaved: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            WebKitWrapper(
                webView: $webView,
                targetUrl: targetUrl,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward,
                point: $point,
                placesaved: $placesaved
            )
            
            HStack {
                Spacer()
                
                Button(action: {
                    if webView.canGoBack { webView.goBack() }
                }) {
                    Image(systemName: "chevron.backward")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .padding(8)
                
                Spacer()
                
                Button(action: {
                    if webView.canGoForward { webView.goForward() }
                }) {
                    Image(systemName: "chevron.forward")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                .padding(8)
                
                Spacer()
            }
            .background(Color.black)
        }
        .background(Color.black.ignoresSafeArea(.all))
    }
}

struct WebKitWrapper: UIViewRepresentable {
    @Binding var webView: WKWebView
    let targetUrl: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var point: String
    @Binding var placesaved: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true
        let dataStore = WKWebsiteDataStore.default()
        config.websiteDataStore = dataStore
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        
        HTTPCookieStorage.shared.cookies?.forEach {
            dataStore.httpCookieStore.setCookie($0)
        }
        
        let wk = WKWebView(frame: .zero, configuration: config)
        wk.navigationDelegate = context.coordinator
        wk.uiDelegate = context.coordinator
        wk.allowsBackForwardNavigationGestures = true
        
        wk.evaluateJavaScript("navigator.userAgent") { (result, error) in
            if let currentUserAgent = result as? String {
                let cleanUA = currentUserAgent
                    .replacingOccurrences(of: "([^\\s]+)AppleWebKit", with: "AppleWebKit", options: .regularExpression)
                    .replacingOccurrences(of: "Version\\/\\d+\\.\\d+\\s+", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "; wv", with: "")
                
                wk.customUserAgent = cleanUA
            }
        }
        
        if let url = URL(string: targetUrl) {
            wk.load(URLRequest(url: url))
        }
        
        DispatchQueue.main.async {
            self.webView = wk
        }
        
        return wk
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebKitWrapper
        var lastRedirectURL: URL?
        
        init(_ parent: WebKitWrapper) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
                if let url = webView.url {
                    self.lastRedirectURL = url
                }
            }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                
                if let url = webView.url?.absoluteString, !self.parent.placesaved {
                    self.parent.placesaved = true
                    self.parent.point = url
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError

            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorHTTPTooManyRedirects {
                if let url = lastRedirectURL {
                    let request = URLRequest(url: url)
                    webView.load(request)
                }
            }
        }
        
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            let scheme = url.scheme?.lowercased() ?? ""

            if ["http", "https", "about", "file"].contains(scheme) {
                if url.host?.contains("apps.apple.com") == true {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                    return
                }
                
                self.lastRedirectURL = url
                decisionHandler(.allow)
                return
            }

            decisionHandler(.cancel)
            
            UIApplication.shared.open(url, options: [:]) { success in
            }
        }
        
        @available(iOS 15, *)
        func webView(_ webView: WKWebView,
                     requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                     initiatedByFrame frame: WKFrameInfo,
                     type: WKMediaCaptureType,
                     decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }
        
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}

