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
    @IBAction func stopJobList(_ sender: AnyObject) {
        queue.cancelAllOperations()
        currentJob?.status = .cancelled
        jobListTable.reloadData()
    }
    
    @IBOutlet weak var playButton: NSButton!
    @IBAction func startJobList(_ sender: AnyObject) {
        processJobList() {
            if let url = self.pathControl.url  {
                SummaryBuilder.createReport(self.jobList, url: url)
            }
        }
    }
    
    @IBOutlet weak var pathControl: NSPathControl!
    
    @IBOutlet weak var jobListTable: NSTableView!
    
    @IBOutlet weak var addButton: NSButton!
    @IBAction func addJob(_ sender: AnyObject) {
        let job = Job()
        job.description = "Experiment #\(jobListTable.numberOfRows + 1)"
        jobList.append(job)
        jobListTable.reloadData()
        
        playButton.isEnabled = true
    }
    
    @IBOutlet weak var removeButton: NSButton!
    @IBAction func removeJob(_ sender: AnyObject) {
        jobList = jobList.filter { !jobListTable.selectedRowIndexes.contains(jobList.index(of: $0)!) }
        
        jobListTable.reloadData()
        
        if jobList.isEmpty {
            playButton.isEnabled = false
        }
    }
    
    @IBAction func openJobList(_ sender: AnyObject) {
        jobList = CSVEngine.getJobListFromCSV()
        jobListTable.reloadData()
    }
    
    @IBAction func saveJobList(_ sender: AnyObject) {
        CSVEngine.saveAsCSV(jobList)
    }
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    var jobList: [Job] = [Job()]
    var queue: OperationQueue = OperationQueue()
    var currentJob: Job?
    
    var distancesResultsList = [DistancesResult]()
    var kTResultsList = [[(distance: Double, kT: Double)]]()
    
    override func viewDidLoad() {
        jobListTable.delegate = self
        jobListTable.dataSource = self
        
        playButton.isEnabled = true
        
        pathControl.url = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
    }
    
    func processJobList(_ completionHandler: (() -> Void)? = nil) {
        stopButton.isEnabled = true
        playButton.isEnabled = false
        
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        for job in jobList {
            let operation = BlockOperation(block: {
                self.currentJob = job
                
                OperationQueue.main.addOperation {
                    job.status = .inProgress
                    self.jobListTable.reloadData()
                    
                    self.progressIndicator.doubleValue = 0
                    self.progressIndicator.maxValue = Double(job.repeats)
                }
                
                // Calcul des distances
                
                let distancesResult = job.getAverageDistances(job.repeats, repeatCompletionHandler: {
                        OperationQueue.main.addOperation {
                            self.progressIndicator.increment(by: (job.kTCalculations == .none) ? 1 : 0.5)
                        }
                    })
                
                OperationQueue.main.addOperation {
                    self.distancesResultsList.append(distancesResult)
                    
                    if job.kTCalculations == .none {
                        job.status = .finished
                        
                        self.jobListTable.reloadData()
                        
                        completionHandler?()
                    }
                }
                
                
                // Calcul des kT
                
                if job.kTCalculations != .none {
                    
                    let relation: RelationType = (job.kTCalculations == .donorDonor) ? .donorDonor : ((job.kTCalculations == .donorAcceptor) ? .donorAcceptor : .acceptorAcceptor)
                    
                    let kTResults = job.maxKTAsCSV(relation, repeats: job.repeats, repeatCompletionHandler: {
                            OperationQueue.main.addOperation {
                                self.progressIndicator.increment(by: 0.5)
                            }
                        })
                    
                    OperationQueue.main.addOperation {
                        self.kTResultsList.append(kTResults)
                        job.status = .finished
                        
                        self.jobListTable.reloadData()
                        
                        completionHandler?()
                    }
                }
            })
            
            queue.addOperation(operation)
        }
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async {
            self.queue.waitUntilAllOperationsAreFinished()
        
            DispatchQueue.main.async {
                self.stopButton.isEnabled = false
                self.playButton.isEnabled = true
            }
        }
    }
}

extension BatchViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return jobList.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
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
    
    func configureLabel(_ text: String, row: Int = 0, tableColumnIdentifier: String = "") -> NSTextField {
        let label = CellTextField()
        label.delegate = self
        label.row = row
        label.columnIdentifier = tableColumnIdentifier
        label.stringValue = text
        label.isBordered = false
        label.backgroundColor = NSColor.clear
        return label
    }
    
    func configureStatusImage(_ job: Job) -> NSImageView {
        var imageView = NSImageView()
        
        switch job.status {
        case .cancelled:
            imageView.image = NSImage(named: "cancelled")
        case .finished:
            imageView.image = NSImage(named: "complete")
        case .inProgress:
            imageView = NSAnimatedImageView(imageList: ["working0", "working1", "working2", "working3", "working4", "working5"])
        case .queued:
            imageView.image = NSImage()
        }
        
        return imageView
    }
    
    func configurePopUpButton(_ job: Job, row: Int = 0, tableColumnIdentifier: String = "") -> NSPopUpButton {
        let popup = CellPopUpButton()
        popup.action = "popUpButtonDidChange:"
        popup.row = row
        popup.columnIdentifier = tableColumnIdentifier
        popup.addItems(withTitles: ["None","Donor-Donor","Donor-Acceptor","Acceptor-Acceptor"])
        
        let title: String!
        if job.kTCalculations == .none {
            title = "None"
        } else if job.kTCalculations == .donorDonor {
            title = "Donor-Donor"
        } else if job.kTCalculations == .donorAcceptor {
            title = "Donor-Acceptor"
        } else {
            title = "Acceptor-Acceptor"
        }
        
        popup.selectItem(withTitle: title)
        return popup
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if jobListTable.selectedRowIndexes.count != 0 {
            removeButton.isEnabled = true
        } else {
            removeButton.isEnabled = false
        }
    }
}

extension BatchViewController: NSTextFieldDelegate {
    override func controlTextDidEndEditing(_ obj: Notification) {
        
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
    
    func popUpButtonDidChange(_ obj: AnyObject) {
        
        if let popUpButton = obj as? CellPopUpButton {
            let job = jobList[popUpButton.row]
            
            switch popUpButton.title {
            case "None":
                job.kTCalculations = .none
            case "Donor-Donor":
                job.kTCalculations = .donorDonor
            case "Donor-Acceptor":
                job.kTCalculations = .donorAcceptor
            case "Acceptor-Acceptor":
                job.kTCalculations = .acceptorAcceptor
            default:
                return
            }
        }
    }
}
