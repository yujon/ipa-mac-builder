//
//  MiniAppXPC.swift
//


import Foundation

@objc(AltXPC)
class AltXPC: NSObject, AltXPCProtocol
{
    func ping(_ completionHandler: @escaping () -> Void)
    {
        completionHandler()
    }
    
    func requestAnisetteData(completionHandler: @escaping (ALTAnisetteData?, Error?) -> Void)
    {
        let anisetteData = ALTPluginService.shared.requestAnisetteData()
        completionHandler(anisetteData, nil)
    }
}
