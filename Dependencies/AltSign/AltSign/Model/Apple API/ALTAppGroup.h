//
//  ALTAppGroup.h
//  AltSign
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALTAppGroup : NSObject

@property (copy, nonatomic, readonly) NSString *name;
@property (copy, nonatomic, readonly) NSString *identifier;

@property (copy, nonatomic, readonly) NSString *groupIdentifier;

@end

NS_ASSUME_NONNULL_END
