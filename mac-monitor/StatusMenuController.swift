//
//  StatusMenuController.swift
//  mac-monitor
//
//  Created by Matthew Slocum on 6/27/16.
//  Copyright © 2016 Matthew Slocum, Sami Sahli. All rights reserved.
//
//  The basic functionality of this code was established using a tutorial
//  at http://footle.org/WeatherBar/ 
//  the vast majority of it has changed, but credit where it's due.

// NOTE: battery temp ioreg -r -n AppleSmartBattery | grep Temperature | cut -c23-


import Cocoa

class StatusMenuController: NSObject {
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(60)
    
    var tempUnit: Character = "C"
    var temperatue: Double = 0
    var curTempMenuItem: NSMenuItem? //ptr to last button to set temp units (for toggle off)
    
    override func awakeFromNib() {
        //let icon = NSImage(named: "statusIcon")
        //icon?.template = true
        //statusItem.image = icon
        curTempMenuItem = statusMenu.itemArray[0].submenu?.itemWithTitle("C");
        curTempMenuItem?.state = NSOnState;
        statusItem.menu = statusMenu
        renderTitle()
    }
    
    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self)
    }
    
    @IBAction func setTempFClicked(sender: NSMenuItem) {
        setTemp(sender, unit: "F")
    }
    
    @IBAction func setTempCClicked(sender: NSMenuItem) {
        setTemp(sender, unit: "C")
    }
    
    func setTemp(sender: NSMenuItem, unit: Character) {
        if (curTempMenuItem == sender) {
            return
        }
        tempUnit = unit
        if (curTempMenuItem != nil) {
            curTempMenuItem?.state = NSOffState
        }
        sender.state = NSOnState
        curTempMenuItem = sender
        renderTitle()
    }
    
    func renderTitle() {
        var t: Double = temperatue
        if (tempUnit=="F") {
            t = (t * 1.8) + 32
        }
        statusItem.title = String(Int(t))+" \u{00B0}"+String(tempUnit)
    }
    
  
}
