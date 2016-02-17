//
//  BatchViewController.swift
//  Transfer calculator
//
//  Created by Thomas Brichart on 16/02/2016.
//  Copyright © 2016 Thomas Brichart. All rights reserved.
//

import Foundation
import Cocoa

class BatchViewController: NSViewController {
    
    @IBOutlet weak var stopButton: NSButton!
    @IBAction func stopJobList(sender: AnyObject) {
        
    }
    
    @IBOutlet weak var playButton: NSButton!
    @IBAction func startJobList(sender: AnyObject) {
        
    }
    
    @IBOutlet weak var jobListTable: NSTableView!
    
    @IBOutlet weak var addButton: NSButton!
    @IBAction func addJob(sender: AnyObject) {
        jobList.append(Job())
        jobListTable.reloadData()
    }
    
    @IBOutlet weak var removeButton: NSButton!
    @IBAction func removeJob(sender: AnyObject) {
        jobList = jobList.filter { !jobListTable.selectedRowIndexes.containsIndex(jobList.indexOf($0)!) }
        
        jobListTable.reloadData()
    }
    
    var jobList: [Job] = [Job()]
    
    override func viewDidLoad() {
        jobListTable.setDelegate(self)
        jobListTable.setDataSource(self)
    }
}

extension BatchViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return jobList.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let job = jobList[row]
        
        if let identifier = tableColumn?.identifier {
            switch identifier {
            case "numberCol":
                return configureLabel("\(row + 1)")
            case "descriptionCol":
                return configureLabel(job.description)
            case "radiusCol":
                return configureLabel("\(job.particleRadius)")
            case "donorsCol":
                return configureLabel("\(job.donors)")
            case "acceptorsCol":
                return configureLabel("\(job.acceptors)")
            case "exclusionCol":
                return configureLabel("\(job.exclusionRadius)")
            case "dimerCol":
                return configureLabel("\(job.dimerProbability)")
            case "kTCol":
                return configurePopUpButton(job.status)
            case "statusCol":
                return configureStatusImage(job)
            default:
                return nil
            }
        }
        
        return nil
    }
    
    func configureLabel(text: String) -> NSTextField {
        let label = NSTextField()
        label.stringValue = text
        label.bordered = false
        label.backgroundColor = NSColor.clearColor()
        return label
    }
    
    func configureStatusImage(job: Job) -> NSImageView {
        var imageView = NSImageView()
        
        switch job.status {
        case .Cancelled:
            imageView.image = NSImage(named: "cancelled")
        case .Finished:
            imageView.image = NSImage(named: "complete")
        case .InProgress:
            imageView = NSAnimatedImageView(imageList: ["working0", "working1", "working2", "working3", "working4", "working5"])
        case .Queued:
            imageView.image = NSImage()
        }
        
        return imageView
    }
    
    func configurePopUpButton(status: JobStatus) -> NSPopUpButton {
        let popup = NSPopUpButton()
        popup.addItemsWithTitles(["None","Donor-Donor","Donor-Acceptor","Acceptor-Acceptor"])
        
        return popup
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        if jobListTable.selectedRowIndexes.count != 0 {
            removeButton.enabled = true
        } else {
            removeButton.enabled = false
        }
    }
}