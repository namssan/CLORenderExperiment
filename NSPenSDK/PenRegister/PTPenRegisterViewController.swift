//
//  INPenRegisterViewController.swift
//  IdeaNotes
//
//  Created by Sang Nam on 30/12/16.
//  Copyright © 2016 Sang Nam. All rights reserved.
//

import UIKit
import BAFluidView
import CoreData

class PTPenRegisterViewController: UIViewController {


    @IBOutlet weak var connectBtn: UIButton!
    @IBOutlet weak var viewUpper: UIView!
    @IBOutlet weak var bgCircle: UIView!
    @IBOutlet weak var penImgView: UIImageView!
    
    
    @IBOutlet weak var passwdTextField: UITextField!
    @IBOutlet weak var labelContainer: UIView!
    @IBOutlet weak var p1Label: UILabel!
    @IBOutlet weak var p2Label: UILabel!
    @IBOutlet weak var p3Label: UILabel!
    @IBOutlet weak var p4Label: UILabel!
    @IBOutlet weak var msgLabel: UILabel!
    @IBOutlet weak var LCMsgLabelBottomMargin: NSLayoutConstraint!
    @IBOutlet weak var LCMsgLabelTopMargin: NSLayoutConstraint!
    
    @IBOutlet weak var flashContainer: UIView!
    @IBOutlet weak var flash: UIView!
    @IBOutlet weak var light1: UIView!
    @IBOutlet weak var light2: UIView!
    @IBOutlet weak var light3: UIView!
    @IBOutlet weak var light4: UIView!
    @IBOutlet weak var light5: UIView!
    @IBOutlet weak var light6: UIView!
    @IBOutlet weak var light7: UIView!
    
    
    
    var a =  [INPenInfoEntity]()

    var penInfos : [NPPenRegInfo] = [NPPenRegInfo]()
    var penCommunicating = false
    var tryPasswd : String = "0000"
    let kPENINFO_KEY_LOCAL = "idea.notes.peninfos"
    let kPENINFO_KEY_CLOUD = "ipeninfos"

    var isAskingPasswd : Bool = false
    var isFirstCall : Bool = true
    var countLeft : Int = 0
    var isInProcess : Bool = false
    var isFirst : Bool = true
    var isPasswdCreating : Bool = false
    var isRegisterBtnPressed : Bool = false
    var isForPenRegistration : Bool = false {
        
        didSet {
            msgLabel.textColor = .darkGray
            if(isForPenRegistration) {
                self.flashContainer.isHidden = false
                self.msgLabel.text = NSLocalizedString("PCVC_INFO_REGISTER", comment: "")
                self.connectBtn.setTitle(NSLocalizedString("PCVC_BTN_REGISTER", comment: ""), for: .normal)
                self.animateLightEffet()
            } else {
                self.flashContainer.isHidden = true
                self.msgLabel.text = NSLocalizedString("PCVC_INFO_INIT", comment: "")
                self.connectBtn.setTitle(NSLocalizedString("PCVC_BTN_CONNECT", comment: ""), for: .normal)
            }
        }
    }
    
    lazy var fluidView : BAFluidView = {
        
        var view = BAFluidView(frame: CGRect(x:0.0, y: 0.0, width: self.bgCircle.frame.size.width, height: self.bgCircle.frame.size.height))
        view.fillColor = UIColor(hex: 0x4384FF)
        view.fillAutoReverse = false;
        view.fillRepeatCount = 1;
        view.maxAmplitude = 15
        view.lineWidth = 3
        
        
        let maskPath = UIBezierPath(roundedRect: self.bgCircle.bounds, cornerRadius: self.bgCircle.bounds.size.width/2.0)
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bgCircle.bounds
        maskLayer.path = maskPath.cgPath
        view.layer.mask = maskLayer
        
        self.bgCircle.addSubview(view)
        
        return view
    } ()
    
    var waterView : UIView?
    var shapeLayer : CAShapeLayer?
    var shapeLayer2 : CAShapeLayer?
    let t2 = CGAffineTransform(rotationAngle: -CGFloat(M_PI_2)/3.0 * 2.0)
    let t3 = CGAffineTransform(rotationAngle: -CGFloat(M_PI_2)/3.0)
    let t5 = CGAffineTransform(rotationAngle: CGFloat(M_PI_2)/3.0)
    let t6 = CGAffineTransform(rotationAngle: CGFloat(M_PI_2)/3.0 * 2.0)

    
    @IBAction func connectBtnPressed(_ sender: Any) {
        
        if(isForPenRegistration) {
            registerPen()
        } else {
            connectPen()
        }
        
    }
    @IBAction func registerPen() {
        
        isRegisterBtnPressed = true
        if(penInfos.count >= 20) {
            let alertVC = UIAlertController(title: "Info", message: "You can add upto 20 registration. please delete un-used registration and try again", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                
            })
            alertVC.addAction(okAction)
            self.present(alertVC, animated: true, completion: { 
                
            })
            return
        }
        
        
        penCommunicating = true
        NPCommManager.sharedInstance().btStartForRegister()
        
        self.fluidView.fillDuration = 13.0
//        self.fluidView.fillColor = UIColor(hex: 0xdc3c37)
        self.fluidView.fill(to: NSNumber(value: 0.9))
        self.fluidView.startAnimation()
        
        updateBtns()
    }
    
    
    @IBAction func connectPen() {
        
        
        isRegisterBtnPressed = false
        penCommunicating = true
        NPCommManager.sharedInstance().btStart()
        
        self.fluidView.fillDuration = 6.0
//        self.fluidView.fillColor = UIColor(hex: 0x397ebe)
        self.fluidView.fill(to: NSNumber(value: 0.9))
        self.fluidView.startAnimation()
        
        updateBtns()
    }
    
    @IBAction func bgTapped(_ sender: Any) {
        
        if(penCommunicating) { return }
        self.dismiss(animated: true) {
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        loadPenInfos()
        updateBtns()
        NPCommManager.sharedInstance().delegatePenConnect = self
        NPCommManager.sharedInstance().delegatePenPassword = self
        
        if(NPCommManager.sharedInstance().isPenConnected) {
            self.fluidView.fillDuration = 0.5 
            self.fluidView.fill(to: NSNumber(value:0.9))
            self.fluidView.startAnimation()
            let uuid = NPCommManager.sharedInstance().penUUID
            print("registered uuid: \(uuid)")
        }

        
        passwdTextField.delegate = self
        passwdTextField.addTarget(self, action: #selector(didPasswdChange(_:)), for: .editingChanged)
        
        
        let hasPenRegistration = (self.penInfos.count > 0)
        if(hasPenRegistration) {
            isForPenRegistration = false
        } else {
            isForPenRegistration = true
        }
        
        self.bgCircle.backgroundColor = UIColor.clear
        
        self.light2.transform = t2
        self.light3.transform = t3
        self.light5.transform = t5
        self.light6.transform = t6
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(penConnectionStatusChange(_:)), name: NSNotification.Name(rawValue: NPConnectionStatusNotification), object: nil)
        nc.addObserver(self, selector: #selector(penDidRegister(_:)), name: NSNotification.Name(rawValue: NPRegistrationNotification), object: nil)
        
//        nc.addObserver(self, selector: #selector(penPasswordCompareSuccess(_:)), name: NSNotification.Name(rawValue: NPCommManagerPenConnectionStatusChangeNotification), object: nil)
        nc.addObserver(self, selector: #selector(penPasswordValidationFail(_:)), name: NSNotification.Name(rawValue: NPPasswordValidationFailNotification), object: nil)
        
//        let store = NSUbiquitousKeyValueStore.default
//        nc.addObserver(self, selector: #selector(updateKeyValueParis(_:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: store)
//
//        store.synchronize()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        let nc = NotificationCenter.default
        nc.removeObserver(NPConnectionStatusNotification)
        nc.removeObserver(NPRegistrationNotification)
        nc.removeObserver(NSUbiquitousKeyValueStore.didChangeExternallyNotification)
//        nc.removeObserver(NPCommManagerPenConnectionStatusChangeNotification)
        nc.removeObserver(NPPasswordValidationFailNotification)
        
        if(isAskingPasswd) {
            print("DISCONNECT PEN MANUALL")
            NPCommManager.sharedInstance().disConnect()
        }
        super.viewWillDisappear(animated)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if(isFirstCall) {
            isFirstCall = false
            self.startAnimation()
        }
        
        connectBtn.layer.cornerRadius = 20.0
    }

    func loadPenInfos() {
        
        penInfos.removeAll()
        let context = PTDBManager.sharedInstance.moc
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "INPenInfoEntity")
    
        let sd1 = NSSortDescriptor(key: "dateLastUse", ascending: false)
        let sd2 = NSSortDescriptor(key: "penName", ascending: true)
        fetchRequest.sortDescriptors = [sd1,sd2]
        
        let results = try! context.fetch(fetchRequest) as! [INPenInfoEntity]
        for info in results {
            
            let p = NPPenRegInfo()
            p.penMac = info.penMac
            p.penName = info.penName
            p.penPasswd = info.penPasswd
            p.dateLastUse = info.dateLastUse
            p.dateRegister = info.dateRegister
            
            print("saving: pen \(info.penName)----> \(info.penPasswd)")
            penInfos.append(p)
        }
        print("successfully loaded pen infos : \(penInfos.count)")
        
    }
    
    func savePenInofs(localOnly : Bool) {
        
        let localMoc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        localMoc.parent = PTDBManager.sharedInstance.moc
        localMoc.performAndWait({
            
            do {
                // delete whole penInfos first
                let fetchRequest  = NSFetchRequest<NSFetchRequestResult>(entityName: "INPenInfoEntity")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try localMoc.execute(deleteRequest)
                try localMoc.save()
                
                for info in self.penInfos {
                
                    let entry = NSEntityDescription.insertNewObject(forEntityName: "INPenInfoEntity", into: localMoc) as! INPenInfoEntity
                    entry.penMac = info.penMac
                    entry.penName = info.penName
                    entry.penPasswd = info.penPasswd
                    entry.dateLastUse = info.dateLastUse!
                    entry.dateRegister = info.dateRegister!
                    
                    print("saving: pen \(info.penName)----> \(info.penPasswd)")
                }
                
                try localMoc.save()

            } catch {
                
            }
            
        })
        
        PTDBManager.sharedInstance.saveContext(wait: true)
        
        if(localOnly) { return }
        
        // save to iCloud
//        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: penInfos)
//        print("save peninfos into cloud \(penInfos.count)")
//        let store = NSUbiquitousKeyValueStore.default
//        store.set(encodedData, forKey: kPENINFO_KEY_CLOUD)
//        store.synchronize()

    }
    
    func startAnimation() {
        
        self.addCircleLayer()
        
        CATransaction.begin()
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.duration = 1.0
        anim.fromValue = NSNumber(value: 0.0)
        anim.toValue = NSNumber(value: 1.0)
        CATransaction.setCompletionBlock {
            self.animateLightEffet()
        }
        self.shapeLayer2?.add(anim, forKey: "strokeEnd")
        CATransaction.commit()
        
    }
    
    func addCircleLayer() {
        
        if(self.waterView == nil) {
            
            let frame = CGRect(x: 0, y: 0, width: self.bgCircle.bounds.size.width, height: self.bgCircle.bounds.size.height)
            self.waterView = UIView(frame: frame)
            
            self.bgCircle.addSubview(waterView!)
            let maskPath = UIBezierPath(roundedRect: self.bgCircle.bounds, cornerRadius: self.bgCircle.bounds.size.width/2.0)
            let maskLayer = CAShapeLayer()
            maskLayer.frame = self.bgCircle.bounds
            maskLayer.path = maskPath.cgPath
            self.waterView?.layer.mask = maskLayer
            
            self.shapeLayer = CAShapeLayer()
            self.shapeLayer!.frame = self.bgCircle.bounds
            self.shapeLayer!.path = maskPath.cgPath
            self.shapeLayer!.lineWidth = 5.0
            self.shapeLayer!.strokeColor = UIColor(hexString: "0xdbdbd5").cgColor
            self.shapeLayer!.fillColor = UIColor.clear.cgColor
            self.penImgView?.layer.addSublayer(self.shapeLayer!)
            
            self.shapeLayer2 = CAShapeLayer()
            self.shapeLayer2!.frame = self.bgCircle.bounds
            self.shapeLayer2!.path = maskPath.cgPath
            self.shapeLayer2!.lineWidth = 5.0
            self.shapeLayer2!.strokeColor = UIColor(hexString: "51BED7").cgColor
            self.shapeLayer2!.fillColor = UIColor.clear.cgColor
            self.shapeLayer2!.lineCap = kCALineCapRound
            self.penImgView?.layer.addSublayer(self.shapeLayer2!)
            
        }
    }
    
    
    func animateLightEffet() {
        
        self.light2.transform = CGAffineTransform(translationX: 0, y: 10)
        self.light3.transform = CGAffineTransform(translationX: 0, y: 10)
        self.light4.transform = CGAffineTransform(translationX: 0, y: 10)
        self.light5.transform = CGAffineTransform(translationX: 0, y: 10)
        self.light6.transform = CGAffineTransform(translationX: 0, y: 10)
        self.light1.transform = CGAffineTransform(translationX: 10, y: 0)
        self.light7.transform = CGAffineTransform(translationX: -10, y: 0)
        
        self.light1.alpha = 0.0
        self.light2.alpha = 0.0
        self.light3.alpha = 0.0
        self.light4.alpha = 0.0
        self.light5.alpha = 0.0
        self.light6.alpha = 0.0
        self.light7.alpha = 0.0
        self.flash.alpha = 0.3
        
        UIView.animate(withDuration: 1.1, delay: 0.67, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.0, options:  [.repeat, .curveEaseInOut], animations: {
            
            self.light1.transform = .identity
            self.light2.transform = self.t2
            self.light3.transform = self.t3
            self.light4.transform = .identity
            self.light5.transform = self.t5
            self.light6.transform = self.t6
            self.light7.transform = .identity
            self.light1.alpha = 1.0
            self.light2.alpha = 1.0
            self.light3.alpha = 1.0
            self.light4.alpha = 1.0
            self.light5.alpha = 1.0
            self.light6.alpha = 1.0
            self.light7.alpha = 1.0
            self.flash.alpha = 1.0
            
        }) { (finished) in
            
        }
    }

    
    func updateBtns() {
        
        let connected = NPCommManager.sharedInstance().isPenConnected
        
        if(connected || penCommunicating) {
            btnEnable(btn: connectBtn, enable: false)
//            statusLabel.isHidden = false
            if(connected) {
//                statusLabel.text = "connected"
//                statusLabel.textColor = UIColor.white
            } else {
                if(isRegisterBtnPressed) {
//                    statusLabel.text = "finding new pen..."
                } else {
//                    statusLabel.text = "connecting..."
                }
//                statusLabel.textColor = UIColor.darkGray
            }
            
        } else {
        
            btnEnable(btn: connectBtn, enable: true)
        }
    }
    
    func btnEnable(btn : UIButton, enable : Bool) {
        
        btn.isEnabled = enable
        btn.alpha = (enable) ? 1.0 : 0.5
    }
    
    
    
//    func encodeObject(_ object : NSCoding) -> Data {
//        
//        let data = NSMutableData()
//        let archiver = NSKeyedArchiver(forWritingWith: data)
//        archiver.encode(object, forKey: "data")
//        archiver.finishEncoding()
//        
//        return data as Data
//    }
//    
//    
//    func decodeObject(_ object : Data) -> AnyObject? {
//        
//        let unarchiver = NSKeyedUnarchiver.init(forReadingWith: object)
//        return unarchiver.decodeObject(forKey: "data") as AnyObject?
//    }
//    
    
    func addNewRegistration(penName: String,mac : String) {
        
        let penInfo = NPPenRegInfo()
        penInfo.penName = penName
        penInfo.penMac = mac
        penInfo.dateRegister = Date()
        penInfo.dateLastUse = Date()
        
        if(!penInfos.contains(penInfo)) {
            penInfos.insert(penInfo, at: 0)
            self.savePenInofs(localOnly: false)
        }
    }

}




extension PTPenRegisterViewController  {
    
    @objc func penConnectionStatusChange(_ notification : NSNotification) {
        
        let dic = notification.userInfo!
        let info : NSNumber = dic["info"] as! NSNumber
        let status : Int = info.intValue
        let uuid = dic["uuid"] as! String
        
        
        if(status == NPConnectionStatus.scanStarted.rawValue) {
            print("scan started...\(uuid)")

        } else if(status == NPConnectionStatus.connected.rawValue) {
            print("connected!!...\(uuid)")
            
            penPasswordCompareSuccess()
            penCommunicating = false
            updateBtns()
            
//            PTSettingStore.sharedInstance.penLastUseMac = uuid
            dismiss(animated: true, completion: {
                
            })
            
        } else if(status == NPConnectionStatus.disconnected.rawValue) {
            print("dis-connected!!...\(uuid)")
            penCommunicating = false
            updateBtns()
            
            if(NPCommManager.sharedInstance().penConnectionTrace == NPConnectionTrace.noMac) {
                print("THIS MUST BE NEW DEVICE TRY REGISTRATION")
                isForPenRegistration = true
            } else {
                if(!isRegisterBtnPressed) {
                    self.msgLabel.text = NSLocalizedString("PCVC_INFO_NO_PEN", comment: "")
                }
                self.connectBtn.setTitle(NSLocalizedString("PCVC_BTN_TRY_AGAIN", comment: ""), for: .normal)
            }
            
            self.fluidView.fillDuration = 1.0
            self.fluidView.fill(to: NSNumber(value:0.01))
            self.fluidView.startAnimation()
        }
    }
    
    
    @objc func penDidRegister(_ notification : NSNotification) {
        
        let dic = notification.userInfo!
        let penName = dic["pen_name"] as! String
        let mac = dic["uuid"] as! String
        
        print("got registered...\(penName) --- \(mac)")
        addNewRegistration(penName: penName, mac: mac)
    }
    
    
//    @objc func updateKeyValueParis(_ notification : NSNotification) {
//
//        let dic = notification.userInfo!
//        let changeReason = dic[NSUbiquitousKeyValueStoreChangeReasonKey] as! NSNumber
//        let reason = changeReason.intValue
//
//        if((reason == NSUbiquitousKeyValueStoreServerChange) || (reason == NSUbiquitousKeyValueStoreInitialSyncChange)) {
//
//            let changedKeys = dic[NSUbiquitousKeyValueStoreChangedKeysKey] as! [String]
//            let store = NSUbiquitousKeyValueStore.default
//
//            for key in changedKeys {
//
//                print("we have changed key from cloud ---> \(key)")
//                if let data = store.object(forKey: kPENINFO_KEY_CLOUD) as? Data {
//                    penInfos = NSKeyedUnarchiver.unarchiveObject(with: data) as! [NPPenRegInfo]
//                    penInfos = penInfos.sorted { $0.dateLastUse > $1.dateLastUse }
//                    savePenInofs(localOnly: true)
//                    updateBtns()
//                }
//
//            }
//        }
//
//    }
}



extension PTPenRegisterViewController : NPPenConnectDelegate {
    
    func penInfoList() -> [NPPenRegInfo]! {
        return penInfos
    }
}


extension PTPenRegisterViewController : NPPenPasswordDelegate {
    
    func performComparePassword(withCount countLeft: Int32) {
        
        isPasswdCreating = true
        self.countLeft = Int(countLeft)
        
        showPasswdInput(show: true)
        
        userInputErrorShake()
        passwdTextField.text = ""
        updatePassLabels()
        updateMsgString()
        
    }
    
    func showPasswdInput(show : Bool) {
        
        if(show) {
            isAskingPasswd = true
//            LCMsgLabelBottomMargin.constant = UIDevice.isIphoneX ? 50.0 : 25.0
//            LCMsgLabelTopMargin.constant = UIDevice.isIphoneX ? 10.0 : 20.0
        } else {
            isAskingPasswd = false
            LCMsgLabelBottomMargin.constant = 5.0
            passwdTextField.endEditing(true)
        }
        
        
        UIView.animate(withDuration: 0.3, animations: { 
            
            if(show) {
                self.penImgView.alpha = 0.0
                self.fluidView.alpha = 0.0
                self.labelContainer.alpha = 1.0
            } else {
                self.penImgView.alpha = 1.0
                self.fluidView.alpha = 1.0
                self.labelContainer.alpha = 0.0
            }
            self.view.layoutIfNeeded()
            
        }) { (completed) in
            
            if(show) {
                self.passwdTextField.becomeFirstResponder()
                
            } else {
                self.passwdTextField.endEditing(true)
            }
        }
        
    }
    
    @objc func penPasswordValidationFail(_ notification : NSNotification) {
        
        self.showPasswdInput(show: false)
        let alertVC = UIAlertController(title: NSLocalizedString("PCVC_POPUP_PWD_FAIL_TITLE", comment: ""), message: NSLocalizedString("PCVC_POPUP_PWD_FAIL_DESC", comment: ""), preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("COMM_OK", comment: ""), style: .default) { (action) in
            
        }
        alertVC.addAction(okAction)
        present(alertVC, animated: true) { 

            if(self.isForPenRegistration) {
                self.isForPenRegistration = true
            } else {
                self.isForPenRegistration = false
            }
        }
        
    }
    
    func penPasswordCompareSuccess() {
        
        if(isPasswdCreating ) {
        
            let passwd = self.passwdTextField.text
            self.passwdTextField.endEditing(true)
            showPasswdInput(show: false)
            let uuid = NPCommManager.sharedInstance().penUUID!
            
            for penInfo in penInfos {
                if(penInfo.penMac.caseInsensitiveCompare(uuid) == .orderedSame) {
                    penInfo.penPasswd = passwd
                    penInfo.dateLastUse = Date()
                }
            }
            self.savePenInofs(localOnly: false)
        }
    }
}

extension PTPenRegisterViewController : UITextFieldDelegate {
    
    @objc func didPasswdChange(_ sender : AnyObject) {
        self.updatePassLabels()
        
        if let passwd = self.passwdTextField.text {
            if(passwd.characters.count == 4) {
                isInProcess = true
                NPCommManager.sharedInstance().setBTComparePassword(passwd)
            }
        }
    }
    
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let newLength = (textField.text?.characters.count)! + string.characters.count - range.length
        var ok : Bool = true
        ok = (newLength <= 4)
        
        if(ok) {
            let alphaSet = NSMutableCharacterSet(charactersIn: "0123456789") as CharacterSet
            ok = (string.trimmingCharacters(in: alphaSet).compare("") == .orderedSame)
        }
        
        return (ok && !self.isInProcess)
    }
    
    
    func updateMsgString() {
        
        passwdTextField.text = ""
        self.updatePassLabels()
        isInProcess = false
        
        var textColor = UIColor.darkGray
        
        if(isFirst) {
            isFirst = false
        } else {
            self.userInputErrorShake()
        }
        
        let format = NSLocalizedString("PCVC_INFO_PWD_GO", comment: "")
        var msg = String(format: format, countLeft)
        if(countLeft <= 1) {
            msg = NSLocalizedString("PCVC_INFO_PWD_LAST", comment: "")
            textColor = UIColor.red
        }
        
        msgLabel.text = msg
        msgLabel.textColor = textColor
    }
    
    func updatePassLabels() {
        
        let passwd = self.passwdTextField.text
        var p1 = "_"
        var p2 = "_"
        var p3 = "_"
        var p4 = "_"
        
        if(!(passwd?.isEmpty)! && (passwd?.characters.count)! > 0) {
            
            let count = passwd?.characters.count
            if(count == 1) {
                p1 = "•"
                
            } else if(count == 2) {
                p1 = "•"
                p2 = "•"
            } else if(count == 3) {
                p1 = "•"
                p2 = "•"
                p3 = "•"
            } else  {
                p1 = "•"
                p2 = "•"
                p3 = "•"
                p4 = "•"
            }
        }
        
        p1Label.text = p1
        p2Label.text = p2
        p3Label.text = p3
        p4Label.text = p4
        
    }

    func userInputErrorShake() {
        
        CATransaction.begin()
        let anim = CAKeyframeAnimation(keyPath: "transform")
        anim.values = [NSValue(caTransform3D : CATransform3DMakeTranslation(-4.0, 0.0, 0.0)),
                       NSValue(caTransform3D : CATransform3DMakeTranslation(4.0, 0.0, 0.0))]
        anim.autoreverses = true
        anim.repeatCount = 2.0
        anim.duration = 0.1
        CATransaction.setCompletionBlock {
            
        }
        self.labelContainer.layer.add(anim, forKey: nil)
        CATransaction.commit()
        
    }
}
