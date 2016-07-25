//
//  StatusMenuController.swift
//  xTherm
//
//  Created by Matthew Slocum on 6/27/16.
//  Copyright © 2016 Matthew Slocum, Sami Sahli. All rights reserved.
//
//  The basic functionality of this code was established using a tutorial
//  at http://footle.org/WeatherBar/ licensed under MIT.
//  the vast majority of it has changed, but credit where it's due.

import Cocoa



class StatusMenuController: NSObject {
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    // Timer used for rendering and refreshing
    var refreshTimer = NSTimer()
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(60)
    
    // Application settings; for saving on quit:
    // http://stackoverflow.com/questions/28628225/how-do-you-save-local-storage-data-in-a-swift-application
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // * * *
    // Application variables
    // * * *
    
    var xthermPath: String = ""
    
    var logginStatusMenu: NSMenuItem?
    var loggingStatus: Bool = false
    
    var tempUnit: String = "C"
    var curTempUnitMenuItem: NSMenuItem? // ptr to last button to set temp units (for toggle off)
    var cpuMaxTempMenu: NSMenuItem?
    var cpuTemp: Double = 0
    var cpuMaxTemp: Double = 0
    
    var fanCount: Int = 0
    var fanMenuItems: Array<NSMenuItem?> = Array()
    var fanCurrentSpeeds: Array<Int> = Array()
    var fanMaxSpeeds: Array<Int> = Array()
    
 
    
    // * * *
    // bootstrapping function
    // * * *
    
    override func awakeFromNib() {
        // Init vars for directory & file path
        let fileManager = NSFileManager.defaultManager()
        var isDir: ObjCBool = false
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject = paths[0]
        xthermPath = documentsDirectory.stringByAppendingPathComponent("xTherm")
        
        // Check if ~/Documents/xTherm exists; if not create it
        if !fileManager.fileExistsAtPath(xthermPath, isDirectory: &isDir) {
            // http://stackoverflow.com/questions/26931355/how-to-create-directory-using-swift-code-nsfilemanager
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(xthermPath, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
        }
        
        // Flush logs older than 2 days
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = NSDate()
        let dateToday = dateFormatter.stringFromDate(date)
        let calendar = NSCalendar.currentCalendar()
        let dateYesterday = dateFormatter.stringFromDate(calendar.dateByAddingUnit(.Day, value: -1, toDate: NSDate(), options: [])!)
        let files = try! fileManager.contentsOfDirectoryAtPath(xthermPath)
        for file in files {
            if (file != (dateToday+".xlog") && file != (dateYesterday+".xlog")) {
                let _ = try? fileManager.removeItemAtPath(xthermPath+"/"+file)
            }
        }
        
        // Link our menu to the status bar
        statusItem.menu = statusMenu
        
        // Load previous temperature unit settings if available
        if let temp = defaults.stringForKey("tempUnit") {
            tempUnit = temp;
            if (temp == "C") {
                curTempUnitMenuItem = statusMenu.itemWithTitle("Temperature Units")!.submenu?.itemWithTitle("C")
                curTempUnitMenuItem?.state = NSOnState
            } else {
                curTempUnitMenuItem = statusMenu.itemWithTitle("Temperature Units")!.submenu?.itemWithTitle("F")
                curTempUnitMenuItem?.state = NSOnState
            }
        }
        // Default to Celsius
        else {
            curTempUnitMenuItem = statusMenu.itemWithTitle("Temperature Units")!.submenu?.itemWithTitle("C")
            curTempUnitMenuItem?.state = NSOnState
        }
        
        // Load previous logging settings if available
        if let logging: Optional<Bool> = defaults.boolForKey("logging") {
            loggingStatus = logging!
            statusMenu.itemWithTitle("Logging")!.submenu?.itemWithTitle("Disabled")?.state = NSOnState // apply check mark to menu item
            if logging == true {
                statusMenu.itemWithTitle("Logging")!.submenu?.itemWithTitle("Disabled")?.title = "Enabled"
            }
        }
        
        // Init max temp to 0
        cpuMaxTempMenu = statusMenu.itemWithTag(1)
        cpuMaxTempMenu?.title="CPU Max Temp 0 \u{00B0}"+tempUnit

        // Retrieve number of fans and their max speeds
        let _ = try? SMCKit.open()
        fanCount = try! SMCKit.fanCount()
        for i in 0 ..< fanCount {
            fanMaxSpeeds.append(try!SMCKit.fanMaxSpeed(i))
        }
        SMCKit.close()
        
        // Init fan speeds to 0, add menu items per fan
        for i in 0 ..< fanCount {
            fanCurrentSpeeds.append(0)
            fanMaxSpeeds.append(0)
            fanMenuItems.append(NSMenuItem())
            let fanMenuTitle = "Fan " + String(i) + ": "
            fanMenuItems[i]?.title = fanMenuTitle
            statusMenu?.insertItem((fanMenuItems[i])!, atIndex: 3 + i)
            let _ = try? SMCKit.open()
            fanMaxSpeeds[i] = try! SMCKit.fanMaxSpeed(i)
            SMCKit.close()
        }
        
        // Render, and continue rendering with refreshTimer
        renderMenu()
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: #selector(StatusMenuController.renderMenu), userInfo: nil, repeats: true)
    }
    
    
    
    // * * *
    // Menu Item Bindings
    // * * *
    
    // Reset the max temp
    @IBAction func clearMaxCpuTempClicked(sender: NSMenuItem) {
        cpuMaxTemp = 0
        renderMenu()
    }
    
    // Tempature Unit -> F
    @IBAction func setTempFClicked(sender: NSMenuItem) {
        setTempUnits(sender, unit: "F")
    }
    
    // Tempature Unit -> C
    @IBAction func setTempCClicked(sender: NSMenuItem) {
        setTempUnits(sender, unit: "C")
    }
    
    // Save tempUnit and quit
    @IBAction func quitClicked(sender: NSMenuItem) {
        defaults.setObject(tempUnit, forKey: "tempUnit")
        NSApplication.sharedApplication().terminate(self)
    }
    
    // Toggles enable/disable of logging
    @IBAction func toggleLoggingClicked(sender: NSMenuItem) {
        if loggingStatus == true {
            loggingStatus = false;
            statusMenu.itemWithTitle("Logging")!.submenu?.itemWithTitle("Enabled")?.title = "Disabled"
        } else {
            loggingStatus = true;
            statusMenu.itemWithTitle("Logging")!.submenu?.itemWithTitle("Disabled")?.title = "Enabled"
        }
        // save logging status for next load
        defaults.setObject(loggingStatus, forKey: "logging")
    }
    
    // Displays log
    @IBAction func showLogClicked(sender: NSMenuItem) {
        NSWorkspace.sharedWorkspace().selectFile(nil, inFileViewerRootedAtPath: xthermPath)
    }
    
    
    
    // * * *
    // Helper functions
    // * * *
    
    // Switch temperature units
    func setTempUnits(sender: NSMenuItem, unit: String) {
        if (curTempUnitMenuItem == sender) {
            return
        }

        tempUnit = unit
        // Swap "checked" states
        if (curTempUnitMenuItem != nil) {
            curTempUnitMenuItem?.state = NSOffState
        }
        
        sender.state = NSOnState
        curTempUnitMenuItem = sender
 
        renderMenu()
    }
    
    // Refresh temperature from SMCKit and save to log file
    func refreshTempData() {
        let _ = try? SMCKit.open()
        cpuTemp = try! SMCKit.temperature(1413689424)
        SMCKit.close()
        if (cpuTemp > cpuMaxTemp) {
            // update max recorded temp
            cpuMaxTemp = cpuTemp
        }
    }
    
    // Refresh fan speeds
    func refreshFanData() {
        let _ = try? SMCKit.open()
        for i in 0 ..< fanCount {
            fanCurrentSpeeds[i] = try! SMCKit.fanCurrentSpeed(i)
        }
        SMCKit.close()
    }
    
    // * * *
    // Logging functions
    // * * *
    
    // writes sensor data to a <date>.xlog file
    func logSensorData() {
        //get todays date for log filename
        // FIXME: do this every time?
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateToday = dateFormatter.stringFromDate(date)
        dateFormatter.dateFormat = "hh:mm:ss"
        let timestamp = dateFormatter.stringFromDate(date)
        
        // string to write out sensor data
        let out: String = timestamp+"\tCPU Temperature "+String(cpuTemp)+" \u{00B0}C"
        
        //append log file
        writeToFile(out, fileName: "/xTherm/"+dateToday+".xlog")
    }
    
    // creates or appends data to a file
    // http://stackoverflow.com/questions/36736215/append-new-string-to-txt-file-in-swift-2
    func writeToFile(content: String, fileName: String) {
        let contentToAppend = content+"\n"
        let filePath = NSHomeDirectory() + "/Documents/" + fileName
        
        //Check if file exists
        if let fileHandle = NSFileHandle(forWritingAtPath: filePath) {
            //Append to file
            fileHandle.seekToEndOfFile()
            fileHandle.writeData(contentToAppend.dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        else {
            //Create new file
            do {
                try contentToAppend.writeToFile(filePath, atomically: true, encoding: NSUTF8StringEncoding)
            } catch {
                print("Error creating \(filePath)")
            }
        }
    }
    
    // * * *
    // Render functions
    // * * *
    
    // Refresh data and render
    func renderMenu() {
        refreshTempData()
        refreshFanData()
        if loggingStatus {
            logSensorData()
        }
        renderTitle()
        renderCpuMaxTemp()
        renderFanSpeeds()
    }
    
    // Render menu title; convert temperature if necessary
    func renderTitle() {
        var t: Double = cpuTemp

        if (tempUnit=="F") {
            t = (t * 1.8) + 32
        }

        statusItem.title = String(Int(t)) + " \u{00B0}" + tempUnit
    }
    
    // Render max temp menu title; convert temperature if necessary
    func renderCpuMaxTemp() {
        var t: Double = cpuMaxTemp
        
        if (tempUnit=="F") {
            t = (t * 1.8) + 32
        }
        
        cpuMaxTempMenu?.title =
            "CPU Max Temp " + String(Int(t)) + " \u{00B0}" + tempUnit
    }
    
    // Render fan speeds menu titles
    func renderFanSpeeds() {
        for i in 0 ..< fanCount {
            let curFanSpeedPercent =
                String(Int((Double(fanCurrentSpeeds[i])
                    / Double(fanMaxSpeeds[i])) * 100))
            
            let fanMenuItemTitle = "Fan " + String(i) + ": " +
                String(fanCurrentSpeeds[i]) + "RPM (" +
                curFanSpeedPercent + "%) (max " +
                String(fanMaxSpeeds[i]) + "RPM)"
            
            fanMenuItems[i]?.title = fanMenuItemTitle
        }
    }
}
