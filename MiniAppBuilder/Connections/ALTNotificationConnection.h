#import "AltSign.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(NotificationConnection)
@interface ALTNotificationConnection : NSObject

@property (nonatomic, copy, readonly) ALTDevice *device;

@property (nonatomic, copy, nullable) void (^receivedNotificationHandler)(CFNotificationName notification);

- (void)startListeningForNotifications:(NSArray<NSString *> *)notifications
                     completionHandler:(void (^)(BOOL success, NSError *_Nullable error))completionHandler;

- (void)sendNotification:(CFNotificationName)notification
       completionHandler:(void (^)(BOOL success, NSError *_Nullable error))completionHandler;

- (void)disconnect;

@end

NS_ASSUME_NONNULL_END
