import UIKit

class CounterModel: NSObject {
    @objc dynamic var counterInteger: Int = 0
    
    override init() {
        counterInteger = UserDefaults.standard.integer(forKey: "counter")
    }
}
