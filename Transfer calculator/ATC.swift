//
//  ATC.swift
//  Transfer calculator
//
//  Created by Thomas Brichart on 08/01/2016.
//  Copyright © 2016 Thomas Brichart. All rights reserved.
//

import Foundation

func randomDouble() -> Double {
    return Double(arc4random_uniform(UINT32_MAX)) / Double(UINT32_MAX)
}

enum CalculationType {
    case distance, kT
}

enum RelationType {
    case donorDonor, donorAcceptor, acceptorAcceptor
}

class Particule {
    var acceptorsNumber: Int = 0
    var donorsNumber: Int = 0
    let radius: Double!
    var moleculesList: [Int: Molecule] = [:]
    var dimerNumber: Int = 0
    
    var distanceTable: [Int: [Int: Double]] = [:]
    var kTTable: [Int: [Int: Double]] = [:]
    
    init(radius: Double, kernelRadius: Double, donors: Int, acceptors: Int, exclusionRadius: Double, dimerProbability: Double) {
        
        self.radius = radius
        
       while self.acceptorsNumber < acceptors {
        let candidate = Molecule(inParticleOfRadius: radius, withKernelRadius: kernelRadius, withDimerProbability: dimerProbability)
           
           var isTooClose = false
           
           for (_, molecule) in moleculesList {
               if candidate.distanceToMolecule(molecule) < exclusionRadius {
                   isTooClose = true
                   break
               }
           }
           
           if !isTooClose {
               candidate.molID = (acceptorsNumber + 1)
               moleculesList[candidate.molID] = candidate
               acceptorsNumber += 1
           } 
       }
       
       while self.donorsNumber < donors {
           let candidate = Molecule(inParticleOfRadius: radius, withKernelRadius: kernelRadius,withDimerProbability: dimerProbability)
           
           var isTooClose = false
           
           for (_, molecule) in moleculesList {
               if candidate.distanceToMolecule(molecule) < exclusionRadius {
                   isTooClose = true
                   break
               }
           }
           
           if !isTooClose {
               candidate.molID = -(donorsNumber + 1)
               moleculesList[candidate.molID] = candidate
               donorsNumber += 1
               
               if candidate.isDimer {
                   dimerNumber += 1
               }
            }
       }
    }
    
    func getMeanSortedDistances(_ relationType: RelationType, limit: Int = 10) -> [Double] {
        
        let ranges = getRanges(relationType)
        
        var results = [[Double]]()
        
        for i in ranges.first {
            if let firstMolecule = moleculesList[i] {
                
                var subResult = [Double]()
                
                for j in ranges.second {
                    if let secondMolecule = moleculesList[j], secondMolecule.molID != firstMolecule.molID {
                        subResult.append(firstMolecule.distanceToMolecule(secondMolecule))
                    }
                }
                
                if !subResult.isEmpty {
                    subResult.sort { $0 < $1 }
                    
                    if subResult.count > limit {
                        subResult = Array(subResult[0..<limit])
                    }
                }
                
                results.append(subResult)
            }
        }
        
        var final = [Double]()
        
        for distanceList in results {
            if final.isEmpty {
                final = distanceList
            } else {
                for i in 0..<distanceList.count {
                    final[i] += distanceList[i]
                }
            }
        }
        
        for i in 0..<final.count {
            final[i] = final[i] / Double(results.count)
        }
        
        return final
    }
    
    func getMaxKTAsFunctionOfDistance(_ relationType: RelationType) -> [(distance: Double, kT: Double)] {
        
        let ranges = getRanges(relationType)
        
        var result = [(distance: Double, kT: Double)]()
        
        for i in ranges.first {
            if let firstMolecule = moleculesList[i] {
                var distance: Double = 0
                var maxKT: Double = 0
                
                for j in ranges.second {
                    if let secondMolecule = moleculesList[j], secondMolecule.molID != firstMolecule.molID {
                        let kT = firstMolecule.kTRelativeToMolecule(secondMolecule)
                        
                        if kT > maxKT {
                            maxKT = kT
                            distance = firstMolecule.distanceToMolecule(secondMolecule)
                        }
                    }
                }
                
                if distance != 0 {
                    result.append((distance: distance, kT: maxKT))
                }
            }
        }
        
        return result
    }
    
    func getRanges(_ relationType: RelationType) -> (first: CountableRange<Int>, second: CountableRange<Int>) {
        
        let firstRange: CountableRange<Int>!
        let secondRange: CountableRange<Int>!
        
        switch relationType {
        case .donorDonor:
            firstRange = (donorsNumber == 0) ? (0 ..< 0) : -donorsNumber..<(0)
            secondRange = (donorsNumber == 0) ? (0 ..< 0) : -donorsNumber..<(0)
        case .donorAcceptor:
            firstRange = (donorsNumber == 0) ? (0 ..< 0) : -donorsNumber..<(0)
            secondRange = (acceptorsNumber == 0) ? (0 ..< 0) : 1..<(acceptorsNumber + 1)
        case .acceptorAcceptor:
            firstRange = (acceptorsNumber == 0) ? (0 ..< 0) : 1..<(acceptorsNumber + 1)
            secondRange = (acceptorsNumber == 0) ? (0 ..< 0) : 1..<(acceptorsNumber + 1)
        }
        
        return (first: firstRange, second: secondRange)
    }
}

class Molecule {
    var molID: Int = -1
    
    var radius: Double!
    var theta: Double!
    var phi: Double!
    
    var x: Double { return self.radius * sqrt(1 - pow(self.theta, 2)) * cos(self.phi) }
    var y: Double  { return self.radius * sqrt(1 - pow(self.theta, 2)) * sin(self.phi) }
    var z: Double  { return self.radius * self.theta }
    
    var directionPhi: Double!
    var directionTheta: Double!
    
    var isDimer: Bool = false
    
    init(inParticleOfRadius radius: Double, withKernelRadius kernelRadius: Double, withDimerProbability dimerProbability: Double) {
        self.radius = sqrt(randomDouble()) * radius
        
        while self.radius < kernelRadius {
            self.radius = sqrt(randomDouble()) * radius
        }
        
        self.theta = -1 + randomDouble() * 2
        self.phi = 2 * .pi * randomDouble()
        
        self.directionTheta = .pi * randomDouble()
        self.directionPhi = 2 * .pi * randomDouble()
        
        let random = randomDouble()
        
        if random < dimerProbability {
            isDimer = true
        }
    }
    
    func distanceToMolecule(_ otherMolecule: Molecule) -> Double {
        return sqrt(pow(self.x - otherMolecule.x, 2) + pow(self.y - otherMolecule.y, 2) + pow(self.z - otherMolecule.z, 2))
    }
    
    func kTRelativeToMolecule(_ otherMolecule: Molecule) -> Double {
        return pow((sin(self.directionTheta) * sin(otherMolecule.directionTheta) * cos(self.directionPhi - otherMolecule.directionPhi) - 2 * cos(self.directionTheta) * cos(otherMolecule.directionTheta)), 2) / pow(self.distanceToMolecule(otherMolecule), 6)
    }
}

class Utils {
    
    enum OrderType {
        case ascending, descending
    }
    
    class func averageDicOfArrays(_ dic: [Int: [Double]]) -> [Double] {
        var result = [Double]()
        
        var temp = [[Double]]()
        
        for (_, truc) in dic {
            
            for (index, distance) in truc.enumerated() {
                if temp.count <= index {
                    temp.append([distance])
                } else {
                    temp[index].append(distance)
                }
            }
        }
        
        for array in temp {
            let sum = array.reduce(0, {$0 + $1})
            result.append(sum / Double(array.count))
        }
        
        return result
    }
}
