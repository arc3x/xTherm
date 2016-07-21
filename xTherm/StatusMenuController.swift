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
    
    // Timer used for rendering and refreshing
    var refreshTimer = NSTimer()
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(60)
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    // Application settings; for saving on quit:
    // http://stackoverflow.com/questions/28628225/how-do-you-save-local-storage-data-in-a-swift-application
    var tempUnit: String = "C"
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // Application variables
    var curTempUnitMenuItem: NSMenuItem? // ptr to last button to set temp units (for toggle off)
    var cpuMaxTempMenu: NSMenuItem?
    var fanMenuItems: Array<NSMenuItem?> = Array()
    var cpuTemp: Double = 0
    var cpuMaxTemp: Double = 0
    var fanCount: Int = 0
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
        let xthermPath = documentsDirectory.stringByAppendingPathComponent("xTherm")
        
        // Check if ~/Documents/xTherm exists; if not create it
        if !fileManager.fileExistsAtPath(xthermPath, isDirectory: &isDir) {
            print(isDir)
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
            if (file != (dateToday+".log") && file != (dateYesterday+".log")) {
                let _ = try? fileManager.removeItemAtPath(xthermPath+"/"+file)
            }
        }
        
        // Link our menu to the status bar
        statusItem.menu = statusMenu
        
        // Load previous settings if available
        if let t = defaults.stringForKey("tempUnit") {
            tempUnit = t;
            if (t == "C") {
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
        
        // Init max temp to 0
        cpuMaxTempMenu = statusMenu.itemWithTag(1)
        cpuMaxTempMenu?.title="CPU Max Temp 0 \u{00B0}"+tempUnit

        // Retrieve number of fans
        let _ = try? SMCKit.open()
        fanCount = try! SMCKit.fanCount()
        SMCKit.close()
        
        // Init fan speeds to 0, add menu items per fan
        for i in 0 ..< fanCount {
            fanCurrentSpeeds.append(0)
            fanMaxSpeeds.append(0)
            fanMenuItems.append(NSMenuItem())
            let fanMenuTitle = "Fan " + String(i) + ": "
            fanMenuItems[i]?.title = fanMenuTitle
            statusMenu?.insertItem((fanMenuItems[i])!, atIndex: 3 + i)
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
    
    // Refresh temperature from SMCKit
    func refreshTempData() {
        let _ = try? SMCKit.open()
        cpuTemp = try! SMCKit.temperature(1413689424)
        SMCKit.close()
        
        if (cpuTemp > cpuMaxTemp) {
            cpuMaxTemp = cpuTemp
        }
    }
    
    // Refresh fan speeds
    // FIXME: Not necessary to keep retrieving max fan speed; it doesn't change
    func refreshFanData() {
        let _ = try? SMCKit.open()
        for i in 0 ..< fanCount {
            fanCurrentSpeeds[i] = try! SMCKit.fanCurrentSpeed(i)
            fanMaxSpeeds[i] = try! SMCKit.fanMaxSpeed(i)
        }
        SMCKit.close()
    }
    
    
    
    // * * *
    // Render functions
    // * * *
    
    // Refresh data and render
    func renderMenu() {
        refreshTempData()
        refreshFanData()
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
