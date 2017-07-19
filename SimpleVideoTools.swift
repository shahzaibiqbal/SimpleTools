//
//  SimpleVideoTools.swift
//
//  Created by shahzaib iqbal on 7/17/17.
//  Copyright © 2017 shahzaib iqbal. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class SimpleVideoTools: NSObject {
    
    //MARK: Private properties
    private var asset: AVAsset!
    private var video_Track: AVAssetTrack!
    private var audio_Track: AVAssetTrack!
    private var progressBlock: ((Float,String)-> Void)!
    private var finishedBlock: ((URL?, Error?)-> Void)!
    private var exportTimer: Timer!
    private var exportSession: AVAssetExportSession!
    
    //MARK: Public methods
    /*
     *
     *  Mehtod optimizeVideo will resize or set fps for video.
     *
     * @param path (required) is URL object. File url for the video which need to process.
     *
     *  @param exportPreset (optional) is the String object which contains size for the video. Any of following sizes can be selected by default it will be AVAssetExportPresetHighestQuality
     * AVAssetExportPresetLowQuality
     * AVAssetExportPresetMediumQuality
     * AVAssetExportPresetHighestQuality
     * AVAssetExportPreset640x480
     * AVAssetExportPreset960x540
     * AVAssetExportPreset1280x720
     * AVAssetExportPreset1920x1080
     * AVAssetExportPreset3840x2160
     * AVAssetExportPresetPassthrough
     *
     * @param progress: (Float,String)-> Void (required). This block will call while processing the video to let user know about status and progress of video process. Progress will be between 0.0 to 1.0
     
     *
     *  @return finish: (URL?, Error?)-> Void) (required). This will call when video will be finished processing or any error occur while procerssing.
     */
    
    func optimizeVideo(path: URL, exportPreset: String = AVAssetExportPresetHighestQuality, fps: Int32 = 0 , progress: @escaping (Float,String)-> Void, finish: @escaping (URL?, Error?)-> Void) {
        self.progressBlock = progress
        self.finishedBlock = finish
        self.extract_Audio_Video_Assets(path: path)
        guard let composition = self.getComposition(withDuration: kCMTimeZero, endDuration: self.asset.duration, shouldScale: false, rate: 1.0) else {
            finish(nil, NSError(domain: "Invalid asset", code: -999, userInfo: nil))
            return
        }
        var givenFps =  self.video_Track.minFrameDuration
        if fps > 0 {
            givenFps = CMTimeMake(1, fps)
        }
        let video_composition = self.renderContents(layers: [], fps: givenFps, composition: composition)
         self.exportSession(composition: composition, video_Composition: video_composition, optimizedfornetwork: true, preset: exportPreset)
    }
    /*
     *
     *  Mehtod trimVideo will trime video for given begin and end time duration.
     *
     * @param path (required) is URL object. File url for the video which need to process.
     *
     * @param begin (required). Begin time from where video should start.
     *
     *
     * @param end (required). end time from where video should end.
     *
     * @param progress: (Float,String)-> Void (required). This block will call while processing the video to let user know about status and progress of video process. Progress will be between 0.0 to 1.0
     
     *
     *  @return finish: (URL?, Error?)-> Void) (required). This will call when video will be finished processing or any error occur while procerssing.
     */
    func trimVideo(path: URL, begin: Float64, end: Float64, progress: @escaping (Float,String)-> Void, finish: @escaping (URL?, Error?)-> Void) {
        self.progressBlock = progress
        self.finishedBlock = finish
        self.extract_Audio_Video_Assets(path: path)
        guard let composition = self.getComposition(withDuration: CMTimeMakeWithSeconds(begin, Int32(NSEC_PER_SEC)), endDuration: CMTimeMakeWithSeconds(end, Int32(NSEC_PER_SEC)), shouldScale: false, rate: 1.0) else {
            finish(nil, NSError(domain: "Invalid asset", code: -999, userInfo: nil))
            return
        }
        let video_composition = self.renderContents(layers: [], fps: video_Track.minFrameDuration, composition: composition)
        self.exportSession(composition: composition, video_Composition: video_composition, optimizedfornetwork: false, preset: AVAssetExportPresetHighestQuality)
    }
    /*
     *
     *  Mehtod setVideoRate will set speed or rate for the video in given duration.
     *
     * @param path (required) is URL object. File url for the video which need to process.
     *
     * @param rate (required). speed of video for given duration.
     *
     * @param begin (required). Begin time from where video should start.
     *
     *
     * @param end (required). end time from where video should end.
     *
     * @param progress: (Float,String)-> Void (required). This block will call while processing the video to let user know about status and progress of video process. Progress will be between 0.0 to 1.0
     
     *
     *  @return finish: (URL?, Error?)-> Void) (required). This will call when video will be finished processing or any error occur while procerssing.
     */
    func setVideoRate(path: URL, rate: Float, begin: Float64, end: Float64, progress: @escaping (Float,String)-> Void, finish: @escaping (URL?, Error?)-> Void) {
        self.progressBlock = progress
        self.finishedBlock = finish
        self.extract_Audio_Video_Assets(path: path)
        guard let composition = self.getComposition(withDuration: CMTimeMakeWithSeconds(begin, Int32(NSEC_PER_SEC)), endDuration: CMTimeMakeWithSeconds(end, Int32(NSEC_PER_SEC)), shouldScale: true, rate: rate) else {
            finish(nil, NSError(domain: "Invalid asset", code: -999, userInfo: nil))
            return
        }
        let video_composition = self.renderContents(layers: [], fps: video_Track.minFrameDuration, composition: composition)
        self.exportSession(composition: composition, video_Composition: video_composition, optimizedfornetwork: false, preset: AVAssetExportPresetHighestQuality)
    }
    /*
     *
     *  Mehtod addContentToVideo will add text or image to video.
     *
     * @param path (required) is URL object. File url for the video which need to process.
     *
     * @param boundingSize (required) is the CGSize object. Which gives the current display size of UIImage object on screen. By using this size method will calculate new cooridantes and size for rending objects with respect to image size to make them appear on image as it was showing on screen.
     *
     * @param contents (required) is a [UIView] array object. You should only pass UIImageView and UILabel objects in this other kind of object will be ignored by this method. This method will get different properties on object e.g transform, size , origin etc from objects.
     *
     * @param progress: (Float,String)-> Void (required). This block will call while processing the video to let user know about status and progress of video process. Progress will be between 0.0 to 1.0
     
     *
     *  @return finish: (URL?, Error?)-> Void) (required). This will call when video will be finished processing or any error occur while procerssing.
     */
    func addContentToVideo(path: URL, boundingSize: CGSize, contents: [UIView], progress: @escaping (Float,String)-> Void, finish: @escaping (URL?, Error?)-> Void) {
        var layers: [CALayer] = [CALayer]()
        self.extract_Audio_Video_Assets(path: path)
        for content in contents {
            if content.isKind(of: UILabel.self) {
                layers.append(self.getTextLayer(lable: content as! UILabel, size: boundingSize))
            }
            else if content.isKind(of: UIImageView.self) {
                layers.append(self.getImageLayer(imgView: content as! UIImageView, size: boundingSize))
            }
        }
        if layers.count == 0 {
            finish(nil, NSError(domain: "Invalid contents", code: -999, userInfo: nil))
            return
        }
        self.progressBlock = progress
        self.finishedBlock = finish
        guard let composition = self.getComposition(withDuration: kCMTimeZero, endDuration: self.asset.duration, shouldScale: false, rate: 1.0) else {
            finish(nil, NSError(domain: "Invalid asset", code: -999, userInfo: nil))
            return
        }
        let video_composition = self.renderContents(layers: layers, fps: video_Track.minFrameDuration, composition: composition)
        self.exportSession(composition: composition, video_Composition: video_composition, optimizedfornetwork: false, preset: AVAssetExportPresetHighestQuality)
    }
    /*
     *  Mehtod exportTimerCall for timer call.
     */
    func exportTimerCall() {
        guard (exportTimer != nil) else {
            return
        }
        guard (progressBlock != nil) else {
            return
        }
        var status: String!
        switch exportSession.status {
        case .waiting:
            status = "waiting"
            break
        case .exporting:
            status = "importing"
            break
        default:
            break
        }
        if status != nil {
            progressBlock(exportSession.progress, status)
        }
    }
    deinit {
        if asset != nil {
            asset = nil
        }
        if video_Track != nil {
            video_Track = nil
        }
        if audio_Track != nil {
            audio_Track = nil
        }
        if progressBlock != nil {
            progressBlock = nil
        }
        if finishedBlock != nil {
            finishedBlock = nil
        }
        if exportTimer != nil {
            exportTimer = nil
        }
        if exportSession != nil {
            exportSession = nil
        }
    }
    
    //MARK: Private methods
    
    private func renderContents(layers: [CALayer], fps: CMTime, composition: AVMutableComposition) -> AVMutableVideoComposition {
        var video_size = video_Track.naturalSize
        var current_fps = video_Track.minFrameDuration
        if current_fps.seconds > fps.seconds {
            current_fps = fps
        }
        if self.isTrackPortriate() {
            video_size = CGSize(width: video_size.height, height: video_size.width)
        }
        let video_compositon = AVMutableVideoComposition()
        video_compositon.renderSize = video_size
        video_compositon.frameDuration = current_fps
        if layers.count > 0 {
            let baselayer = CALayer()
            baselayer.frame = CGRect(x: 0, y: 0, width: video_size.width, height: video_size.height)
            let videoLayer = CALayer()
            videoLayer.frame = CGRect(x: 0, y: 0, width: video_size.width, height: video_size.height)
            baselayer.addSublayer(videoLayer)
            for layer in layers {
                baselayer.addSublayer(layer)
            }
            video_compositon.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: baselayer)
            
        }
        let instructions: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        instructions.timeRange = CMTimeRangeMake(kCMTimeZero, composition.duration)
        let video_track = composition.tracks(withMediaType: AVMediaTypeVideo).first
        let layerInstructions : AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: video_track!)
        layerInstructions.setTransform(self.video_Track.preferredTransform, at: kCMTimeZero)
        instructions.layerInstructions = [layerInstructions]
        instructions.timeRange = CMTimeRangeMake(kCMTimeZero, composition.duration)
        video_compositon.instructions = [instructions]
        return video_compositon
    }
    
    private func isTrackPortriate() -> Bool {
        var  isVideoAssetPortrait: Bool = false
        let videoTransform: CGAffineTransform = self.video_Track.preferredTransform
        
        if(videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0){
            isVideoAssetPortrait = true
        }
        else if(videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0)  {
            isVideoAssetPortrait = true
        }
        //        if(videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0)   {videoAssetOrientation_ =  UIImageOrientationUp;}
        //        if(videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {videoAssetOrientation_ = UIImageOrientationDown;}
        return isVideoAssetPortrait
    }
    private func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    private func exportSession(composition: AVMutableComposition, video_Composition: AVVideoComposition?,optimizedfornetwork: Bool, preset: String) {
        guard let outputUrl = self.getFullURL(fnam: self.randomString(length: 10) + ".mp4")
            else {
                return
        }
        exportSession = AVAssetExportSession(asset: composition, presetName: preset)!
        exportSession.shouldOptimizeForNetworkUse = optimizedfornetwork
        exportSession.videoComposition = video_Composition
        
        exportSession.outputURL = outputUrl
        exportSession.outputFileType = AVFileTypeMPEG4
        self.beginTimer()
        exportSession.exportAsynchronously(completionHandler: {
            
            if self.exportSession.status == AVAssetExportSessionStatus.completed {
                self.stopTimer()
                self.finishedBlock(self.exportSession.outputURL, nil)
            }
            else if self.exportSession.status == AVAssetExportSessionStatus.failed || self.exportSession.status == AVAssetExportSessionStatus.cancelled {
                self.stopTimer()
                self.finishedBlock(nil, self.exportSession.error)
            }
        })
    }
    private func extract_Audio_Video_Assets(path: URL) {
        self.asset = AVAsset(url: path)
        guard (asset) != nil else {
            return
        }
        video_Track = asset.tracks(withMediaType: AVMediaTypeVideo).first!
        audio_Track = asset.tracks(withMediaType: AVMediaTypeAudio).first!
    }
    private func getComposition(withDuration beginDuration: CMTime, endDuration: CMTime, shouldScale: Bool, rate: Float) -> AVMutableComposition? {
        guard (asset) != nil else {
            return nil
        }
        
        do {
            let composition: AVMutableComposition = AVMutableComposition()
            let differnce = CMTimeSubtract(endDuration, beginDuration)
            if video_Track != nil {
                let video_composition_Track: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
                if shouldScale {
                    try video_composition_Track.insertTimeRange(video_Track.timeRange, of: video_Track, at: kCMTimeZero)
                }
                else {
                    try video_composition_Track.insertTimeRange(CMTimeRangeMake(beginDuration, differnce), of: video_Track, at: kCMTimeZero)
                }
            }
            if audio_Track != nil {
                let audio_composition_Track: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
                if shouldScale {
                    try audio_composition_Track.insertTimeRange(audio_Track.timeRange, of: audio_Track, at: kCMTimeZero)
                }
                else {
                    try audio_composition_Track.insertTimeRange(CMTimeRangeMake(beginDuration, differnce), of: audio_Track, at: kCMTimeZero)
                }
                
            }
            if shouldScale {
                var differenceInSeconds = CMTimeGetSeconds(differnce)
                differenceInSeconds = differenceInSeconds / Float64(rate)
                let scaledTime = CMTimeMakeWithSeconds(differenceInSeconds, differnce.timescale)
                composition.scaleTimeRange(CMTimeRangeMake(beginDuration, differnce), toDuration: scaledTime)
            }
            return composition
        }
        catch {
            print(error)
            return nil
        }
        
    }
    private func stopTimer() {
        if exportTimer == nil {
            return
        }
        exportTimer.invalidate()
        exportTimer = nil
    }
    private func beginTimer() {
        if exportTimer != nil {
            self.stopTimer()
        }
        exportTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(SimpleVideoTools.exportTimerCall), userInfo: nil, repeats: true)
    }
    private func getTextLayer(lable: UILabel, size: CGSize) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.backgroundColor = lable.backgroundColor?.cgColor
        textLayer.frame = self.getTransformedRect(fromSize: size, forView: lable)
        textLayer.transform =  CATransform3DMakeAffineTransform(lable.transform.inverted())
        textLayer.isWrapped = true
        let video_rect = self.getVideoRect()
        let sizeScale = CGSize(width: video_rect.width / size.width , height: video_rect.height / size.height)
        textLayer.font = lable.font
        textLayer.fontSize = lable.font.pointSize * sizeScale.width
        textLayer.foregroundColor = lable.textColor.cgColor
        switch lable.textAlignment {
        case .center:
            textLayer.alignmentMode = kCAAlignmentCenter
            break
        case .justified:
            textLayer.alignmentMode = kCAAlignmentJustified
            break
        case .left:
            textLayer.alignmentMode = kCAAlignmentLeft
            break
        case .right:
            textLayer.alignmentMode = kCAAlignmentRight
            break
        default:
            textLayer.alignmentMode = kCAAlignmentNatural
        }
        textLayer.string = lable.text
        return textLayer
    }
    private func getTransformedRect(fromSize: CGSize, forView: UIView) -> CGRect {
        let video_rect = self.getVideoRect()
        let sizeScale = CGSize(width: video_rect.width / fromSize.width , height: video_rect.height / fromSize.height)
        let newSize = CGSize(width: forView.bounds.width * sizeScale.width, height: forView.bounds.height * sizeScale.height)
        var newOrigin = CGPoint(x: (sizeScale.width * forView.center.x) - (newSize.width / 2), y: (sizeScale.height * forView.center.y) - (newSize.height / 2))
        newOrigin.y = video_rect.height - newOrigin.y -  newSize.height
        return CGRect(origin: newOrigin, size: newSize)
    }
    private func getVideoRect() -> CGRect {
        var video_rect = CGRect(origin: CGPoint(x: 0, y: 0), size: video_Track.naturalSize)
        if self.isTrackPortriate() {
            video_rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: video_rect.height, height: video_rect.width))
        }
        return video_rect
    }
    private func getImageLayer(imgView: UIImageView, size: CGSize) -> CALayer {
        let imglayer = CALayer()
        imglayer.backgroundColor = imgView.backgroundColor?.cgColor
        imglayer.contents = imgView.image?.cgImage
        imglayer.frame = self.getTransformedRect(fromSize: size, forView: imgView)
        imglayer.transform =  CATransform3DMakeAffineTransform(imgView.transform.inverted())
        switch imgView.contentMode {
        case .bottom:
            imglayer.contentsGravity = kCAGravityBottom
            break
        case .top:
            imglayer.contentsGravity = kCAGravityTop
            break
        case .topLeft:
            imglayer.contentsGravity = kCAGravityTopLeft
            break
        case .topRight:
            imglayer.contentsGravity = kCAGravityTopRight
            break
        case .scaleToFill:
            imglayer.contentsGravity = kCAGravityResizeAspectFill
            break
        case .scaleAspectFit:
            imglayer.contentsGravity = kCAGravityResize
            break
        case .center:
            imglayer.contentsGravity = kCAGravityCenter
            break
        case .left:
            imglayer.contentsGravity = kCAGravityLeft
            break
        case .bottomLeft:
            imglayer.contentsGravity = kCAGravityBottomLeft
            break
        case .bottomRight:
            imglayer.contentsGravity = kCAGravityBottomRight
            break
        case .right:
            imglayer.contentsGravity = kCAGravityRight
            break
        case .redraw:
            imglayer.contentsGravity = kCAGravityResize
            break
        case .scaleAspectFill:
            imglayer.contentsGravity = kCAGravityResizeAspectFill
            break
        }
        return imglayer
    }
    private func getFullURL(fnam: String) -> URL? {
        var path = NSTemporaryDirectory()
        path.append("/" + fnam)
        do {
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.removeItem(atPath: path)
            }
            return URL(fileURLWithPath: path)
        }
        catch {
            return nil
        }
    }
}
