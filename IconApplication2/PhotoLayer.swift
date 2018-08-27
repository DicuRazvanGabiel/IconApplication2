//
//  PhotoLayer.swift
//  IconApplication2
//
//  Created by razvan on 8/25/18.
//  Copyright © 2018 razvan. All rights reserved.
//

import Cocoa

class PhotoLayer: NSCollectionViewItem {

    @IBOutlet var image: NSImageView!
    @IBOutlet var label: NSTextField!
    var viewController: ViewController?
    var idURL: String?
    
    let selectedBorderThickness: CGFloat = 3;
    
    override var isSelected: Bool{
        didSet{
            if isSelected{
                view.layer?.borderWidth = selectedBorderThickness
                view.shadow = setShadow()
                viewController?.setSelectedImage(selectImage: self)
                
            }else{
                view.layer?.borderWidth = 0
                view.shadow = NSShadow()
            }
        }
    }
    
    override var highlightState: NSCollectionViewItem.HighlightState{
        didSet{
            if highlightState == .forSelection{
                view.layer?.borderWidth = selectedBorderThickness
                view.shadow = setShadow()
            }else{
                if !isSelected{
                    view.layer?.borderWidth = 0
                    view.shadow = NSShadow()
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.borderColor = NSColor.black.cgColor
        view.layer?.cornerRadius = 5
    }
    
    func setViewController(controller: ViewController){
        viewController = controller
    }
    
    func setShadow(offset: Float = 0, color: NSColor = NSColor.blue, blur: Float = 5) -> NSShadow{
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: CGFloat(offset), height: CGFloat(offset))
        shadow.shadowColor = color
        shadow.shadowBlurRadius = CGFloat(blur)
        
        shadow.set()
        return shadow
    }
}
