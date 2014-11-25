#import <FSSwitchDataSource.h>
#import <FSSwitchPanel.h>
#import <notify.h>

#define kSpringBoardPlist @"/var/mobile/Library/Preferences/com.apple.springboard.plist"

#ifndef GSEVENT_H
extern void GSSendAppPreferencesChanged(CFStringRef bundleID, CFStringRef key);
#endif

@interface VibrationSwitch : NSObject <FSSwitchDataSource>
@end

@implementation VibrationSwitch

static void VibrationSettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    [[FSSwitchPanel sharedPanel] stateDidChangeForSwitchIdentifier:[NSBundle bundleForClass:[VibrationSwitch class]].bundleIdentifier];
}

+ (void)load
{
    CFNotificationCenterRef center = CFNotificationCenterGetDarwinNotifyCenter();
    CFNotificationCenterAddObserver(center, NULL, VibrationSettingsChanged, CFSTR("com.apple.springboard.ring-vibrate.changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    CFNotificationCenterAddObserver(center, NULL, VibrationSettingsChanged, CFSTR("com.apple.springboard.ring-silent.changed"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
    if (kCFCoreFoundationVersionNumber >= 1000) {
        CFPreferencesAppSynchronize(CFSTR("com.apple.springboard"));
	BOOL enabled = (CFPreferencesGetAppBooleanValue(CFSTR("ring-vibrate"), CFSTR("com.apple.springboard"),NULL) && CFPreferencesGetAppBooleanValue(CFSTR("silent-vibrate"), CFSTR("com.apple.springboard"),NULL));
	return enabled;
    } else {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:kSpringBoardPlist];
        BOOL enabled = ([[dict valueForKey:@"ring-vibrate"] boolValue] && [[dict valueForKey:@"silent-vibrate"] boolValue]);
        return enabled;
    }
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier
{
	if (newState == FSSwitchStateIndeterminate)
		return;

    if (kCFCoreFoundationVersionNumber >= 1000) {
	CFPreferencesSetAppValue(CFSTR("ring-vibrate"), (CFTypeRef)[NSNumber numberWithBool:newState], CFSTR("com.apple.springboard"));
	CFPreferencesSetAppValue(CFSTR("silent-vibrate"), (CFTypeRef)[NSNumber numberWithBool:newState], CFSTR("com.apple.springboard"));
	CFPreferencesAppSynchronize(CFSTR("com.apple.springboard"));
    } else {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:kSpringBoardPlist] ?: [[NSMutableDictionary alloc] init];
        NSNumber *value = [NSNumber numberWithBool:newState];
        [dict setValue:value forKey:@"ring-vibrate"];
        [dict setValue:value forKey:@"silent-vibrate"];
        [dict writeToFile:kSpringBoardPlist atomically:YES];
    	[dict release];
    }

    notify_post("com.apple.springboard.ring-vibrate.changed");
    GSSendAppPreferencesChanged(CFSTR("com.apple.springboard"), CFSTR("ring-vibrate"));
    notify_post("com.apple.springboard.silent-vibrate.changed");
    GSSendAppPreferencesChanged(CFSTR("com.apple.springboard"), CFSTR("silent-vibrate"));
}

@end
