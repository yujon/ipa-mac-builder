#import "ALTNotificationConnection.h"

#include <libimobiledevice/libimobiledevice.h>
#include <libimobiledevice/notification_proxy.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALTNotificationConnection ()

@property (nonatomic, readonly) np_client_t client;

- (instancetype)initWithDevice:(ALTDevice *)device client:(np_client_t)client;

@end

NS_ASSUME_NONNULL_END
