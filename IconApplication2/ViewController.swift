//
//  ViewController.swift
//  IconApplication2
//
//  Created by razvan on 8/25/18.
//  Copyright © 2018 razvan. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {

    
    @IBOutlet var collectionView: NSCollectionView!
    
    @IBOutlet var imangesContainer: NSImageView!
    
    var itemsBeingDragged : Set<IndexPath>?
    var photos = [URL]()
    
    lazy var photosDirectory: URL = {
        let fm = FileManager.default
        let paths = fm.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let saveDirectory = documentsDirectory.appendingPathComponent("IconApp")
        
        if !fm.fileExists(atPath: saveDirectory.path) {
            try? fm.createDirectory(at: saveDirectory, withIntermediateDirectories: true)
        }
        return saveDirectory
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: kUTTypeURL as String as String)])
        do{
            let fm = FileManager.default
            let files = try fm.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: nil)
            
            for file in files{
                if file.pathExtension == "jpeg" || file.pathExtension == "png"{
                    photos.append(file)
                }
            }
        } catch {
            print("Set up error")
        }
        renderImagesToPreview()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PhotoLayer"), for: indexPath)
        guard let pictureItem = item as? PhotoLayer else {return item}
        
        let image = NSImage(contentsOf: photos[indexPath.item])
        pictureItem.imageView?.image = image
        
        //pictureItem.view.layer?.backgroundColor = NSColor.red.cgColor
        pictureItem.setViewController(controller: self)
        return pictureItem
    }

    func printHello(){
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
        
        return .move
    }
    
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
        
        itemsBeingDragged = indexPaths
    }
    
    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {
        
        itemsBeingDragged = nil
    }
    
    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
        
        if let moveItems = itemsBeingDragged?.sorted() {
            
            //this is an internal drag
            performInternalDrag(with: moveItems, to: indexPath)
            
        } else {
            
            //this is an external drag
            let pasteboard = draggingInfo.draggingPasteboard()
            guard let items = pasteboard.pasteboardItems else { return true }
            
            performExternalDrag(with: items, at: indexPath)
        }
        
        return true
    }
    
    func performInternalDrag(with items: [IndexPath], to indexPath: IndexPath) {
        
        //keep track of where we're moving to
        var targetIndex = indexPath.item
        
        for fromIndexPath in items {
            
            //figure out where we're moving from
            let fromItemIndex = fromIndexPath.item
            
            //this is a move towards the front of the array
            if (fromItemIndex > targetIndex) {
                
                //call our array extension to perform the move
                photos.moveItem(from: fromItemIndex, to: targetIndex)
                
                //move it in the collection view too
                collectionView.moveItem(at: IndexPath(item: fromItemIndex, section: 0), to: IndexPath(item: targetIndex, section: 0))
                
                //update our destination position
                targetIndex += 1
            }
        }
        //reset the target position - we want to move to the slot before the item the user chose
        targetIndex = indexPath.item - 1
        
        //loop backwards over our items
//        for fromIndexPath in items.reversed() {
//            let fromItemIndex = fromIndexPath.item
//            
//            //this is a move towards the back of the array
//            if (fromItemIndex < targetIndex) {
//                
//                //call our array extension to perform the move
//                photos.moveItem(from: fromItemIndex, to: targetIndex)
//                
//                //move it in the collection view too
//                let targetIndexPath = IndexPath(item: targetIndex, section: 0)
//                collectionView.moveItem(at: IndexPath(item: fromItemIndex, section: 0), to: targetIndexPath)
//                
//                //update our destination position
//                targetIndex -= 1
//            }
//        }
        renderImagesToPreview()
    }
    
    func performExternalDrag(with items: [NSPasteboardItem], at indexPath: IndexPath) {
        let fm = FileManager.default
        
        //1 - loop over every item on the drag and drop pasteboard
        for item in items {
            
            //2 - pull out the string containing the URL for this item
            guard let stringURL = item.string(forType: NSPasteboard.PasteboardType(rawValue: kUTTypeFileURL as String as String)) else { continue }
            
            //3 - attempt to convert the string into a real URL
            guard let sourceURL = URL(string: stringURL) else { continue }
            
            //4 - create a destination URL by combining photosDirectory with the last path component
            let destinationURL = photosDirectory.appendingPathComponent(sourceURL.lastPathComponent)
            
            do {
                //5 - attempt to copy the file to our app's folder
                try fm.copyItem(at: sourceURL, to: destinationURL)
                
            } catch {
                
                print("Could not copy \(sourceURL)")
            }
            
            //6 - update the array and collection view
            photos.insert(destinationURL, at: indexPath.item)
            collectionView.insertItems(at: [indexPath])
        }
        renderImagesToPreview()
    }
    
    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        
        return photos[indexPath.item] as NSPasteboardWriting?
    }
    
    override func keyUp(with event: NSEvent) {
        
        //bail out if we dont have any selected items
        guard collectionView.selectionIndexPaths.count > 0 else { return }
        
        //convert the integer to a Unicode scalar, then to a string
        if event.charactersIgnoringModifiers == String(UnicodeScalar(NSDeleteCharacter)!) {
            
            let fm = FileManager.default
            
            //loop over the selected items in reverse sorted order
            for indexPath in collectionView.selectionIndexPaths.sorted().reversed() {
                
                do {
                    //move this item to the trash and remove it from the array
                    try fm.trashItem(at: photos[indexPath.item], resultingItemURL: nil)
                    photos.remove(at: indexPath.item)
                    
                } catch {
                    print("Failed to delete |(photos[indexPath.item])")
                }
            }
            //remove the items from the collection view
            collectionView.animator().deleteItems(at: collectionView.selectionIndexPaths)
        }
        renderImagesToPreview()
    }
    
    func renderImagesToPreview(){
        for view in imangesContainer.subviews {
            view.removeFromSuperview()
        }
        var indexOfXY = 1
        for url in (0..<photos.count).reversed()  {
            let movableImageToAdd = MovableImage()
            let imageImported = NSImage(byReferencing: photos[url])
            movableImageToAdd.frame = NSRect(x:indexOfXY * 10, y:indexOfXY * 10, width: 1, height: 1)
            if imageImported.size.width > imangesContainer.frame.width {
                movableImageToAdd.frame.size = imangesContainer.frame.size
            } else {
                movableImageToAdd.frame.size = imageImported.size
            }
            movableImageToAdd.image = imageImported
            imangesContainer.addSubview(movableImageToAdd)
            indexOfXY += 1
        }
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

extension Array {
    
    mutating func moveItem(from: Int, to: Int) {
        
        let item = self[from]
        self.remove(at: from)
        
        if to <= from {
            self.insert(item, at: to)
        } else {
            self.insert(item, at: to - 1)
        }
    }
}

