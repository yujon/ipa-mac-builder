//
//  PluginManager.swift
//
//


import Foundation
import AppKit
import CryptoKit

import STPrivilegedTask

private let pluginDirectoryURL = URL(fileURLWithPath: "/Library/Mail/Bundles", isDirectory: true)
private let pluginURL = pluginDirectoryURL.appendingPathComponent("MiniAppPlugin.mailbundle")

extension PluginError
{
    enum Code: Int, ALTErrorCode
    {
        typealias Error = PluginError
        
        case cancelled
        case unknown
        case notFound
        case mismatchedHash
        case taskError
        case taskErrorCode
    }
    
    static let cancelled = PluginError(code: .cancelled)
    static let notFound = PluginError(code: .notFound)
    
    static func unknown(file: String = #fileID, line: UInt = #line) -> PluginError { PluginError(code: .unknown, sourceFile: file, sourceLine: line) }
    static func mismatchedHash(hash: String, expectedHash: String) -> PluginError { PluginError(code: .mismatchedHash, hash: hash, expectedHash: expectedHash) }
    static func taskError(output: String) -> PluginError { PluginError(code: .taskError, taskErrorOutput: output) }
    static func taskErrorCode(_ code: Int) -> PluginError { PluginError(code: .taskErrorCode, taskErrorCode: code) }
}

struct PluginError: ALTLocalizedError
{
    let code: Code
    
    var errorTitle: String?
    var errorFailure: String?
    var sourceFile: String?
    var sourceLine: UInt?
    
    var hash: String?
    var expectedHash: String?
    var taskErrorOutput: String?
    var taskErrorCode: Int?
    
    var errorFailureReason: String {
        switch self.code
        {
        case .cancelled: return NSLocalizedString("Mail plug-in installation was cancelled.", comment: "")
        case .unknown: return NSLocalizedString("Failed to install Mail plug-in.", comment: "")
        case .notFound: return NSLocalizedString("The Mail plug-in does not exist at the requested URL.", comment: "")
        case .mismatchedHash:
            let baseMessage = NSLocalizedString("The hash of the downloaded Mail plug-in does not match the expected hash.", comment: "")
            guard let hash = self.hash, let expectedHash = self.expectedHash else { return baseMessage }
            
            let additionalInfo = String(format: NSLocalizedString("Hash:\n%@\n\nExpected Hash:\n%@", comment: ""), hash, expectedHash)
            return baseMessage + "\n\n" + additionalInfo
            
        case .taskError:
            if let output = self.taskErrorOutput
            {
                return output
            }
            
            // Use .taskErrorCode base message as fallback.
            fallthrough
            
        case .taskErrorCode:
            let baseMessage = NSLocalizedString("There was an error installing the Mail plug-in.", comment: "")
            guard let errorCode = self.taskErrorCode else { return baseMessage }
            
            let additionalInfo = String(format: NSLocalizedString("(Error Code: %@)", comment: ""), NSNumber(value: errorCode))
            return baseMessage + " " + additionalInfo
        }
    }
}

class PluginManager
{
    private let session = URLSession(configuration: .ephemeral)
    
    var isMailPluginInstalled: Bool {
        let isMailPluginInstalled = FileManager.default.fileExists(atPath: pluginURL.path)
        return isMailPluginInstalled
    }
}

extension PluginManager
{
    func installMailPlugin(completionHandler: @escaping (Result<Void, Error>) -> Void)
    {
          do {
            let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
            let localPluginPath = executableURL.deletingLastPathComponent().appendingPathComponent("MiniAppPlugin.zip").path
            let fileURL = URL(fileURLWithPath: localPluginPath)
            // Ensure plug-in directory exists.
            let authorization = try self.runAndKeepAuthorization("mkdir", arguments: ["-p", pluginDirectoryURL.path])
            
            // Create temporary directory.
            let temporaryDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            defer { try? FileManager.default.removeItem(at: temporaryDirectoryURL) }
                
            // Unzip AltPlugin to temporary directory.
            try self.runAndKeepAuthorization("unzip", arguments: ["-o", fileURL.path, "-d", temporaryDirectoryURL.path], authorization: authorization)
            
            if FileManager.default.fileExists(atPath: pluginURL.path)
            {
                // Delete existing Mail plug-in.
                try self.runAndKeepAuthorization("rm", arguments: ["-rf", pluginURL.path], authorization: authorization)
            }
            
            // Copy AltPlugin to Mail plug-ins directory.
            // Must be separate step than unzip to prevent macOS from considering plug-in corrupted.
            let unzippedPluginURL = temporaryDirectoryURL.appendingPathComponent(pluginURL.lastPathComponent)
            try self.runAndKeepAuthorization("cp", arguments: ["-R", unzippedPluginURL.path, pluginDirectoryURL.path], authorization: authorization)
            
            guard self.isMailPluginInstalled else { throw PluginError.unknown() }
            
            // Enable Mail plug-in preferences.
            try self.run("defaults", arguments: ["write", "/Library/Preferences/com.apple.mail", "EnableBundles", "-bool", "YES"], authorization: authorization)
            
            print("Finished installing Mail plug-in!")
            
            completionHandler(.success(()))
        }
        catch
        {
            completionHandler(.failure(error))
        }
    }
    
}

private extension PluginManager
{
    func run(_ program: String, arguments: [String], authorization: AuthorizationRef? = nil) throws
    {
        _ = try self._run(program, arguments: arguments, authorization: authorization, freeAuthorization: true)
    }
    
    @discardableResult
    func runAndKeepAuthorization(_ program: String, arguments: [String], authorization: AuthorizationRef? = nil) throws -> AuthorizationRef
    {
        return try self._run(program, arguments: arguments, authorization: authorization, freeAuthorization: false)
    }
    
    func _run(_ program: String, arguments: [String], authorization: AuthorizationRef? = nil, freeAuthorization: Bool) throws -> AuthorizationRef
    {
        var launchPath = "/usr/bin/" + program
        if !FileManager.default.fileExists(atPath: launchPath)
        {
            launchPath = "/bin/" + program
        }
        
        // print("Running program:", launchPath)
        
        let task = STPrivilegedTask()
        task.launchPath = launchPath
        task.arguments = arguments
        task.freeAuthorizationWhenDone = freeAuthorization
        
        let errorCode: OSStatus
        
        if let authorization = authorization
        {
            errorCode = task.launch(withAuthorization: authorization)
        }
        else
        {
            errorCode = task.launch()
        }
        
        guard errorCode == 0 else { throw PluginError.taskErrorCode(Int(errorCode)) }
        
        task.waitUntilExit()
        
        // print("Exit code:", task.terminationStatus)
        
        guard task.terminationStatus == 0 else {
            let outputData = task.outputFileHandle.readDataToEndOfFile()
            
            if let outputString = String(data: outputData, encoding: .utf8), !outputString.isEmpty
            {
                throw PluginError.taskError(output: outputString)
            }
            
            throw PluginError.taskErrorCode(Int(task.terminationStatus))
        }
        
        guard let authorization = task.authorization else { throw PluginError.unknown() }
        return authorization
    }
}
