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
    private var appleIdContentView: NSView? = nil
    private var appleIdUsernameField: NSTextField? = nil
    private var appleIdPasswordField: NSTextField? = nil
    private var rememberAppleIdCheckbox: NSButton? = nil

    private var certificateContentView: NSView? = nil
    private var certificateField: NSTextField? = nil
    private var certificatePasswordField: NSTextField? = nil
    private var profileField: NSTextField? = nil
    private var rememberCertificateCheckbox: NSButton? = nil

    func launch() throws
    {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            let parser = ArgumentParser(usage: "<options>", overview: "A description")
            // action
            let actionOption = parser.add(option: "--action", shortName: "-a", kind: String.self, usage: "sign|getDevices")

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
                 guard let appleIdInfo = self.showAppleIdAlert() else {
                        printStdErr("appleID or password is undefined")
                        throw ArgValidateError.appleIDOrPassswordUndefined
                }
                username = appleIdInfo.username
                password = appleIdInfo.password
                rememberAppleId = appleIdInfo.remember ? "yes" : "no"
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
                    guard let certificateInfo = self.showCertificateAlert() else {
                        printStdErr("certificate or profile is undefined")
                        throw ArgValidateError.certificateOrProfileUndefined
                    }
                    certificatePath = certificateInfo.certificate
                    certificatePassword = certificateInfo.password
                    profilePath = certificateInfo.profile
                    rememberCertificate = certificateInfo.remember ? "yes" : "no"
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

            UserDefaults.standard.registerDefaults()

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

    func showAppleIdAlert() -> (username: String, password: String, remember: Bool)? {
        var username = ""
        var password = ""
        var remember = false
        
        let alert = NSAlert()
        alert.addButton(withTitle: "确认")
        alert.addButton(withTitle: "取消")
        alert.alertStyle = .informational
        alert.messageText = ""
        alert.informativeText = ""
        
        self.appleIdContentView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 150))
         
        let usernameLabel = NSTextField(labelWithString: "Apple 账号")
        usernameLabel.frame = NSRect(x: 20, y: 110, width: 80, height: 20)
        self.appleIdContentView!.addSubview(usernameLabel)

        self.appleIdUsernameField = NSTextField(frame: NSRect(x: 100, y: 110, width: 200, height: 20))
        self.appleIdUsernameField!.placeholderString = "Apple 账号"
        self.appleIdUsernameField!.isEnabled = false
        self.appleIdContentView!.addSubview(self.appleIdUsernameField!)
        
        let usernameButton = NSButton(title: "输入", target: self, action: #selector(getAppleIdUsername))
        usernameButton.frame = NSRect(x: 310, y: 110, width: 60, height: 20)
        self.appleIdContentView!.addSubview(usernameButton)
  
        let passwordLabel = NSTextField(labelWithString: "Apple 密码：")
        passwordLabel.frame = NSRect(x: 20, y: 80, width: 80, height: 20)
        self.appleIdContentView!.addSubview(passwordLabel)

        self.appleIdPasswordField = NSSecureTextField(frame: NSRect(x: 100, y: 80, width: 200, height: 20))
        self.appleIdPasswordField!.placeholderString = "Apple 密码"
        self.appleIdPasswordField!.isEnabled = false
        self.appleIdContentView!.addSubview(self.appleIdPasswordField!)
        
        let passwordButton = NSButton(title: "输入", target: self, action: #selector(getAppleIdPassword))
        passwordButton.frame = NSRect(x: 310, y: 80, width: 60, height: 20)
        self.appleIdContentView!.addSubview(passwordButton)
  
        self.rememberAppleIdCheckbox = NSButton(checkboxWithTitle: "记住我的选择", target: self, action: #selector(rememberSelection))
        self.rememberAppleIdCheckbox!.frame = NSRect(x: 20, y: 50, width: 200, height: 20)
        self.appleIdContentView!.addSubview(self.rememberAppleIdCheckbox!)
        
        alert.accessoryView = self.appleIdContentView!
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            username = self.appleIdUsernameField!.stringValue
            password = self.appleIdPasswordField!.stringValue
            remember = self.rememberAppleIdCheckbox!.state == .on
        }
        
        if username.isEmpty && password.isEmpty {
            return nil
        }
        
        return (username, password, remember)
    }

    func showCertificateAlert() -> (certificate: String, password: String, profile: String, remember: Bool)? {
        var certificate = ""
        var password = ""
        var profile = ""
        var remember = false
        
        let alert = NSAlert()
        alert.addButton(withTitle: "确认")
        alert.addButton(withTitle: "取消")
        alert.alertStyle = .informational
        alert.messageText = ""
        alert.informativeText = ""
        
        self.certificateContentView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 180))
        
        let certificateLabel = NSTextField(labelWithString: "证书文件：")
        certificateLabel.frame = NSRect(x: 20, y: 140, width: 80, height: 20)
        self.certificateContentView!.addSubview(certificateLabel)

        self.certificateField = NSTextField(frame: NSRect(x: 100, y: 140, width: 200, height: 20))
        self.certificateField!.placeholderString = "证书文件路径"
        self.certificateField!.isEnabled = false
        self.certificateContentView!.addSubview(self.certificateField!)
            
        let certificateButton = NSButton(title: "选择", target: self, action: #selector(selectCertificateFile))
        certificateButton.frame = NSRect(x: 310, y: 140, width: 60, height: 20)
        self.certificateContentView!.addSubview(certificateButton)
        
        let passwordLabel = NSTextField(labelWithString: "密码：")
        passwordLabel.frame = NSRect(x: 20, y: 110, width: 80, height: 20)
        self.certificateContentView!.addSubview(passwordLabel)

        self.certificatePasswordField = NSSecureTextField(frame: NSRect(x: 100, y: 110, width: 200, height: 20))
        self.certificatePasswordField!.placeholderString = "密码"
        self.certificatePasswordField!.isEnabled = false
        self.certificateContentView!.addSubview(self.certificatePasswordField!)
        
        let passwordButton = NSButton(title: "输入", target: self, action: #selector(getCertificatePassword))
        passwordButton.frame = NSRect(x: 310, y: 110, width: 60, height: 20)
        self.certificateContentView!.addSubview(passwordButton)
        
        let profileLabel = NSTextField(labelWithString: "profile 文件：")
        profileLabel.frame = NSRect(x: 20, y: 80, width: 80, height: 20)
        self.certificateContentView!.addSubview(profileLabel)

        self.profileField = NSTextField(frame: NSRect(x: 100, y: 80, width: 200, height: 20))
        self.profileField!.placeholderString = "profile 文件路径"
        self.profileField!.isEnabled = false
        self.certificateContentView!.addSubview(self.profileField!)    

        let profileButton = NSButton(title: "选择", target: self, action: #selector(selectProfileFile))
        profileButton.frame = NSRect(x: 310, y: 80, width: 60, height: 20)
        self.certificateContentView!.addSubview(profileButton)
        
        self.rememberCertificateCheckbox = NSButton(checkboxWithTitle: "记住我的选择", target: self, action: #selector(rememberSelection))
        self.rememberCertificateCheckbox!.frame = NSRect(x: 20, y: 50, width: 200, height: 20)
        self.certificateContentView!.addSubview(self.rememberCertificateCheckbox!)
        
        alert.accessoryView = self.certificateContentView!
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            certificate = self.certificateField!.stringValue
            password = self.certificatePasswordField!.stringValue
            profile = self.profileField!.stringValue
            remember = self.rememberCertificateCheckbox!.state == .on
        }
        
        if certificate.isEmpty && password.isEmpty && profile.isEmpty {
            return nil
        }
        
        return (certificate, password, profile, remember)
    }


    func chooseFile(type: String, title: String) throws -> String {
        let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        let inputCommand = executableURL.deletingLastPathComponent().appendingPathComponent("choosefile.sh").path
        let inputOutput = executeCommand("\"\(inputCommand)\" \(type) \(title)")
        if let input = inputOutput {
            let inputLines = input.split(separator: "\n")
            if inputLines.count < 1  {
                return ""
            }
            return String(inputLines[0])
        }
        return ""
    }

    func getInputValue(label: String, hideText: String = "") throws -> String {
        let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        let inputCommand = executableURL.deletingLastPathComponent().appendingPathComponent("input.sh").path
        let inputOutput = executeCommand("\"\(inputCommand)\" \(label) \(hideText)")
        if let input = inputOutput {
            let inputLines = input.split(separator: "\n")
            if inputLines.count < 1  {
                return ""
            }
            return String(inputLines[0])
        }
        return ""
    }

    @objc func getAppleIdUsername() throws {
        let username = try self.getInputValue(label: "请输入Apple账号\\(如是手机号前面+86\\):")
        self.appleIdUsernameField!.stringValue = username;
    }

    @objc func getAppleIdPassword() throws {
        let password = try self.getInputValue(label: "请输入Apple密码:", hideText: "hide")
        self.appleIdPasswordField!.stringValue = password;
    }

    @objc func selectCertificateFile() throws {
        let certificateFile = try self.chooseFile(type: "p12", title: "请选择p12文件")
        if(certificateFile != "") {
            self.certificateField!.stringValue = certificateFile;
        }
    }

    @objc func getCertificatePassword() throws {
        let password = try self.getInputValue(label: "请选择输入证书对应的密码", hideText: "hide")
        self.certificatePasswordField!.stringValue = password;
    }

    @objc func selectProfileFile() throws {
        let profileFile = try self.chooseFile(type: "mobileprovision", title: "请选择mobileprovision文件")
        if(profileFile != "") {
            self.profileField!.stringValue = profileFile;
        }
    }
    
    @objc func rememberSelection() throws {
        
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
