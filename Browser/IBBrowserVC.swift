//
//  IBBrowserVC.swift
//  Browser
//
//  Created by Illya Bakurov on 12/23/15.
//  Copyright © 2015 IB. All rights reserved.
//

import UIKit
import WebKit

class IBBrowserVC: UIViewController, UITextFieldDelegate, WKNavigationDelegate {

    enum Process {
        case EnteringURL
        case SurfingWebView
    }
    
    @IBOutlet var viewForWebView: UIView!
    var webView: WKWebView
    @IBOutlet var URLField: UITextField! {
        didSet {
            URLField.delegate = self
        }
    }
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var titleLabel: UILabel!
    var process : Process = .EnteringURL
    
    //MARK: - Initialization
    
    required init?(coder aDecoder: NSCoder) {
        self.webView = WKWebView(frame: CGRect.zero)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Adding observers
            //Once we are loading some page, we may want to make back and forward button enabled
        webView.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
            //We want to follow progress of loading to show that to user
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
            //Get title of the page
        webView.addObserver(self, forKeyPath: "title", options: .New, context: nil)
        
        webView.navigationDelegate = self
        
        //Default page to load
        if let url = NSURL(string:"http://www.apple.com") {
            let request = NSURLRequest(URL:url)
            webView.loadRequest(request)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        //Removing observers
        webView.removeObserver(self, forKeyPath: "loading")
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        webView.removeObserver(self, forKeyPath: "title")
    }
    
    override func viewDidLayoutSubviews() {
        //Once views did layouts, I add the WKWebView to proper view  with proper view sizes
        webView.frame = viewForWebView.frame
        webView.frame.origin = CGPoint.zero
        viewForWebView?.addSubview(webView)
    }
    
    //Status bar change to the white Style
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    //MARK: - UITextField Delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        URLField.resignFirstResponder()
        if var text = textField.text {
            
            //Checking for http:// prefix an if it doesn't have it then add it
            text = handleHttpPrefix(text)
            
            if let url = NSURL(string: text) {
                webView.loadRequest(NSURLRequest(URL: url))
                URLField.text = text
            }
        }
        return false
    }
    
    //Check and add if neede http:// prefix
    func handleHttpPrefix(var text: String) -> String {
        let prefixes = ["http://", "https://", "http://www.", "https://www.", "www."]
        for prefix in prefixes
        {
            if ((prefix.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) == nil) {
                text = String(format: "http://%@", text)
                break
            }
        }
        return text
    }
    
    //MARK: - Observer
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (keyPath == "loading") {
            backButton.enabled = webView.canGoBack
            forwardButton.enabled = webView.canGoForward
        } else if (keyPath == "estimatedProgress") {
            progressView.hidden = webView.estimatedProgress == 1
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
        } else if (keyPath == "title") {
            if process == .SurfingWebView {
                titleLabel.hidden = false
                titleLabel.text = webView.title
                URLField.hidden = true
            }
        }
    }
    
    //MARK: - Toolbar
    
    //MARK: Toolbar Properties
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    @IBOutlet var reloadButton: UIBarButtonItem!
    
    //MARK: Toolbar Methods
    
    @IBAction func goBack(sender: UIBarButtonItem) {
        webView.goBack()
    }
    
    @IBAction func goForward(sender: UIBarButtonItem) {
        webView.goForward()
    }
    
    @IBAction func reload(sender: UIBarButtonItem) {
        if let url = webView.URL {
            let request = NSURLRequest(URL: url)
            webView.loadRequest(request)
        }
    }
    
    //MARK: - WebKit Navigation Delegate 
        
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        progressView.setProgress(0.0, animated: false)
        if process == .EnteringURL {
            titleLabel.hidden = false
            titleLabel.text = webView.title
            URLField.hidden = true
            process = .SurfingWebView
        }
    }
    
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        URLField.text = webView.URL?.host
    }
    
    //MARK: - Tap Gesture On Navigation View
    
    @IBAction func navigationViewTapped(sender: UITapGestureRecognizer) {
        if (process == .SurfingWebView) {
            titleLabel.hidden = true
            URLField.hidden = false
            URLField.becomeFirstResponder()
            process = .EnteringURL
        } else if (process == .EnteringURL) {
            titleLabel.hidden = false
            URLField.hidden = true
            process = .SurfingWebView
        }
    }
}
