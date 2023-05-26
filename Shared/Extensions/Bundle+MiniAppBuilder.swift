//
//  Bundle+MiniAppBuilder.swift
//
//


import Foundation

public extension Bundle
{
    struct Info
    {
        public static let deviceID = "ALTDeviceID"
        public static let certificateID = "ALTCertificateID"
        public static let appGroups = "ALTAppGroups"
        
        public static let urlTypes = "CFBundleURLTypes"
        public static let exportedUTIs = "UTExportedTypeDeclarations"
        
        public static let untetherURL = "ALTFugu14UntetherURL"
        public static let untetherRequired = "ALTFugu14UntetherRequired"
        public static let untetherMinimumiOSVersion = "ALTFugu14UntetherMinimumVersion"
        public static let untetherMaximumiOSVersion = "ALTFugu14UntetherMaximumVersion"
    }
}

public extension Bundle
{
    var infoPlistURL: URL {
        let infoPlistURL = self.bundleURL.appendingPathComponent("Info.plist")
        return infoPlistURL
    }
    
    var provisioningProfileURL: URL {
        let provisioningProfileURL = self.bundleURL.appendingPathComponent("embedded.mobileprovision")
        return provisioningProfileURL
    }
    
    var certificateURL: URL {
        let certificateURL = self.bundleURL.appendingPathComponent("MiniAppCertificate.p12")
        return certificateURL
    }
}

public extension Bundle
{
    var appGroups: [String] {
        return self.infoDictionary?[Bundle.Info.appGroups] as? [String] ?? []
    }
    
    var completeInfoDictionary: [String : Any]? {
        let infoPlistURL = self.infoPlistURL
        return NSDictionary(contentsOf: infoPlistURL) as? [String : Any]
    }
}
