//
//  ViewController.swift
//  ImageRecognitionSample
//
//  Created by Yuta Fukuda on 2021/03/08.
//

import UIKit
import AVFoundation
import CoreML

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var captureSession = AVCaptureSession()
    var mainCamera: AVCaptureDevice?                      // main camera
    var innerCamera: AVCaptureDevice?                     // inner camera
    var currentDevice: AVCaptureDevice?                   // current device
    var photoOutput: AVCapturePhotoOutput?                // captured output
    var cameraPreviewLayer : AVCaptureVideoPreviewLayer?  // layer to preview
    
    let model = MyModel()

    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var myButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupCaptureSession()
        self.setupDevice()
        self.setupInputOutput()
        self.setupPreviewLayer()
        self.captureSession.startRunning()
        
        self.myLabel.text = ""
    }
    
    /// Sets up capture session.
    func setupCaptureSession() {
        self.captureSession.sessionPreset = AVCaptureSession.Preset.photo  // high resolution
    }
    
    /// Sets up property of camera device.
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices  // list of camera device fulfills the condition

        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                self.mainCamera = device
            } else if device.position == AVCaptureDevice.Position.front {
                self.innerCamera = device
            }
        }

        self.currentDevice = self.mainCamera  // use main camera when setup
    }
        
    /// Sets up input/output data.
    func setupInputOutput() {
        do {
            // initialize input to use the device
            let captureDeviceInput = try AVCaptureDeviceInput(device: self.currentDevice!)
            // add the input to capture session
            self.captureSession.addInput(captureDeviceInput)
            // initialize photo output
            self.photoOutput = AVCapturePhotoOutput()
            // specify format of output file
            self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            self.captureSession.addOutput(self.photoOutput!)
        } catch {
            print(error)
        }
    }
    
    /// Sets up layer to preview camera
    func setupPreviewLayer() {
        // initialize preview layer with the capture session
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        // keep aspect ratio
        self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
        // specify orientation
        self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait

        self.cameraPreviewLayer?.frame = self.view.frame
        self.view.layer.insertSublayer(self.cameraPreviewLayer!, at: 0)
    }

    @IBAction func onMyButtonTapped(_ sender: UIButton) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto  // flash
        //settings.isAutoStillImageStabilizationEnabled = true  // image stabilization
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    
    // ★MARK: AVCapturePhotoCaptureDelegate
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            let image = UIImage(data: imageData)!  // convert data to UIImage
            
            // prediction
            let input = try! MyModelInput(imageWith: image.cgImage!)
            let output = try! self.model.prediction(input: input)
            
            // display
            self.myLabel.text = output.classLabel
            
            // save image
            let outImage = self.addText(image: image, text: output.classLabel)
            UIImageWriteToSavedPhotosAlbum(outImage, nil, nil, nil)
        }
    }
    
    
    /// Adds text to image.
    /// - Parameters:
    ///   - image: image
    ///   - text: text
    /// - Returns: image with text
    func addText(image: UIImage, text: String) -> UIImage {
        let font = UIFont.boldSystemFont(ofSize: 64)
        let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)

        UIGraphicsBeginImageContext(image.size)

        image.draw(in: imageRect)

        let textRect  = CGRect(x: 20, y: 20, width: image.size.width - 5, height: image.size.height - 5)
        let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        let textFontAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: UIColor.red,
            NSAttributedString.Key.paragraphStyle: textStyle
        ]
        text.draw(in: textRect, withAttributes: textFontAttributes)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return newImage!
    }
}

