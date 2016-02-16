//
//  ViewController.swift
//  DetectFaces
//
//  Created by Stijn Oomes on 22/01/16.
//  Copyright © 2016 Oomes Vision Systems. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var ciFaceID: UILabel!
    @IBOutlet weak var ciFaceAngle: UILabel!
    @IBOutlet weak var avFaceID: UILabel!
    @IBOutlet weak var avFaceRoll: UILabel!
    @IBOutlet weak var avFaceYaw: UILabel!
    
    var captureSession: AVCaptureSession!
    var cameraDevice: AVCaptureDevice?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var metadataOutput: AVCaptureMetadataOutput!
    var faceDetector: CIDetector?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetMedium
        
        let cameras = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in cameras as! [AVCaptureDevice] {
            if device.position == .Front {
                cameraDevice = device
            }
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: cameraDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                print("Video input can not be added.")
            }
        } catch {
            print("Something went wrong with the video input.")
            return
        }

        if let previewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession) {
            previewLayer.frame = videoView.bounds
            videoView.layer.addSublayer(previewLayer)
        } else {
            print("Preview layer could not be added.")
        }
        
        metadataOutput = AVCaptureMetadataOutput()
        let metaQueue = dispatch_queue_create("MetaDataSession", DISPATCH_QUEUE_SERIAL)
        metadataOutput.setMetadataObjectsDelegate(self, queue: metaQueue)
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
        } else {
            print("Meta data output can not be added.")
        }

        metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA)]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        let outputQueue = dispatch_queue_create("CameraSession", DISPATCH_QUEUE_SERIAL)
        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("Video output can not be added.")
        }
        
        let configurationOptions: [String: AnyObject] = [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorTracking : true, CIDetectorNumberOfAngles: 11]
        faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: configurationOptions)

        captureSession.startRunning()
    }
    
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        for metadataObject in metadataObjects as! [AVMetadataFaceObject] {
            dispatch_async(dispatch_get_main_queue()) {
                self.avFaceID.text = "face ID: \(metadataObject.faceID)"
                self.avFaceRoll.text = "roll: \(Int(metadataObject.rollAngle))"
                self.avFaceYaw.text = "yaw: \(Int(metadataObject.yawAngle))"
            }
        }
    }

    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let inputImage = CIImage.init(CVImageBuffer: imageBuffer)
        
        let detectorOptions: [String: AnyObject] = [CIDetectorSmile: true, CIDetectorEyeBlink: true, CIDetectorImageOrientation : 6]
        
        let faces = self.faceDetector!.featuresInImage(inputImage, options: detectorOptions)
        
        for face in faces as! [CIFaceFeature] {
            dispatch_async(dispatch_get_main_queue()) {
                self.ciFaceID.text = "face ID: \(face.trackingID)"
                self.ciFaceAngle.text = "angle: \(Int(face.faceAngle))"
            }
        }
    }
    
}

