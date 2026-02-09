import UIKit

struct DeviceInfo {
    
    static var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    static var systemVersion: String {
        UIDevice.current.systemVersion
    }
    
    static var languageCode: String {
        let pref = Locale.preferredLanguages.first ?? "en"
        if let idx = pref.firstIndex(of: "-") {
            return String(pref[..<idx])
        }
        return pref
    }
    
    static var countryCode: String {
        Locale.current.region?.identifier ?? ""
    }
}
