//
//  ALTSigner.h
//  AltSign
//

#import <Foundation/Foundation.h>

@class ALTAppID;
@class ALTTeam;
@class ALTCertificate;
@class ALTProvisioningProfile;

NS_ASSUME_NONNULL_BEGIN

@interface ALTSigner : NSObject

@property (nonatomic) ALTTeam *team;
@property (nonatomic) ALTCertificate *certificate;

- (instancetype)initWithTeam:(ALTTeam *)team certificate:(ALTCertificate *)certificate;

- (NSProgress *)signAppAtURL:(NSURL *)appURL provisioningProfiles:(NSArray<ALTProvisioningProfile *> *)profiles completionHandler:(void (^)(BOOL success, NSError *_Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
