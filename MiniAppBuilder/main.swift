//
//  main.swift
//
//  Created by jonnyyu on 2023/3/23.
//

import Foundation
import Cocoa
import AltSign
import ArgumentParserKit

extension ALTDevice {}

enum ArgValidateError: Error {
    case invalidLength
    case notConnectedDevice
    case IpaPathNotFound
    case notOutputOrInstall
    case appleIDOrPassswordUndefined
    case certificateOrProfileUndefined
    case certificateNotFound
    case profileNotFound
}

func queryStringToDictionary(_ queryString: String) -> [String: String] {
    var dict = [String: String]()
    let pairs = queryString.components(separatedBy: "&")
    for pair in pairs {
        let elements = pair.components(separatedBy: "=")
        if elements.count == 2 {
            let key = elements[0]
            let value = elements[1]
            dict[key] = value
        }
    }
    return dict
}


class Application: NSObject {

    private let pluginManager = PluginManager()


    func launch() throws
    {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            let parser = ArgumentParser(usage: "<options>", overview: "A description")
            // action
            let actionOption = parser.add(option: "--action", shortName: "-a", kind: String.self, usage: "sign|getDevices|clear")

            // sign
            let ipaOption = parser.add(option: "--ipa", shortName: "-ipa", kind: String.self, usage: "ipa path")
            let typeOption = parser.add(option: "--type", shortName: "-t", kind: String.self, usage: "apple sign type: appleId or certificate")
            let usernameOption = parser.add(option: "--appleId", shortName: "-ai", kind: String.self, usage: "apple ID")
            let passwordOption = parser.add(option: "--password", shortName: "-p", kind: String.self, usage: "apple password")
            let deviceIdOption = parser.add(option: "--deviceId", shortName: "-di", kind: String.self, usage: "device udid。 required when")
            let deviceNameOption = parser.add(option: "--deviceName", shortName: "-dn", kind: String.self, usage: "device name")
            let bundleIdOption = parser.add(option: "--bundleId", shortName: "-bi", kind: String.self, usage: "the bundleId, same|auto|xx.xx.xx(specified bundleId)")
            let entitlementsOption = parser.add(option: "--entitlements", shortName: "-e", kind: String.self, usage: "the emtitlement, A=xxx&B=xxx")
            let certificatePathOption = parser.add(option: "--certificatePath", shortName: "-cpa", kind: String.self, usage: "certificate path")
            let certificatePasswordOption = parser.add(option: "--certificatePassword", shortName: "-cpw", kind: String.self, usage: "certificate password")
            let profilePathOption = parser.add(option: "--profilePath", shortName: "-pf", kind: String.self, usage: "profile path")
            let outputDirOption = parser.add(option: "--output", shortName: "-o", kind: String.self, usage: "output dir")
            let installOption = parser.add(option: "--install", shortName: "-i", kind: Bool.self, usage: "install instantly to device")
            let parsedArguments = try parser.parse(arguments)

            let action = parsedArguments.get(actionOption) ?? "getDevices"

            // 获取设备列表
            if action == "getDevices" {
                self.doGetDeviceAction()
                exit(0)
            }

            // 签名
            let signType = parsedArguments.get(typeOption) ?? "appleId"
            
            if action == "clear" {
                if signType == "appleId" {
                    UserDefaults.standard.set("no", forKey: "rememberAppleId")
                }
                if signType == "certificate" {
                    UserDefaults.standard.set("no", forKey: "rememberCertificate")
                }
                print("Clear remember successfully")
                exit(0)
            }

            let ipaPath = parsedArguments.get(ipaOption)

            var username = parsedArguments.get(usernameOption)
            var password = parsedArguments.get(passwordOption)
            let deviceId = parsedArguments.get(deviceIdOption)
            var deviceName = parsedArguments.get(deviceNameOption)

            var certificatePath = parsedArguments.get(certificatePathOption)
            var certificatePassword = parsedArguments.get(certificatePasswordOption)
            var profilePath = parsedArguments.get(profilePathOption)

            let install = parsedArguments.get(installOption) ?? false
            let outputDir = parsedArguments.get(outputDirOption)
            let bundleId = parsedArguments.get(bundleIdOption) ?? "same"
            let entitlementsStr = parsedArguments.get(entitlementsOption)
            
            // 清除clear
            if action == "clear" {
                UserDefaults.standard.set("no", forKey: "rememberAppleId")
                UserDefaults.standard.set("no", forKey: "rememberCertificate")
                print("Clear successfully")
                exit(0)
            }
            
            if ipaPath == nil {
               printStdErr("the ipa path not found")
               throw ArgValidateError.IpaPathNotFound
           }
            let fileURL =  URL(fileURLWithPath: ipaPath!)
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                print("File not exists")
                printStdErr("the ipa path not found")
                throw ArgValidateError.IpaPathNotFound
            }
        
            // output或install至少一种
            if outputDir == nil && !install {
                printStdErr("not output Dir or install instantly")
                throw ArgValidateError.notOutputOrInstall
            }

           if signType == "appleId" {
               var rememberAppleId = UserDefaults.standard.string(forKey: "rememberAppleId") ?? "no"
               if (username == nil || password == nil) && rememberAppleId == "yes" {
                   username = UserDefaults.standard.string(forKey: "username")
                   password = UserDefaults.standard.string(forKey: "password")
               }
               if username == nil || password == nil {
                    let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
                    let inputCommand = executableURL.deletingLastPathComponent().appendingPathComponent("AppleAccount.sh").path
                    let inputOutput = executeCommand("\"\(inputCommand)\"")
                    if let input = inputOutput {
                        let inputLines = input.split(separator: "\n")
                        if inputLines.count < 3  {
                            printStdErr("appleID or password is undefined")
                            throw ArgValidateError.appleIDOrPassswordUndefined
                        }
                        username = String(inputLines[0])
                        password = String(inputLines[1])
                        rememberAppleId = String(inputLines[2])
                    } else {
                        printStdErr("appleID or password is undefined")
                        throw ArgValidateError.appleIDOrPassswordUndefined
                    }
               }
               if rememberAppleId == "yes" {
                   UserDefaults.standard.set("yes", forKey: "rememberAppleId")
                   UserDefaults.standard.set(username, forKey: "username")
                   UserDefaults.standard.set(password, forKey: "password")
               } else {
                   UserDefaults.standard.set("no", forKey: "rememberAppleId")
               }
           } else {
                var rememberCertificate = UserDefaults.standard.string(forKey: "rememberCertificate") ?? "no"
                if (certificatePath == nil || profilePath == nil) && rememberCertificate == "yes" {
                   certificatePath = UserDefaults.standard.string(forKey: "certificatePath")
                   certificatePassword = UserDefaults.standard.string(forKey: "certificatePassword")
                   profilePath = UserDefaults.standard.string(forKey: "profilePath")
                }
                if certificatePath == nil || profilePath == nil {
                    let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
                    let inputCommand = executableURL.deletingLastPathComponent().appendingPathComponent("AppleCertificate.sh").path
                    let inputOutput = executeCommand("\"\(inputCommand)\"")
                    if let input = inputOutput {
                        let inputLines = input.split(separator: "\n")
                        if inputLines.count < 4  {
                            printStdErr("certificate or profile is undefined")
                            throw ArgValidateError.certificateOrProfileUndefined
                        }
                        certificatePath = String(inputLines[0])
                        certificatePassword = String(inputLines[1])
                        profilePath = String(inputLines[2])
                        rememberCertificate = String(inputLines[3])
                    } else {
                        printStdErr("certificate or profile is undefined")
                        throw ArgValidateError.certificateOrProfileUndefined
                    }
                }
                guard FileManager.default.fileExists(atPath: certificatePath!) else {
                     printStdErr("certificate not found")
                    throw ArgValidateError.certificateNotFound
                }
                guard FileManager.default.fileExists(atPath: profilePath!) else {
                     printStdErr("profile not found")
                    throw ArgValidateError.profileNotFound
                }
               if rememberCertificate == "yes" {
                    UserDefaults.standard.set("yes", forKey: "rememberCertificate")
                    UserDefaults.standard.set(certificatePath, forKey: "certificatePath")
                    UserDefaults.standard.set(certificatePassword, forKey: "certificatePassword")
                    UserDefaults.standard.set(profilePath, forKey: "profilePath")
               } else {
                    UserDefaults.standard.set("no", forKey: "rememberCertificate")
               }
           }
        
            var entitlements: [String : String] = [:]
            if entitlementsStr != nil {
                entitlements = queryStringToDictionary(entitlementsStr ?? "")
            }

            // 采用appleId方式，或者开启install需要有deviceId
            var device: ALTDevice? = nil
            if signType == "appleId" || install {
                if deviceId == nil {
                    ALTDeviceManager.shared.start()
                    if ALTDeviceManager.shared.availableDevices.count == 0 {
                        printStdErr("not connected device")
                        throw ArgValidateError.notConnectedDevice
                    }
                    device = ALTDeviceManager.shared.availableDevices[0]
                } else {
                    deviceName = deviceName ?? "your iphone"
                    device = ALTDevice(name: deviceName!, identifier:deviceId!, type: ALTDeviceType.iphone);
                }
            }


            self.doSignAction(
                at: fileURL,
                signType: signType,
                username: username,
                password: password,
                certificatePath: certificatePath,
                certificatePassword: certificatePassword,
                profilePath: profilePath,
                to: device,
                outputDir: outputDir,
                install: install,
                bundleId: bundleId,
                entitlements: entitlements
            )  { (result) in
                switch result{
                    case .success(let application):
                        CFRunLoopStop(runLoop.getCFRunLoop())
                        exit(0)
                    case .failure(let error):
                        printStdErr(error.localizedDescription);
                        CFRunLoopStop(runLoop.getCFRunLoop())
                        // clear
                        // if signType == "appleId" {
                        //     UserDefaults.standard.set("no", forKey: "rememberAppleId")
                        // }
                        // if signType == "certificate" {
                        //     UserDefaults.standard.set("no", forKey: "rememberCertificate")
                        // }
                        exit(1)
                }
            }
        }
        catch {
            printStdErr(error.localizedDescription);
            CFRunLoopStop(runLoop.getCFRunLoop())
            exit(1)
        }
    }

}

private extension Application
{

    func doGetDeviceAction() {
         ALTDeviceManager.shared.start()
        var devoceCount = ALTDeviceManager.shared.availableDevices.count
        if devoceCount == 0 {
            exit(0)
        }
        for device in ALTDeviceManager.shared.availableDevices {
            if device.type != ALTDeviceType.iphone {
                continue
            }
            let osVersion = device.osVersion
            let versionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
            let arr = ["iphone", device.name, versionString, device.identifier]
            print(arr.joined(separator: "|"))
        }
    }
    
    func doSignAction(
        at fileURL: URL,
        signType: String,
        username: String?,
        password: String?,
        certificatePath: String?,
        certificatePassword: String?,
        profilePath: String?,
        to device: ALTDevice?,
        outputDir: String?,
        install: Bool,
        bundleId: String?,
        entitlements: [String : String]?,
        completion: @escaping ((Result<Void, Error>) -> Void)
    )
    {
        func finish(_ result: Result<Void, Error>)
        {
            
            switch result
            {
            case .success(let application):
                // continuation.resume(returning: ())
                completion(.success(()))
            case .failure(OperationError.cancelled), .failure(ALTAppleAPIError.requiresTwoFactorAuthentication):
                // Ignore
                // continuation.resume(returning: ())
                completion(.success(()))
                break
                
            case .failure(let error):
                // continuation.resume(throwing: error)
                completion(.failure(error))
            }
        }

        func signFinish(_ result: Result<(ALTApplication, Set<String>), Error>)
        {
                do{
                let (application, profiles) = try result.get()
                if outputDir != nil {
                    let resignedIPAURL = try FileManager.default.zipAppBundle(at: application.fileURL);
                    let ipaName = application.fileURL.lastPathComponent.replacingOccurrences(of: ".app", with: ".ipa")
                    let distIPAURL = URL(fileURLWithPath: outputDir!).appendingPathComponent(ipaName)
                    if FileManager.default.fileExists(atPath: distIPAURL.path) {
                        try FileManager.default.removeItem(at: distIPAURL)
                    }
                    try FileManager.default.moveItem(at: resignedIPAURL, to: distIPAURL)
                    print("Export the ipa successfullly")
                }
                if install {
                    ALTDeviceManager.shared.installApplication(at: application, to: device!, profiles: profiles,  completion: finish(_:))
                } else {
                    finish(.success(()))
                }
            }
            catch
            {
                finish(.failure(error))
            }
        }
    
        if signType == "appleId"
        {
            if !self.pluginManager.isMailPluginInstalled
            {
                self.pluginManager.installMailPlugin { (result) in
                    DispatchQueue.main.async {
                        switch result
                        {
                        case .failure(let error):
                            printStdErr("Failed to Install Mail Plug-in", error.localizedDescription)
                            finish(.failure(error))
                        case .success:
                            finish(.failure(PluginError.taskError(output: "Mail Plug-in had Installed, Please Operate according to [url:https://github.com/yujon/ipa-mac-builder#mail-plugin] and restart Mail. Mail must be running when signing and installing apps")))
                        }
                    }
                }
                return
            }
            ALTDeviceManager.shared.signWithAppleID(at: fileURL, to: device!, appleID: username!, password: password!, bundleId: bundleId, entitlements: entitlements!, completion: signFinish)
        } else {
            ALTDeviceManager.shared.signWithCertificate(at: fileURL, certificatePath: certificatePath!, certificatePassword: certificatePassword, profilePath: profilePath!, entitlements: entitlements!, completion: signFinish)
        }
   }
}

let runLoop = RunLoop.current
let app = Application()
try app.launch()
runLoop.run()
print("done")
