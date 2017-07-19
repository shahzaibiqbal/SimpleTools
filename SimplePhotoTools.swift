//
//  SimplePhotoTools
//
//
//  Created by shahzaib iqbal on 7/17/17.
//  Copyright © 2017 shahzaib iqbal. All rights reserved.
//

import UIKit

class SimplePhotoTools: NSObject {
    
    //MARK: Private properties
    private var imgAsset: UIImage!
    
    //MARK: Public methods
    /*
     *
     *  Mehtod resizeImage resize image to givine size by keeping aspect ratio same.
     *
     *  @param img (required) img is the UIImage object which need to be resized.
     *
     * @param newSize (required) newSize is the CGSize object to which image need to resized.
     *
     *  @return UIImage (optional) object. If image size is smaller than given size it will return nil.
     */

    func resizeImage(img: UIImage, newSize: CGSize) -> UIImage? {
        let size = img.size
        
        let widthRatio  = newSize.width  / img.size.width
        let heightRatio = newSize.height / img.size.height
        if widthRatio >= 1.0 && heightRatio >= 1.0 {
            return nil
        }
        // Figure out what our orientation is, and use that to form the rectangle
        var newScaledSize: CGSize
        if(widthRatio > heightRatio) {
            newScaledSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newScaledSize = CGSize(width:size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newScaledSize.width, height: newScaledSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newScaledSize, false, 1.0)
        img.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    /*
     *
     *  Mehtod addContentToImage render objects on give image.
     *
     *  @param img (required) img is the UIImage object in which other objects will be added.
     *
     * @param boundingSize (required) is the CGSize object. Which gives the current display size of UIImage object on screen. By using this size method will calculate new cooridantes and size for rending objects with respect to image size to make them appear on image as it was showing on screen.
     *
     *
     * @param contents (required) is a [UIView] array object. You should only pass UIImageView and UILabel objects in this other kind of object will be ignored by this method. This method will get different properties on object e.g transform, size , origin etc from objects.
     *
     * @param (UIImage?, Error?)-> Void (required) is finishing block. Which will be passed by UIImage or Error? object on compeletion of procress.
    */
    func addContentToImage(img: UIImage, boundingSize: CGSize, contents: [UIView], finish: @escaping (UIImage?, Error?)-> Void) {
        imgAsset = img
        UIGraphicsBeginImageContextWithOptions(img.size, false, 1.0)
        img.draw(at: CGPoint.zero)
        for content in contents {
            let scaleRect = self.getTransformedRect(fromSize: boundingSize, forView: content)
            var imgContent: UIImage!
            if content.isKind(of: UILabel.self) {
                imgContent = self.getTextImage(lable: content as! UILabel, size: scaleRect.size)
            }
            else if content.isKind(of: UIImageView.self) {
                imgContent = self.getImageLayer(imgView: content as! UIImageView, size: scaleRect.size)
            }
            if imgContent != nil {
                let centerX = scaleRect.origin.x + scaleRect.size.width / 2
                let centerY = scaleRect.origin.y + scaleRect.size.height / 2
                let newOrigin = CGPoint(x: centerX - (imgContent.size.width / 2), y: centerY - (imgContent.size.height / 2))
                imgContent.draw(in: CGRect(origin: newOrigin, size: imgContent.size))
            }
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        finish(newImage, nil)
    }
    deinit {
        if imgAsset != nil {
            imgAsset = nil
        }
    }
    
    //MARK: Private methods
    /*
     *
     *  Mehtod getTextImage cerate transformed image from Text.
     *
     *  @param lable (required) lable is the UILabel object.
     *
     * @param size (required) is the CGSize object. Which will have new calculated size for lable with respect to image size.
     *
     *  @return UIImage object. Return text image.
     */
    private func getTextImage(lable: UILabel, size: CGSize) -> UIImage {
        let nsStr = NSString(string: lable.text!)
        let angle = atan2(lable.transform.b, lable.transform.a)
        let rotatedSize = self.calculateTransformedAngleSize(size: size, angle: angle)
        let scaleSize = CGSize(width: rotatedSize.width / lable.frame.size.width, height: rotatedSize.height / lable.frame.size.height)
        let maxScale = CGFloat.maximum(scaleSize.width, scaleSize.height)
        UIGraphicsBeginImageContext(rotatedSize)
        UIGraphicsGetCurrentContext()!.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        UIGraphicsGetCurrentContext()!.rotate(by: angle)
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = lable.textAlignment
        let newFont = UIFont(name: lable.font.fontName, size: lable.font.pointSize * maxScale)
        let textAttr = [
            NSFontAttributeName: newFont!,
            NSForegroundColorAttributeName: lable.textColor,
            NSParagraphStyleAttributeName: paraStyle
            ] as [String : Any]
        nsStr.draw(in:  CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height), withAttributes: textAttr)
        let textImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return textImg!
    }
    /*
     *
     *  Mehtod getTransformedRect calculate new CGRect with respect to image size.
     *
     *  @param fromSize (required) is the CGSize object.
     *
     * @param forView (required) is the UIView object. Which will have UIView Which need to be convered with respect to image size.
     *
     *  @return CGRect object.
     */
    private func getTransformedRect(fromSize: CGSize, forView: UIView) -> CGRect {
        let sizeScale = CGSize(width: self.imgAsset.size.width / fromSize.width , height: self.imgAsset.size.height / fromSize.height)
        let newSize = CGSize(width: forView.bounds.width * sizeScale.width, height: forView.bounds.height * sizeScale.height)
        let newOrigin = CGPoint(x: (sizeScale.width * forView.center.x) - (newSize.width / 2), y: (sizeScale.height * forView.center.y) - (newSize.height / 2))
        return CGRect(origin: newOrigin, size: newSize)
    }
    /*
     *
     *  Mehtod getImageLayer cerate transformed image.
     *
     *  @param imgView (required) is the UIImageView object.
     *
     * @param size (required) is the CGSize object. Which will have new calculated size for imgView with respect to image size.
     *
     *  @return UIImage object. Return text image.
     */

    private func getImageLayer(imgView: UIImageView, size: CGSize) -> UIImage {
        let angle = atan2(imgView.transform.b, imgView.transform.a)
        let rotatedSize = self.calculateTransformedAngleSize(size: size, angle: angle)
        UIGraphicsBeginImageContext(rotatedSize)
        UIGraphicsGetCurrentContext()!.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        UIGraphicsGetCurrentContext()!.rotate(by: angle)
        imgView.image?.draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    /*
     *
     *  Mehtod calculateTransformedAngleSize calculate size of rotated image.
     *
     * @param size (required) is the CGSize object. Which will have size before transform.
     *
     *
     * @param angle (required) is the CGFloat object. Which will have angle for transform.
     *
     *  @return CGSize object. Return new size for transform object.
     */
    private func calculateTransformedAngleSize(size: CGSize, angle: CGFloat) -> CGSize {
        let v = UIView(frame: CGRect(origin: CGPoint.zero, size: size))
        let t = CGAffineTransform(rotationAngle: angle)
        v.transform = t
        return v.frame.size
    }
}
