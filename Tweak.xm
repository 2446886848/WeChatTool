#import "WeChatTool.h"

#pragma mark - Dice And JKenPu
static DiceNumber dice = DiceNumberNone;
static JKenPu jKenPu = JKenPuNone;
static CurrentChange currentChange = CurrentChangeNone;

static HeathStepMode stepMode = HeathStepModeMutiply;
static double stepNumber = 3.5;

static NSString *stepModeKey = @"stepModeKey";
static NSString *stepNumberKey = @"stepNumberKey";

static BOOL autoRedEnvOpen = NO;
static BOOL isInAutoRedEnvOpening = NO;

long (*oldRandom)(void);

long myRandom(void)
{
    if (currentChange == CurrentChangeDice) {
        return dice - 1;
    }
    else if (currentChange == CurrentChangeJKenPu) {
        return jKenPu - 1;
    }
    return oldRandom();
}

double changedStepCount(double oldStepCount) {
    double ret = oldStepCount;
    switch (stepMode) {
        case HeathStepModeNone:
            break;
        case HeathStepModeMutiply:
            ret = (unsigned int)(ret * stepNumber);
            break;
        case HeathStepModeAdd:
            ret += stepNumber;
            break;
        case HeathStepModeSet:
            ret = stepNumber;
            break;
        default:
            break;
    }
    
    return ret;
}

%ctor
{
    stepMode = (HeathStepMode)[[[NSUserDefaults standardUserDefaults] valueForKey:stepModeKey] integerValue];
    stepNumber = [[[NSUserDefaults standardUserDefaults] valueForKey:stepNumberKey] doubleValue];
    MSHookFunction(random ,myRandom,&oldRandom);
}

%hook GameController

//发送游戏数据函数
- (void)sendGameMessage:(id)arg1 toUsr:(id)arg2
{
    id emotionWrap = arg1;
    unsigned int m_uiType = [[emotionWrap valueForKey:@"m_uiType"] unsignedIntValue];
    unsigned int m_uiGameType = [[emotionWrap valueForKey:@"m_uiGameType"] unsignedIntValue];
    
    if (m_uiType == 1 && m_uiGameType == 2 && dice != 0) {
        currentChange = CurrentChangeDice;
    }
    else if (m_uiType == 1 && m_uiGameType == 1 && jKenPu != 0) {
        currentChange = CurrentChangeJKenPu;
    }
    else
    {
        currentChange = CurrentChangeNone;
    }
    %orig;
    currentChange = CurrentChangeNone;
}

%end

static NewMainFrameViewController *sessionVc;

%hook NewMainFrameViewController
- (void)viewDidLoad
{
    %orig;
    sessionVc = self;
}
%end

%hook MMNewSessionMgr
- (void)OnAddMsg:(NSString *)name MsgWrap:(CMessageWrap *)arg2
{
    %orig;
    [self checkRedEnvelopeWithName:name message:arg2];
}

%new
//检查红包
- (void)checkRedEnvelopeWithName:(NSString *)name message:(CMessageWrap *)arg2
{
    MMSessionInfo *sessionInfo = [self GetSessionByUserName:name]; //MMSessionInfo *
    
    MainFrameCellData *cellData = [self cellDataForMessageInfo:sessionInfo];
    
    BOOL isHongBao = [[cellData valueForKey:@"m_textForMessageLabel"] containsString:@"[微信红包]"];
    NSString *sessionName = [cellData valueForKey:@"m_textForNameLabel"];
    if (isHongBao && [[arg2 description] containsString:@"<silence>1</silence>"]) {
        [self showLocalNotification:[NSString stringWithFormat:@"“%@”%@", sessionName, @"发来了微信红包!"]];
    }
}

%new
- (MainFrameCellData *)cellDataForMessageInfo:(MMSessionInfo *)info
{
    MainFrameCellDataManager *cellDataManager = [[sessionVc valueForKey:@"m_mainFrameLogicController"] valueForKey:@"m_cellDataMgr"];
    MainFrameCellData *cellData = [cellDataManager getCellData:info]; //MainFrameCellData
    return cellData;
}

%new
- (void)showLocalNotification:(NSString *)alertBody
{
    UILocalNotification*notification = [[UILocalNotification alloc]init];
    NSDate * pushDate = [NSDate dateWithTimeIntervalSinceNow:0.1];
    if (notification != nil) {
        notification.fireDate = pushDate;
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.repeatInterval = kCFCalendarUnitDay;
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.alertBody = alertBody;
        notification.applicationIconBadgeNumber = 0;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        
    }
}
%end // MMNewSessionMgr end

%hook CMessageWrap

%new
- (BOOL)isMessageFromMe
{
    MMServiceCenter *center = [%c(MMServiceCenter) defaultCenter];
    //通讯录管理器
    CContactMgr *contactManager = [center getService:%c(CContactMgr)];
    
    id selfContact = [contactManager getSelfContact];
    
    NSString *m_nsFromUsr = [self valueForKey:@"m_nsFromUsr"];
    
    NSString *m_nsUsrName = [selfContact valueForKey:@"m_nsUsrName"];
    BOOL isMesasgeFromMe = [m_nsFromUsr isEqualToString:m_nsUsrName];
    
    return isMesasgeFromMe;
}
%end //CMessageWrap end

%hook BaseMsgContentViewController

- (void)AsyncSendMessage:(NSString *)arg1
{
    if ([arg1 isKindOfClass:[NSString class]]) {
        if([self dealMessage:arg1] || [self dealHeathStep:arg1]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"设置成功" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [alertView show];
        }
        else if ([arg1 isEqualToString:@"帮助"])
        {
            %orig(@"一个“微信”小功能集合。输入“帮助”即可查看帮助信息。\n  1、“骰子”控制，在自己对话框输入“骰子任意”（骰子任意）、“骰子一点”（一点）、“骰子二点”（二点）、“骰子三点”（三点）、“骰子四点”（四点）、“骰子五点”（五点）、“骰子六点”（六点）。\n  2、“猜拳”游戏控制，“猜拳任意”（猜拳任意）、“猜拳剪刀”（剪刀）、“猜拳石头”（石头）、“猜拳布”（布）。\n  3、微信步数控制，步数原值、步数乘n、步数加n、步数为n，通过以上指令可以控制步数的值。\n  4、屏蔽消息撤销功能。\n  5、微信自动抢红包，输入“自动抢红包”即可在聊天页面自动抢红包，输入“取消自动抢红包”取消自动抢红包功能。\n  备注：（1、2、5点）重启后程序均恢复为默认。");
        }
        else
        {
            %orig;
        }
    }
}

- (void)viewDidDisappear:(_Bool)arg1
{
    %orig;
    isInAutoRedEnvOpening = NO;
}
         
%new
//检查健康步数
- (BOOL)dealHeathStep:(NSString *)messageText
{
    BOOL isCmd = NO;
    NSString *setpOriStr = @"步数原值";
    NSString *setpAddStr = @"步数加";
    NSString *setpMulStr = @"步数乘";
    NSString *setpIsStr = @"步数为";
    if ([messageText containsString:setpAddStr]) {
        isCmd = YES;
        NSString *numberStr = [messageText substringFromIndex:setpAddStr.length];
        stepNumber = [numberStr integerValue];
        stepMode = HeathStepModeAdd;
    }
    if ([messageText containsString:setpMulStr]) {
        isCmd = YES;
        NSString *numberStr = [messageText substringFromIndex:setpMulStr.length];
        stepNumber = [numberStr doubleValue];
        stepMode = HeathStepModeMutiply;
    }
    if ([messageText containsString:setpIsStr]) {
        isCmd = YES;
        NSString *numberStr = [messageText substringFromIndex:setpIsStr.length];
        stepNumber = [numberStr integerValue];
        stepMode = HeathStepModeSet;
    }
    if ([messageText containsString:setpOriStr]) {
        isCmd = YES;
        stepMode = HeathStepModeNone;
    }
    
    //保存设置到沙盒
    [[NSUserDefaults standardUserDefaults] setObject:@(stepMode) forKey:stepModeKey];
    [[NSUserDefaults standardUserDefaults] setObject:@(stepNumber) forKey:stepNumberKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return isCmd;
}
         
%new
//处理自己输入的控制内容
- (BOOL)dealMessage:(NSString *)messageText
{
    BOOL isCmd = NO;
    if ([messageText isEqualToString:@"骰子任意"]) {
        isCmd = YES;
        dice = DiceNumberNone;
    }
    if ([messageText isEqualToString:@"骰子一点"]) {
        isCmd = YES;
        dice = DiceNumberOne;
    }
    if ([messageText isEqualToString:@"骰子二点"]) {
        isCmd = YES;
        dice = DiceNumberTwo;
    }
    if ([messageText isEqualToString:@"骰子三点"]) {
        isCmd = YES;
        dice = DiceNumberThree;
    }
    if ([messageText isEqualToString:@"骰子四点"]) {
        isCmd = YES;
        dice = DiceNumberFour;
    }
    if ([messageText isEqualToString:@"骰子五点"]) {
        isCmd = YES;
        dice = DiceNumberFive;
    }
    if ([messageText isEqualToString:@"骰子六点"]) {
        isCmd = YES;
        dice = DiceNumberSix;
    }
    if ([messageText isEqualToString:@"猜拳任意"]) {
        isCmd = YES;
        jKenPu = JKenPuNone;
    }
    if ([messageText isEqualToString:@"猜拳剪刀"]) {
        isCmd = YES;
        jKenPu = JKenPuOne;
    }
    if ([messageText isEqualToString:@"猜拳石头"]) {
        isCmd = YES;
        jKenPu = JKenPuTwo;
    }
    if ([messageText isEqualToString:@"猜拳布"]) {
        isCmd = YES;
        jKenPu = JKenPuThree;
    }
    if ([messageText isEqualToString:@"自动抢红包"]) {
        isCmd = YES;
        autoRedEnvOpen = YES;
    }
    if ([messageText isEqualToString:@"取消自动抢红包"]) {
        isCmd = YES;
        autoRedEnvOpen = NO;
    }
    return isCmd;
}

%end


#pragma mark - SetpCount

%hook HKStatistics

- (HKQuantity *)sumQuantity
{
    HKQuantity *quantity = %orig;
    
    HKUnit *unit = [quantity valueForKey:@"_unit"];
    double value = [quantity doubleValueForUnit:unit];
    HKQuantity *newQuantity = [%c(HKQuantity) quantityWithUnit:unit doubleValue:changedStepCount(value)];
    
    return newQuantity;
}

%end


//屏蔽删除消息功能
%hook CMessageMgr

- (void)DelMsg:(id)arg1 MsgList:(id)arg2 DelAll:(_Bool)arg3{}

%end

#pragma mark - RedEnvelope

@interface MMTableView : UITableView

@end

@interface CMessageNodeData : NSObject

@property(retain, nonatomic) CMessageWrap *m_msgWrap;

@end


@interface WCPayC2CMessageNodeView : UIView

- (BOOL)isRedEnvelop;
- (BOOL)isLastCell;

- (UITableViewCell *)zh_cell;
- (BaseMsgContentViewController *)zh_vc;

- (void)onClick;

@end

@interface WCRedEnvelopesReceiveHomeView : UIView

@property (nonatomic, strong) NSNumber *autoProcessed;
@property (nonatomic, strong) NSObject *tempData;

- (void)OnCancelButtonDone;
- (void)OnOpenRedEnvelopes;

@end

@interface WCRedEnvelopesRedEnvelopesDetailViewController : UIViewController

- (void)OnLeftBarButtonDone;

@end

%hook  WCPayC2CMessageNodeView

%new
- (BOOL)isRedEnvelop
{
    CMessageWrap *msg = [self valueForKey:@"m_oMessageWrap"];
    return msg.m_uiMessageType == 49;
}

%new
- (BOOL)isLastCell
{
    BaseMsgContentViewController *vc = [self zh_vc];
    if([vc isKindOfClass:[NSClassFromString(@"BaseMsgContentViewController") class]]) {
        NSMutableArray<CMessageNodeData *> *nodeDatas = [vc valueForKey:@"m_arrMessageNodeData"];
        CMessageNodeData *lastNodeData = nodeDatas.lastObject;
        CMessageWrap *msg = [self valueForKey:@"m_oMessageWrap"];
        return [lastNodeData m_msgWrap] == msg;
        //        return [lastNodeData m_msgWrap].m_n64MesSvrID == msg.m_n64MesSvrID;
    }
    return NO;
}

%new
- (UITableViewCell *)zh_cell
{
    UIView *view = self;
    while(view)
    {
        if([view isKindOfClass:[UITableViewCell class]])
        {
            return (UITableViewCell *)view;
        }
        view = [view superview];
    }
    return nil;
}
%new
- (BaseMsgContentViewController *)zh_vc
{
    UIResponder *responder = self;
    while(responder)
    {
        if([responder isKindOfClass:[UIViewController class]])
        {
            return (BaseMsgContentViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

- (void)layoutSubviews
{
    %orig;
    
    if (autoRedEnvOpen)
    {
        CMessageWrap *msg = (CMessageWrap *)[self valueForKey:@"m_oMessageWrap"];
        //消息来自于自己的单聊不处理
        
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:[NSString stringWithFormat:@"%@ %@", [msg isMesasgeFromMe], [[[self zh_vc] GetContact]] delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
//        [alertView show];
        
        if ([msg isMessageFromMe] && ![[[[self zh_vc] GetContact] valueForKey:@"m_nsUsrName"] containsString:@"@chatroom"])
        {
           return;
        }
        if([self isLastCell] && [self isRedEnvelop]) {
            isInAutoRedEnvOpening = YES;
            [self onClick];
        }
    }
}

%end

%hook WCRedEnvelopesReceiveHomeView

%new
- (NSNumber *)autoProcessed
{
    return objc_getAssociatedObject(self, @selector(autoProcessed));
}

%new
- (void)setAutoProcessed:(NSNumber *)autoProcessed
{
    objc_setAssociatedObject(self, @selector(autoProcessed), autoProcessed, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (NSObject *)tempData
{
    return objc_getAssociatedObject(self, @selector(tempData));
}

%new
- (void)setTempData:(NSObject *)tempData
{
    objc_setAssociatedObject(self, @selector(tempData), tempData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)layoutSubviews
{
    %orig;
    
    if (isInAutoRedEnvOpening && !self.autoProcessed)
    {
        UIButton *openButton = [self valueForKey:@"openRedEnvelopesButton"];
        if (openButton.hidden)
        {
            self.autoProcessed = nil;
            isInAutoRedEnvOpening = NO;
            [self OnCancelButtonDone];
        }
        else
        {
            self.autoProcessed = @(YES);
            [self OnOpenRedEnvelopes];
        }
    }
    
}


%end

%hook WCRedEnvelopesRedEnvelopesDetailViewController

- (void)setLeftCloseBarButton
{
    %orig;
    
    if (isInAutoRedEnvOpening) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            isInAutoRedEnvOpening = NO;
            [self OnLeftBarButtonDone];
        });
    }
}

%end

//%hook WCRedEnvelopesReceiveControlLogic
//
//- (void)OnLoadMoreRedEnvelopesList { %log; %orig; }
//- (void)OnOpenRedEnvelopesRequest:(id)arg1 Error:(id)arg2 { %log; %orig; }
//- (void)OnQueryRedEnvelopesDetailRequest:(id)arg1 Error:(id)arg2 { %log; %orig; }
//- (void)OnQueryUserSendOrReceiveRedEnveloperListRequest:(id)arg1 Error:(id)arg2 { %log; %orig; }
//- (void)OnReceiverQueryRedEnvelopesRequest:(id)arg1 Error:(id)arg2 { %log; %orig; }
//
//%end

