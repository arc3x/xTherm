//
//  StatusMenuController.swift
//  mac-monitor
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
    
    var refreshTimer = NSTimer()
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(60)
    
    var tempUnit: Character = "C"
    var temperatue: Double = 0
    var curTempMenuItem: NSMenuItem? //ptr to last button to set temp units (for toggle off)
    
    // tracked temperatures
    var cpuTemp: Double = 0
    
    // bootstrapping function
    override func awakeFromNib() {
        // default to Celcius
        curTempMenuItem = statusMenu.itemArray[0].submenu?.itemWithTitle("C")
        // apply a check mark to the menu item
        curTempMenuItem?.state = NSOnState;
        // link the menu to the status bar "view"
        statusItem.menu = statusMenu
        // process and write info to the view
        renderTitle()
        // setup a timer to refresh the view
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(2.5, target: self, selector: #selector(StatusMenuController.renderTitle), userInfo: nil, repeats: true)
    }
    
    // quit menu option
    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    // Tempature Unit -> F menu option
    @IBAction func setTempFClicked(sender: NSMenuItem) {
        setTempUnits(sender, unit: "F")
    }
    
    // Tempature Unit -> C menu option
    @IBAction func setTempCClicked(sender: NSMenuItem) {
        setTempUnits(sender, unit: "C")
    }
    
    // helper function
    // sets temp variables, swaps 'checked' state, and re-renders
    func setTempUnits(sender: NSMenuItem, unit: Character) {
        // if we are changing to current value ret
        if (curTempMenuItem == sender) {
            return
        }
        // change units
        tempUnit = unit
        // swap 'checked' state
        if (curTempMenuItem != nil) {
            curTempMenuItem?.state = NSOffState
        }
        sender.state = NSOnState
        curTempMenuItem = sender
        // re-render
        renderTitle()
    }
    
    // gets new data from temp sensors
    func refreshTempData() {
        // open connection to SMC api
        let _ = try? SMCKit.open()
        // read CPU proximity sensor
        cpuTemp = try! SMCKit.temperature(1413689424)
        // close connection
        SMCKit.close()
    }
    
    // does unit conversion and writes tempature to status bar "view"
    func renderTitle() {
        // get new tempature
        refreshTempData()
        // get local copy of cpuTemp
        var t: Double = cpuTemp
        // convert if necissary
        if (tempUnit=="F") {
            t = (t * 1.8) + 32
        }
        // wrtie temp to status bar
        statusItem.title = String(Int(t))+" \u{00B0}"+String(tempUnit)
    }
    
  
}
