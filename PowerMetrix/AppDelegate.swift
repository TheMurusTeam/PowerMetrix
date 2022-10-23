//
//  AppDelegate.swift
//  PowerMetrix
//
//  Created by Hany El Imam on 05/06/21.
//


// POWERMETRIX


import Cocoa
import ServiceManagement


/*
    TO CREATE A POWERMETRICS REPORT:
 
    sudo powermetrics -s cpu_power,gpu_power,bandwidth -i 1000 -f plist -n 1 > output.plist
 
 */



let xpccontroller = PMHelper()

// CPU INFO

var cpu_name = "Unknown CPU"
func cpu() -> String {
    var size = 0
    sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
    var machine = [CChar](repeating: 0,  count: Int(size))
    sysctlbyname("machdep.cpu.brand_string", &machine, &size, nil, 0)
    return String(cString: machine)
}
func cpu_image() -> NSImage {
    switch cpu_name {
    case "Apple M1" : return NSImage(named: "m1")!
    case "Apple M1 Pro" : return NSImage(named: "m1pro")!
    case "Apple M1 Max" : return NSImage(named: "m1max")!
    default : return NSImage(named: "genericarm")!
    }
}


func powermetrixVersion() -> String {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.0"
}
func powermetrixBuild() -> String {
    return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}
func powermetrixFullVersion() -> String {
    return ((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") + " (build " + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "000") + ")")
}



@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // arch
#if arch(arm64)
        NSLog("Welcome to Powermetrix for macOS")
#elseif arch(x86_64)
        let alert = NSAlert()
        alert.messageText = "Unsupported architecture"
        alert.informativeText = "PowerMetrix requires an Apple Silicon Mac.\nIntel Macs are not supported."
        alert.addButton(withTitle: "Quit")
        alert.runModal()
        NSApplication.shared.terminate(nil)
#endif
        
        // get CPU name
        cpu_name = cpu()
        
        // install powermetrixd xpc helper
        shouldInstallHelper(callback: {
            installed in
            if !installed {
                NSLog("Powermetrix needs to install its privileged helper tool it.murus.powermetrix.helper...")
                self.isInstallingHelper = true
                self.installHelper()
               // self.startPowermetrix()
            } else {
                NSLog("it.murus.powermetrix.helper helper tool found")
                self.startPowermetrix()
            }
        })
    }
    
    
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        (xpccontroller.helperConnection()?.synchronousRemoteObjectProxyWithErrorHandler() { error -> Void in print("XPC error: %@", error) } as? PMHelperProtocol)?.quitHelper()
    }

    
    // MARK: MENULET
    
    
    @objc dynamic var statusBar = NSStatusBar.system
    @objc dynamic var statusBarItem : NSStatusItem = NSStatusItem()
    @IBOutlet weak var menuletMenu: NSMenu!
    @IBOutlet weak var statusBarView: NSView!
    @IBOutlet weak var label_menulet: NSTextField!
    
    override func awakeFromNib() {
        self.startMenulet()
    }
    
    var statusItem: NSStatusItem!
    var statusButton: NSStatusBarButton!
    
    var isEnabled: Bool = true
    
    func startMenulet() {
        DispatchQueue.main.async {
            self.statusItem = NSStatusBar.system.statusItem(withLength: self.statusBarView.frame.width)
            self.statusItem.isVisible = true
            self.statusItem.behavior = [.removalAllowed, .terminationOnRemoval]
            self.statusButton = self.statusItem.button!
            self.statusButton.target = self
            self.statusButton.action = #selector(self.didTapButton)
            self.statusButton.addSubview(self.statusBarView)
        }
    }
    
    @objc func didTapButton() {
        if pmWindows["main"] == nil {
            pmWindows["main"] = PMMainWindowController(windowNibName: "PMMainWindowController")
        }
        (pmWindows["main"] as? PMMainWindowController)?.window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        
    }
    
    
    
    
    
    
    
    // MARK: - START POWERMETRIX
    
    func startPowermetrix() {
        NSLog("starting Powermetrix")
        
        // wakeup helper getting helper version
        (xpccontroller.helperConnection()?.remoteObjectProxyWithErrorHandler() { error -> Void in print("XPC error: %@", error) } as? PMHelperProtocol)?.getVersion() { build in
            NSLog("it.murus.powermetrix.helper build \(build) is running")
        }
        
    }
    
    
    
    
    
    
    

    
    
    // MARK: - SHOULD INSTALL XPC HELPER
     
    var isInstallingHelper = false
    
    func shouldInstallHelper(callback: @escaping (Bool) -> Void){
        let helperURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LaunchServices/it.murus.powermetrix.helper")
        let helperBundleInfo = CFBundleCopyInfoDictionaryForURL(helperURL as CFURL)
        if helperBundleInfo != nil {
            let helperInfoCF = helperBundleInfo!
            let helperInfo = helperInfoCF as NSDictionary
            let helperVersion = helperInfo["CFBundleVersion"] as! String
            print("bundled it.murus.powermetrix.helper version: \(helperVersion)")
            (xpccontroller.helperConnection()?.remoteObjectProxyWithErrorHandler({ _ in callback(false)}) as? PMHelperProtocol)?.getVersion(reply: {
                installedVersion in
                print("installed it.murus.powermetrix.helper version: \(installedVersion)")
                if installedVersion == helperVersion { // versione uguale
                    callback(true)
                } else if installedVersion.compare(helperVersion, options: .numeric) == .orderedDescending { // installed + nuovo
                    callback(true)
                    
                } else if installedVersion.compare(helperVersion, options: .numeric) == .orderedAscending { // installed + vecchio
                    callback(false)
                }
            })
        } else {
            callback(false)
        }
    }
    
    
    
    // MARK: - INSTALL HELPER WITH SMJobBless
    
    func installHelper(){
        var authRef:AuthorizationRef?
        var authItem = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value:UnsafeMutableRawPointer(bitPattern: 0), flags: 0)
        var authRights:AuthorizationRights = AuthorizationRights(count: 1, items:&authItem)
        let authFlags: AuthorizationFlags = [ [], .extendRights, .interactionAllowed, .preAuthorize ]
        
        let status = AuthorizationCreate(&authRights, nil, authFlags, &authRef)
        if (status != errAuthorizationSuccess){
            let error = NSError(domain:NSOSStatusErrorDomain, code:Int(status), userInfo:nil)
            NSLog("Authorization error: \(error)")
        } else {
            var cfError: Unmanaged<CFError>? = nil
            if !SMJobBless(kSMDomainSystemLaunchd, "it.murus.powermetrix.helper" as CFString, authRef, &cfError) {
                // ERROR!
                let blessError = cfError!.takeRetainedValue() as Error
                NSLog("Can't install it.murus.powermetrix.helper! Error: \(blessError)")
                DispatchQueue.main.async {
                    let alert = NSAlert(); alert.messageText = "Error: can't run Powermetrix"; alert.informativeText = "Can't install it.murus.powermetrix.helper. \(blessError)\n\nPlease report this bug to info@murus.it, thank you. "; alert.runModal()
                    NSApplication.shared.terminate(nil)
                }
            } else {
                // SUCCESS
                NSLog("it.murus.powermetrix.helper installed successfully")
                // quit
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Done"
                    alert.informativeText = "PowerMetrix helper installed successfully. PowerMetrix will now quit.\n\nPlease restart PowerMetrix."
                    alert.runModal()
                    NSApplication.shared.terminate(nil)
                }
                
            }
        }
    }

    
    
    
    
    
    
    
    // UPDATE MENULET LABEL
    func displayMenuletMetrics(metrix:[String:AnyObject]) {
        var totalEnergyKey = "package_energy"
        if #available(OSX 13.0, *) {
            totalEnergyKey = "combined_power"
        }
        
        let processor = metrix["processor"] as? [String:AnyObject]
        self.label_menulet.stringValue = "\((Double(truncating: processor?[totalEnergyKey] as? NSNumber ?? 0) / 1000).rounded(toPlaces: 1)) W"
    }
    
    
    
    
}










extension Double {
    /// Rounds the number to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

