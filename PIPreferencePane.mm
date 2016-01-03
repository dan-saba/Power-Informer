#import <Preferences/Preferences.h>

@interface PIPreferencePaneListController: PSListController {
}

+ (PIPreferencePaneListController*)sharedInstance;

@end

@implementation PIPreferencePaneListController

static PIPreferencePaneListController *sharedInstance = nil;

void updateNotifReceived (
    CFNotificationCenterRef center,
    void *observer,
    CFStringRef name,
    const void *object,
    CFDictionaryRef userInfo
)
{
	[[PIPreferencePaneListController sharedInstance] reloadSpecifiers];
}

/*- (PIPreferencePaneListController*)init
{
	self = [super init];
	if (self)
	{
		sharedInstance = self;
		
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, updateNotifReceived,
		 CFSTR("com.timedaemon.powerinformer"), NULL,
		  CFNotificationSuspensionBehaviorDeliverImmediately);
		  
		//Piracy detection
		BOOL pr;
		if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/com.timedaemon.powerinformer.list"])
			pr = YES;
		else
			pr = NO;
		
		if (pr)
		{
			NSString *prMsg = @"Looks like we've spotted a pirate! If you like Power Informer, please consider donating some buried treasure!";
			UIAlertView *prAlert = [[UIAlertView alloc] initWithTitle: @"Arrgh, A Pirate!"
												message:prMsg
											delegate:nil 
									  cancelButtonTitle:@"Dismiss"
									  otherButtonTitles:nil];
			[prAlert show];
		}
	}
	return self;
}*/

+ (PIPreferencePaneListController*)sharedInstance
{
	return sharedInstance;
}

- (id)specifiers
{
	if(!_specifiers)
		_specifiers = [self loadSpecifiersFromPlistName:@"PISpecifiersList" target:self];
		
	return _specifiers;
}

static NSArray* convertNSNumberArrayToNSStringArrayWithPercent(NSArray *numberArray)
{
	NSMutableArray *NSStringArray = [NSMutableArray new];
	
	for (int i = 0; i < [numberArray count]; i++)
		[NSStringArray addObject: [NSString stringWithFormat: @"%@ %%", [numberArray objectAtIndex: i]]];
	
	return [[NSArray alloc] initWithArray: NSStringArray];
}

- (NSArray*)getValidPowerLevelValues
{
	NSMutableArray *valuesList = [NSMutableArray new];
	
	for (int i = 100; i >= 1; i--)
		[valuesList addObject: [NSNumber numberWithInt: i]];
	
	return [[NSArray alloc] initWithArray: valuesList];
}

- (NSArray*)getValidPowerLevelTitles
{
	return convertNSNumberArrayToNSStringArrayWithPercent([self getValidPowerLevelValues]);
}

- (NSArray*)getValidIncrementValues
{
	NSMutableArray *validIncrementValues = [NSMutableArray new];
	
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile: 
	@"/User/Library/Preferences/com.timedaemon.powerinformer.plist"];
	int powerLevel = 30;
	if (settings[@"powerLevel"]){
		powerLevel = [settings[@"powerLevel"] intValue];
	}
	
	for (int i = powerLevel - 1; i >= 1; i--)
		[validIncrementValues addObject: @(i)];
		
	return [[NSArray alloc] initWithArray: validIncrementValues];
}

- (NSArray*)getValidIncrementTitles
{
	return convertNSNumberArrayToNSStringArrayWithPercent([self getValidIncrementValues]);
}

- (void)openPaypalLink:(id)param
{
	 [[UIApplication sharedApplication] openURL:[NSURL URLWithString: 
	 @"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=RZR4L777XGYF2&lc=US&item_name=Power%20Informer&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted"]];
}

@end

// vim:ft=objc
