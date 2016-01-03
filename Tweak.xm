#ifndef kCFCoreFoundationVersionNumber_iOS_9_0
#define kCFCoreFoundationVersionNumber_iOS_9_0 1240.10
#endif

static BOOL isEnabled = YES;
static int powerLevel = 30;
static int incrementLevel = 10;
static NSMutableArray *alertLevels = nil;
static NSString *batteryAlertString = @"Battery Alert";
static NSString *percentRemainingString = @"of battery remaining";
static NSString *fullyChargedString = @"Battery fully charged";
static NSString *dismissString = @"Dismiss";
static BOOL shouldIgnore20Percent = YES;

@interface SBUIController : NSObject

- (float)batteryCapacity;

@end

static int hookedBatteryCapacityMethod(SBUIController *controller);

%hook SBUIController

static int lastPercentageShown = -1;

- (SBUIController*)init
{
	self = %orig;
	
	[[UIDevice currentDevice] setBatteryMonitoringEnabled: YES];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		selector:@selector(batteryStateDidChange:)
		name:UIDeviceBatteryStateDidChangeNotification
		object:nil];
	
	return self;
}

BOOL shouldShowAlert(int batteryCapacity)
{
	if (!(isEnabled && [[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateUnplugged))
		return NO;
	
	if (lastPercentageShown != batteryCapacity && [alertLevels containsObject: @(batteryCapacity)])
		return YES;
	else
		return NO;
}

- (int)batteryCapacityAsPercentage
{
	return hookedBatteryCapacityMethod(self);
}

/**
- (int)displayBatteryCapacityAsPercentage
{
	return hookedBatteryCapacityMethod(self);
} **/

static int hookedBatteryCapacityMethod(SBUIController *controller)
{
	float capacityAsFloat = [controller batteryCapacity] * 100;
	int batteryCapacity = lroundf(capacityAsFloat);
	
	if (shouldShowAlert(batteryCapacity))
	{
		lastPercentageShown = batteryCapacity;
		
		NSString *batteryRemainingMessage;
		if (batteryCapacity < 100)
		{
			batteryRemainingMessage = [NSString stringWithFormat: @"%d%% ", batteryCapacity];
			batteryRemainingMessage = [batteryRemainingMessage stringByAppendingString: percentRemainingString];
		}
		else
			batteryRemainingMessage = fullyChargedString;
			
		UIAlertView *batteryAlert = [[UIAlertView alloc] initWithTitle: batteryAlertString
													message:batteryRemainingMessage
												delegate:nil 
										  cancelButtonTitle:dismissString
										  otherButtonTitles:nil];
								  
		[batteryAlert show];
	}
	
	return batteryCapacity;	
}

%new
- (void)batteryStateDidChange:(NSNotification*)notification
{
	if ([[UIDevice currentDevice] batteryState] == UIDeviceBatteryStateCharging)
		lastPercentageShown = -1;
}

%end

%hook SBLowPowerAlertItem

+ (BOOL)_shouldIgnoreChangeToBatteryLevel:(unsigned int)arg1
{
	return shouldIgnore20Percent;
}

%end

static void setSettings()
{
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile: 
	@"/User/Library/Preferences/com.timedaemon.powerinformer.plist"];
	
	if (settings[@"isEnabled"]){
		isEnabled = [settings[@"isEnabled"] boolValue];
	}
	if (settings[@"powerLevel"]){
		powerLevel = [settings[@"powerLevel"] intValue];
	}
	if (settings[@"incrementLevel"]){
		incrementLevel = [settings[@"incrementLevel"] intValue];
	}
	if (settings[@"batteryAlertString"]){
		batteryAlertString = settings[@"batteryAlertString"];
	}
	if (settings[@"percentRemainingString"]){
		percentRemainingString = settings[@"percentRemainingString"];
	}
	if (settings[@"fullyChargedString"]){
		fullyChargedString = settings[@"fullyChargedString"];
	}
	if (settings[@"dismissString"]){
		dismissString = settings[@"dismissString"];
	}
	if (settings[@"shouldIgnore20Percent"]){
		shouldIgnore20Percent = [settings[@"shouldIgnore20Percent"] boolValue];
	}
	
	alertLevels = [NSMutableArray new];
	for (int i = powerLevel; i >= 1; i -= incrementLevel)
		[alertLevels addObject: @(i)];
}

void updateSettings (
    CFNotificationCenterRef center,
    void *observer,
    CFStringRef name,
    const void *object,
    CFDictionaryRef userInfo
){
	setSettings();
}

%ctor
{
	setSettings();
	
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, updateSettings,
	CFSTR("com.timedaemon.powerinformer"), NULL,
	CFNotificationSuspensionBehaviorDeliverImmediately);
	
	%init;
}