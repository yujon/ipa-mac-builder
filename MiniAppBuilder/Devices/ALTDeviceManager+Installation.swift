//
//  ALTDeviceManager+Installation.swift
//
//

import Cocoa
import UserNotifications
import ObjectiveC
import Security

private let appGroupsSemaphore = DispatchSemaphore(value: 1)
private let developerDiskManager = DeveloperDiskManager()

private let session: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    configuration.urlCache = nil
    
    let session = URLSession(configuration: configuration)
    return session
}()

extension OperationError
{
    enum Code: Int, ALTErrorCode
    {
        typealias Error = OperationError
        
        case cancelled
        case noTeam
        case missingPrivateKey
        case missingCertificate
    }
    
    static let cancelled = OperationError(code: .cancelled)
    static let noTeam = OperationError(code: .noTeam)
    static let missingPrivateKey = OperationError(code: .missingPrivateKey)
    static let missingCertificate = OperationError(code: .missingCertificate)
}

struct OperationError: ALTLocalizedError
{
    var code: Code
    var errorTitle: String?
    var errorFailure: String?
    
    var errorFailureReason: String {
        switch self.code
        {
        case .cancelled: return NSLocalizedString("The operation was cancelled.", comment: "")
        case .noTeam: return NSLocalizedString("You are not a member of any developer teams.", comment: "")
        case .missingPrivateKey: return NSLocalizedString("The developer certificate's private key could not be found.", comment: "")
        case .missingCertificate: return NSLocalizedString("The developer certificate could not be found.", comment: "")
        }
    }
}


func executeCommand(_ command: String) -> String? {
    let process = Process()
    process.launchPath = "/bin/bash"
    process.arguments = ["-c", command]
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    process.launch()
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    let outputString = String(data: outputData, encoding: .utf8)
    return outputString
}

private extension ALTDeviceManager
{
    struct Source: Decodable
    {
        struct App: Decodable
        {
            struct Version: Decodable
            {
                var version: String
                var downloadURL: URL
                
                var minimumOSVersion: OperatingSystemVersion? {
                    return self.minOSVersion.map { OperatingSystemVersion(string: $0) }
                }
                private var minOSVersion: String?
            }
            
            var name: String
            var bundleIdentifier: String
            
            var versions: [Version]?
        }
        
        var name: String
        var identifier: String
        
        var apps: [App]
    }
}

extension ALTDeviceManager
{
    func installApplication(at application: ALTApplication, to device: ALTDevice,  profiles: Set<String>, completion: @escaping (Result<Void, Error>) -> Void)
    {
        let ipaFileURL = application.fileURL;
        let bundleIdentifier = application.bundleIdentifier;
        var appName = ipaFileURL.deletingPathExtension().lastPathComponent
        self.prepareDevice(device) { (result) in
            switch result
            {
            case .failure(let error):
                printStdErr("Failed to install DeveloperDiskImage.dmg to \(device).", error)
                fallthrough // Continue installing app even if we couldn't install Developer disk image.
            
            case .success:
                do{
                    ALTDeviceManager.shared.installApp(at: ipaFileURL, to: device, activeProvisioningProfiles: profiles) { (success, error) in
                        if(error != nil) {
                            completion(Result(success, error))
                            return
                        }
                        ALTDeviceManager.shared.launchApp(forBundleIdentifier: bundleIdentifier, to: device) { (success, error) in
                            completion(Result(success, error))
                        }
                    }
                }
                catch
                {
                    let failure = String(format: NSLocalizedString("%@ could not be downloaded.", comment: ""), appName)
                    completion(.failure(failure as! Error))
                }
            }
        }
    }
    
    func signWithAppleID(at ipaFileURL: URL, to altDevice: ALTDevice, appleID: String, password: String, bundleId: String?, entitlements: [String: String] , completion: @escaping (Result<(ALTApplication, Set<String>), Error>) -> Void)
    {

        let destinationDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var appName = ipaFileURL.deletingPathExtension().lastPathComponent
        
        func finish(_ result: Result<(ALTApplication,Set<String>), Error>, failure: String? = nil)
        {
            DispatchQueue.main.async {
                switch result
                {
                case .success(let result):
                    print("Sign the app successfully")
                    completion(.success(result))
                case .failure(var error as NSError):
                    error = error.withLocalizedTitle(String(format: NSLocalizedString("%@ could not sign %@.", comment: ""), appName, altDevice.name))
                    if let failure, error.localizedFailure == nil
                    {
                        error = error.withLocalizedFailure(failure)
                    }
                    completion(.failure(error))
                }
            }
            // try? FileManager.default.removeItem(at: destinationDirectoryURL)
        }

        print("Init the sign environment for " + appleID + "...");
        AnisetteDataManager.shared.requestAnisetteData { (result) in
            do
            {
                let anisetteData = try result.get()
                self.authenticate(appleID: appleID, password: password, anisetteData: anisetteData) { (result) in
                    do
                    {
                        let (account, session) = try result.get()
                        
                        self.fetchTeam(for: account, session: session) { (result) in
                            do
                            {
                                let team = try result.get()
                                
                                self.register(altDevice, team: team, session: session) { (result) in
                                    do
                                    {
                                        let device = try result.get()
                                        device.osVersion = altDevice.osVersion
                                        
                                        self.fetchCertificate(for: team, session: session) { (result) in
                                            do
                                            {
                                                let certificate = try result.get()

                                                let fileURL = ipaFileURL
                                                
                                                try FileManager.default.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                                                // 解压ipa
                                                var appBundleURL = try FileManager.default.unzipAppBundle(at: fileURL, toDirectory: destinationDirectoryURL)
                                                guard let application = ALTApplication(fileURL: appBundleURL) else { throw ALTError(.invalidApp) }
                                                
                                                appName = application.name
                                                
                                                // Refresh anisette data to prevent session timeouts.
                                                AnisetteDataManager.shared.requestAnisetteData { (result) in
                                                    do
                                                    {
                                                        let anisetteData = try result.get()
                                                        session.anisetteData = anisetteData
                                                        
                                                        self.prepareAllProvisioningProfiles(for: application, device: device, team: team, bundleId: bundleId, entitlements: entitlements, session: session) { (result) in
                                                            do
                                                            {
                                                                let profiles = try result.get()
                                                                self.signCore(application, certificate: certificate, profiles: profiles, entitlements: entitlements) { (result) in
                                                                    do
                                                                    {
                                                                        let activeProfiles = try result.get()
                                                                        guard let newApplication = ALTApplication(fileURL: application.fileURL) else { throw ALTError(.invalidApp) }
                                                                        finish(.success((newApplication, activeProfiles)))
                                                                    }
                                                                    catch
                                                                    {
                                                                        finish(.failure(error))
                                                                    }
                                                                }
                                                            }
                                                            catch
                                                            {
                                                                finish(.failure(error), failure: NSLocalizedString("MIniAppBuilder could not fetch new provisioning profiles.", comment: ""))
                                                            }
                                                        }
                                                    }
                                                    catch
                                                    {
                                                        finish(.failure(error))
                                                    }
                                                }
                                            }
                                            catch
                                            {
                                                finish(.failure(error), failure: NSLocalizedString("A valid signing certificate could not be created.", comment: ""))
                                            }
                                        }
                                    }
                                    catch
                                    {
                                        finish(.failure(error), failure: NSLocalizedString("Your device could not be registered with your development team.", comment: ""))
                                    }
                                }
                            }
                            catch
                            {
                                finish(.failure(error))
                            }
                        }
                    }
                    catch
                    {
                        finish(.failure(error), failure: NSLocalizedString("MiniAppBuilder could not sign in with your Apple ID.", comment: ""))
                    }
                }
            }
            catch
            {
                finish(.failure(error))
            }
        }
    }

    func signWithCertificate(at ipaFileURL: URL, certificatePath: String, certificatePassword: String?, profilePath: String, entitlements: [String: String], completion: @escaping (Result<(ALTApplication, Set<String>), Error>) -> Void)
    {

        let destinationDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var appName = ipaFileURL.deletingPathExtension().lastPathComponent

        func finish(_ result: Result<(ALTApplication,Set<String>), Error>, failure: String? = nil)
        {
            DispatchQueue.main.async {
                switch result
                {
                case .success(let result): completion(.success(result))
                case .failure(var error as NSError):
                    error = error.withLocalizedTitle(String(format: NSLocalizedString("%@ could not sign %@.", comment: ""), appName))
                    if let failure, error.localizedFailure == nil
                    {
                        error = error.withLocalizedFailure(failure)
                    }
                    completion(.failure(error))
                }
            }
            // try? FileManager.default.removeItem(at: destinationDirectoryURL)
        }
        
        do
        {
           try FileManager.default.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true, attributes: nil)
           // 解压ipa
           let appBundleURL = try FileManager.default.unzipAppBundle(at: ipaFileURL, toDirectory: destinationDirectoryURL)
           guard let application = ALTApplication(fileURL: appBundleURL) else { throw ALTError(.invalidApp) }

            guard FileManager.default.fileExists(atPath: certificatePath) else { throw ALTError(.missingCertificate) }

            let certificateFileURL = URL(fileURLWithPath: certificatePath)
            let profileFileURL = URL(fileURLWithPath: profilePath)
            if let data = try? Data(contentsOf: certificateFileURL),
               let certificate = ALTCertificate(p12Data: data, password: certificatePassword)
            {
                // Manually set machineIdentifier so we can encrypt + embed certificate if needed.
                certificate.machineIdentifier = certificatePassword

                let provisioningProfile: ALTProvisioningProfile = try ALTProvisioningProfile(url: profileFileURL)
                let profiles = [application.bundleIdentifier:provisioningProfile]

                self.signCore(application, certificate: certificate, profiles: profiles, entitlements: entitlements) { (result) in
                    do
                    {
                        let activeProfiles = try result.get()
                        finish(.success((application, activeProfiles)))
                    }
                    catch
                    {
                        finish(.failure(error))
                    }
                }
            } else {
                printStdErr("parse certificate fail")
                // finish(.failure(error))
            }
        }
        catch
        {
            finish(.failure(error))
        }
    }


}

extension ALTDeviceManager
{
    func prepareDevice(_ device: ALTDevice, completionHandler: @escaping (Result<Void, Error>) -> Void)
    {        
        ALTDeviceManager.shared.isDeveloperDiskImageMounted(for: device) { (isMounted, error) in
            switch (isMounted, error)
            {
            case (_, let error?): return completionHandler(.failure(error))
            case (true, _): return completionHandler(.success(()))
            case (false, _):
                developerDiskManager.downloadDeveloperDisk(for: device) { (result) in
                    switch result
                    {
                    case .failure(let error): completionHandler(.failure(error))
                    case .success((let diskFileURL, let signatureFileURL)):
                        ALTDeviceManager.shared.installDeveloperDiskImage(at: diskFileURL, signatureURL: signatureFileURL, to: device) { (success, error) in
                            switch Result(success, error)
                            {
                            case .failure(let error as ALTServerError) where error.code == .incompatibleDeveloperDisk:
                                developerDiskManager.setDeveloperDiskCompatible(false, with: device)
                                completionHandler(.failure(error))
                                
                            case .failure(let error):
                                // Don't mark developer disk as incompatible because it probably failed for a different reason.
                                completionHandler(.failure(error))
                                
                            case .success:
                                developerDiskManager.setDeveloperDiskCompatible(true, with: device)
                                completionHandler(.success(()))
                            }
                        }
                    }
                }
            }
        }
    }
}

private extension ALTDeviceManager
{
    
    func authenticate(appleID: String, password: String, anisetteData: ALTAnisetteData, completionHandler: @escaping (Result<(ALTAccount, ALTAppleAPISession), Error>) -> Void)
    {
        func handleVerificationCode(_ completionHandler: @escaping (String?) -> Void)
        {
            let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
            let inputCommand = executableURL.deletingLastPathComponent().appendingPathComponent("input.sh").path
            let inputOutput = executeCommand("\"\(inputCommand)\" \"Please enter your verificationCode:\"")
            if let input = inputOutput {
                let inputLines = input.split(separator: "\n")
                if inputLines.count < 1  {
                    printStdErr("verificationCode is undefined")
                    completionHandler(nil)
                }
                let code = String(inputLines[0])
                completionHandler(code)
            } else {
                printStdErr("verificationCode is undefined")
                completionHandler(nil)
            }
        }
        
        ALTAppleAPI.shared.authenticate(appleID: appleID, password: password, anisetteData: anisetteData, verificationHandler: handleVerificationCode) { (account, session, error) in
            if let account = account, let session = session
            {
                completionHandler(.success((account, session)))
            }
            else
            {
                completionHandler(.failure(error ?? ALTAppleAPIError.unknown()))
            }
        }
    }
    
    func fetchTeam(for account: ALTAccount, session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTTeam, Error>) -> Void)
    {
        ALTAppleAPI.shared.fetchTeams(for: account, session: session) { (teams, error) in
            do
            {
                let teams = try Result(teams, error).get()
                
                if let team = teams.first(where: { $0.type == .individual })
                {
                    return completionHandler(.success(team))
                }
                else if let team = teams.first(where: { $0.type == .free })
                {
                    return completionHandler(.success(team))
                }
                else if let team = teams.first
                {
                    return completionHandler(.success(team))
                }
                else
                {
                    throw OperationError(.noTeam)
                }
            }
            catch
            {
                completionHandler(.failure(error))
            }
        }
    }
    
    func fetchCertificate(for team: ALTTeam, session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTCertificate, Error>) -> Void)
    {
        ALTAppleAPI.shared.fetchCertificates(for: team, session: session) { (certificates, error) in
            do
            {
                var isCancelled = false
                let certificates = try Result(certificates, error).get()
                
                let certificateFileURL = FileManager.default.certificatesDirectory.appendingPathComponent(team.identifier + ".p12")
                try FileManager.default.createDirectory(at: FileManager.default.certificatesDirectory, withIntermediateDirectories: true, attributes: nil)
                
                // Check if there is another MiniAppBuilder certificate, which means MiniAppBuilder has been installed with this Apple ID before.
                let miniappCertificate = certificates.first { $0.machineName?.starts(with: "MiniAppBuilder") == true }
                if let previousCertificate = miniappCertificate
                {
                    if FileManager.default.fileExists(atPath: certificateFileURL.path),
                       let data = try? Data(contentsOf: certificateFileURL),
                       let certificate = ALTCertificate(p12Data: data, password: previousCertificate.machineIdentifier)
                    {
                        // Manually set machineIdentifier so we can encrypt + embed certificate if needed.
                        certificate.machineIdentifier = previousCertificate.machineIdentifier
                        return completionHandler(.success(certificate))
                    }
                }

                // 安装证书
                func addCertificate()
                {
                    ALTAppleAPI.shared.addCertificate(machineName: "MiniAppBuilder", to: team, session: session) { (certificate, error) in
                        do
                        {
                            let certificate = try Result(certificate, error).get()
                            guard let privateKey = certificate.privateKey else { throw OperationError(.missingPrivateKey) }
                            
                            ALTAppleAPI.shared.fetchCertificates(for: team, session: session) { (certificates, error) in
                                do
                                {
                                    let certificates = try Result(certificates, error).get()
                                    
                                    guard let certificate = certificates.first(where: { $0.serialNumber == certificate.serialNumber }) else {
                                        throw OperationError(.missingCertificate)
                                    }
                                    
                                    certificate.privateKey = privateKey
                                    
                                    completionHandler(.success(certificate))
                                    
                                    if let machineIdentifier = certificate.machineIdentifier,
                                       let encryptedData = certificate.encryptedP12Data(withPassword: machineIdentifier)
                                    {
                                        // Cache certificate.
                                        do { try encryptedData.write(to: certificateFileURL, options: .atomic) }
                                        catch { printStdErr("Failed to cache certificate:", error) }
                                    }
                                }
                                catch
                                {
                                    completionHandler(.failure(error))
                                }
                            }
                        }
                        catch
                        {
                            completionHandler(.failure(error))
                        }
                    }
                }
                
                // 已安装的话先撤销再重新安装
                if let certificate = miniappCertificate
                {
                    ALTAppleAPI.shared.revoke(certificate, for: team, session: session) { (success, error) in
                        do
                        {
                            try Result(success, error).get()
                            addCertificate()
                        }
                        catch
                        {
                            completionHandler(.failure(error))
                        }
                    }
                }
                else
                {
                    addCertificate()
                }
            }
            catch
            {
                completionHandler(.failure(error))
            }
        }
    }
    
    func prepareAllProvisioningProfiles(for application: ALTApplication, device: ALTDevice, team: ALTTeam, bundleId: String?, entitlements: [String: String], session: ALTAppleAPISession,
                                        completion: @escaping (Result<[String: ALTProvisioningProfile], Error>) -> Void)
    {
        self.prepareProvisioningProfile(for: application, parentApp: nil, device: device, team: team, bundleId: bundleId, entitlements: entitlements, session: session) { (result) in
            do
            {
                let profile = try result.get()
                
                var profiles = [application.bundleIdentifier: profile]
                var error: Error?
                
                let dispatchGroup = DispatchGroup()
                
                for appExtension in application.appExtensions
                {
                    dispatchGroup.enter()
                    
                    self.prepareProvisioningProfile(for: appExtension, parentApp: application, device: device, team: team,  bundleId: bundleId, entitlements: entitlements, session: session) { (result) in
                        switch result
                        {
                        case .failure(let e): error = e
                        case .success(let profile): profiles[appExtension.bundleIdentifier] = profile
                        }
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .global()) {
                    if let error = error
                    {
                        completion(.failure(error))
                    }
                    else
                    {
                        completion(.success(profiles))
                    }
                }
            }
            catch
            {
                completion(.failure(error))
            }
        }
    }
    
    func prepareProvisioningProfile(for application: ALTApplication, parentApp: ALTApplication?, device: ALTDevice, team: ALTTeam, bundleId: String?, entitlements: [String: String], session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTProvisioningProfile, Error>) -> Void)
    {
        let parentBundleID = parentApp?.bundleIdentifier ?? application.bundleIdentifier
        var bundleID = bundleId ?? "same"
        if bundleId == "same" {
            bundleID = parentBundleID
        } else if  bundleId == "auto" {
            bundleID = parentBundleID + "." + team.identifier
        } else {
            bundleID = bundleId!
        }
        
        var preferredName: String
        if let parentApp = parentApp
        {
            preferredName = parentApp.name + " " + application.name
        }
        else
        {
            preferredName = application.name 
        }
        // 可能有中文，编码下
        preferredName = preferredName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            
        self.registerAppID(name: preferredName, bundleID: bundleID, team: team, session: session) { (result) in
            do
            {
                let appID = try result.get()
                
                self.updateFeatures(for: appID, app: application, team: team, entitlements: entitlements, session: session) { (result) in
                    do
                    {
                        let appID = try result.get()
                        
                        self.updateAppGroups(for: appID, app: application, team: team, session: session) { (result) in
                            do
                            {
                                let appID = try result.get()
                                
                                self.fetchProvisioningProfile(for: appID, device: device, team: team, session: session) { (result) in
                                    completionHandler(result)
                                }
                            }
                            catch
                            {
                                completionHandler(.failure(error))
                            }
                        }
                    }
                    catch
                    {
                        completionHandler(.failure(error))
                    }
                }
            }
            catch
            {
                completionHandler(.failure(error))
            }
        }
    }
    
    func registerAppID(name appName: String, bundleID: String, team: ALTTeam, session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTAppID, Error>) -> Void)
    {
        ALTAppleAPI.shared.fetchAppIDs(for: team, session: session) { (appIDs, error) in
            do
            {
                let appIDs = try Result(appIDs, error).get()
                
                if let appID = appIDs.first(where: { $0.bundleIdentifier == bundleID })
                {
                    completionHandler(.success(appID))
                }
                else
                {
                    ALTAppleAPI.shared.addAppID(withName: appName, bundleIdentifier: bundleID, team: team, session: session) { (appID, error) in
                        completionHandler(Result(appID, error))
                    }
                }
            }
            catch
            {
                completionHandler(.failure(error))
            }
        }
    }
    
    func updateFeatures(for appID: ALTAppID, app: ALTApplication, team: ALTTeam, entitlements: [String: String], session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTAppID, Error>) -> Void)
    {
        let requiredFeatures = app.entitlements.compactMap { (entitlement, value) -> (ALTFeature, Any)? in
            guard let feature = ALTFeature(entitlement: entitlement) else { return nil }
            return (feature, value)
        }
        
        var features = requiredFeatures.reduce(into: [ALTFeature: Any]()) { $0[$1.0] = $1.1 }
        
        if let applicationGroups = app.entitlements[.appGroups] as? [String], !applicationGroups.isEmpty
        {
            // App uses app groups, so assign `true` to enable the feature.
            features[.appGroups] = true
        }
        else
        {
            // App has no app groups, so assign `false` to disable the feature.
            features[.appGroups] = false
        }
        
        var updateFeatures = false
        
        // Determine whether the required features are already enabled for the AppID.
        for (feature, value) in features
        {
            if let appIDValue = appID.features[feature] as AnyObject?, (value as AnyObject).isEqual(appIDValue)
            {
                // AppID already has this feature enabled and the values are the same.
                continue
            }
            else if appID.features[feature] == nil, let shouldEnableFeature = value as? Bool, !shouldEnableFeature
            {
                // AppID doesn't already have this feature enabled, but we want it disabled anyway.
                continue
            }
            else
            {
                // AppID either doesn't have this feature enabled or the value has changed,
                // so we need to update it to reflect new values.
                updateFeatures = true
                break
            }
        }
        
        if updateFeatures
        {
            let appID = appID.copy() as! ALTAppID
            appID.features = features
            
            ALTAppleAPI.shared.update(appID, team: team, session: session) { (appID, error) in
                completionHandler(Result(appID, error))
            }
        }
        else
        {
            completionHandler(.success(appID))
        }
    }
    
    func updateAppGroups(for appID: ALTAppID, app: ALTApplication, team: ALTTeam, session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTAppID, Error>) -> Void)
    {
        guard let applicationGroups = app.entitlements[.appGroups] as? [String], !applicationGroups.isEmpty else {
            // Assigning an App ID to an empty app group array fails,
            // so just do nothing if there are no app groups.
            return completionHandler(.success(appID))
        }
        
        // Dispatch onto global queue to prevent appGroupsSemaphore deadlock.
        DispatchQueue.global().async {
            // Ensure we're not concurrently fetching and updating app groups,
            // which can lead to race conditions such as adding an app group twice.
            appGroupsSemaphore.wait()
            
            func finish(_ result: Result<ALTAppID, Error>)
            {
                appGroupsSemaphore.signal()
                completionHandler(result)
            }
            
            ALTAppleAPI.shared.fetchAppGroups(for: team, session: session) { (groups, error) in
                switch Result(groups, error)
                {
                case .failure(let error): finish(.failure(error))
                case .success(let fetchedGroups):
                    let dispatchGroup = DispatchGroup()
                    
                    var groups = [ALTAppGroup]()
                    var errors = [Error]()
                    
                    for groupIdentifier in applicationGroups
                    {
                        let adjustedGroupIdentifier = groupIdentifier + "." + team.identifier
                        
                        if let group = fetchedGroups.first(where: { $0.groupIdentifier == adjustedGroupIdentifier })
                        {
                            groups.append(group)
                        }
                        else
                        {
                            dispatchGroup.enter()
                            
                            // Not all characters are allowed in group names, so we replace periods with spaces (like Apple does).
                            let name = "MiniAppBuilder " + groupIdentifier.replacingOccurrences(of: ".", with: " ")
                            
                            ALTAppleAPI.shared.addAppGroup(withName: name, groupIdentifier: adjustedGroupIdentifier, team: team, session: session) { (group, error) in
                                switch Result(group, error)
                                {
                                case .success(let group): groups.append(group)
                                case .failure(let error): errors.append(error)
                                }
                                
                                dispatchGroup.leave()
                            }
                        }
                    }
                    
                    dispatchGroup.notify(queue: .global()) {
                        if let error = errors.first
                        {
                            finish(.failure(error))
                        }
                        else
                        {
                            ALTAppleAPI.shared.assign(appID, to: Array(groups), team: team, session: session) { (success, error) in
                                let result = Result(success, error)
                                finish(result.map { _ in appID })
                            }
                        }
                    }
                }
            }
        }
    }
    
    func register(_ device: ALTDevice, team: ALTTeam, session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTDevice, Error>) -> Void)
    {
        ALTAppleAPI.shared.fetchDevices(for: team, types: device.type, session: session) { (devices, error) in
            do
            {
                let devices = try Result(devices, error).get()
                
                if let device = devices.first(where: { $0.identifier == device.identifier })
                {
                    completionHandler(.success(device))
                }
                else
                {
                    ALTAppleAPI.shared.registerDevice(name: device.name, identifier: device.identifier, type: device.type, team: team, session: session) { (device, error) in
                        completionHandler(Result(device, error))
                    }
                }
            }
            catch
            {
                completionHandler(.failure(error))
            }
        }
    }
    
    func fetchProvisioningProfile(for appID: ALTAppID, device: ALTDevice, team: ALTTeam, session: ALTAppleAPISession, completionHandler: @escaping (Result<ALTProvisioningProfile, Error>) -> Void)
    {
        ALTAppleAPI.shared.fetchProvisioningProfile(for: appID, deviceType: device.type, team: team, session: session) { (profile, error) in
            completionHandler(Result(profile, error))
        }
    }
    
    func signCore(_ application: ALTApplication, certificate: ALTCertificate, profiles: [String: ALTProvisioningProfile], entitlements: [String: String], completionHandler: @escaping (Result<Set<String>, Error>) -> Void)
    {

        func prepare(_ bundle: Bundle, additionalInfoDictionaryValues: [String: Any] = [:]) throws
        {
            guard let identifier = bundle.bundleIdentifier else { throw ALTError(.missingAppBundle) }
            guard let profile = profiles[identifier] else { throw ALTError(.missingProvisioningProfile) }
            guard var infoDictionary = bundle.completeInfoDictionary else { throw ALTError(.missingInfoPlist) }
            infoDictionary[kCFBundleIdentifierKey as String] = profile.bundleIdentifier
            for (key, value) in additionalInfoDictionaryValues
            {
                infoDictionary[key] = value
            }
            if let appGroups = profile.entitlements[.appGroups] as? [String]
            {
                infoDictionary[Bundle.Info.appGroups] = appGroups
            }
            try (infoDictionary as NSDictionary).write(to: bundle.infoPlistURL)
        }
        
        DispatchQueue.global().async {
            do
            {
                print("Signing the app...");
                guard let appBundle = Bundle(url: application.fileURL) else { throw ALTError(.missingAppBundle) }
                guard let infoDictionary = appBundle.completeInfoDictionary else { throw ALTError(.missingInfoPlist) }
                
                var allURLSchemes = infoDictionary[Bundle.Info.urlTypes] as? [[String: Any]] ?? []
                var additionalValues: [String: Any] = [Bundle.Info.urlTypes: allURLSchemes]
                
                try prepare(appBundle, additionalInfoDictionaryValues: additionalValues)
                for appExtension in application.appExtensions
                {
                    guard let bundle = Bundle(url: appExtension.fileURL) else { throw ALTError(.missingAppBundle) }
                    try prepare(bundle)
                }
                
                let resigner = ALTSigner(certificate: certificate)
                resigner.signApp(at: application.fileURL, provisioningProfiles: Array(profiles.values), entitlements: entitlements) { (success, error) in
                    do
                    {
                        try Result(success, error).get()
                        let activeProfiles: Set<String>? = Set(profiles.values.map(\.bundleIdentifier))
                        completionHandler(Result(activeProfiles, error))
                    }
                    catch
                    {
                        printStdErr("Failed to install app", error)
                        completionHandler(.failure(error))
                    }
                }
            }
            catch
            {
                printStdErr("Failed to install app", error)
                completionHandler(.failure(error))
            }
        }
    }
    
}
