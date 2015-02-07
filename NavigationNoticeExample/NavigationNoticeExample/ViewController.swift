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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let content1 = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 20))
        content1.backgroundColor = UIColor.redColor()
        NavigationNotice.addContent(content1).hide(1).showOn(self.view)
        
        let content2 = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 64))
        content2.backgroundColor = UIColor.blueColor()
        NavigationNotice.statusBarHidden(false).addContent(content2).showOn(self.view).hide(0)
        
        NavigationNotice.defaultStatusBarHidden = false
        
        let content3 = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 100))
        content3.backgroundColor = UIColor.redColor()
        NavigationNotice.addContent(content3).showOn(self.view)
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(4.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            NavigationNotice.currentNotice()?.hide(2)
            return
        })
    }
}
