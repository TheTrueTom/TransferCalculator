//
//  ParticleView.swift
//  Transfer calculator
//
//  Created by Thomas Brichart on 09/01/2016.
//  Copyright © 2016 Thomas Brichart. All rights reserved.
//

import Foundation
import Cocoa

class ParticleView: NSView {
    
    var donorColor: NSColor = NSColor.blue {
        didSet {
            self.needsDisplay = true
        }
    }
    
    var acceptorColor: NSColor = NSColor.red {
        didSet {
            self.needsDisplay = true
        }
    }
    
    var particule: Particule? {
        didSet {
            self.needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        // Body of the particle
        NSColor.white.set()
        NSBezierPath(ovalIn: self.bounds).fill()
        
        // Outer rim of the particle
        NSColor.gray.set()
        NSBezierPath(ovalIn: self.bounds).stroke()
        
        if let particule = self.particule {
            for (index, molecule) in particule.moleculesList {
                if index < 0 {
                    acceptorColor.set()
                } else {
                    donorColor.set()
                }
                
                let x = CGFloat(molecule.x / particule.radius / 2) * self.bounds.size.width + self.bounds.size.width / 2 - 1
                let y = CGFloat(molecule.y / particule.radius / 2) * self.bounds.size.height + self.bounds.size.height / 2 - 1
                NSBezierPath(rect: NSRect(x: x, y: y, width: 2, height: 2)).fill()
            }
        }
    }
}
