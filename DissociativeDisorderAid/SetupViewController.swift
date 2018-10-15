import UIKit
import AudioToolbox
import Repeat
import UserNotifications

class SetupViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UNUserNotificationCenterDelegate {
    
    @IBOutlet var sessionLengthPickerView: UIPickerView!
    @IBOutlet var intervalValue: UILabel!
    var pickerData: [Int] = [Int]()
    var selectedPickerValue: Int = 0
    let delegate = UIApplication.shared.delegate as! AppDelegate
    var model: CounterModel!
    let userNotificationCenter = UNUserNotificationCenter.current()
    let categoryId = "notificationCategory"
    let stopActionID = "alert.stop"
    let yesActionID = "alert.yes"
    let noActionID = "alert.no"
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model = delegate.model
        sessionLengthPickerView.delegate = self
        sessionLengthPickerView.dataSource = self
//        pickerData = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]
        pickerData = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]  //For Testing
        
        userNotificationCenter.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if granted {
                let yesAction = UNNotificationAction(identifier: self.yesActionID,
                                                      title: "Yes",
                                                      options: [])
                let noAction = UNNotificationAction(identifier: self.noActionID,
                                                      title: "No",
                                                      options: [])
                let stopAction = UNNotificationAction(identifier: self.stopActionID,
                                                      title: "End Session",
                                                      options: [])
                let category = UNNotificationCategory(identifier: self.categoryId,
                                                      actions: [yesAction, noAction, stopAction],
                                                      intentIdentifiers: [],
                                                      options: [.customDismissAction])
                self.userNotificationCenter.setNotificationCategories([category])
                self.userNotificationCenter.delegate = self
            } else {
                print("User denied local notifications access")
            }
        }
        userNotificationCenter.removeAllPendingNotificationRequests()
        
    }
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Button Actions
    
    @IBAction func increaseIntervalButtonClick(_ sender: Any) {
        var value = Int(intervalValue.text!)!
        value += 1
        intervalValue.text = String(value)
    }
    
    @IBAction func decreaseIntervalButtonClick(_ sender: Any) {
        var value = Int(intervalValue.text!)!
        if(value > 0) {
            value -= 1
            intervalValue.text = String(value)
        }
    }
    
    @IBAction func startSessionButtonClick(_ sender: Any) {
        UserDefaults.standard.setValue(intervalValue.text, forKey: "intervals")
        UserDefaults.standard.setValue(selectedPickerValue, forKey: "sessionLength")
        
        if(selectedPickerValue == 0 || intervalValue.text == "0") {
            let alertView = UIAlertController(title: "Choose Value", message: "Select a value for session length and interval", preferredStyle: .alert)
            
            alertView.addAction(UIAlertAction(title:"Ok", style: .cancel, handler: nil))
            
            self.present(alertView, animated: true)
        } else {
            let content = UNMutableNotificationContent()
            content.title = "Alert"
            content.body = "Let us know if the session was useful?"
            content.categoryIdentifier = categoryId
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (Double(selectedPickerValue*60)), repeats: true)
            let request = UNNotificationRequest.init(identifier: "alert",
                                                     content: content,
                                                     trigger: trigger)
            
            self.userNotificationCenter.add(request, withCompletionHandler: { (error) in
                if let error = error {
                    print("Error: \(error)")
                }
            })
            
            delegate.timer = Repeater.every(.seconds(Double(selectedPickerValue*60)), count: Int(intervalValue.text!)) { timer  in
                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                print("Fired")
                self.model.counterInteger += 1
            }
            delegate.timer.start()
            
            let sessionViewController = self.storyboard?.instantiateViewController(withIdentifier: "sessionVC") as! SessionViewController
            self.navigationController?.pushViewController(sessionViewController, animated: true)
        }
    }
    
    // MARK: Notification Delegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case stopActionID:
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            self.resetTimer()
        case yesActionID:
            UserDefaults.standard.setValue(UserDefaults.standard.integer(forKey: "UpVote") + 1, forKey: "UpVote")
        case noActionID:
            UserDefaults.standard.setValue(UserDefaults.standard.integer(forKey: "DownVote") + 1, forKey: "DownVote")
        default:
            print("Triggered action: \(response.actionIdentifier)")
        }
        completionHandler()
    }
    
    // MARK: Picker View Delegates
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    // MARK: Picker View Data Source
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(pickerData[row])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedPickerValue = pickerData[row];
    }
    
    // MARK: Other Methods

    func resetTimer() {
        UserDefaults.standard.setValue(nil, forKey: "intervals")
        UserDefaults.standard.setValue(nil, forKey: "sessionLength")
        UserDefaults.standard.setValue(0, forKey: "counter")
        if(self.delegate.timer != nil) {
            self.delegate.timer.removeAllObservers(thenStop: true)
            self.delegate.timer = nil
        }
    }
}
