//
//  NSFileManager+Zip.h
//  AltSign
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (Zip)

- (BOOL)unzipArchiveAtURL:(NSURL *)archiveURL toDirectory:(NSURL *)directoryURL error:(NSError **)error;
- (BOOL)unzipArchiveAtURL:(NSURL *)archiveURL toDirectory:(NSURL *)directoryURL progress:(NSProgress *)progress error:(NSError **)error;

- (nullable NSURL *)unzipAppBundleAtURL:(NSURL *)ipaURL toDirectory:(NSURL *)directoryURL error:(NSError **)error;
- (nullable NSURL *)zipAppBundleAtURL:(NSURL *)appBundleURL error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
