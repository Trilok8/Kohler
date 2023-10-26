//
//  SecondController.swift
//  BNIVideoBooth
//
//  Created by Altaf Razzaque on 11/01/2023.
//

import UIKit

class SecondController: NoBarsController {

    private var count:Int = 5
    private var countdownTimer:Timer = Timer()
    var labels:[UILabel] = []
    var centerXConstraints:[NSLayoutConstraint] = [NSLayoutConstraint]()
    
    override func viewWillAppear(_ animated: Bool) {
        count = 5
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if(labels.count > 0){
            for i in 0...4{
                centerXConstraints[i].constant = -100
            }
            view.layoutIfNeeded()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for i in 1...5{
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.textColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
            label.text = "\(i)"
            label.font = UIFont(name: "HelveticaNeueLTPro-Roman", size: 150)
            label.adjustsFontSizeToFitWidth = true
            self.view.addSubview(label)
            labels.append(label)
            let centerXAnchor = NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: -100)
            centerXConstraints.append(centerXAnchor)
            centerXAnchor.isActive = true
            label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
            label.widthAnchor.constraint(equalToConstant: 150).isActive = true
            label.heightAnchor.constraint(equalToConstant: 150).isActive = true
            label.alpha = 0
        }
        
        // Do any additional setup after loading the view.
//        for family in UIFont.familyNames {
//            print(family)
//            for names in UIFont.fontNames(forFamilyName: family){
//                print("== \(names)")
//            }
//        }
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
            let vc = storyboard?.instantiateViewController(withIdentifier: "VideoRecordController") as! VideoRecordController
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }

    @IBAction func goToNextController(_ sender: Any) {
        countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(startCountdown), userInfo: nil, repeats: true)
        
    }
    
    @IBAction func dismiss(_ sender: Any) {
        dismiss(animated: true)
    }
    
}
