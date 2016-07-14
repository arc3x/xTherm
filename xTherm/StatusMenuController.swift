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
    
    // timer for display refresh
    var refreshTimer = NSTimer()
    
    // statas bar app
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(60)
    
    // menu for status bar
    @IBOutlet weak var statusMenu: NSMenu!
    
    // application settings
    var tempUnit: String = "C"
    // for saving settings on quit
    // http://stackoverflow.com/questions/28628225/how-do-you-save-local-storage-data-in-a-swift-application
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // application variables
    var curTempUnitMenuItem: NSMenuItem? //ptr to last button to set temp units (for toggle off)
    var cpuTemp: Double = 0
    var cpuMaxTemp: Double = 0
    var fanCount: Int = 0
    var fanCurrentSpeeds: Array<Int> = Array()
    var fanMaxSpeeds: Array<Int> = Array()
    
    
    // pointers to menu items (for writing to)
    var cpuMaxTempMenu: NSMenuItem?
    var fanMenuItems: Array<NSMenuItem?> = Array()
    
    
    // * * *
    // bootstrapping function
    // * * *
    
    override func awakeFromNib() {
        // if set -> get last settings
        if let t = defaults.stringForKey("tempUnit") {
            tempUnit = t;
            if (t == "C") {
                // get pointer for toggle
                curTempUnitMenuItem = statusMenu.itemWithTitle("Temperature Units")!.submenu?.itemWithTitle("C")
                // apply a check mark to the menu item
                curTempUnitMenuItem?.state = NSOnState
            } else {
                // get pointer for toggle
                curTempUnitMenuItem = statusMenu.itemWithTitle("Temperature Units")!.submenu?.itemWithTitle("F")
                // apply a check mark to the menu item
                curTempUnitMenuItem?.state = NSOnState
            }
        }
        // else -> default to Celcius
        else {
            // get pointer for toggle
            curTempUnitMenuItem = statusMenu.itemWithTitle("Temperature Units")!.submenu?.itemWithTitle("C")
            // apply a check mark to the menu item
            curTempUnitMenuItem?.state = NSOnState
        }
        // link the menu to the status bar "view"
        statusItem.menu = statusMenu
        // get ptr to cpuMaxTemp meun item
        cpuMaxTempMenu = statusMenu.itemWithTag(1)
        // set default value
        cpuMaxTempMenu?.title="CPU Max Temp 0 \u{00B0}"+tempUnit
        // get number of fans
        let _ = try? SMCKit.open()
        fanCount = try! SMCKit.fanCount()
        SMCKit.close()
        // default fan values, and add new menu items per fan
        for i in 0 ..< fanCount {
            fanCurrentSpeeds.append(0)
            fanMaxSpeeds.append(0)
            fanMenuItems.append(NSMenuItem())
            let fanMenuTitle = "Fan " + String(i) + ": "
            fanMenuItems[i]?.title = fanMenuTitle
            statusMenu?.insertItem((fanMenuItems[i])!, atIndex: 3+i)
        }
        // process and write info to the menu
        renderMenu()
        // setup a timer to refresh the menu
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: #selector(StatusMenuController.renderMenu), userInfo: nil, repeats: true)
    }
    
    
    // * * *
    // Menu Item Bindings
    // * * *
    
    //  clears the recored max cpu temp
    @IBAction func clearMaxCpuTempClicked(sender: NSMenuItem) {
        cpuMaxTemp = 0
        renderMenu()
    }
    
    // Tempature Unit -> F menu option
    @IBAction func setTempFClicked(sender: NSMenuItem) {
        setTempUnits(sender, unit: "F")
    }
    
    // Tempature Unit -> C menu option
    @IBAction func setTempCClicked(sender: NSMenuItem) {
        setTempUnits(sender, unit: "C")
    }
    
    // quit menu option
    @IBAction func quitClicked(sender: NSMenuItem) {
        // save settings
        defaults.setObject(tempUnit, forKey: "tempUnit")
        // quit
        NSApplication.sharedApplication().terminate(self)
    }
    
    
    // * * *
    // helper functions
    // * * *
    
    // sets temp variables, swaps 'checked' state, and re-renders
    func setTempUnits(sender: NSMenuItem, unit: String) {
        // if we are changing to current value ret
        if (curTempUnitMenuItem == sender) {
            return
        }
        // change units
        tempUnit = unit
        // swap 'checked' state
        if (curTempUnitMenuItem != nil) {
            curTempUnitMenuItem?.state = NSOffState
        }
        sender.state = NSOnState
        curTempUnitMenuItem = sender
        // re-render
        renderMenu()
    }
    
    // gets new data from temp sensors
    func refreshTempData() {
        // open connection to SMC api
        let _ = try? SMCKit.open()
        // read CPU proximity sensor
        cpuTemp = try! SMCKit.temperature(1413689424)
        // close connection
        SMCKit.close()
        // update cpuMaxTemp if applicable
        if (cpuTemp > cpuMaxTemp) {
            cpuMaxTemp = cpuTemp
        }
    }
    
    // get current and max fan speeds
    func refreshFanData() {
        let _ = try? SMCKit.open()
        for i in 0 ..< fanCount {
            fanCurrentSpeeds[i] = try! SMCKit.fanCurrentSpeed(i)
            fanMaxSpeeds[i] = try! SMCKit.fanMaxSpeed(i)
        }
        SMCKit.close()
    }
    
    
    // * * *
    // render functions
    // * * *
    
    // updates the menu with current data
    func renderMenu() {
        // get new tempature
        refreshTempData()
        refreshFanData()
        renderTitle()
        renderCpuMaxTemp()
        renderFanSpeeds()
    }
    
    // does unit conversion and writes tempature to status bar "view"
    func renderTitle() {
        // get local copy of cpuTemp
        var t: Double = cpuTemp
        // convert if necissary
        if (tempUnit=="F") {
            t = (t * 1.8) + 32
        }
        // wrtie temp to status bar
        statusItem.title = String(Int(t))+" \u{00B0}"+tempUnit
    }
    
    // does unit conversion and writes max recorded temperature to menu
    func renderCpuMaxTemp() {
        // get local copy of cpuMaxTemp
        var t: Double = cpuMaxTemp
        // convert if necissary
        if (tempUnit=="F") {
            t = (t * 1.8) + 32
        }
        // wrtie temp to status bar
        cpuMaxTempMenu?.title="CPU Max Temp "+String(Int(t))+" \u{00B0}"+tempUnit
    }
    
    // write current and max fan speeds
    func renderFanSpeeds() {
        for i in 0 ..< fanCount {
            let fanMenuItemTitle = "Fan " + String(i) + ": " +
                String(fanCurrentSpeeds[i]) + "RPM (max " +
                String(fanMaxSpeeds[i]) + "RPM)"
            fanMenuItems[i]?.title = fanMenuItemTitle
        }
    }
    
  
}
