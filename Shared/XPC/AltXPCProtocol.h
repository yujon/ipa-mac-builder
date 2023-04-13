//
//  AltXPCProtocol.h
//


#import <Foundation/Foundation.h>

@class ALTAnisetteData;

@protocol AltXPCProtocol

- (void)ping:(void (^_Nonnull)(void))completionHandler;
- (void)requestAnisetteDataWithCompletionHandler:(void (^_Nonnull)(ALTAnisetteData *_Nullable anisetteData, NSError *_Nullable error))completionHandler;
    
@end
