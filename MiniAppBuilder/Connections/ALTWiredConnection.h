//
//  ALTWiredConnection.h
//
//


#import "AltSign.h"

#import "ALTConnection.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(WiredConnection)
@interface ALTWiredConnection : NSObject <ALTConnection>

@property (nonatomic, readonly, getter=isConnected) BOOL connected;

@property (nonatomic, copy, readonly) ALTDevice *device;

- (void)sendData:(NSData *)data completionHandler:(void (^)(BOOL, NSError * _Nullable))completionHandler;
- (void)receiveDataWithExpectedSize:(NSInteger)expectedSize completionHandler:(void (^)(NSData * _Nullable, NSError * _Nullable))completionHandler;

- (void)disconnect;

@end

NS_ASSUME_NONNULL_END
