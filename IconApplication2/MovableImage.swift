//
//  MovableImage.swift
//  IconApplication2
//
//  Created by razvan on 8/25/18.
//  Copyright © 2018 razvan. All rights reserved.
//

import Cocoa

class MovableImage: NSImageView {
    
    var firstMouseDownPoint: NSPoint = NSZeroPoint
    var idImage: Int?
    var urlImage: URL?
    
    init() {
        super.init(frame: NSZeroRect)
        self.wantsLayer = true
        //self.layer?.backgroundColor = NSColor.red.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
    
    override func mouseDown(with event: NSEvent) {
        firstMouseDownPoint = (self.window?.contentView?.convert(event.locationInWindow, to: self))!
    }
    
    override func mouseDragged(with event: NSEvent) {
        let newPoint = (self.window?.contentView?.convert(event.locationInWindow, to: self))!
        let offset = NSPoint(x: newPoint.x - firstMouseDownPoint.x, y: newPoint.y - firstMouseDownPoint.y)
        let origin = self.frame.origin
        let size = self.frame.size
        self.frame = NSRect(x: origin.x + offset.x, y: origin.y + offset.y, width: size.width, height: size.height)
    }
}
