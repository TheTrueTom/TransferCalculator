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
        queue?.cancelAllOperations()
        currentJob?.status = .Cancelled
        jobListTable.reloadData()
    }
    
    @IBOutlet weak var playButton: NSButton!
    @IBAction func startJobList(sender: AnyObject) {
        processJobList() {
            if let url = self.pathControl.URL  {
                SummaryBuilder.createReport(self.jobList, url: url)
            }
        }
    }
    
    @IBOutlet weak var pathControl: NSPathControl!
    
    @IBOutlet weak var jobListTable: NSTableView!
    
    @IBOutlet weak var addButton: NSButton!
    @IBAction func addJob(sender: AnyObject) {
        let job = Job()
        job.description = "Experiment #\(jobListTable.numberOfRows + 1)"
        jobList.append(job)
        jobListTable.reloadData()
        
        playButton.enabled = true
    }
    
    @IBOutlet weak var removeButton: NSButton!
    @IBAction func removeJob(sender: AnyObject) {
        jobList = jobList.filter { !jobListTable.selectedRowIndexes.containsIndex(jobList.indexOf($0)!) }
        
        jobListTable.reloadData()
        
        if jobList.isEmpty {
            playButton.enabled = false
        }
    }
    
    @IBAction func openJobList(sender: AnyObject) {
        jobList = CSVEngine.getJobListFromCSV()
        jobListTable.reloadData()
    }
    
    @IBAction func saveJobList(sender: AnyObject) {
        CSVEngine.saveAsCSV(jobList)
    }
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    var jobList: [Job] = [Job()]
    var queue: NSOperationQueue?
    var currentJob: Job?
    
    var distancesResultsList = [DistancesResult]()
    var kTResultsList = [[(distance: Double, kT: Double)]]()
    
    override func viewDidLoad() {
        jobListTable.setDelegate(self)
        jobListTable.setDataSource(self)
        
        playButton.enabled = true
        
        pathControl.URL = NSFileManager.defaultManager().URLsForDirectory(.DesktopDirectory, inDomains: .UserDomainMask).first
    }
    
    func processJobList(completionHandler: (() -> Void)? = nil) {
        stopButton.enabled = true
        playButton.enabled = false
        
        queue = NSOperationQueue()
        queue?.maxConcurrentOperationCount = 1
        
        for job in jobList {
            let operation = NSBlockOperation(block: {
                self.currentJob = job
                
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    job.status = .InProgress
                    self.jobListTable.reloadData()
                    
                    self.progressIndicator.doubleValue = 0
                    self.progressIndicator.maxValue = Double(job.repeats)
                }
                
                // Calcul des distances
                
                job.getAverageDistances(job.repeats, repeatCompletionHandler: {
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            if job.kTCalculations == .None {
                                self.progressIndicator.incrementBy(1)
                            } else {
                                self.progressIndicator.incrementBy(0.5)
                            }
                        }
                    }, finalCompletionHandler: { distancesResult in
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            self.distancesResultsList.append(distancesResult)
                        
                            if job.kTCalculations == .None {
                                job.status = .Finished
                                self.jobListTable.reloadData()
                                
                                self.stopButton.enabled = false
                                self.playButton.enabled = true
                                completionHandler?()
                            }
                        }
                })
                
                // Calcul des kT
                
                if job.kTCalculations != .None {
                    
                    let relation: RelationType = (job.kTCalculations == .DonorDonor) ? .DonorDonor : ((job.kTCalculations == .DonorAcceptor) ? .DonorAcceptor : .AcceptorAcceptor)
                    
                    job.maxKTAsCSV(relation, repeats: job.repeats, repeatCompletionHandler: {
                            NSOperationQueue.mainQueue().addOperationWithBlock {
                                self.progressIndicator.incrementBy(0.5)
                            }
                        }, finalCompletionHandler: { kTResults in
                            NSOperationQueue.mainQueue().addOperationWithBlock {
                                self.kTResultsList.append(kTResults)
                                job.status = .Finished
                                self.jobListTable.reloadData()
                                
                                self.stopButton.enabled = false
                                self.playButton.enabled = true
                                completionHandler?()
                            }
                    })
                }
            })
            
            queue?.addOperation(operation)
        }
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
                return configureLabel(job.description, row: row, tableColumnIdentifier: identifier)
            case "radiusCol":
                return configureLabel("\(job.particleRadius)", row: row, tableColumnIdentifier: identifier)
            case "donorsCol":
                return configureLabel("\(job.donors)", row: row, tableColumnIdentifier: identifier)
            case "acceptorsCol":
                return configureLabel("\(job.acceptors)", row: row, tableColumnIdentifier: identifier)
            case "exclusionCol":
                return configureLabel("\(job.exclusionRadius)", row: row, tableColumnIdentifier: identifier)
            case "dimerCol":
                return configureLabel("\(job.dimerProbability)", row: row, tableColumnIdentifier: identifier)
            case "repeatsCol":
                return configureLabel("\(job.repeats)", row: row, tableColumnIdentifier: identifier)
            case "kTCol":
                return configurePopUpButton(job, row: row, tableColumnIdentifier: identifier)
            case "statusCol":
                return configureStatusImage(job)
            default:
                return nil
            }
        }
        
        return nil
    }
    
    func configureLabel(text: String, row: Int = 0, tableColumnIdentifier: String = "") -> NSTextField {
        let label = CellTextField()
        label.delegate = self
        label.row = row
        label.columnIdentifier = tableColumnIdentifier
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
    
    func configurePopUpButton(job: Job, row: Int = 0, tableColumnIdentifier: String = "") -> NSPopUpButton {
        let popup = CellPopUpButton()
        popup.action = "popUpButtonDidChange:"
        popup.row = row
        popup.columnIdentifier = tableColumnIdentifier
        popup.addItemsWithTitles(["None","Donor-Donor","Donor-Acceptor","Acceptor-Acceptor"])
        
        let title: String!
        if job.kTCalculations == .None {
            title = "None"
        } else if job.kTCalculations == .DonorDonor {
            title = "Donor-Donor"
        } else if job.kTCalculations == .DonorAcceptor {
            title = "Donor-Acceptor"
        } else {
            title = "Acceptor-Acceptor"
        }
        
        popup.selectItemWithTitle(title)
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

extension BatchViewController: NSTextFieldDelegate {
    override func controlTextDidEndEditing(obj: NSNotification) {
        
        if let cellTextField = obj.object as? CellTextField {
            let job = jobList[cellTextField.row]
            
            switch cellTextField.columnIdentifier {
            case "descriptionCol":
                job.description = cellTextField.stringValue
            case "radiusCol":
                if let particleRadius = Double(cellTextField.stringValue) {
                    job.particleRadius = particleRadius
                }
            case "donorsCol":
                if let donors = Int(cellTextField.stringValue) {
                    job.donors = donors
                }
            case "acceptorsCol":
                if let acceptors = Int(cellTextField.stringValue) {
                    job.acceptors = acceptors
                }
            case "exclusionCol":
                if let exclusionRadius = Double(cellTextField.stringValue) {
                    job.exclusionRadius = exclusionRadius
                }
            case "dimerCol":
                if let dimerProbability = Double(cellTextField.stringValue) {
                    job.dimerProbability = dimerProbability
                }
            case "repeatsCol":
                if let repeats = Int(cellTextField.stringValue) {
                    job.repeats = repeats
                }
            default:
                return
            }
        }
    }
    
    func popUpButtonDidChange(obj: AnyObject) {
        
        if let popUpButton = obj as? CellPopUpButton {
            let job = jobList[popUpButton.row]
            
            switch popUpButton.title {
            case "None":
                job.kTCalculations = .None
            case "Donor-Donor":
                job.kTCalculations = .DonorDonor
            case "Donor-Acceptor":
                job.kTCalculations = .DonorAcceptor
            case "Acceptor-Acceptor":
                job.kTCalculations = .AcceptorAcceptor
            default:
                return
            }
        }
    }
}
