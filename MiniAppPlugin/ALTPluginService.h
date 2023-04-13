//
//  ALTPluginService.h
//  AltPlugin
//


#import <Foundation/Foundation.h>

@class ALTAnisetteData;

NS_ASSUME_NONNULL_BEGIN

@interface ALTPluginService : NSObject

@property (class, nonatomic, readonly) ALTPluginService *sharedService;

- (ALTAnisetteData *)requestAnisetteData;

@end

NS_ASSUME_NONNULL_END
