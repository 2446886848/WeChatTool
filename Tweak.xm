#import "WeChatTool.h"

#pragma mark - Dice And JKenPu
static DiceNumber dice = DiceNumberNone;
static JKenPu jKenPu = JKenPuNone;
static CurrentChange currentChange = CurrentChangeNone;

static HeathStepMode stepMode = HeathStepModeMutiply;
static double stepNumber = 3.5;

static NSString *stepModeKey = @"stepModeKey";
static NSString *stepNumberKey = @"stepNumberKey";

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
    %orig;
    if ([arg1 isKindOfClass:[NSString class]]) {
        [self dealMessage:arg1];
        [self dealHeathStep:arg1];
    }
}
         
%new
//检查健康步数
- (void)dealHeathStep:(NSString *)messageText
{
    NSString *setpOriStr = @"步数原值";
    NSString *setpAddStr = @"步数加";
    NSString *setpMulStr = @"步数乘";
    NSString *setpIsStr = @"步数为";
    if ([messageText containsString:setpAddStr]) {
        NSString *numberStr = [messageText substringFromIndex:setpAddStr.length];
        stepNumber = [numberStr integerValue];
        stepMode = HeathStepModeAdd;
    }
    if ([messageText containsString:setpMulStr]) {
        NSString *numberStr = [messageText substringFromIndex:setpMulStr.length];
        stepNumber = [numberStr doubleValue];
        stepMode = HeathStepModeMutiply;
    }
    if ([messageText containsString:setpIsStr]) {
        NSString *numberStr = [messageText substringFromIndex:setpIsStr.length];
        stepNumber = [numberStr integerValue];
        stepMode = HeathStepModeSet;
    }
    if ([messageText containsString:setpOriStr]) {
        stepMode = HeathStepModeNone;
    }
    
    //保存设置到沙盒
    [[NSUserDefaults standardUserDefaults] setObject:@(stepMode) forKey:stepModeKey];
    [[NSUserDefaults standardUserDefaults] setObject:@(stepNumber) forKey:stepNumberKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
         
%new
//处理自己输入的控制内容
- (void)dealMessage:(NSString *)messageText
{
    if ([messageText containsString:@"骰子任意"]) {
        dice = DiceNumberNone;
    }
    if ([messageText containsString:@"骰子一点"]) {
        dice = DiceNumberOne;
    }
    if ([messageText containsString:@"骰子二点"]) {
        dice = DiceNumberTwo;
    }
    if ([messageText containsString:@"骰子三点"]) {
        dice = DiceNumberThree;
    }
    if ([messageText containsString:@"骰子四点"]) {
        dice = DiceNumberFour;
    }
    if ([messageText containsString:@"骰子五点"]) {
        dice = DiceNumberFive;
    }
    if ([messageText containsString:@"骰子六点"]) {
        dice = DiceNumberSix;
    }
    if ([messageText containsString:@"猜拳任意"]) {
        jKenPu = JKenPuNone;
    }
    if ([messageText containsString:@"猜拳剪刀"]) {
        jKenPu = JKenPuOne;
    }
    if ([messageText containsString:@"猜拳石头"]) {
        jKenPu = JKenPuTwo;
    }
    if ([messageText containsString:@"猜拳布"]) {
        jKenPu = JKenPuThree;
    }
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

