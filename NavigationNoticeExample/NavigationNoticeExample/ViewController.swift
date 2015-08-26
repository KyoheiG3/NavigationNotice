//
//  ViewController.swift
//  NavigationNoticeExample
//
//  Created by Kyohei Ito on 2015/02/08.
//  Copyright (c) 2015年 kyohei_ito. All rights reserved.
//

import UIKit
import NavigationNotice

class ViewController: UIViewController {
    var tableSourceList: [[String]] = [[Int](0..<20).map({ "section 0, cell \($0)" })]

    private func contentView(text: String) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 64))
        view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        let label = UILabel(frame: view.bounds)
        label.frame.origin.x = 10
        label.frame.origin.y = 10
        label.frame.size.width -= label.frame.origin.x
        label.frame.size.height -= label.frame.origin.y
        
        label.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        label.text = text
        label.numberOfLines = 2
        label.textColor = UIColor.whiteColor()
        view.addSubview(label)
        
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Notification"
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            let content1 = self.contentView("Interactive Notification.\nYour original contents.")
            content1.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.9)
            
            NavigationNotice.statusBarHidden(false).addContent(content1).showOn(self.view).showAnimations { animations, completion in
                UIView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.1, options: .BeginFromCurrentState, animations: animations, completion: completion)
            } .hideAnimations { animations, completion in
                UIView.animateWithDuration(0.8, animations: animations, completion: completion)
            }
            
            NavigationNotice.defaultShowAnimations = { animations, completion in
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .BeginFromCurrentState, animations: animations, completion: completion)
            }
            
            NavigationNotice.defaultHideAnimations = { animations, completion in
                UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .BeginFromCurrentState, animations: animations, completion: completion)
            }
            
            let content2 = self.contentView("Timer Notification.\nCustomize your animation.")
            content2.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.9)
            
            NavigationNotice.addContent(content2).showOn(self.view).hide(2)
        }
    }
    
    @IBAction func showButtonWasTapped(sender: UIButton) {
        let content = self.contentView("Create your content.")
        content.frame.size.height = 50
        content.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.9)
        NavigationNotice.addContent(content).showOn(self.view).hide(5)
    }
    
    @IBAction func hideBUttonWasTapped(sender: UIButton) {
        NavigationNotice.currentNotice()?.hide(0)
    }
}
