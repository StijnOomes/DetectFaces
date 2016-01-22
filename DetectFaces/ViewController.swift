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
    
    var session: AVCaptureSession!
    var camera: AVCaptureDevice?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var metadataOutput:AVCaptureMetadataOutput!
    var faceDetector: CIDetector?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetMedium
        
        let cameras = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in cameras as! [AVCaptureDevice] {
            if device.position == .Back {
                camera = device
            }
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                print("Camera video input can not be added.")
            }
        } catch {
            print("Something went wrong with the  camera.")
            return
        }

        if let previewLayer = AVCaptureVideoPreviewLayer.init(session: session) {
            previewLayer.frame = videoView.bounds
            videoView.layer.addSublayer(previewLayer)
        } else {
            print("Preview layer could not be added.")
        }
        
        metadataOutput = AVCaptureMetadataOutput()
        let metaQueue = dispatch_queue_create("MetaDataSession", DISPATCH_QUEUE_SERIAL)
        metadataOutput.setMetadataObjectsDelegate(self, queue: metaQueue)
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
        } else {
            print("Meta data output can not be added.")
        }

        metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeFace]
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA)]
        videoOutput.alwaysDiscardsLateVideoFrames = true        
        let outputQueue = dispatch_queue_create("CameraSession", DISPATCH_QUEUE_SERIAL)
        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        } else {
            print("Camera video output can not be added.")
        }
        
        let configurationOptions: [String: AnyObject] = [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorTracking : true, CIDetectorNumberOfAngles: 11]
        faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: configurationOptions)

        session.startRunning()
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

