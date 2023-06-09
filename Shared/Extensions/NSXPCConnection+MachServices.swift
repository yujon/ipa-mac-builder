//
//  NSXPCConnection+MachServices.swift
//
//


import Foundation

@objc private protocol XPCPrivateAPI
{
    init(machServiceName: String)
    init(machServiceName: String, options: NSXPCConnection.Options)
}

public extension NSXPCConnection
{
    class func makeConnection(machServiceName: String) -> NSXPCConnection
    {
        let connection = unsafeBitCast(self, to: XPCPrivateAPI.Type.self).init(machServiceName: machServiceName, options: .privileged)
        return unsafeBitCast(connection, to: NSXPCConnection.self)
    }
}

public extension NSXPCListener
{
    class func makeListener(machServiceName: String) -> NSXPCListener
    {
        let listener = unsafeBitCast(self, to: XPCPrivateAPI.Type.self).init(machServiceName: machServiceName)
        return unsafeBitCast(listener, to: NSXPCListener.self)
    }
}
