//
//  OperatingSystemVersion+Comparable.swift
//Core
//
//  Created by Riley Testut on 11/15/22.
//
//

import Foundation

extension OperatingSystemVersion: Comparable
{
    public static func ==(lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool
    {
        return lhs.majorVersion == rhs.majorVersion && lhs.minorVersion == rhs.minorVersion && lhs.patchVersion == rhs.patchVersion
    }
    
    public static func <(lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool
    {
        return lhs.stringValue.compare(rhs.stringValue, options: .numeric) == .orderedAscending
    }
}
