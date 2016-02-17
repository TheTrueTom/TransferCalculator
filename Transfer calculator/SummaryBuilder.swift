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
        var string = "<!DOCTYPE html>\n"
        string += "<html lang='en'>\n"
        string += "<head>\n"
        string += "<title>Result Summary</title>\n"
        string += "</head>\n"
        string += "<body>\n"
        
        return string
    }
    
    func createAllExperiments(jobList: [Job]) -> String {
        var string = String()
        
        for job in jobList {
            string += createExperiment(job)
        }
        
        return string
    }
    
    func createExperiment(job: Job) -> String {
        var string = "<h1>\(job.description)</h1>"
        string += "<h2>Parameters</h2>"
        string += createParameters(job)
        
        string += "<h2>Distances</h2>"
        string += createDistances(job.distancesResult)
        
        string += "<h2>kT</h2>"
        string += createkT(job.kTResult)
        
        return string
    }
    
    func createParameters(job: Job) -> String {
        return ""
    }
    
    func createDistances(distanceResults: DistancesResult) -> String {
        return ""
    }
    
    func createkT(kTResults: [(distance: Double, kT: Double)]) -> String {
        return ""
    }
    
    func createFooter() -> String {
        var string = "</body>\n"
        string += "</html>"
        
        return string
    }
}