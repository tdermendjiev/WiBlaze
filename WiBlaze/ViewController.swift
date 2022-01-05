//
//  ViewController.swift
//  WiBlaze
//
//  Created by Justin Bush on 2020-07-14.
//  Copyright © 2020 Justin Bush. All rights reserved.
//

import UIKit
import WebKit

let debug = true


extension String {
    func escapeString() -> String {
        var newString = self.replacingOccurrences(of: "\"", with: "\"\"")
        
        if newString.contains(",") || newString.contains("\n") {
            newString = String(format: "\"%@\"", newString)
        }

        return newString
    }
}

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UITextFieldDelegate, UIScrollViewDelegate, CircleMenuDelegate {

    // UI Elements
    @IBOutlet weak var webView: WKWebView!                  // Main WebView
    @IBOutlet weak var textField: UITextField!              // URLSearchBar
    @IBOutlet weak var menuButton: UIBarButtonItem!         // Menu Button
    @IBOutlet weak var backButton: UIBarButtonItem!         // Back Button
    @IBOutlet weak var secureButton: UIBarButtonItem!       // Secure Icon
    @IBOutlet weak var circleMenuButton: CircleMenu!        // CircleMenu Button
    @IBOutlet weak var topConstraint: NSLayoutConstraint!   // Top Bar Constraint
    
    // WebView Observers
    var webViewURLObserver: NSKeyValueObservation?          // Observer for URL
    var webViewTitleObserver: NSKeyValueObservation?        // Observer for Page Title
    var webViewProgressObserver: NSKeyValueObservation?     // Observer for Load Progress
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showMenu(false, withAnimation: false)               // Hide Menu on Launch
        
        // Initializers
        initWebView()               // Initalize WebView
        widenTextField()            // Set URLSearchBar constraints
        
        /*
        if !Settings.hasLaunchedBefore {
            Settings.setDefaults()
        }
        */
        
        // OBSERVER: WebView URL (Detect Changes)
        webViewURLObserver = webView.observe(\.url, options: .new) { [weak self] webView, change in
            self?.urlDidChange("\(String(describing: change.newValue))") }
        
    }
    
    
    
    
    // MARK:- WebView
    
    func initWebView() {
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.customUserAgent = Browser.getUserAgent()            // Set Browser UserAgent
        // WebView Configuration
        let config = webView.configuration
        
        config.applicationNameForUserAgent = Browser.name           // Set Client Name
        config.preferences.javaScriptEnabled = true                 // Enable JavaScript
        // ScrollView Setup
        webView.scrollView.delegate = self
        webView.scrollView.isScrollEnabled = true                   // Enable Scroll
        webView.scrollView.keyboardDismissMode = .onDrag
        // Hide Keyboard on WebView Drag
        
        let contentController = self.webView.configuration.userContentController
        contentController.add(self, name: "removeCookieMessageHandler")
        contentController.add(self, name: "executeScriptMessageHandler")
        contentController.add(self, name: "updateHeadersMessageHandler")

        // Load Homepage
        
        load(Settings.getLaunchURL())
        
        //progressBar.progress = 0
        //progressBar.alpha = 0
    }
    
    func load(_ url: String) {
        self.webView.load(url)
    }
    
    func reload() {
        self.webView.reload()
    }
    
    func getMyJavaScript() -> String {
           if let filepath = Bundle.main.path(forResource: "common", ofType: "js") {
               do {
                   return try String(contentsOfFile: filepath)
               } catch {
                   return ""
               }
           } else {
              return ""
           }
       }
    
    func getSetupJS() -> String {
        if let filepath = Bundle.main.path(forResource: "extensionApi", ofType: "js") {
            do {
                return try String(contentsOfFile: filepath)
            } catch {
                return ""
            }
        } else {
           return ""
        }
    }
    
    func getScriptsAsOne() -> String {
        if let filepath1 = Bundle.main.path(forResource: "common", ofType: "js"),
           let filepath2 = Bundle.main.path(forResource: "sites", ofType: "js"),
           let filepath3 = Bundle.main.path(forResource: "background", ofType: "js") {
            do {
                return try
                """
                \(String(contentsOfFile: filepath1))

                \(String(contentsOfFile: filepath2))

                \(String(contentsOfFile: filepath3))
                """
            } catch {
                return ""
            }
        } else {
           return ""
        }
    }
    
    func getManifestString() -> String {
        if let filepath = Bundle.main.path(forResource: "manifest", ofType: "json") {
            do {
                return try String(contentsOfFile: filepath)
            } catch {
                return ""
            }
        } else {
           return ""
        }
    }
    
    func getScript(name: String, type: String) -> String {
        if let filepath = Bundle.main.path(forResource: name, ofType: type) {
            do {
                return try String(contentsOfFile: filepath)
            } catch {
                return ""
            }
        } else {
           return ""
        }
    }
    
    func setupBrowserObject(urlString: String, cookiesJsonString: String, completion: @escaping((Error?) -> Void)) {
        
        let manifest = self.getManifestString()
 
        let jsString = """
          \(getSetupJS())
          var browser;
          var runtime;
            runtime = new Runtime(\(manifest));
            var tabs = new Tabs([{url:"\(urlString.escapeString())"}]);
            var webRequest = new WebRequest();
            var cookies = new Cookies(\(cookiesJsonString));
            console.log("cookies", cookies);
            var shouldRunPluginSetup = false;
            window.shouldRunPluginSetup = shouldRunPluginSetup
            if (typeof browser === "undefined") {
                            browser = new Browser(runtime, tabs, webRequest, cookies);
                            window.browser = browser;
                            console.log("BROWSER SETUP");
                window.shouldRunPluginSetup = true;
            }
        """
        
        let pluginScripts = """
                if (shouldRunPluginSetup) {
                  //  \(getScriptsAsOne())
                };
        """
        self.webView.evaluateJavaScript(jsString) { (result, error) in
            if error != nil {
                let s = jsString
                print(error)
            }
            self.webView.evaluateJavaScript(pluginScripts) { (result, error) in
                if error != nil {
                    let s = jsString
                    print(error)
                }
                completion(error)
            }
            
        }
        
    }
    
    func getCookiesJson(completion: @escaping (String) -> Void) {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { (cookies) in
            var jsonString = "["
            for (index, cookie) in cookies.enumerated() {
                let dict = [
                    "name": cookie.name,
                    "value": cookie.value,
                    "secure": cookie.isSecure,
                    "path": cookie.path,
                    "domain": cookie.domain
                ] as [String : Any]
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .withoutEscapingSlashes)
                    let str = String(decoding: jsonData, as: UTF8.self)
                    jsonString = jsonString + str
                    if index != cookies.count - 1 {
                        jsonString = jsonString + ", "
                    } else {
                        jsonString = jsonString + "]"
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
            completion(jsonString)
        }
    }
    
    func jsonToString(json: AnyObject){
            do {
                let data1 =  try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted) // first of all convert json to the data
                let convertedString = String(data: data1, encoding: String.Encoding.utf8) // the data will be converted to the string
                print(convertedString) // <-- here is ur string

            } catch let myJSONError {
                print(myJSONError)
            }

        }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        Debug.log("webView didStartProvisionalNavigation")
        let urlString = webView.url?.absoluteString
        alignText()
        updateTextField(pretty: false)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let cookiesJson = getCookiesJson { [weak self] (json) in
            guard let `self`  = self else { return }
            self.setupBrowserObject(urlString: webView.url!.absoluteString, cookiesJsonString: json) { (error) in
                
                if error != nil {
                    decisionHandler(.cancel)
                    return
                }
                let onBefore = """
                    if (!browser) {debugger;}
                   browser.runtime.onInstalled.fire({reason:"install"});
                   browser.webRequest.onBeforeRequest.fire({url: "\(webView.url!.absoluteString)"});
                    if (typeof headerResults === "undefined") {
                        let headerResults = {};
                    }
                    
                """
                self.webView.evaluateJavaScript(onBefore) { (result, error) in
                    if let err = error {
                        print(err)
                    }
                    
                    self.webView.evaluateJavaScript("window.browser.webRequest.onBeforeSendHeaders.fire({requestHeaders: [], url: \"\(webView.url!.absoluteString)\"});") { (result, error) in
                        if let err = error {
                            print(err)
                            decisionHandler(.cancel)
                            return
                        }
                        if let res = result as? [[String:[[String:String]]]], res.count > 0,
                           let headers = res[0]["requestHeaders"], headers.count > 0  {
                            print(headers)
                            for header in headers {
                                if let name = header["name"] {
                                    if navigationAction.request.httpMethod != "GET" || navigationAction.request.value(forHTTPHeaderField: name) != nil {
                                                // not a GET or already a custom request - continue
                                                decisionHandler(.allow)
                                                return
                                            }
                                }
                                
                            }
                            
                            decisionHandler(.cancel)
                            self.requestWithHeaders(navigationAction: navigationAction, headers: headers)
                        } else if let res = result as? [[String: [String:AnyObject]]], res.count > 0,
                            let cancel = res[0]["cancel"] as? Bool {
                            
                            if cancel {
                                decisionHandler(.cancel)
                            } else {
                                decisionHandler(.allow)
                            }
                                
                        } else {
                            decisionHandler(.allow)
                        }
                        
                        
                    }
//                    self.webView.load(url)
//                    decisionHandler(.allow)
                }
                
            }
        }
    }
    
    func requestWithHeaders(navigationAction: WKNavigationAction, headers: [[String:String]]) {
        var req:URLRequest = navigationAction.request;
        for header in headers {
            if let key = header["name"], let value = header["value"] {
                req.addValue(value, forHTTPHeaderField: key);
            } else {
                print("should not be here")
            }
            
        }
        
        webView.load(req);
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        Debug.log("webView didCommit")
        let urlString = webView.url?.absoluteString
        // TEMP: Print warning workaround
        print(Query.getLoadable(urlString!))
        Query.updateURL(urlString!)
        
        alignText()
        updateTextField(pretty: true)
        resize(urlString!)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Debug.log("webView didFinish")
        let urlString = webView.url?.absoluteString
        
        alignText()
        updateTextField(pretty: true)
        
        let secureColor = UIColor(named: "Secure")
        //let insecureColor = UIColor(named: "Primary")
        let grayColor = UIColor(named: "Disabled")
        
        if urlString!.contains("https://") {
            secureButton.tintColor = secureColor
            //menuButton.tintColor = secureColor
        } else {
            secureButton.tintColor = grayColor
        }
        
        Settings.save(Live.fullURL, forKey: Keys.lastSessionURL)
        resize(urlString!)
        
        let didFinish = """
            if (!window.browser) { debugger; }
            console.log(window.browser);
            window.browser.webRequest.onCompleted.fire({url: "\(urlString!)"});
        """
      
        self.webView.evaluateJavaScript(didFinish) { (result, error) in
            if error != nil {
                print(error)
            }
        }
        
    }
    
    // TODO: Figure out how to resize WebView when facing sites like YouTube
    // The code below fixes the YouTube layout issue, but messes up every website that follows
    func resize(_ url: String) {
        topConstraint.constant = navBarHeight
        /*
        if Site.needsFullScreen(url) {
            topConstraint.constant = navBarHeight
            Debug.log("FullScreen URL: \(Live.fullURL), withHeight: \(navBarHeight)")
        } else {
            topConstraint.constant = 0
            Debug.log("New Constraint: \(topConstraint.constant)")
        }
        */
        
    }
    
    
    
    // MARK:- URL Did Change
    func urlDidChange(_ urlString: String) {
        let url = Clean.url(urlString)
        Debug.log("URL: \(url)")        // Debug: Print URL to Load
        resize(url)                     // Resize Layout for Specific Domains
    }
    
    
    
    
    // MARK:- Navigation Bar
    
    /// Prompts the CircleMenu handler to manage display
    @IBAction func showCircleMenu(_ sender: Any) {
        let hiddenMenu = circleMenuButton.isHidden
        if hiddenMenu { circleMenuButton.onTap() }
        showMenu(hiddenMenu, withAnimation: !hiddenMenu)
    }
    
    
    
    
    // MARK:- Menu Functions
    /// Load homepage in WebView
    func loadHomepage() {
        load(Settings.getHomepage())
    }
    /// Reload current WebView URL
    func refresh() {
        reload()
    }
    /// Add page to favourite
    func favouritePage() {
        Debug.log("Favourite Page")
        setCustomHome()
    }
    /// Segue Bookmarks ViewController
    func openBookmarks() {
        Debug.log("Open Bookmarks")
    }
    /// Open Action sheet
    func openAction() {
        Debug.log("Open Share Action")
        let items = [URL(string: Live.fullURL)!]
        let actionSheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(actionSheet, animated: true)
    }
    /// Segue Settings ViewController
    func openSettings() {
        print("Open Settings")
        let settingsVC = SettingsViewController()
        self.navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    
    
    
    // MARK:- Extended Functions
    func setCustomHome() {
        let home = Alerts.customHome
        let alert = UIAlertController(title: home.title, message: home.message, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { action in
            Settings.save(Live.fullURL, forKey: Keys.homepageString)
            Settings.save(false, forKey: Keys.restoreLastSession)
            Settings.restoreLiveSession = false
            self.doneCustomHomeAlert()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    func doneCustomHomeAlert() {
        let done = Alerts.setHome
        let alert = UIAlertController(title: done.title, message: done.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    
    
    
    // MARK:- TextField Handler
    
    func updateTextField(pretty: Bool) {
        Debug.log("Query.isSearchTerm: \(Query.isSearchTerm)")
        alignText() // TEMP: NEEDED?
        // Case: Search Term
        if Query.isSearchTerm {                     //if !Live.isURL {
            textField.text = Live.searchTerm
        // Case: Pretty URL
        } else if !Query.isSearchTerm && pretty {   //} else if Live.isURL && pretty {
            textField.text = Live.prettyURL
        // Case: Full URL
        } else {
            if (textField.text?.contains(Live.fullURL))! {
                textField.text = Live.prettyURL
            } else {
                textField.text = Live.fullURL
            }
        }
        Live.debug()
    }
    
    var firstLoad = true
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        alignText()
        // Case: First Load
        if firstLoad {
            textField.text = ""             // Empty TextField upon first selection
            firstLoad = false               // Set firstLoad to false
        } else {
            updateTextField(pretty: false)  // Set full URL or search query
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        alignText()
        textField.becomeFirstResponder()
        textField.selectAll(nil)
        textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let url = Query.getLoadable(textField.text!)
        updateTextField(pretty: false)   // TEMP: NEEDED?
        load(url.absoluteString)
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateTextField(pretty: false) // TEMP: NEEDED?
        hideKeyboard()
    }
    // TextField: Denies entry to non-ASCII characters (ie. emojis)
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if !string.canBeConverted(to: String.Encoding.ascii) { return false }
        return true
    }
    /// Aligns content of TextField based on search or URL
    func alignText() {
        if textField.isEditing {
            textField.textAlignment = .left
        /*
        } else if webView.isLoading && !Query.isSearchTerm {
            textField.textAlignment = .left
        */
        } else {
            textField.textAlignment = .center
        }
    }
    /// Manually hides keyboard
    func hideKeyboard() {
        textField.resignFirstResponder()
        //checkSecureAndUpdate()
    }
    
    
    
    
    // MARK:- Circle Menu
    
    // Option 1: Home,     Refresh,   Fav/Save & Share,   History & Bookmarks,   Actions,           Settings
    // Option 2: Home,     Refresh,   Fav/Save,           History & Bookmarks,   Share & Actions,   Settings *
    // Colors 1: Orange,   Blue,      Red,                Purple,                Green,             Gray
    // Colors 2: Purple,   Blue,      Red,                Orange,                Green,             Gray     *
    // ACTIONS: Different from ShareSheet; Actions will allow you to manipulate the content of the Web Browser (ie. view source code, request desktop site, JavaScript console with injection, etc.)
    // TODO: Find appropriate place to implement Print, possibly in Share or Actions
    
    //    let colors = [UIColor.redColor(), UIColor.grayColor(), UIColor.greenColor(), UIColor.purpleColor()]
    let items: [(icon: String, color: UIColor)] = [
        ("menu_home", UIColor(red: 0.49, green: 0.37, blue: 1.00, alpha: 1)),           // Home
        ("menu_refresh", UIColor(red: 0.00, green: 0.47, blue: 1.00, alpha: 1)),        // Refresh
        ("menu_share", UIColor(red: 0.03, green: 0.82, blue: 0.45, alpha: 1)),          // Share / Action
        ("menu_settings", UIColor(red: 0.47, green: 0.47, blue: 0.47, alpha: 1)),       // Settings
        ("menu_bookmarks", UIColor(red: 1.00, green: 0.62, blue: 0.10, alpha: 1)),      // Bookmarks
        ("menu_favourite", UIColor(red: 1.00, green: 0.22, blue: 0.22, alpha: 1))       // Favourite
    ]
    
    /**
     Toggle CircleMenu to hide or show, with optional animation
     - Parameters:
        - show: `Bool` value that specifies to show or hide the CircleMenu
        - withAnimation: `Bool` value that specifies if the CircleMenu collapsing should be animated
     
     The `withAnimation` value should only be set to `true` when using custom functions to close the CircleMenu
     */
    func showMenu(_ show: Bool, withAnimation: Bool) {
        if withAnimation { circleMenuButton.hideButtons(0.2) }
        circleMenuButton.isHidden = !show
    }
    
    
    // MARK: <CircleMenuDelegate>

    func circleMenu(_: CircleMenu, willDisplay button: UIButton, atIndex: Int) {
        button.backgroundColor = items[atIndex].color
        button.setImage(UIImage(named: items[atIndex].icon), for: .normal)
        // Set highlighted image
        let highlightedImage = UIImage(named: items[atIndex].icon)?.withRenderingMode(.alwaysTemplate)
        button.setImage(highlightedImage, for: .highlighted)
        button.tintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
    }

    func circleMenu(_: CircleMenu, buttonWillSelected _: UIButton, atIndex: Int) {
        Debug.log("Menu: button will selected: \(atIndex)")
        showMenu(false, withAnimation: false)
    }

    func circleMenu(_: CircleMenu, buttonDidSelected _: UIButton, atIndex: Int) {
        Debug.log("Menu: button did selected: \(atIndex)")
        showMenu(false, withAnimation: false)
        if atIndex == 0 { loadHomepage() }
        else if atIndex == 1 { refresh() }
        else if atIndex == 2 { openAction() }
        else if atIndex == 3 { openSettings() }
        else if atIndex == 4 { openBookmarks() }
        else if atIndex == 5 { favouritePage() }
        else { print("Menu option is out of range") }
    }
    
    func menuCollapsed(_ circleMenu: CircleMenu) {
        Debug.log("Menu: collapsed")
        showMenu(false, withAnimation: true)
    }
    
    
    
    
    // MARK:- TextField Width
    // Device did change orientation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        widenTextField()
        if Device.isPortrait() {
            Debug.log("New Orientation: Portrait")
        } else {
            Debug.log("New Orientation: Landscape")
        }
        
        if UIDevice.current.orientation.isLandscape { Debug.log("New Orientation: Landscape") }
        else { Debug.log("New Orientation: Portrait") }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
            self.resize(Live.fullURL)
        }
    }
    
    /// Resizes `UITextField` in `UINavigationBar` to maximum possible width (called on device rotation)
    func widenTextField() {
        var frame: CGRect? = textField?.frame
        frame?.size.width = 10000
        textField?.frame = frame!
    }
    
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    

}


extension UIViewController {

    /**
     *  Height of status bar + navigation bar (if navigation bar exist)
     */
    var navBarHeight: CGFloat {
        return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
            (self.navigationController?.navigationBar.frame.height ?? 0.0)
    }
}

extension ViewController: WKScriptMessageHandler{
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String : AnyObject] else {
            return
        }
        
        switch message.name {
        case "executeScriptMessageHandler":
            if let obj = dict["message"] as? String {
                if let script = obj.toJSON() as? [String: AnyObject] {
                    if let name  = script["file"] as? String {
                        let splitted = name.split(separator: ".")
                        let src = getScript(name: String(splitted[0]) as String, type: String(splitted[1]) as String)
                        self.webView.evaluateJavaScript(src) { (result, error) in
                            if error != nil {
                                print(String(splitted[0]))
                                print(error)
                            }
                        }
                    }
                }
                
            }
            
        case "removeCookieMessageHandler":
            if let obj = dict["message"] as? String {
                
                
            }
            
        case "updateHeadersMessageHandler":
            if let obj = dict["message"] as? String {
                if let headers = obj.toJSON() as? [[String: AnyObject]] {
                    print(headers)
                }
            }
        default:
            break
            
        }

        print("in handler:\(message.name)")
    }
}

extension String {
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}

