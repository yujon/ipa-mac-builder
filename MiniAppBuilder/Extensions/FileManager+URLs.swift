//
//  FileManager+URLs.swift
//
//


import Foundation

extension FileManager
{
    var altserverDirectory: URL {
        let applicationSupportDirectoryURL = self.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        
        let altserverDirectoryURL = applicationSupportDirectoryURL.appendingPathComponent("com.tencent.MiniAppBuilder")
        return altserverDirectoryURL
    }
    
    var certificatesDirectory: URL {
        let certificatesDirectoryURL = self.altserverDirectory.appendingPathComponent("Certificates")
        return certificatesDirectoryURL
    }
    
    var developerDisksDirectory: URL {
        let developerDisksDirectoryURL = self.altserverDirectory.appendingPathComponent("DeveloperDiskImages")
        return developerDisksDirectoryURL
    }
}
