#import <substrate.h>

@interface CMessageWrap : NSObject

@property(nonatomic) long long m_n64MesSvrID;
@property(nonatomic) unsigned int m_uiMessageType;

- (BOOL)isMessageFromMe;

@end

@interface MMTableViewSectionInfo

+ (id)sectionInfoDefaut;
- (void)addCell:(id)arg1;

@end

@interface MMTableViewInfo

- (id)getTableView;
- (void)addSection:(id)arg1;
- (void)insertSection:(id)arg1 At:(unsigned int)arg2;

@end

@interface MMTableViewCellInfo

+ (id)normalCellForSel:(SEL)arg1 target:(id)arg2 title:(id)arg3 accessoryType:(long long)arg4;
+ (id)switchCellForSel:(SEL)arg1 target:(id)arg2 title:(id)arg3 on:(_Bool)arg4;
+ (id)normalCellForSel:(SEL)arg1 target:(id)arg2 title:(id)arg3 rightValue:(id)arg4 accessoryType:(long long)arg5;
+ (id)normalCellForTitle:(id)arg1 rightValue:(id)arg2;

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

@interface WCPayC2CMessageViewModel : NSObject

+ (BOOL)canCreateMessageViewModelWithMessageWrap:(id)arg1;

@end

@interface CMessageMgr : NSObject

- (BOOL)isChatStatusNotifyOpenForMsgWrap:(id)arg1;

@end

@interface BaseMsgContentViewController : NSObject

- (BOOL)dealHeathStep:(NSString *)messageText;
- (BOOL)dealMessage:(NSString *)messageText;
- (id)GetContact;

@end

@interface CAppViewControllerManager : NSObject

+ (CAppViewControllerManager *)getAppViewControllerManager;
- (void)OnShowPush:(CMessageWrap *)msg;

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
