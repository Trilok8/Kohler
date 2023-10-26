//
//  StartController.swift
//  BNIVideoBooth
//
//  Created by Altaf Razzaque on 11/01/2023.
//

import UIKit

let folderNames = ["Kohler"]

class StartController: NoBarsController {

    let fileManager = FileManager.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var isDir: ObjCBool = true
        
        
        for i in folderNames {
            let path = DocumentDirectory.appendingPathComponent(i)
            if fileManager.fileExists(atPath: path!.path, isDirectory: &isDir) {
                print(isDir.boolValue ? "Directory exists": "File exists---",path?.path)
            } else {
                do {
                    try fileManager.createDirectory(at: path!, withIntermediateDirectories: true, attributes: [:])
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    
    @IBAction func goToNext(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "VideoRecordController") as! VideoRecordController
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
}
