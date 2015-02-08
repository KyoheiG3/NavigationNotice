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
            return (noticeView.gestureRecognizers as? [UIGestureRecognizer])?.filter({ $0 as? UIPanGestureRecognizer != nil }).first as? UIPanGestureRecognizer
        }
        private var noticeView: HitScrollView!
        private weak var targetView: UIView?
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
        
        var hideCompletionHandler: (() -> Void)?
        
        override func loadView() {
            super.loadView()
            view = HitView(frame: view.bounds)
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            panGesture.delegate = self
            
            noticeView = HitScrollView(frame: view.bounds)
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
                
                if let view = panGesture.view {
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
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * Double(NSEC_PER_SEC)))
            
            dispatch_after(time, dispatch_get_main_queue()) {
                self.hiddenTimeInterval = 0
                
                if self.autoHidden == true {
                    if self.panGesture.state != .Changed && self.scrollPanGesture?.state != .Some(.Changed) {
                        self.hide(true)
                    }
                }
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
                    }) { _ in
                        self.removeContent()
                        self.hideCompletionHandler?()
                }
            } else {
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
            
            var locationOffsetY = gesture.locationInView(view).y
            
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
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .BeginFromCurrentState, animations: animations, completion: completion)
        }
        
        func hideContent(animations: () -> Void, completion: (Bool) -> Void) {
            UIView.animateWithDuration(0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .BeginFromCurrentState, animations: animations, completion: completion)
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
        private var statusBarHidden: Bool = true
        
        private func startNotice(notice: NavigationNotice) {
            showingNotice = notice
            
            noticeWindow?.rootViewController = notice.noticeViewController
            noticeWindow?.windowLevel = UIWindowLevelStatusBar + (notice.statusBarHidden ? 1 : -1)
            
            if let view = notice.noticeViewController.targetView {
                mainWindow = view.window
                
                notice.noticeViewController.showOn(view)
            }
        }
        
        private func endNotice() {
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
            if let notice = contents.first {
                return contents.removeAtIndex(0)
            }
            return nil
        }
        
        func removeAll() {
            contents.removeAll()
        }
    }
    
    private class func sharedManager() -> NoticeManager {
        struct Singleton {
            static var notice = NoticeManager()
        }
        return Singleton.notice
    }
    
    public class func currentNotice() -> NavigationNotice? {
        return sharedManager().showingNotice
    }
    
    public class func addContent(view: UIView) -> NavigationNotice {
        let notice = NavigationNotice()
        notice.noticeViewController.setContent(view)
        
        return notice
    }
    
    public class func statusBarHidden(hidden: Bool) -> NavigationNotice {
        let notice = NavigationNotice()
        notice.statusBarHidden =  hidden
        
        return notice
    }
    
    private var noticeViewController = ViewController()
    private var statusBarHidden: Bool = NavigationNotice.defaultStatusBarHidden
    public class var defaultStatusBarHidden: Bool {
        set { sharedManager().statusBarHidden = newValue }
        get { return sharedManager().statusBarHidden }
    }
    
    private init() {}
    
    public func addContent(view: UIView) -> Self {
        noticeViewController.setContent(view)
        
        if noticeViewController.targetView != nil {
            self.dynamicType.sharedManager().add(self)
        }
        
        return self
    }
    
    public func showOn(view: UIView) -> Self {
        noticeViewController.targetView = view
        noticeViewController.hideCompletionHandler = {
            self.dynamicType.sharedManager().next()
        }
        
        if noticeViewController.contentView != nil {
            self.dynamicType.sharedManager().add(self)
        }
        
        return self
    }
    
    public func hide(interval: NSTimeInterval) -> Self {
        noticeViewController.setInterval(interval)
        
        return self
    }
    
    public func removeAll(hidden: Bool) -> Self {
        let notice = self.dynamicType.sharedManager()
        notice.removeAll()
        
        if hidden {
            notice.showingNotice?.hide(0)
        }
        
        return self
    }
}
