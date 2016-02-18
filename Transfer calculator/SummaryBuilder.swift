//
//  SummaryBuilder.swift
//  Transfer calculator
//
//  Created by Thomas Brichart on 17/02/2016.
//  Copyright © 2016 Thomas Brichart. All rights reserved.
//

import Foundation
import Cocoa

class SummaryBuilder {
    
    init(jobList: [Job]) {
        var result = createHeader()
        result += createAllExperiments(jobList)
        result += createFooter()
    }
    
    func createHeader() -> String {
        var string = String()
    
        if let path = NSBundle.mainBundle().pathForResource("model-header", ofType: "txt"), text = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
            string += text
        }
        
        return string
    }
    
    func createAllExperiments(jobList: [Job]) -> String {
        var string = String()
        
        for (index, job) in jobList.enumerate() {
            string += createExperiment(job, index: index)
        }
        
        return string
    }
    
    func createExperiment(job: Job, index: Int) -> String {
        var string = "<div class='experiment'>"
        string += "<h2>Experiment #\(index + 1)</h2>"
        string += "<p>\(job.description)</p>"
        string += "<h3>Parameters</h3>"
        string += createParameters(job)
        
        string += "<h3>Distances</h3>"
        string += createDistances(job.distancesResult)
        
        string += "<h3>kT</h3>"
        string += createkT(job.kTResult)
        
        string += "</div>"
        
        return string
    }
    
    func createParameters(job: Job) -> String {
        var string = "<table class='parameters'><tbody>"
        string += "<tr><td>Particle Radius</td><td>\(job.particleRadius) nm</td><td>Exclusion Radius</td><td>\(job.exclusionRadius) nm</td></tr>"
        string += "<tr><td># Donors</td><td>\(job.donors)</td><td># Acceptors</td><td>\(job.acceptors)</td></tr>"
        string += "<tr><td>Dimer probability</td><td>\(job.dimerProbability * 10) %</td><td>Repeats</td><td>\(job.repeats)</td></tr>"
        string += "</tbody></table>"
        return string
    }
    
    func createDistances(distanceResults: DistancesResult) -> String {
        guard let donDon = distanceResult["donDon"], let donAcc = distanceResult["donAcc"], let accAcc = distanceResult["accAcc"] else { return }
        
        let maximum = max(donDon.count, donAcc.count, accAcc.count)
        
        for array in [donDon, donAcc, accAcc] {
            for _ in 0..<(maximum - array.count) {
                array.append(0)
            }
        }
        
        var string = String()
        
        if distanceResults.isEmpty {
            string += "<p>No distance results available</p>"
        } else {
            string += "<table class='result'><tbody><tr><td>&nbsp;</td><td>Donor-Donor (nm)</td><td>Donor-Acceptor (nm)</td><td>Acceptor-Acceptor (nm)</td></tr>"
            
            for i in 1...maximum {
                string += "<tr><td>1</td>"
                string += "<td>" + ((donDon[i-1] == 0) ? "" : "\(donDon[i-1])") + "</td>"
                string += "<td>" + ((donAcc[i-1] == 0) ? "" : "\(donAcc[i-1])") + "</td>"
                string += "<td>" + ((accAcc[i-1] == 0) ? "" : "\(accAcc[i-1])") + "</td>"
                string += "</tr>"
            }
            
            string += "</tbody></table>"
        }
        
        return string
    }
    
    func createkT(kTResults: [(distance: Double, kT: Double)]) -> String {
        var string = String()
        
        if kTResults.isEmpty {
            string += "<p>No kT results available</p>"
        } else {
        
        }
        
        return string
    }
    
    func createFooter() -> String {
        var string = "</body>\n"
        string += "</html>"
        
        return string
    }
}
