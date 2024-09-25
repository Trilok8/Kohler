//  BNIVideoBooth
//  Created by Trilok Boyapalli on 11/01/2023.

import UIKit
import AVKit
import AVFoundation
import MediaWatermark
import Alamofire
import Lottie
let DocumentDirectory = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)

class VideoRecordController: NoBarsController,AVCaptureVideoDataOutputSampleBufferDelegate,StopCameraSession, AVCaptureFileOutputRecordingDelegate,UITextFieldDelegate {
    
    func stopCameraSession() {
        print("Stopping Camera Session")
        cameraSession.stopRunning()
    }
    
    //Capture Session
    var cameraSession: AVCaptureSession = AVCaptureSession()
    
    //Capture Device
    var cameraDevice: AVCaptureDevice?
    
    //VideoData Output
    var videoDataOutput = AVCaptureVideoDataOutput()
    var fileOutput = AVCaptureMovieFileOutput()
    
    var isDeviceFound = false
    var isDeviceInputAdded = false
    
    var appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //Unique Queue
    let queue = DispatchQueue(label: "com.lazulite.Kohler",qos: .userInitiated,autoreleaseFrequency: .workItem)
    
    @IBOutlet weak var imgFrame: UIView!
    @IBOutlet weak var VIEWFORVIDEO: UIView!
    @IBOutlet weak var recordingRedView: UIView!
    @IBOutlet weak var btnVideoPlay: UIButton!
    @IBOutlet weak var btnVideoConfirm: UIButton!
    
    @IBOutlet weak var btnRecord: UIButton!
    
    @IBOutlet weak var btnRetake: UIButton!
    @IBOutlet weak var btnHome: UIButton!
    @IBOutlet weak var viewForSubmit: UIView!
    @IBOutlet weak var imgEmailSent: UIImageView!
    @IBOutlet weak var captureBGView: UIView!
    @IBOutlet weak var fldEmail: UITextField!
    
    @IBOutlet weak var animationView: LottieAnimationView!
    @IBOutlet weak var btnSubmissionClose: UIButton!
    
    var videoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    
    
    var fileURL: URL?
    
    var avplayer = AVPlayer()
    
    private var count:Int = 5
    private var countdownTimer:Timer = Timer()
    var labels:[UILabel] = []
    var centerXConstraints:[NSLayoutConstraint] = [NSLayoutConstraint]()
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        resignFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fldEmail.delegate = self
        animationView.isHidden = true
        for i in 1...5{
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.textColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
            label.text = "\(i)"
            label.font = UIFont(name: "HelveticaNeueLTPro-Roman", size: 150)
            label.adjustsFontSizeToFitWidth = true
            self.imgFrame.addSubview(label)
            labels.append(label)
            let centerXAnchor = NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: -100)
            centerXConstraints.append(centerXAnchor)
            centerXAnchor.isActive = true
            label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
            label.widthAnchor.constraint(equalToConstant: 150).isActive = true
            label.heightAnchor.constraint(equalToConstant: 150).isActive = true
            label.alpha = 0
        }
        
        btnHome.isHidden = true
        btnRetake.isHidden = true
        btnVideoConfirm.isHidden = true
        
        captureBGView.isHidden = true
        
        openCamera()
        appDelegate.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(replayVideo), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        btnVideoPlay.isHidden = true
        viewForSubmit.isHidden = true
        imgEmailSent.isHidden = true
        btnRecord.isHidden = false
    }
    
    @IBAction func actionRecord(_ sender: Any) {
        btnRecord.isHidden = true
        countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(startCountdown), userInfo: nil, repeats: true)
    }
    
    @objc func startCountdown(){
        if(count > 0){
            count -= 1
            self.labels[self.count].alpha = 1
            DispatchQueue.main.async {
                UIView.animate(withDuration: 1, delay: 0) {
                    self.centerXConstraints[self.count].constant = 250
                    self.labels[self.count].alpha = 0
                    self.view.layoutIfNeeded()
                } completion: { isCompleted in
                    if(isCompleted){
//                        if(self.count == 0){
//                            for i in 0...4{
//                                self.centerXConstraints[i].constant = -100
//                            }
//                        }
                    }
                }

            }
        } else {
            countdownTimer.invalidate()
            if(labels.count > 0){
                recordingRedView.isHidden = false
                let date = Date()
                let milliseconds = Int(date.timeIntervalSince1970 * 1000)
                if let url = DocumentDirectory.appendingPathComponent(folderNames[0])?.appendingPathComponent("\(milliseconds)").appendingPathExtension("mp4"){
                    try? FileManager.default.removeItem(at: url)
                    fileOutput.startRecording(to: url, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
                    print("Video Capture Started")
                }
                Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(stopRecording), userInfo: nil, repeats: false)
                for i in 0...4{
                    centerXConstraints[i].constant = -100
                }
                view.layoutIfNeeded()
            }
        }
    }
    
    @IBAction func actionReplay(_ sender: Any) {
        avplayer.seek(to: CMTime.zero)
        avplayer.play()
        btnVideoPlay.isHidden = true
    }
    
    @objc func replayVideo(){
        btnVideoPlay.isHidden = false
        VIEWFORVIDEO.bringSubviewToFront(btnVideoPlay)
    }
    
    @IBAction func recapture(_ sender: Any) {
        count = 5
        stopRecording()
        avplayer.pause()
        openCamera()
        if(labels.count > 0){
            for i in 0...4{
                centerXConstraints[i].constant = -100
            }
            view.layoutIfNeeded()
        }
        //countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(startCountdown), userInfo: nil, repeats: true)
    }
    
    @IBAction func actionVideoConfirm(_ sender: Any) {
        viewForSubmit.isHidden = false
        //sendMail()
    }
    
    @IBAction func closeSubmitScreen(_ sender: Any) {
        viewForSubmit.isHidden = true
        imgEmailSent.isHidden = true
    }
    
    @IBAction func actionSendEmail(_ sender: Any) {
        fldEmail.resignFirstResponder()
        btnSubmissionClose.isUserInteractionEnabled = false
        let btn = sender as! UIButton
        btn.isUserInteractionEnabled = false
        
//        imgEmailSent.isHidden = false
//        viewForSubmit.isHidden = true
        playAnim()
        sendMail()
        
    }
    
    @objc func dismissHomeWithDelay(){
        if(VIEWFORVIDEO.isHidden == false){
            avplayer.pause()
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
        avplayer.pause()
        self.view.window?.rootViewController?.dismiss(animated: false)
    }
    
    func sendMail(){
        
        if(fileURL != nil){
            do {
                let file: Data = try Data(contentsOf: fileURL!)
                print(file.count)
                if let url = URL(string: "http://15.187.43.17:8000/FileUpload"){
                    let headers = [
                        "Content-type": "multipart/form-data"
                    ]
                    if let mail = fldEmail.text {
                        var mailString = ""
                        if(mail.count > 0){
                            mailString = mail
                            AF.upload(multipartFormData: { multipartFormData in
                                multipartFormData.append(file, withName: "file",fileName: "myVideo")
                                multipartFormData.append(mailString.data(using: .utf8)!, withName: "mail")
                            }, to: url).responseString { response in
                                print(response)
                                if(response.response?.statusCode == 200){
                                    self.viewForSubmit.isHidden = true
                                    self.imgEmailSent.isHidden = false
                                    self.animationView.isHidden = true
                                }
                            }
                        }



                    }
                    
//                    AF.upload(multipartFormData: { multipartFormData in
//                        multipartFormData.append(file, withName: "file",fileName: "myVideo")
//                        multipartFormData.append("kohlermiddleeastcommunication@kohler.com".data(using: .utf8)!, withName: "mail")
//                    }, to: url).responseString { response in
//                        print(response)
//                        if(response.response?.statusCode == 200){
//                            self.viewForSubmit.isHidden = true
//                            self.imgEmailSent.isHidden = false
//                            self.animationView.isHidden = true
//                            Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.dismissHomeWithDelay), userInfo: nil, repeats: false)
//                        }
//                    }
                    //let boundary: String = "Boundary- \(UUID().uuidString)"
                    
                    
                
//                var multipart = MultipartRequest()
//                if let mail = fldEmail.text {
//                    if(mail.count > 0){
//                        multipart.add(key: "mail", value: mail)
//                    } else {
//                        multipart.add(key: "mail", value: "kohlermiddleeastcommunication@kohler.com")
//                    }
//                } else {
//                    multipart.add(key: "mail", value: "kohlermiddleeastcommunication@kohler.com")
//                }
//
//
//
//                multipart.add(key: "file", fileName: "something.mp4", fileMimeType: "video/mp4", fileData: file)
//
//                if let url = URL(string: "http://15.184.55.228:8080/FileUpload"){
//                    var request = URLRequest(url: url)
//                    request.httpMethod = "POST"
//                    request.setValue(multipart.httpContentTypeHeadeValue, forHTTPHeaderField: "Content-Type")
//                    request.httpBody = multipart.httpBody
//                    URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
//                        if(error != nil){
//                            print(error?.localizedDescription)
//                            print("SOMETHING WENT WRONG")
//                            return
//                        } else {
//                            print((response as! HTTPURLResponse).statusCode)
//                            print(String(data: data!, encoding: .utf8))
//                            Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.dismissHomeWithDelay), userInfo: nil, repeats: false)
//                        }
//
//                    })
                } else {
                    print("URL ERROR")
                    self.viewForSubmit.isHidden = true
                    self.imgEmailSent.isHidden = false
                    self.animationView.isHidden = true
                    Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.dismissHomeWithDelay), userInfo: nil, repeats: false)
                }
            } catch {
                print(error.localizedDescription)
                self.viewForSubmit.isHidden = true
                self.imgEmailSent.isHidden = false
                self.animationView.isHidden = true
                Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.dismissHomeWithDelay), userInfo: nil, repeats: false)
            }
        } else {
            print("FILE URL NIL")
            self.viewForSubmit.isHidden = true
            self.imgEmailSent.isHidden = false
            self.animationView.isHidden = true
            Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.dismissHomeWithDelay), userInfo: nil, repeats: false)
        }
        
        
        
    }
    
    func openCamera(){
        imgFrame.isHidden = false
        captureBGView.isHidden = true
        btnHome.isHidden = true
        btnRetake.isHidden = true
        btnVideoConfirm.isHidden = true
        switch(AVCaptureDevice.authorizationStatus(for: .video)){
        case .restricted:
            print("restricted")
            requestVideoCapture()
        case .authorized:
            print("Camera Permission access has been given")
            setupCamera()
            addCameraToSession()
        case .denied:
            requestVideoCapture()
            print("denied")
        case .notDetermined:
            requestVideoCapture()
            print("not determined")
        default:
            break
        }
    }
    
    //Setup Camera
    func setupCamera(){
        VIEWFORVIDEO.isHidden = true
        //recordingRedView.isHidden = false
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front){
            do{
                isDeviceFound = true
                cameraDevice = device
                print("Found Front Camera")
            }
        }
    }
    
    //Configure and Setup Camera Session
    func addCameraToSession(){
        if(cameraDevice != nil){
            print("camera is not nil")
            do {
                cameraSession.beginConfiguration()
                
                // Add camera to your session
                let deviceInput = try AVCaptureDeviceInput(device: cameraDevice!)
                if(cameraSession.canAddInput(deviceInput)){
                    cameraSession.addInput(deviceInput)
                }
                cameraSession.sessionPreset = .hd1920x1080
                
                //Define your video output
                videoDataOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                videoDataOutput.alwaysDiscardsLateVideoFrames = true
                
                if cameraSession.canAddOutput(videoDataOutput){
                    videoDataOutput.setSampleBufferDelegate(self, queue: queue)
                    cameraSession.addOutput(videoDataOutput)
                }
                
                if(cameraSession.canAddOutput(fileOutput)){
                    cameraSession.addOutput(fileOutput)
                }
                
                cameraSession.commitConfiguration()
                
                //Present the preview of video
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: cameraSession)
                videoPreviewLayer.frame = self.view.bounds
                videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                videoPreviewLayer.backgroundColor = UIColor.red.cgColor
                self.view.layer.addSublayer(videoPreviewLayer)
                
                DispatchQueue.global(qos: .background).async {
                    self.cameraSession.startRunning()
                }
                
                btnVideoConfirm.isHidden = true
                recordingRedView.isHidden = false
                btnRecord.isHidden = true
                view.bringSubviewToFront(imgFrame)
                VIEWFORVIDEO.bringSubviewToFront(btnRecord)
                //deleteTempFileIfExists()
                
//                let date = Date()
//                let milliseconds = Int(date.timeIntervalSince1970 * 1000)
//                if let url = DocumentDirectory.appendingPathComponent(folderNames[0])?.appendingPathComponent("\(milliseconds)").appendingPathExtension("mp4"){
//                    try? FileManager.default.removeItem(at: url)
//                    fileOutput.startRecording(to: url, recordingDelegate: self as AVCaptureFileOutputRecordingDelegate)
//                    print("Video Capture Started")
//                }
//                Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(stopRecording), userInfo: nil, repeats: false)
            } catch let error {
                print("Error occured while adding input to session, Error: \(error.localizedDescription)")
            }
            
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        fileURL = outputFileURL
        print("RECORDING FINISHED" + outputFileURL.absoluteString)
        
        
        addWaterMark(videoURL: outputFileURL)
        //self.mergeFilesWithUrl(videoUrl: fileURL!, audioUrl: Bundle.main.url(forResource: "audio", withExtension: ".mp3")!)
    }
    
    //There is only one same method for both of these delegates
    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                       from connection: AVCaptureConnection!) {
        //The detect faces, overlay video will happen here]
        print("Camera Device Output: ",sampleBuffer.totalSampleSize)
    }
    
    func addWaterMark(videoURL: URL){
        deleteTempFileIfExists()
        if let item = MediaItem(url: videoURL){
            if let logoImage = UIImage(named: "1-06"){
                let firstElement = MediaElement(image: logoImage)
                firstElement.frame = CGRect(x: 0, y: 0, width: logoImage.size.width, height: logoImage.size.height)
                
                item.add(element: firstElement)
                let mediaProcessor = MediaProcessor()
                
                mediaProcessor.processElements(item: item) { result, error in
                    if(error == nil){
                        
                        self.mergeFilesWithUrl(videoUrl: result.processedUrl!, audioUrl: Bundle.main.url(forResource: "audio", withExtension: ".mp3")!)
                    } else {
                        print("Overlay Result Error: \(String(describing: error?.localizedDescription))")
                    }
                    
                }
                
            }
        }
    }
    
    func mergeFilesWithUrl(videoUrl:URL, audioUrl:URL)
    {
        deleteTempFileIfExistsBNI()
        let mixComposition : AVMutableComposition = AVMutableComposition()
        var mutableCompositionVideoTrack : [AVMutableCompositionTrack] = []
        var mutableCompositionAudioTrack : [AVMutableCompositionTrack] = []
        let totalVideoCompositionInstruction : AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        
        
        //start merge
        
        let aVideoAsset : AVAsset = AVAsset(url: videoUrl)
        let aAudioAsset : AVAsset = AVAsset(url: audioUrl)
        
        mutableCompositionVideoTrack.append(mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        mutableCompositionAudioTrack.append( mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!)
        
        let aVideoAssetTrack : AVAssetTrack = aVideoAsset.tracks(withMediaType: .video)[0]
        let aAudioAssetTrack : AVAssetTrack = aAudioAsset.tracks(withMediaType: .audio)[0]
        
        
        
        do{
            try mutableCompositionVideoTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aVideoAssetTrack, at: CMTime.zero)
            
            //In my case my audio file is longer then video file so i took videoAsset duration
            //instead of audioAsset duration
            
            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration), of: aAudioAssetTrack, at: CMTime.zero)
            
            //Use this instead above line if your audiofile and video file's playing durations are same
            
            //            try mutableCompositionAudioTrack[0].insertTimeRange(CMTimeRangeMake(kCMTimeZero, aAudioAssetTrack.timeRange.duration), ofTrack: aAudioAssetTrack, atTime: kCMTimeZero)
            
        }catch{
            print("merge files" + error.localizedDescription)
        }
        
        totalVideoCompositionInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero,duration: aVideoAssetTrack.timeRange.duration )
        
        let mutableVideoComposition : AVMutableVideoComposition = AVMutableVideoComposition()
        mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        //mutableVideoComposition
        
        //mutableVideoComposition.renderSize = CGSizeMake(720,1280)
        
        //        playerItem = AVPlayerItem(asset: mixComposition)
        //        player = AVPlayer(playerItem: playerItem!)
        //
        //
        //        AVPlayerVC.player = player
        
        
        
        //find your video on this URl
        //let savePathUrl : NSURL = NSURL(fileURLWithPath: NSHomeDirectory() + "/Documents/newVideo.mp4")
        
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPreset1280x720)!
        assetExport.outputFileType = AVFileType.mp4
        let date = Date()
        let milliseconds = Int(date.timeIntervalSince1970 * 1000)
        fileURL = DocumentDirectory.appendingPathComponent(folderNames[0])?.appendingPathComponent("\(milliseconds)").appendingPathExtension("mp4")
        assetExport.outputURL = fileURL
        assetExport.shouldOptimizeForNetworkUse = true
        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
                
            case AVAssetExportSession.Status.completed:
                
                //Uncomment this if u want to store your video in asset
                
                //let assetsLib = ALAssetsLibrary()
                //assetsLib.writeVideoAtPathToSavedPhotosAlbum(savePathUrl, completionBlock: nil)
//                self.avplayer = AVPlayer(url: self.fileURL!)
//                let playerLayer = AVPlayerLayer(player: self.avplayer)
//                playerLayer.frame = self.VIEWFORVIDEO.layer.bounds
//                self.VIEWFORVIDEO.layer.addSublayer(playerLayer)
//                self.avplayer.externalPlaybackVideoGravity = .resizeAspectFill
//                self.avplayer.play()
                
                
                
                print("success")
                
                DispatchQueue.main.async {
                    self.animationView.isHidden = true
                    self.captureBGView.isHidden = true
                    self.btnVideoConfirm.isHidden = false
                    self.btnHome.isHidden = false
                    self.btnRetake.isHidden = false
                    self.btnVideoConfirm.isHidden = false
                    self.imgFrame.isHidden = true
                    self.avplayer = AVPlayer(url: self.fileURL!)
                    let playerLayer = AVPlayerLayer(player: self.avplayer)
                    playerLayer.frame = self.VIEWFORVIDEO.layer.bounds
                    self.VIEWFORVIDEO.layer.addSublayer(playerLayer)
                    self.avplayer.externalPlaybackVideoGravity = .resizeAspectFill
                    self.avplayer.play()
                }
                
            case  AVAssetExportSession.Status.failed:
                print("failed \(String(describing: assetExport.error?.localizedDescription))")
            case AVAssetExportSession.Status.cancelled:
                print("cancelled \(String(describing: assetExport.error?.localizedDescription))")
            default:
                print("complete")
            }
        }
    }
    
    func presentEmailController(){
        let vc = storyboard?.instantiateViewController(withIdentifier: "EmailShareController") as! EmailShareController
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .fullScreen
        vc.fileURL = fileURL
        present(vc, animated: true)
    }
    
    func deleteTempFileIfExists(){
        do {
             let fileManager = FileManager.default
            
            // Check if file exists
            if fileManager.fileExists(atPath: (DocumentDirectory.appendingPathComponent("processed")?.appendingPathExtension("mp4").path)!) {
                // Delete file
                try fileManager.removeItem(at: DocumentDirectory.appendingPathComponent("processed")!.appendingPathExtension("mp4"))
            } else {
                print("File does not exist")
            }
         
        }
        catch let error as NSError {
            print("An error took place: \(error)")
        }
    }
    
    func deleteTempFileIfExistsBNI(){
        do {
             let fileManager = FileManager.default
            
            // Check if file exists
            if fileManager.fileExists(atPath: fileURL!.path) {
                // Delete file
                do {
                    try fileManager.removeItem(at: fileURL!)
                } catch {
                    print("DELETE TEMP FILE KOHLER FOLDER" + error.localizedDescription)
                }
            } else {
                print("File does not exist BNI")
            }
         
        }
        catch let error as NSError {
            print("An error took place: \(error)")
        }
    }
    
    func playAnim(){
        animationView.isHidden = false
        if let animation = LottieAnimation.named("loading") {
            animationView.animation = animation
            animationView.loopMode = .loop
            animationView.play()
        }
    }
    
    @objc func stopRecording(){
        animationView.isHidden = false
        playAnim()
        
        captureBGView.isHidden = true
        imgFrame.isHidden = true
        videoPreviewLayer.removeFromSuperlayer()
        recordingRedView.isHidden = true
        VIEWFORVIDEO.isHidden = false
        stopCameraSession()
        fileOutput.stopRecording()
        print("Camera Recording \(cameraSession.isRunning)")
    }
    
    func requestVideoCapture(){
        AVCaptureDevice.requestAccess(for: .video, completionHandler: {result in
            if(result){
                print("Camera Permission has been given")
            } else{
                self.showSimpleAlert(title: "Camera Not Found", message: "Please give permissions to access camera")
            }
        })
    }
    
    func showSimpleAlert(title: String,message: String){
        DispatchQueue.main.async {
            let alert:UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default,handler: {_ in
                alert.dismiss(animated: true)
            }))
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func dismissCurrent(_ sender: Any) {
        if(VIEWFORVIDEO.isHidden == false){
            avplayer.pause()
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
        avplayer.pause()
        dismiss(animated: true)
    }
    
    @IBAction func dismissHome(_ sender: Any) {
        if(VIEWFORVIDEO.isHidden == false){
            avplayer.pause()
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
        avplayer.pause()
        self.view.window?.rootViewController?.dismiss(animated: false)
    }
    
}

