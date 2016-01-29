//
//  NavigationNotice.swift
//  NavigationNotice
//
//  Created by Kyohei Ito on 2015/02/06.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit

public class NavigationNotice {
    class ViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        class HitView: UIView {
            override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
                if let superView = super.hitTest(point, withEvent: event) {
                    if superView != self {
                        return superView
                    }
                }
                return nil
            }
        }
        
        class HitScrollView: UIScrollView {
            override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
                if let superView = super.hitTest(point, withEvent: event) {
                    if superView != self {
                        return superView
                    }
                }
                return nil
            }
        }
        
        private lazy var panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: "panGestureAction:")
        private var scrollPanGesture: UIPanGestureRecognizer? {
            return noticeView.gestureRecognizers?.filter({ $0 as? UIPanGestureRecognizer != nil }).first as? UIPanGestureRecognizer
        }
        private lazy var noticeView: HitScrollView = HitScrollView(frame: self.view.bounds)
        private weak var targetView: UIView? {
            didSet { targerWindow = targetView?.window }
        }
        private weak var targerWindow: UIWindow?
        private var targetController: UIViewController? {
            return targerWindow?.rootViewController
        }
        private var childController: UIViewController? {
            return targetController?.presentedViewController ?? targetController
        }
        private var contentView: UIView?
        private var autoHidden: Bool = false
        private var hiddenTimeInterval: NSTimeInterval = 0
        private var contentHeight: CGFloat {
            return noticeView.bounds.height
        }
        private var contentOffsetY: CGFloat {
            set { noticeView.contentOffset.y = newValue }
            get { return noticeView.contentOffset.y }
        }
        private var hiddenTimer: NSTimer? {
            didSet {
                oldValue?.invalidate()
            }
        }
        
        var showAnimations: ((() -> Void, (Bool) -> Void) -> Void)?
        var hideAnimations: ((() -> Void, (Bool) -> Void) -> Void)?
        var hideCompletionHandler: (() -> Void)?
        
        override func shouldAutorotate() -> Bool {
            return childController?.shouldAutorotate()
                ?? super.shouldAutorotate()
        }
        
        override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
            return childController?.supportedInterfaceOrientations()
                ?? super.supportedInterfaceOrientations()
        }
        
        override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
            return childController?.preferredInterfaceOrientationForPresentation()
                ?? super.preferredInterfaceOrientationForPresentation()
        }
        
        override func childViewControllerForStatusBarStyle() -> UIViewController? {
            return childController
        }
        
        override func childViewControllerForStatusBarHidden() -> UIViewController? {
            return childController
        }
        
        override func loadView() {
            super.loadView()
            view = HitView(frame: view.bounds)
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            panGesture.delegate = self
            
            noticeView.clipsToBounds = false
            noticeView.showsVerticalScrollIndicator = false
            noticeView.pagingEnabled = true
            noticeView.bounces = false
            noticeView.delegate = self
            noticeView.autoresizingMask = .FlexibleWidth
            view.addSubview(noticeView)
        }
        
        func setInterval(interval: NSTimeInterval) {
            hiddenTimeInterval = interval
            
            if interval >= 0 {
                autoHidden = true
                
                if panGesture.view != nil {
                    timer(interval)
                }
            } else {
                autoHidden = false
            }
        }
        
        func setContent(view: UIView) {
            contentView = view
        }
        
        func removeContent() {
            contentView?.removeFromSuperview()
            contentView = nil
        }
        
        func timer(interval: NSTimeInterval) {
            let handler: (CFRunLoopTimer?) -> Void = { [weak self] timer in
                self?.hiddenTimer = nil
                self?.hiddenTimeInterval = 0
                
                if self?.autoHidden == true {
                    if self?.panGesture.state != .Changed && self?.scrollPanGesture?.state != .Some(.Changed) {
                        self?.hide(true)
                    }
                }
            }
            
            if interval > 0 {
                let fireDate = interval + CFAbsoluteTimeGetCurrent()
                let timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, fireDate, 0, 0, 0, handler)
                CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, kCFRunLoopCommonModes)
                hiddenTimer = timer
            } else {
                handler(nil)
            }
        }
        
        func showOn(view: UIView) {
            targetView = view
            
            if let view = contentView {
                noticeView.frame.size.height = view.frame.height
                view.frame.size.width = noticeView.bounds.width
                view.frame.origin.y = -contentHeight
                view.autoresizingMask = .FlexibleWidth
                noticeView.addSubview(view)
                view.setNeedsDisplay()
            }
            
            noticeView.contentSize = noticeView.bounds.size
            noticeView.contentInset.top = contentHeight
            
            show() {
                self.targetView?.addGestureRecognizer(self.panGesture)
                
                if self.autoHidden == true {
                    self.timer(self.hiddenTimeInterval)
                }
            }
        }
        
        func show(completion: () -> Void) {
            showContent({
                self.contentOffsetY = -self.contentHeight
                self.setNeedsStatusBarAppearanceUpdate()
                }) { _ in
                    completion()
            }
        }
        
        func hide(animated: Bool) {
            targetView?.removeGestureRecognizer(panGesture)
            hiddenTimeInterval = 0
            autoHidden = false
            
            if animated == true {
                hideContent({
                    self.contentOffsetY = 0
                    self.setNeedsStatusBarAppearanceUpdate()
                    }) { _ in
                        self.removeContent()
                        self.hideCompletionHandler?()
                }
            } else {
                self.setNeedsStatusBarAppearanceUpdate()
                removeContent()
                hideCompletionHandler?()
            }
        }
        
        func hideIfNeeded(animated: Bool) {
            if autoHidden == true && hiddenTimeInterval <= 0 {
                hide(animated)
            }
        }
        
        func panGestureAction(gesture: UIPanGestureRecognizer) {
            if contentOffsetY >= 0 {
                hide(false)
                return
            }
            
            let locationOffsetY = gesture.locationInView(view).y
            
            if gesture.state == .Changed {
                if contentHeight > locationOffsetY {
                    contentOffsetY = -locationOffsetY
                } else {
                    contentOffsetY = -contentHeight
                }
            } else if gesture.state == .Cancelled || gesture.state == .Ended {
                if contentHeight < locationOffsetY {
                    contentOffsetY = -contentHeight
                    
                    hideIfNeeded(true)
                    return
                }
                
                if gesture.velocityInView(view).y > 0 {
                    show() {
                        self.hideIfNeeded(true)
                    }
                } else {
                    hide(true)
                }
            }
        }
        
        func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
            if contentOffsetY >= 0 {
                hide(false)
            } else {
                hideIfNeeded(true)
            }
        }
        
        func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return gestureRecognizer == panGesture || otherGestureRecognizer == panGesture
        }
        
        func showContent(animations: () -> Void, completion: (Bool) -> Void) {
            if let show = showAnimations {
                show(animations, completion)
            } else {
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .BeginFromCurrentState, animations: animations, completion: completion)
            }
        }
        
        func hideContent(animations: () -> Void, completion: (Bool) -> Void) {
            if let hide = hideAnimations {
                hide(animations, completion)
            } else {
                UIView.animateWithDuration(0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .BeginFromCurrentState, animations: animations, completion: completion)
            }
        }
    }

    private class NoticeManager {
        class HitWindow: UIWindow {
            override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
                if let superWindow = super.hitTest(point, withEvent: event) {
                    if superWindow != self {
                        return superWindow
                    }
                }
                return nil
            }
        }
        
        private weak var mainWindow: UIWindow?
        private var noticeWindow: HitWindow?
        private var contents: [NavigationNotice] = []
        private var showingNotice: NavigationNotice?
        private var onStatusBar: Bool = true
        private var showAnimations: ((() -> Void, (Bool) -> Void) -> Void)?
        private var hideAnimations: ((() -> Void, (Bool) -> Void) -> Void)?
        
        private func startNotice(notice: NavigationNotice) {
            showingNotice = notice
            
            noticeWindow?.rootViewController = notice.noticeViewController
            noticeWindow?.windowLevel = UIWindowLevelStatusBar + (notice.onStatusBar ? 1 : -1)
            
            if let view = notice.noticeViewController.targetView {
                mainWindow = view.window
                
                notice.noticeViewController.showOn(view)
            }
        }
        
        private func endNotice() {
            showingNotice?.noticeViewController.setNeedsStatusBarAppearanceUpdate()
            showingNotice = nil
            
            mainWindow?.makeKeyAndVisible()
            noticeWindow = nil
        }
        
        func next() {
            if let notice = pop() {
                startNotice(notice)
            } else {
                endNotice()
            }
        }
        
        func add(notice: NavigationNotice) {
            contents.append(notice)
            
            dispatch_async(dispatch_get_main_queue()) {
                if self.showingNotice == nil {
                    self.noticeWindow = HitWindow(frame: UIScreen.mainScreen().bounds)
                    self.noticeWindow?.makeKeyAndVisible()
                    
                    self.next()
                }
            }
        }
        
        func pop() -> NavigationNotice? {
            if contents.count >= 1 {
                return contents.removeAtIndex(0)
            }
            return nil
        }
        
        func removeAll() {
            contents.removeAll()
        }
    }
    
    private var noticeViewController = ViewController()
    private var onStatusBar: Bool = NavigationNotice.defaultOnStatusBar
    private var completionHandler: (() -> Void)?
    /// Common navigation bar on the status bar. Default is `true`.
    public class var defaultOnStatusBar: Bool {
        set { sharedManager.onStatusBar = newValue }
        get { return sharedManager.onStatusBar }
    }
    private var showAnimations: ((() -> Void, (Bool) -> Void) -> Void)? = NavigationNotice.defaultShowAnimations
    /// Common animated block of show. Default is `nil`.
    public class var defaultShowAnimations: ((() -> Void, (Bool) -> Void) -> Void)? {
        set { sharedManager.showAnimations = newValue }
        get { return sharedManager.showAnimations }
    }
    private var hideAnimations: ((() -> Void, (Bool) -> Void) -> Void)? = NavigationNotice.defaultHideAnimations
    /// Common animated block of hide. Default is `nil`.
    public class var defaultHideAnimations: ((() -> Void, (Bool) -> Void) -> Void)? {
        set { sharedManager.hideAnimations = newValue }
        get { return sharedManager.hideAnimations }
    }
    
    private static let sharedManager = NoticeManager()
    
    /// Notification currently displayed.
    public class func currentNotice() -> NavigationNotice? {
        return sharedManager.showingNotice
    }
    
    /// Add content to display.
    public class func addContent(view: UIView) -> NavigationNotice {
        let notice = NavigationNotice()
        notice.noticeViewController.setContent(view)
        
        return notice
    }
    
    /// Set on the status bar of notification.
    public class func onStatusBar(on: Bool) -> NavigationNotice {
        let notice = NavigationNotice()
        notice.onStatusBar = on
        
        return notice
    }
    
    private init() {}
    
    /// Add content to display.
    public func addContent(view: UIView) -> Self {
        noticeViewController.setContent(view)
        
        if noticeViewController.targetView != nil {
            NavigationNotice.sharedManager.add(self)
        }
        
        return self
    }
    
    /// Show notification on view.
    public func showOn(view: UIView) -> Self {
        noticeViewController.showAnimations = showAnimations
        noticeViewController.hideAnimations = hideAnimations
        noticeViewController.targetView = view
        noticeViewController.hideCompletionHandler = { [weak self] in
            self?.completionHandler?()
            self?.completionHandler = nil
            NavigationNotice.sharedManager.next()
        }
        
        if noticeViewController.contentView != nil {
            NavigationNotice.sharedManager.add(self)
        }
        
        return self
    }
    
    /// Animated block of show.
    public func showAnimations(animations: (() -> Void, (Bool) -> Void) -> Void) -> Self {
        noticeViewController.showAnimations = animations
        
        return self
    }
    
    /// Hide notification.
    public func hide(interval: NSTimeInterval) -> Self {
        noticeViewController.setInterval(interval)
        
        return self
    }
    
    /// Animated block of hide.
    public func hideAnimations(animations: (() -> Void, (Bool) -> Void) -> Void) -> Self {
        noticeViewController.hideAnimations = animations
        
        return self
    }
    
    public func completion(completion: (() -> Void)?) {
        completionHandler = completion
    }
    
    /// Remove all notification.
    public func removeAll(hidden: Bool) -> Self {
        let notice = NavigationNotice.sharedManager
        notice.removeAll()
        
        if hidden {
            notice.showingNotice?.hide(0)
        }
        
        return self
    }
}
