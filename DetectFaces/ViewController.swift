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
    
    //var captureSession: AVCaptureSession!
    var cameraDevice: AVCaptureDevice?
    //var previewLayer: AVCaptureVideoPreviewLayer?
    //var metadataOutput: AVCaptureMetadataOutput!
    var faceDetector: CIDetector?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.medium
        
//        let cameras = AVCaptureDevice.devices(for: AVMediaType.video)
//        for device in cameras as! [AVCaptureDevice] {
//            if device.position == .front {
//                cameraDevice = device
//            }
//        }
        
        let videoDeviceDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        
        for camera in videoDeviceDiscovery.devices as [AVCaptureDevice] {
            if camera.position == .front {
                cameraDevice = camera
            }
        }
        if cameraDevice == nil {
            print("Could not find front camera.")
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: cameraDevice!)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                print("Video input can not be added.")
            }
        } catch {
            print("Something went wrong with the video input.")
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
        previewLayer.frame = videoView.bounds
        videoView.layer.addSublayer(previewLayer)
        
        let metadataOutput = AVCaptureMetadataOutput()
        let metaQueue = DispatchQueue(label: "MetaDataSession")
        metadataOutput.setMetadataObjectsDelegate(self, queue: metaQueue)
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
        } else {
            print("Meta data output can not be added.")
        }

        metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.face]
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        let outputQueue = DispatchQueue(label: "CameraSession")
        videoOutput.setSampleBufferDelegate(self, queue: outputQueue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("Video output can not be added.")
        }
        
        let configurationOptions: [String: AnyObject] = [CIDetectorAccuracy: CIDetectorAccuracyHigh as AnyObject, CIDetectorTracking : true as AnyObject, CIDetectorNumberOfAngles: 11 as AnyObject]
        faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: configurationOptions)

        captureSession.startRunning()
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        for metadataObject in metadataObjects as! [AVMetadataFaceObject] {
            DispatchQueue.main.async {
                self.avFaceID.text = "face ID: \(metadataObject.faceID)"
                self.avFaceRoll.text = "roll: \(Int(metadataObject.rollAngle))"
                self.avFaceYaw.text = "yaw: \(Int(metadataObject.yawAngle))"
            }
        }
        
    }
    


    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let inputImage = CIImage(cvImageBuffer: imageBuffer)
        
        let detectorOptions: [String: AnyObject] = [CIDetectorSmile: true as AnyObject, CIDetectorEyeBlink: true as AnyObject, CIDetectorImageOrientation : 6 as AnyObject]
        
        let faces = self.faceDetector!.features(in: inputImage, options: detectorOptions)
        
        for face in faces as! [CIFaceFeature] {
            DispatchQueue.main.async {
                self.ciFaceID.text = "face ID: \(face.trackingID)"
                self.ciFaceAngle.text = "angle: \(Int(face.faceAngle))"
            }
        }
        
    }

}

