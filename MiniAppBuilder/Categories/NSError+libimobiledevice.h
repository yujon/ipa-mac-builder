#import <libimobiledevice/mobile_image_mounter.h>
#import <libimobiledevice/debugserver.h>
#import <libimobiledevice/installation_proxy.h>

#import <AltSign/ALTDevice.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSError (libimobiledevice)

+ (nullable instancetype)errorWithMobileImageMounterError:(mobile_image_mounter_error_t)error device:(nullable ALTDevice *)device;
+ (nullable instancetype)errorWithDebugServerError:(debugserver_error_t)error device:(nullable ALTDevice *)device;
+ (nullable instancetype)errorWithInstallationProxyError:(instproxy_error_t)error device:(nullable ALTDevice *)device;

@end

NS_ASSUME_NONNULL_END
