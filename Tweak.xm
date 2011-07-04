#import <substrate.h>
#import <SpringBoard/SpringBoard.h>

@interface NSString (latelyAdded)
-(BOOL)containsSubstring:(id)substring;
@end

static BOOL isRingerSwitch;
static BOOL savedState;

extern "C" Boolean CFPreferencesGetAppBooleanValue (CFStringRef key,CFStringRef applicationID,Boolean *keyExistsAndHasValidFormat);

static Boolean (*orig_CFPreferencesGetAppBooleanValue) (CFStringRef key,CFStringRef applicationID,Boolean *keyExistsAndHasValidFormat);

static Boolean replaced_CFPreferencesGetAppBooleanValue (CFStringRef key,CFStringRef applicationID,Boolean *keyExistsAndHasValidFormat){
	if (!isRingerSwitch && [(NSString *)key isEqualToString:@"SBUseHardwareSwitchAsOrientationLock"] )
		return true;
	return orig_CFPreferencesGetAppBooleanValue(key,applicationID,keyExistsAndHasValidFormat);
}

static void getSettings(){
	NSString *path=@"/var/mobile/Library/Preferences/net.limneos.ringerswitchtool.plist";
	NSMutableDictionary *settingsDict=[NSMutableDictionary dictionaryWithContentsOfFile:path];
	if (!settingsDict){
		settingsDict=[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"mode",nil];
		[settingsDict writeToFile:path atomically:YES];
	}
	isRingerSwitch=[settingsDict valueForKey:@"mode"] ? [[settingsDict valueForKey:@"mode"] boolValue] : YES;
}


%hook SBIconController
-(void)_finishedUnscattering{
	%orig;
	getSettings();
	if (savedState!=isRingerSwitch)
		[(SpringBoard *)[%c(SpringBoard) sharedApplication] relaunchSpringBoard];
}
%end



%hook UIImage
+(id)imageNamed:(id)named{
	%log;
	if ([named containsSubstring:@"RotationLocked"] || [named containsSubstring:@"RotationUnlocked"] || [named containsSubstring:@"MuteOffButton"]  || [named containsSubstring:@"MuteOnButton"] )
		named= [NSString stringWithFormat:@"RingerSwitchTool%@",named];
	
	return %orig;
}
%end

%ctor {
	%init;
	getSettings();
	savedState=isRingerSwitch;
	MSHookFunction(CFPreferencesGetAppBooleanValue,replaced_CFPreferencesGetAppBooleanValue,&orig_CFPreferencesGetAppBooleanValue);
}

