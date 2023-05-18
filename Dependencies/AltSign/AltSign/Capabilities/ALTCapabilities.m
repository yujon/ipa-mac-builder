//
//  ALTCapabilities.m
//  AltSign
//


#import "ALTCapabilities.h"

// 'com.apple.security.application-groups' =>               'APG3427HIY',
// 'com.apple.developer.in-app-payments' =>                 'OM633U5T5G',
// 'com.apple.developer.healthkit' =>                       'HK421J6T7P',
// 'com.apple.developer.homekit' =>                         'homeKit',
// 'com.apple.InAppPurchase' =>                             'inAppPurchase',
// 'inter-app-audio' =>                                     'IAD53UNK2F',
// 'com.apple.developer.networking.multipath' =>            'MP49FN762P',
// 'com.apple.developer.networking.networkextension' =>     'NWEXT04537',
// 'com.apple.developer.nfc.readersession.formats' =>       'NFCTRMAY17',
// 'com.apple.developer.networking.vpn.api' =>              'V66P55NK2I',
// 'aps-environment' =>                                     'push',
// 'com.apple.developer.siri' =>                            'SI015DKUHP',
// 'com.apple.developer.pass-type-identifiers' =>           'passbook',
// 'com.apple.developer.associated-domains' =>              'SKC3T5S89Y',
// 'com.apple.developer.networking.HotspotConfiguration' => 'HSC639VEI8',
// 'com.apple.external-accessory.wireless-configuration' => 'WC421J6T7P'

// Entitlements
ALTEntitlement const ALTEntitlementApplicationIdentifier = @"application-identifier";
ALTEntitlement const ALTEntitlementKeychainAccessGroups = @"keychain-access-groups";
ALTEntitlement const ALTEntitlementGetTaskAllow = @"get-task-allow";
ALTEntitlement const ALTEntitlementTeamIdentifier = @"com.apple.developer.team-identifier";
ALTEntitlement const ALTEntitlementAppGroups = @"com.apple.security.application-groups";
ALTEntitlement const ALTEntitlementInterAppAudio = @"inter-app-audio";
ALTEntitlement const ALTEntitlementAssociatedDomain = @"com.apple.developer.associated-domains";
ALTEntitlement const ALTEntitlementHotspotConfiguration = @"com.apple.developer.networking.HotspotConfiguration";
ALTEntitlement const ALTEntitlementWifiInfo = @"com.apple.developer.networking.wifi-info";
ALTEntitlement const ALTEntitlementWireless = @"com.apple.external-accessory.wireless-configuration";

// Features
ALTFeature const ALTFeatureGameCenter = @"gameCenter";
ALTFeature const ALTFeatureAppGroups = @"APG3427HIY";
ALTFeature const ALTFeatureInterAppAudio = @"IAD53UNK2F";
ALTFeature const ALTFeatureAssociatedDomain = @"SKC3T5S89Y";
ALTFeature const ALTFeatureHotspotConfiguration = @"HSC639VEI8";
ALTFeature const ALTFeatureWireless = @"WC421J6T7P";


_Nullable ALTEntitlement ALTEntitlementForFeature(ALTFeature feature)
{
    if ([feature isEqualToString:ALTFeatureAppGroups])
    {
        return ALTEntitlementAppGroups;
    }
    else if ([feature isEqualToString:ALTFeatureInterAppAudio])
    {
        return ALTEntitlementInterAppAudio;
    }
    
    return nil;
}

_Nullable ALTFeature ALTFeatureForEntitlement(ALTEntitlement entitlement)
{
    if ([entitlement isEqualToString:ALTEntitlementAppGroups])
    {
        return ALTFeatureAppGroups;
    }
    else if ([entitlement isEqualToString:ALTEntitlementInterAppAudio])
    {
        return ALTFeatureInterAppAudio;
    } 
    // else if ([entitlement isEqualToString:ALTEntitlementAssociatedDomain])
    // {
    //     return ALTFeatureAssociatedDomain;
    // }
    //  else if ([entitlement isEqualToString:ALTEntitlementHotspotConfiguration])
    // {
    //     return ALTFeatureHotspotConfiguration;
    // }
    //  else if ([entitlement isEqualToString:ALTEntitlementWireless])
    // {
    //     return ALTFeatureWireless;
    // }
    
    
    return nil;
}
