//
//  NSError+MiniAppBuilder.swift
//
//


import Foundation

import AltSign

public extension NSError
{
    @objc(alt_localizedFailure)
    var localizedFailure: String? {
        let localizedFailure = (self.userInfo[NSLocalizedFailureErrorKey] as? String) ?? (NSError.userInfoValueProvider(forDomain: self.domain)?(self, NSLocalizedFailureErrorKey) as? String)
        return localizedFailure
    }
    
    @objc(alt_localizedDebugDescription)
    var localizedDebugDescription: String? {
        let debugDescription = (self.userInfo[NSDebugDescriptionErrorKey] as? String) ?? (NSError.userInfoValueProvider(forDomain: self.domain)?(self, NSDebugDescriptionErrorKey) as? String)
        return debugDescription
    }
    
    @objc(alt_localizedTitle)
    var localizedTitle: String? {
        let localizedTitle = self.userInfo[ALTLocalizedTitleErrorKey] as? String
        return localizedTitle
    }
    
    @objc(alt_errorWithLocalizedFailure:)
    func withLocalizedFailure(_ failure: String) -> NSError
    {
        switch self
        {
        case var error as any ALTLocalizedError:
            error.errorFailure = failure
            return error as NSError
            
        default:
            var userInfo = self.userInfo
            userInfo[NSLocalizedFailureErrorKey] = failure
            
            let error = ALTWrappedError(error: self, userInfo: userInfo)
            return error
        }
    }
    
    @objc(alt_errorWithLocalizedTitle:)
    func withLocalizedTitle(_ title: String) -> NSError
    {
        switch self
        {
        case var error as any ALTLocalizedError:
            error.errorTitle = title
            return error as NSError
            
        default:
            var userInfo = self.userInfo
            userInfo[ALTLocalizedTitleErrorKey] = title

            let error = ALTWrappedError(error: self, userInfo: userInfo)
            return error
        }
    }
    
    func sanitizedForSerialization() -> NSError
    {
        var userInfo = self.userInfo
        userInfo[NSLocalizedDescriptionKey] = self.localizedDescription
        userInfo[NSLocalizedFailureErrorKey] = self.localizedFailure
        userInfo[NSLocalizedFailureReasonErrorKey] = self.localizedFailureReason
        userInfo[NSLocalizedRecoverySuggestionErrorKey] = self.localizedRecoverySuggestion
        userInfo[NSDebugDescriptionErrorKey] = self.localizedDebugDescription
        
        // Remove userInfo values that don't conform to NSSecureEncoding.
        userInfo = userInfo.filter { (key, value) in
            return (value as AnyObject) is NSSecureCoding
        }
        
        // Sanitize underlying errors.
        if let underlyingError = userInfo[NSUnderlyingErrorKey] as? Error
        {
            let sanitizedError = (underlyingError as NSError).sanitizedForSerialization()
            userInfo[NSUnderlyingErrorKey] = sanitizedError
        }
        
        if #available(iOS 14.5, macOS 11.3, *), let underlyingErrors = userInfo[NSMultipleUnderlyingErrorsKey] as? [Error]
        {
            let sanitizedErrors = underlyingErrors.map { ($0 as NSError).sanitizedForSerialization() }
            userInfo[NSMultipleUnderlyingErrorsKey] = sanitizedErrors
        }
        
        let error = NSError(domain: self.domain, code: self.code, userInfo: userInfo)
        return error
    }
    
}

public extension NSError
{
    typealias UserInfoProvider = (Error, String) -> Any?
    
    @objc
    class func alt_setUserInfoValueProvider(forDomain domain: String, provider: UserInfoProvider?)
    {
        NSError.setUserInfoValueProvider(forDomain: domain) { (error, key) in
            let nsError = error as NSError
            
            switch key
            {
            case NSLocalizedDescriptionKey:
                if nsError.localizedFailure != nil
                {
                    // Error has localizedFailure, so return nil to construct localizedDescription from it + localizedFailureReason.
                    return nil
                }
                else if let localizedDescription = provider?(error, NSLocalizedDescriptionKey) as? String
                {
                    // Only call provider() if there is no localizedFailure.
                    return localizedDescription
                }
                
                // Otherwise, return failureReason for localizedDescription to avoid system prepending "Operation Failed" message.
                // Do NOT return provider(NSLocalizedFailureReason), which might be unexpectedly nil if unrecognized error code.
                return nsError.localizedFailureReason
                
            default:
                let value = provider?(error, key)
                return value
            }
        }
    }
}

public extension Error
{
    var underlyingError: Error? {
        let underlyingError = (self as NSError).userInfo[NSUnderlyingErrorKey] as? Error
        return underlyingError
    }
    
    var localizedErrorCode: String {
        let nsError = self as NSError
        let localizedErrorCode = String(format: NSLocalizedString("%@ %@", comment: ""), nsError.domain, self.displayCode as NSNumber)
        return localizedErrorCode
    }
    
    var displayCode: Int {
        guard let serverError = self as? ALTServerError else {
            // Not ALTServerError, so display regular code.
            return (self as NSError).code
        }
        
        // We want ALTServerError codes to start at 2000,
        // but we can't change them without breaking AltServer compatibility.
        // Instead, we just add 2000 when displaying code to user
        // to make it appear as if codes start at 2000 normally.
        let code = 2000 + serverError.code.rawValue
        return code
    }
}
