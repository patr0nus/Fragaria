//
//  AppDelegate.swift
//  Fragaria Swift
//
//  Created by Daniele Cattaneo on 04/12/15.
//
//

import Cocoa
import Fragaria
import FragariaDefaultsCoordinator


@NSApplicationMain class AppDelegate: NSObject, NSApplicationDelegate {

    
var prefsWindow: MASPreferencesWindowController!
    

func applicationWillFinishLaunching(_ aNotification: Notification) {
    let shc: MGSUserDefaultsController = MGSUserDefaultsController.shared()
    shc.managedProperties.remove(MGSFragariaDefaultsSyntaxDefinitionName)
    shc.isPersistent = true
}

    
@IBAction func openPreferences(_ sender: AnyObject) {
    if prefsWindow == nil {
        let color = MGSPrefsColourPropertiesViewController()
        let editor = MGSPrefsEditorPropertiesViewController()
        prefsWindow = MASPreferencesWindowController(viewControllers: [color, editor])
    }
    prefsWindow.showWindow(self)
}

    
}

