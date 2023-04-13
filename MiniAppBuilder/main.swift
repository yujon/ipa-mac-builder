//
//  main.swift
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

    func launch() async throws
    {
        var count = CommandLine.argc
        if count != 4 {
            printStdErr("the length of argument shoule be greater than 3")
            throw ArgValidateError.invalidLength
        }
        let username = CommandLine.arguments[1]
        let password = CommandLine.arguments[2]
        var ipaPath = CommandLine.arguments[3]
        ipaPath = ipaPath.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!;
        let fileURL =  URL(string: ipaPath)
        
        ALTDeviceManager.shared.start()
        if ALTDeviceManager.shared.availableDevices.count == 0 {
            printStdErr("not connected device")
            throw ArgValidateError.notConnectedDevice
        }    
        let device = ALTDeviceManager.shared.availableDevices[0]

        UserDefaults.standard.registerDefaults()
        ServerConnectionManager.shared.start()
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
            

    //        AnisetteDataManager.shared.isXPCAvailable { isAvailable in
    //            if isAvailable
    //            {
    //                // XPC service is available, so we don't need to install/update Mail plug-in.
    //                // Users can still manually do so from the AltServer menu.
    //                ALTDeviceManager.shared.installApplication(at: fileURL, to: device, appleID: appleID, password: password, completion: finish(_:))
    //            }
    //            else
    //            {
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
                            finish(.failure(PluginError.taskError(output: "Mail Plug-in had Installed, Please restart Mail and enable MiniAppPlugin in Mail's Preferences. Mail must be running when signing and installing apps")))
                        }
                    }
                }
            }
            else
            {
                ALTDeviceManager.shared.installApplication(at: fileURL, to: device, appleID: appleID, password: password, completion: finish(_:))
            }
    //            }
    //        }
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
