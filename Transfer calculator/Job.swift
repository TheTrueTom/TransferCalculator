//
//  Job.swift
//  Transfer calculator
//
//  Created by Thomas Brichart on 16/02/2016.
//  Copyright © 2016 Thomas Brichart. All rights reserved.
//

import Foundation

enum JobStatus {
    case Queued, InProgress, Finished, Cancelled
}

enum kTJob {
    case None, DonorDonor, DonorAcceptor, AcceptorAcceptor
}

typealias DistancesResult = [String: [Double]]

class Job: Equatable {
    var creationDate: NSDate = NSDate()
    var description: String = "Experiment"
    var particleRadius: Double = 25
    var donors: Int = 150
    var acceptors: Int = 150
    var exclusionRadius: Double = 1
    var dimerProbability: Double = 0.1
    var repeats: Int = 10
    var kTCalculations: kTJob = .DonorAcceptor
    var status: JobStatus = .Queued
    
    var distancesResult: DistancesResult = ["DonDon": [], "DonAcc": [], "AccAcc": []]
    
    var queue: NSOperationQueue!
    
    /**
     Generate one particule with the parameters taken from the job. Parameters taken are radius, number of donors and acceptors, exclusion radius and dimer probability.
     
     - returns: Generated Particule object
     */
    
    func generateParticule() -> Particule? {
        
        let particule = Particule(radius: particleRadius, donors: donors, acceptors: acceptors, exclusionRadius: exclusionRadius, dimerProbability: dimerProbability)
        
        return particule
    }
    
    /**
     Calculate donor-donor, donor-acceptor and acceptor-acceptor distances for one particle
     
     - parameter particule: The particle whose distances have to be calculated
     - parameter limit: Maximum number of distances to return
     
     - returns: Dictionary of an Array of distances
     */
    
    func calculateAllDistances(particule: Particule, limit: Int = 10) -> [String: [Double]] {
        var result: [String: [Double]] = ["DonDon": [], "DonAcc": [], "AccAcc": []]
        
        let donDon = particule.getMeanSortedDistances(.DonorDonor, limit: limit)
        result.updateValue(donDon, forKey: "DonDon")
        
        let donAcc = particule.getMeanSortedDistances(.DonorAcceptor, limit: limit)
        result.updateValue(donAcc, forKey: "DonAcc")
        
        let accAcc = particule.getMeanSortedDistances(.AcceptorAcceptor, limit: limit)
        result.updateValue(accAcc, forKey: "AccAcc")
        
        return result
    }
    
    /**
     Average the results from multiple DistancesResult into the distancesResult property of the Job class
     
     - parameter source: The array of DistancesResult
     - parameter completionHandler: Block to be executed at the end of the operation
     */
    
    func averageRepeatResults(source: [DistancesResult], completionHandler: (() -> Void)? = nil) {
        var final: [String: [Double]] = ["DonDon": [], "DonAcc": [], "AccAcc": []]
        
        for repeatResult in source {
            for (key, list) in repeatResult {
                if let meanList = final[key] where !meanList.isEmpty {
                    var temp: [Double] = []
                    
                    for i in 0..<list.count {
                        temp.append(meanList[i] + list[i])
                    }
                    
                    final.updateValue(temp, forKey: key)
                }
                
                if let meanList = final[key] where meanList.isEmpty {
                    final.updateValue(list, forKey: key)
                }
            }
        }
        
        for (key, list) in final {
            var temp: [Double] = []
            
            for value in list {
                temp.append(value/Double(source.count))
            }
            
            final.updateValue(temp, forKey: key)
        }
        
        distancesResult = final
        
        completionHandler?()
    }
    
    /**
     Calculate the average distances of the Job particle over a number of repetition
     
     - parameter repeats: The number of repetition to be performed
     - parameter repeatCompletionHandler: Block to be executed at the end of each repetition
     - parameter finalCompletionHandler: Block to be executed once all the repetitions are finished
     */
    
    func getAverageDistances(repeats: Int, repeatCompletionHandler: (() -> Void)? = nil, finalCompletionHandler: (DistancesResult -> Void)? = nil) {
        
        var repeatResults = [[String: [Double]]]() {
            didSet {
                self.averageRepeatResults(repeatResults, completionHandler: repeatCompletionHandler)
            }
        }
        
        queue = NSOperationQueue()
        
        for repetition in 1...repeats {
            let operation = NSBlockOperation(block: {
                if let particule = self.generateParticule() {
                    let preResult = self.calculateAllDistances(particule)
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        repeatResults.append(preResult)
                        
                        print("Repetition \(repetition)/\(repeats) complete")
                    }
                }
            })
            
            queue.addOperation(operation)
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.queue.waitUntilAllOperationsAreFinished()
            finalCompletionHandler?(self.distancesResult)
        }
    }
    
    func maxKTAsCSV(relationType: RelationType, repeats: Int, repeatCompletionHandler: (() -> Void)? = nil, finalCompletionHandler: ([(distance: Double, kT: Double)] -> Void)? = nil) {
        
        var result = [(distance: Double, kT: Double)]()
        
        queue = NSOperationQueue()
        
        for repetition in 1...repeats {
            let operation = NSBlockOperation(block: {
                if let particule = self.generateParticule() {
                    let subResult = particule.getMaxKTAsFunctionOfDistance(relationType)
                    
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        result.appendContentsOf(subResult)
                        
                        print("Repetition \(repetition)/\(repeats) complete")
                        repeatCompletionHandler?()
                    }
                }
            })
            
            queue.addOperation(operation)
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.queue.waitUntilAllOperationsAreFinished()
            
            dispatch_async(dispatch_get_main_queue()) {
                finalCompletionHandler?(result)
            }
            
            /*
            var csvData = "distance (nm), kT,\n"
            
            for element in result {
                csvData += "\(element.distance), \(element.kT),\n"
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                let saveDialog = NSSavePanel()
                
                saveDialog.message = "Please select a path where to save the kT as a function of distance data."
                saveDialog.allowsOtherFileTypes = false
                saveDialog.canCreateDirectories = true
                saveDialog.nameFieldStringValue = "untitled.csv"
                saveDialog.title = "Saving Data..."
                
                let saveResult = saveDialog.runModal()
                
                if saveResult == NSFileHandlingPanelOKButton {
                    if let path = saveDialog.URL?.path {
                        NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil)
                        do {
                            try csvData.writeToFile(path, atomically: true, encoding: NSUTF8StringEncoding)
                        } catch let error as NSError {
                            let alert = NSAlert(error: error)
                            alert.runModal()
                        }
                    }
                }
            }*/
            
        }
        
    }
}

extension Job: Hashable {
    var hashValue: Int {
        return creationDate.hashValue
    }
}

func ==(lhs: Job, rhs: Job) -> Bool {
    if lhs.hashValue != rhs.hashValue { return false }
    
    return true
}