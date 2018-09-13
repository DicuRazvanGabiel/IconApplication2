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
        
        imangesContainer.wantsLayer = true
        
        //setBackgroundColor(color: NSColor.red)
        //roundBackgroundCorners(amount: 100.0)
        //setBackGroundBorder(color: NSColor.red, thickness: 20)
        //setBackGroundShadow(offset: 0, color: NSColor.black, blur: 10)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
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
    
    @IBAction func changeToBackgorundView(_ sender: NSView){
        tabViewController.selectTabViewItem(at: 0)
    }
    
    @IBAction func changeToImageView(_ sender: NSView){
        tabViewController.selectTabViewItem(at: 1)
    }
    
    @IBAction func changeToTextView(_ sender: NSView){
        tabViewController.selectTabViewItem(at: 2)
    }
    
    @IBAction func exportImage(_ sender: NSView){
        let imageToExport = generateImageToExport()
        let image =  imageToExport
        guard let tiffData = image.tiffRepresentation else { return }
        guard let imageRep = NSBitmapImageRep(data: tiffData) else { return }
        guard let png = imageRep.representation(using: .png, properties: [:]) else { return }
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["png"]
        panel.begin { result in
            if result == NSApplication.ModalResponse.OK {
                guard let url = panel.url else { return }
                do {
                    try png.write(to: url)
                } catch {
                    print(error.localizedDescription)
                }
            }
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
    
    func setBackGroundShadow(offset: Float = 0, color: NSColor = NSColor.blue, blur: Float = 5){
        imangesContainer.shadow = setShadow(offset: offset, color: color, blur: blur)
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
        scaleSelectedImage()
    }

    func generateImageToExport() -> NSImage{
        let image = NSImage(size: CGSize(width: 700, height: 720), flipped: false) { [unowned self] rect in
            
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            
            self.drawPhotosToExport(context: ctx, rect: rect)
            
            return true
        }
        
        return image
    }
    
    func drawPhotosToExport(context: CGContext, rect: CGRect){
        
        for index in (0..<photos.count).reversed()  {
            let image = photos[index].image
            let imageOrigin = photos[index].frame.origin
            image?.draw(at: imageOrigin, from: .zero, operation: .sourceOver, fraction: 1)
            //image?.draw(in: rect, from: imageOrigin, operation: .sourceOver, fraction: 1)
        }
    }

    func roundBackgroundCorners(amount: Float = 0.5){
        imangesContainer.layer?.cornerRadius = CGFloat(amount)
    }
    
    func setBackgroundColor(color: NSColor){
        imangesContainer.layer?.backgroundColor = color.cgColor
    }
    
    func setBackGroundBorder(color: NSColor, thickness: Float){
        imangesContainer.layer?.borderColor = color.cgColor
        imangesContainer.layer?.borderWidth = CGFloat(thickness)
    }
    
    func scaleSelectedImage(amount: Float = 100){
        let newSize = NSSize(width: 200, height: 200)
        let newImage = selectedImage?.movableImage.image?.resizeWhileMaintainingAspectRatioToSize(size: newSize)
        //selectedImage?.movableImage.image? = newImage!
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

extension NSImage {
    
    /// Returns the height of the current image.
    var height: CGFloat {
        return self.size.height
    }
    
    /// Returns the width of the current image.
    var width: CGFloat {
        return self.size.width
    }
    
    ///  Copies the current image and resizes it to the given size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func copy(size: NSSize) -> NSImage? {
        // Create a new rect with given width and height
        let frame = NSMakeRect(0, 0, size.width, size.height)
        
        // Get the best representation for the given size.
        guard let rep = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        
        // Create an empty image with the given size.
        let img = NSImage(size: size)
        
        // Set the drawing context and make sure to remove the focus before returning.
        img.lockFocus()
        defer { img.unlockFocus() }
        
        // Draw the new image
        if rep.draw(in: frame) {
            return img
        }
        
        // Return nil in case something went wrong.
        return nil
    }
    
    ///  Copies the current image and resizes it to the size of the given NSSize, while
    ///  maintaining the aspect ratio of the original image.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The resized copy of the given image.
    func resizeWhileMaintainingAspectRatioToSize(size: NSSize) -> NSImage? {
        let newSize: NSSize
        
        let widthRatio  = size.width / self.width
        let heightRatio = size.height / self.height
        
        if widthRatio > heightRatio {
            newSize = NSSize(width: floor(self.width * widthRatio), height: floor(self.height * widthRatio))
        } else {
            newSize = NSSize(width: floor(self.width * heightRatio), height: floor(self.height * heightRatio))
        }
        
        return self.copy(size: newSize)
    }
    
    ///  Copies and crops an image to the supplied size.
    ///
    ///  - parameter size: The size of the new image.
    ///
    ///  - returns: The cropped copy of the given image.
    func crop(size: NSSize) -> NSImage? {
        // Resize the current image, while preserving the aspect ratio.
        guard let resized = self.resizeWhileMaintainingAspectRatioToSize(size: size) else {
            return nil
        }
        // Get some points to center the cropping area.
        let x = floor((resized.width - size.width) / 2)
        let y = floor((resized.height - size.height) / 2)
        
        // Create the cropping frame.
        let frame = NSMakeRect(x, y, size.width, size.height)
        
        // Get the best representation of the image for the given cropping frame.
        guard let rep = resized.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        
        // Create a new image with the new size
        let img = NSImage(size: size)
        
        img.lockFocus()
        defer { img.unlockFocus() }
        
        if rep.draw(in: NSMakeRect(0, 0, size.width, size.height),
                    from: frame,
                    operation: NSCompositingOperation.copy,
                    fraction: 1.0,
                    respectFlipped: false,
                    hints: [:]) {
            // Return the cropped image.
            return img
        }
        
        // Return nil in case anything fails.
        return nil
    }
}
