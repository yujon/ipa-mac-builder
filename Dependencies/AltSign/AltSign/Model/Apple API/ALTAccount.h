//
//  ALTAccount.h
//  AltSign
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALTAccount : NSObject

@property (nonatomic, copy) NSString *appleID;
@property (nonatomic, copy) NSString *identifier;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;

@end

NS_ASSUME_NONNULL_END
