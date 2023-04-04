//
//  main.swift
//  commandline-demo
//
//  Created by jonnyyu on 2023/3/23.
//

import Foundation
import Cocoa

import AltSign

// import Sparkle


extension ALTDevice {}

enum ArgValidateError: Error {
    case invalidLength
    case notConnectedDevice
}

class Application {

    private let pluginManager = PluginManager()
    
    private weak var authenticationAppleIDTextField: NSTextField?
    private weak var authenticationPasswordTextField: NSSecureTextField?
    
    private var isAltPluginUpdateAvailable = false
    
    private var popoverController: NSPopover?
    private var popoverError: NSError?
    private var errorAlert: NSAlert?
    
    func launch() async throws
    {
        UserDefaults.standard.registerDefaults()
        
        
        ServerConnectionManager.shared.start()
        ALTDeviceManager.shared.start()
        
        var count = CommandLine.argc
        if count != 4 {
            printStdErr("the length of argument shoule be greater than 3")
            throw ArgValidateError.invalidLength
        }
        let username = CommandLine.arguments[1]
        let password = CommandLine.arguments[2]
        let fileURL =  URL(string: CommandLine.arguments[3])
        
        if ALTDeviceManager.shared.availableDevices.count == 0 {
            printStdErr("there is not connected device")
            throw ArgValidateError.notConnectedDevice
        }
            
        let device = ALTDeviceManager.shared.availableDevices[0]

        
        
        self.pluginManager.isUpdateAvailable { result in
            guard let isUpdateAvailable = try? result.get() else { return }
            self.isAltPluginUpdateAvailable = isUpdateAvailable
           
            if isUpdateAvailable
            {
                self.installMailPlugin()
            }
         }
        try await self.installApplication(at: fileURL!, to: device, appleID: username, password: password)
        
    }
}

private extension Application
{

    func installApplication(at fileURL: URL, to device: ALTDevice, appleID: String, password: String) async throws 
    {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) -> Void in

            func finish(_ result: Result<ALTApplication, Error>)
            {
                switch result
                {
                case .success(let application):
                    print(String(format: NSLocalizedString("%@ was successfully installed on %@.", comment: ""), application.name, device.name))
                    continuation.resume(returning: ())
                case .failure(OperationError.cancelled), .failure(ALTAppleAPIError.requiresTwoFactorAuthentication):
                    // Ignore
                    continuation.resume(returning: ())
                    break
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            func install()
            {
                ALTDeviceManager.shared.installApplication(at: fileURL, to: device, appleID: appleID, password: password, completion: finish(_:))
            }

        
    //        AnisetteDataManager.shared.isXPCAvailable { isAvailable in
    //            if isAvailable
    //            {
    //                // XPC service is available, so we don't need to install/update Mail plug-in.
    //                // Users can still manually do so from the AltServer menu.
    //                install()
    //            }
    //            else
    //            {
                    self.pluginManager.isUpdateAvailable { result in
                        switch result
                        {
                        case .failure(let error):
                            let error = (error as NSError).withLocalizedTitle(NSLocalizedString("Could not check for Mail plug-in updates.", comment: ""))
                            finish(.failure(error))
                            
                        case .success(let isUpdateAvailable):
                            self.isAltPluginUpdateAvailable = isUpdateAvailable
                            
                            if !self.pluginManager.isMailPluginInstalled || isUpdateAvailable
                            {
                                self.installMailPlugin { result in
                                    switch result
                                    {
                                    case .failure: break
                                    case .success: install()
                                    }
                                }
                            }
                            else
                            {
                                install()
                            }
                        }
                    }
    //            }
    //        }
        }
    }

    private func installMailPlugin(completion: ((Result<Void, Error>) -> Void)? = nil)
    {
        self.pluginManager.installMailPlugin { (result) in
            DispatchQueue.main.async {
                switch result
                {
                case .failure(PluginError.cancelled): break
                case .failure(let error):
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Failed to Install Mail Plug-in", comment: "")
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                    
                case .success:
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Mail Plug-in Installed", comment: "")
                    alert.informativeText = NSLocalizedString("Please restart Mail and enable AltPlugin in Mail's Preferences. Mail must be running when installing or refreshing apps with AltServer.", comment: "")
                    alert.runModal()
                    
                    self.isAltPluginUpdateAvailable = false
                }
                
                completion?(result)
            }
        }
    }
    
    private func uninstallMailPlugin()
    {
        self.pluginManager.uninstallMailPlugin { (result) in
            DispatchQueue.main.async {
                switch result
                {
                case .failure(PluginError.cancelled): break
                case .failure(let error):
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Failed to Uninstall Mail Plug-in", comment: "")
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                    
                case .success:
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Mail Plug-in Uninstalled", comment: "")
                    alert.informativeText = NSLocalizedString("Please restart Mail for changes to take effect. You will not be able to use AltServer until the plug-in is reinstalled.", comment: "")
                    alert.runModal()
                }
            }
        }
    }
}


do {
    let app = Application()
    try await app.launch()
    print("The App exit")
    exit(0)
} catch {
    printStdErr("The App exit error:", error)
    exit(1)
}
