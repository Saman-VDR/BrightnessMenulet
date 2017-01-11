//
//  MainMenuController.h
//  BrightnessMenulet
//
//  Created by Kalvin Loc on 10/10/14.
//
//


#define kMenuQuit 1
#define kMenuPreferences 2
#define kMenuToggleTheme 3
#define kMenuResolution 4
#define kMenuAutoBrightness 5

#ifdef DEBUG
#   define DebugLog(...) NSLog(__VA_ARGS__)
#else
#   define DebugLog(...)
#endif

#import <Cocoa/Cocoa.h>
#import <IOKit/graphics/IOGraphicsLib.h>

#import "LMUDelegate.h"
@interface MainMenuController : NSMenu <LMUDelegate>

- (void)refreshMenuScreens;

- (void)registerHotKeys;
- (void)unregisterHotKeys;

@end
