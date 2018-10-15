import UIKit
import Repeat
import KDCircularProgress

class SessionViewController: UIViewController {
    
    var progress: KDCircularProgress!
    @IBOutlet var progressText: UILabel!
    private var observation :NSKeyValueObservation?
    var model = CounterModel()
    let delegate = UIApplication.shared.delegate as! AppDelegate
    @IBOutlet var rateSessionButton: UIButton!
    var progressString: String = ""
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        model = delegate.model
        self.setUpProgress()
        self.rateSessionButton.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if(model.counterInteger != UserDefaults.standard.integer(forKey: "intervals")) {
            self.progressText.text = "You are on interval " + String(model.counterInteger + 1) + " out of " + String(UserDefaults.standard.integer(forKey: "intervals"))
        }
        self.progress.animate(toAngle: (Double(model.counterInteger)/Double(UserDefaults.standard.integer(forKey: "intervals")) * 360) , duration: 2, completion: { (true) in
        })

        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.observeModel = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.observeModel = false
    }
    
    func setUpProgress () {
        progress = KDCircularProgress(frame: CGRect(x: 0, y: 0, width: 250, height: 250))
        progress.startAngle = -90
        progress.progressThickness = 0.1
        progress.trackThickness = 0.2
        progress.clockwise = true
        progress.gradientRotateSpeed = 2
        progress.roundedCorners = false
        progress.glowMode = .forward
        progress.glowAmount = 0.9
        progress.set(colors: UIColor(red: 124/255, green: 252/255, blue: 0/255, alpha: 1.00))
        progress.center = CGPoint(x: view.center.x, y: 180)
        view.addSubview(progress)
    }
    
    var observeModel = false {
        didSet {
            guard observeModel != oldValue else { return }
            
            if observeModel {
                model.addObserver(self, forKeyPath: "counterInteger", options: NSKeyValueObservingOptions(), context: nil)
            } else {
                model.removeObserver(self, forKeyPath: "counterInteger")
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
                
        guard let object = object else { return }
        
        if let model = object as? CounterModel {
            if keyPath == "counterInteger" {
                DispatchQueue.main.async {
                    self.progress.animate(toAngle: (Double(model.counterInteger)/Double(UserDefaults.standard.integer(forKey: "intervals")) * 360) , duration: 2, completion: { (true) in
                    })
                    
                    if(model.counterInteger == UserDefaults.standard.integer(forKey: "intervals")) {
                        self.rateSessionButton.isHidden = false
                    } else {
                        self.progressText.text = "You are on interval " + String(model.counterInteger + 1) + " out of " + String(UserDefaults.standard.integer(forKey: "intervals"))
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Button Actions
    
    @IBAction func endSessionButtonClick(_ sender: Any) {
        
        if(self.delegate.timer == nil || self.delegate.timer.state == .finished) {
            let alertView = UIAlertController(title: "Session Ended", message: "The session has already ended", preferredStyle: .alert)
            
            alertView.addAction(UIAlertAction(title:"Cancel", style: .cancel, handler: nil))
            
            self.present(alertView, animated: true)
        } else {
            let alertView = UIAlertController(title: "End Session", message: "Are you sure you want to end this session early?", preferredStyle: .alert)
            
            alertView.addAction(UIAlertAction(title:"Cancel", style: .cancel, handler: nil))
            alertView.addAction(UIAlertAction(title:"End", style: .default, handler: { (action: UIAlertAction!) in
                self.rateSessionButton.isHidden = false
                self.observeModel = false
                if(self.delegate.timer != nil) {
                    self.delegate.timer.removeAllObservers(thenStop: true)
                    self.delegate.timer = nil
                }
            }))

            self.present(alertView, animated: true)
        }
    }
    
    @IBAction func viewGraphButtonClicked(_ sender: Any) {
        
        if (UserDefaults.standard.integer(forKey: "UpVote") == 0 && UserDefaults.standard.integer(forKey: "DownVote") == 0) {
            let alertView = UIAlertController(title: "Graph", message: "No Data Available", preferredStyle: .alert)
            
            alertView.addAction(UIAlertAction(title:"Cancel", style: .cancel, handler: nil))
            
            self.present(alertView, animated: true)
        } else {
            let barChartViewController = self.storyboard?.instantiateViewController(withIdentifier: "barChartVC") as! BarChartViewController
            self.navigationController?.pushViewController(barChartViewController, animated: true)
        }
    }
    
    @IBAction func rateButtonClicked(_ sender: Any) {
        let alertView = UIAlertController(title: "Rate Session", message: "Was the session helpful?", preferredStyle: .alert)
        
        alertView.addAction(UIAlertAction(title:"Yes", style: .default, handler: { (action: UIAlertAction!) in
            UserDefaults.standard.setValue(UserDefaults.standard.integer(forKey: "UpVote") + 1, forKey: "UpVote")
            self.rateSessionButton.isHidden = true
        }))
        alertView.addAction(UIAlertAction(title:"No", style: .default, handler: { (action: UIAlertAction!) in
            UserDefaults.standard.setValue(UserDefaults.standard.integer(forKey: "DownVote") + 1, forKey: "DownVote")
            self.rateSessionButton.isHidden = true
        }))
        
        self.present(alertView, animated: true)
    }
}
