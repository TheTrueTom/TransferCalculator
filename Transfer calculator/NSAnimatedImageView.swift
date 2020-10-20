//
//  NSAnimatedImageView.swift
//  Transfer calculator
//
//  Created by Thomas Brichart on 16/02/2016.
//  Copyright © 2016 Thomas Brichart. All rights reserved.
//

import Foundation
import Cocoa

class NSAnimatedImageView: NSImageView {
    var timer: Timer = Timer()
    var interval: TimeInterval = 0.1
    var imagesArray: [String] = []
    var currentIndex: Int = 0
    
    init(imageList: [String]) {
        super.init(frame: NSRect(x: 0, y: 0, width: 25, height: 25))
        
        imagesArray = imageList
        
        
        if !imagesArray.isEmpty {
            self.image = NSImage(named: imagesArray[0])
        }
        
        if imagesArray.count > 1 {
            timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(NSAnimatedImageView.changeImage), userInfo: nil, repeats: true)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @objc func changeImage() {
        currentIndex += 1
        
        if currentIndex >= imagesArray.count {
            currentIndex = 0
        }
        
        self.image = NSImage(named: imagesArray[currentIndex])
        self.needsDisplay = true
    }
}
