#import <substrate.h>

@interface CMessageWrap : NSObject

- (BOOL)isMessageFromMe;

@end

@interface MMSessionInfo : NSObject
@end

@interface MainFrameCellData : NSObject
@end

@interface MainFrameCellDataManager : NSObject
- (id)getCellData:(id)arg1;
@end

@interface MMNewSessionMgr : NSObject
- (MMSessionInfo *)GetSessionByUserName:(id)arg1;
- (MainFrameCellData *)cellDataForMessageInfo:(MMSessionInfo *)info;
- (void)checkRedEnvelopeWithName:(NSString *)name message:(CMessageWrap *)arg2;
- (void)showLocalNotification:(NSString *)alertBody;
@end

@interface NewMainFrameViewController : NSObject
@end

@interface BaseMsgContentViewController : NSObject

- (void)dealHeathStep:(NSString *)messageText;
- (void)dealMessage:(NSString *)messageText;

@end

@interface CContactMgr : NSObject

- (id)getSelfContact;

@end

@interface MMServiceCenter : NSObject

+ (id)defaultCenter;
- (id)getService:(Class)serviceClass;

@end

typedef enum : NSUInteger {
    DiceNumberNone = 0,
    DiceNumberOne,
    DiceNumberTwo,
    DiceNumberThree,
    DiceNumberFour,
    DiceNumberFive,
    DiceNumberSix
} DiceNumber;

typedef enum : NSUInteger {
    JKenPuNone = 0,
    JKenPuOne,
    JKenPuTwo,
    JKenPuThree,
} JKenPu;

typedef enum : NSUInteger {
    CurrentChangeNone,
    CurrentChangeJKenPu,
    CurrentChangeDice,
} CurrentChange;

typedef enum : NSUInteger {
    HeathStepModeNone,
    HeathStepModeMutiply,
    HeathStepModeAdd,
    HeathStepModeSet,
} HeathStepMode;

@interface HKUnit : NSObject

@end

@interface HKQuantity : NSObject

- (double)doubleValueForUnit:(HKUnit *)unit;
+ (id)quantityWithUnit:(HKUnit *)unit doubleValue:(double)value;

@end