//
//  ViewController.swift
//  IconApplication2
//
//  Created by razvan on 8/25/18.
//  Copyright © 2018 razvan. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    
    @IBOutlet var tabViewController: NSTabView!
    @IBOutlet var customView: NSView!
    @IBOutlet var collectionView: NSCollectionView!
    @IBOutlet var imangesContainer: NSImageView!
    @IBOutlet var checkBoxBorder: NSButton!
    @IBOutlet var sliderBordeWeight: NSSlider!
    
    var itemsBeingDragged : Set<IndexPath>?
    
    var photos = [MovableImage]()
    
    var selectedImage: PhotoLayer?
    
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
            var indexXY = 1
            for file in files{
                if file.pathExtension == "jpeg" || file.pathExtension == "png"{
                    let movImage = MovableImage()
                    movImage.urlImage = file
                    photos.append(movImage)
                    addMovableImageToPreview(movableImageToAdd: movImage, indexOfXY: indexXY)
                    indexXY += 1
                }
            }
        } catch {
            print("Set up error")
        }
        customView.wantsLayer = true
        customView.layer?.backgroundColor = NSColor(red: 1, green: 1, blue: 1, alpha: 0.5).cgColor
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func onCheckBoxBorder(_ sender: Any) {
        let imageViewOfMovableImage = selectedImage?.movableImage
        imageViewOfMovableImage?.wantsLayer = true
        if checkBoxBorder.state.rawValue == 1 {
            imageViewOfMovableImage?.layer?.borderColor = NSColor.black.cgColor
            imageViewOfMovableImage?.layer?.borderWidth = 10
        }else{
            imageViewOfMovableImage?.layer?.borderWidth = 0
        }
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PhotoLayer"), for: indexPath)
        guard let pictureItem = item as? PhotoLayer else {return item}
        
        let image = NSImage(contentsOf: photos[indexPath.item].urlImage!)
        pictureItem.imageView?.image = image
        
        pictureItem.setViewController(controller: self)
        pictureItem.movableImage = photos[indexPath.item]
        return pictureItem
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
        arrangementImagesToPreview()
    }
    
    func performExternalDrag(with items: [NSPasteboardItem], at indexPath: IndexPath) {
        let fm = FileManager.default
        
        //1 - loop over every item on the drag and drop pasteboard
        var indexXY = 1
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
            let moveImage = MovableImage()
            moveImage.urlImage = destinationURL
            photos.insert(moveImage, at: indexPath.item)
            
            addMovableImageToPreview(movableImageToAdd: moveImage, indexOfXY: indexXY)
            
            collectionView.insertItems(at: [indexPath])
            indexXY += 1
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt indexPath: IndexPath) -> NSPasteboardWriting? {
        
        return photos[indexPath.item].urlImage as NSPasteboardWriting?
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
                    try fm.trashItem(at: photos[indexPath.item].urlImage!, resultingItemURL: nil)
                    photos.remove(at: indexPath.item)
                    
                } catch {
                    print("Failed to delete |(photos[indexPath.item])")
                }
            }
            //remove the items from the collection view
            collectionView.animator().deleteItems(at: collectionView.selectionIndexPaths)
        }
        arrangementImagesToPreview()
    }
    
    func addMovableImageToPreview(movableImageToAdd: MovableImage, indexOfXY: Int){
        let imageImported = NSImage(byReferencing: movableImageToAdd.urlImage!)
        movableImageToAdd.frame = NSRect(x:indexOfXY * 10, y:indexOfXY * 10, width: 1, height: 1)
        if imageImported.size.width > imangesContainer.frame.width {
            movableImageToAdd.frame.size = imangesContainer.frame.size
        } else {
            movableImageToAdd.frame.size = imageImported.size
        }
        movableImageToAdd.image = imageImported
        arrangementImagesToPreview()
    }
    
    func arrangementImagesToPreview(){
        for view in imangesContainer.subviews {
            view.removeFromSuperview()
        }
        
        for index in (0..<photos.count).reversed()  {
            let movableImageToAdd = photos[index]
            imangesContainer.addSubview(movableImageToAdd)
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
    
    func setSelectedImage(selectImage: PhotoLayer){
        selectedImage = selectImage
    }
    
    @IBAction func changeToBackgorundView(_ sender: NSView){
        tabViewController.selectTabViewItem(at: 0)
    }
    
    @IBAction func changeToImageView(_ sender: NSView){
        tabViewController.selectTabViewItem(at: 1)
    }
    
    @IBAction func changeToTextView(_ sender: NSView){
        tabViewController.selectTabViewItem(at: 2)
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

