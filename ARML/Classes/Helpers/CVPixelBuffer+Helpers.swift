//
//  CVPixelBuffer+Helpers.swift
//  ARML
//
//  Created by Gil Nakache on 24/01/2019.
//  Copyright © 2019 viseo. All rights reserved.
//

import Foundation
import GameKit

extension CVPixelBuffer {
    func search() -> CGPoint? {
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)

        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)

        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))

        defer {
            CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        }

        var returnPoint: CGPoint?

        let clusterRTree = GKRTree(maxNumberOfChildren: 3)

        if let baseAddress = CVPixelBufferGetBaseAddress(self) {
            let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

            for y in (0 ..< height).reversed() {
                for x in (0 ..< width).reversed() {
                    let pixel = buffer[y * bytesPerRow + x * 4]

                    if pixel > 0 {
                        let newPoint = CGPoint(x: x, y: y)

                        clusterRTree.addElement(NSValue(cgPoint: newPoint), boundingRectMin: vector2(Float(x), Float(y)), boundingRectMax: vector2(Float(x), Float(y)), splitStrategy: .linear)

                        let proximityPoints = clusterRTree.elements(inBoundingRectMin: vector2(Float(x - 10), Float(y - 10)), rectMax: vector2(Float(x + 10), Float(y + 10)))

                        if proximityPoints.count > 20 {
                            // we return a normalized point
                            returnPoint = CGPoint(x: newPoint.x / CGFloat(width), y: newPoint.y / CGFloat(height))
                        }

                    } else {
                        // Alpha clear
                        buffer[y * bytesPerRow + x * 4 + 3] = 0
                    }
                }
            }
        }
        return returnPoint
    }
}
