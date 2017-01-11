//
//  MainMenuController.m
//  BrightnessMenulet
//
//  Created by Kalvin Loc on 10/10/14.
//
//

#import "Screen.h"

#import "MainMenuController.h"
#import "PreferencesController.h"

#import "VirtualKeyCodes.h"
#import <Carbon/Carbon.h>

@interface MainMenuController () {
    EventHotKeyRef hotKeyRef;
}

@property PreferencesController* preferencesController;

@property (weak) IBOutlet NSMenuItem *autoBrightnessItem;

@property (assign, nonatomic) BOOL darkModeOn;
@end


@implementation MainMenuController

/*
 - (BOOL)validateMenuItem:(NSMenuItem *)menuItem
 {
 DebugLog(@"validate %@", [menuItem title]);
 if ([menuItem tag] == kMenuAutoBrightness) {
 return lmuCon.avaible;
 }
 return YES;
 }
 */

- (void)refreshMenuScreens {
    [controls refreshScreens];

    while(!(self.itemArray[0].isSeparatorItem))                // Remove all current display menu items
        [self removeItemAtIndex:0];

    if([controls.screens count] == 0){
        // No screen connected, so disable outlets
        NSMenuItem* noDispItem = [[NSMenuItem alloc] init];
        noDispItem.title = @"No displays found";
        
        [self insertItem:noDispItem atIndex:0];

        if(lmuCon.monitoring)
            [lmuCon stopMonitoring];
        return;
    }
    
    // No LMU available
    if(!lmuCon.available) {
        if(self.autoBrightnessItem) {
            [self removeItem:self.autoBrightnessItem];
            NSLog(@"Remove 'Auto-Brightness' menu item");
        }
    }
    

    // add new outlets for screens
    for(Screen* screen in controls.screens){
        NSString* title = [NSString stringWithFormat:@"%@", screen.model];
        NSMenuItem* scrDesc = [[NSMenuItem alloc] init];
        scrDesc.title = title;
        scrDesc.enabled = NO;

        NSSlider* slider = [[NSSlider alloc] initWithFrame:NSRectFromCGRect(CGRectMake(18, 0, 100, 20))];
        slider.target = self;
        slider.action = @selector(sliderUpdate:);
        slider.tag = screen.screenNumber;
        slider.minValue = 0;
        slider.maxValue = screen.maxBrightness;
        slider.integerValue = screen.currentBrightness;
        
        NSTextField* brightLevelLabel = [[NSTextField alloc] initWithFrame:NSRectFromCGRect(CGRectMake(118, 0, 30, 19))];
        brightLevelLabel.backgroundColor = [NSColor clearColor];
        brightLevelLabel.alignment = NSTextAlignmentLeft;
        [[brightLevelLabel cell] setTitle:[NSString stringWithFormat:@"%ld", (long)screen.currentBrightness]];
        [[brightLevelLabel cell] setBezeled:NO];
        
        NSMenuItem* scrSlider = [[NSMenuItem alloc] init];
        
        NSView* view = [[NSView alloc] initWithFrame:NSRectFromCGRect(CGRectMake(0, 0, 140, 20))];
        [view addSubview:slider];
        [view addSubview:brightLevelLabel];
        
        [scrSlider setView:view];
        [self insertItem:scrSlider atIndex:0];
        [self insertItem:scrDesc atIndex:0];

        NSLog(@"MainMenu: %@ - %d outlets set with BR %ld", screen.model, screen.screenNumber, (long)screen.currentBrightness);

        [screen.brightnessOutlets addObjectsFromArray:@[ slider, brightLevelLabel ]];
    }

    // DarkMode
    if ([[[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"] isEqualToString:@"Dark"]) {
        self.darkModeOn = YES;
        [self itemWithTag:kMenuToggleTheme].state = NSOnState;
    }
    else {
        self.darkModeOn = NO;
        [self itemWithTag:kMenuToggleTheme].state = NSOffState;
    }
    
    float scale = [[NSScreen mainScreen] backingScaleFactor];
    [self itemWithTag:kMenuResolution].title = @"High DPI";
    if (scale > 1.0) {
        [self itemWithTag:kMenuResolution].state = NSOnState;
    } else {
        [self itemWithTag:kMenuResolution].state = NSOffState;
    }
}

- (IBAction)toggledAutoBrightness:(NSMenuItem*)sender {
    if(sender.state == NSOffState){
        [sender setState:NSOnState];
        [lmuCon startMonitoring];
    }else{
        [sender setState:NSOffState];
        [lmuCon stopMonitoring];
    }
}

- (IBAction)preferences:(id)sender {
    if(!_preferencesController)
        _preferencesController = [[PreferencesController alloc] init];

    [_preferencesController showWindow];
}

- (void)sliderUpdate:(NSSlider*)slider {
    [[controls screenForDisplayID:slider.tag] setBrightness:[slider integerValue] byOutlet:slider];
}

- (IBAction)quit:(id)sender {
    [[NSApplication sharedApplication] terminate:self];
}

#pragma mark - LMUDelegate

- (void)LMUControllerDidStartMonitoring {
    [_autoBrightnessItem setState:NSOnState];
}

- (void)LMUControllerDidStopMonitoring {
    [_autoBrightnessItem setState:NSOffState];
}

#pragma mark - Global HotKeys
-(void)registerHotKeys
{
    //EventHotKeyRef hotKeyRef;
    if (!hotKeyRef) {
        NSLog(@"Register HotKeys");
        
        EventHotKeyID hotKeyID;
        EventTypeSpec eventType;
        eventType.eventClass=kEventClassKeyboard;
        eventType.eventKind=kEventHotKeyPressed;
        
        InstallApplicationEventHandler(&OnHotKeyEvent, 1, &eventType, (void *)CFBridgingRetain(self), NULL);
        
        hotKeyID.signature='htk1';
        hotKeyID.id=1;
        RegisterEventHotKey(kVK_ANSI_T, cmdKey+optionKey, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
        
        hotKeyID.signature='htk2';
        hotKeyID.id=2;
        RegisterEventHotKey(kVK_BrightnessUp, 0, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
        
        hotKeyID.signature='htk3';
        hotKeyID.id=3;
        RegisterEventHotKey(kVK_BrightnessDown, 0, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
        
        hotKeyID.signature='htk4';
        hotKeyID.id=4;
        RegisterEventHotKey(kVK_BrightnessUp, cmdKey+optionKey, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
        
        hotKeyID.signature='htk5';
        hotKeyID.id=5;
        RegisterEventHotKey(kVK_BrightnessDown, cmdKey+optionKey, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
        
        hotKeyID.signature='htk6';
        hotKeyID.id=6;
        RegisterEventHotKey(kVK_ANSI_R, cmdKey+optionKey, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef);
    }
}

- (void)unregisterHotKeys {
    if (hotKeyRef) {
        NSLog(@"Unregister HotKeys");
        UnregisterEventHotKey(hotKeyRef);
        hotKeyRef = 0;
    }
}

OSStatus OnHotKeyEvent(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData)
{
    EventHotKeyID hkCom;
    
    GetEventParameter(theEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hkCom), NULL, &hkCom);
    MainMenuController *app = (__bridge MainMenuController *)userData;
    
    int l = hkCom.id;
    
    switch (l) {
        case 1:
            DebugLog(@"Capture COMMAND + OPTION + T");
            [app toggleTheme:nil];
            break;
        case 2:
            DebugLog(@"Capture BRIGHTNESS_UP");
            if ([controls.screens count] < 1) return 0;
            [controls.screens[0] setBrightnessRelativeToValue:@"5+"];
            break;
        case 3:
            DebugLog(@"Capture BRIGHTNESS_DOWN");
            if ([controls.screens count] < 1) return 0;
            [controls.screens[0] setBrightnessRelativeToValue:@"5-"];
            break;
        case 4:
            DebugLog(@"Capture COMMAND + OPTION + BRIGHTNESS_UP");
            /*
             for(Screen* screen in controls.screens) {
             [[controls screenForDisplayID:screen.screenNumber] setBrightnessRelativeToValue:@"5+"];
             }
             */
            [app setDisplayResolutionHiDpi];
            break;
        case 5:
            DebugLog(@"Capture COMMAND + OPTION + BRIGHTNESS_DOWN");
            /*
             for(Screen* screen in controls.screens) {
             [[controls screenForDisplayID:screen.screenNumber] setBrightnessRelativeToValue:@"5-"];
             }
             */
            [app setDisplayResolution];
            break;
        case 6:
            DebugLog(@"Capture COMMAND + OPTION + R");
            [app toggleDisplayResolution:nil];
            break;
            
    }
    
    return noErr;
}


// SetDisplayResolution
- (IBAction)toggleDisplayResolution:(id)sender {
    float scale = [[NSScreen mainScreen] backingScaleFactor];
    if (scale > 1.0) {
        [self setDisplayResolution];
    } else {
        [self setDisplayResolutionHiDpi];
    }
}

- (void)setDisplayResolution {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"SetDisplayResolution" ofType:nil]];
    [task setArguments:[NSArray arrayWithObjects:@"-w", @"2560", @"-h", @"1440", @"-s", @"1", @"-o", nil]];
    [task setStandardOutput:[NSPipe pipe]];
    [task setStandardInput:[NSPipe pipe]];
    [task launch];
}

- (void)setDisplayResolutionHiDpi {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:[[NSBundle mainBundle] pathForResource:@"SetDisplayResolution" ofType:nil]];
    [task setArguments:[NSArray arrayWithObjects:@"-w", @"1920", @"-h", @"1080", @"-s", @"2", @"-o", nil]];
    [task setStandardOutput:[NSPipe pipe]];
    [task setStandardInput:[NSPipe pipe]];
    [task launch];
}


/*
 * DarkMode inspired by https://github.com/NSRover/NinjaMode
 * Functions to toggle between Light- and Dark-Mode.
 * Optional - place two wallpapers named light.jpg and dark.jpg
 * in ~/Documents/AppModes/ to set them in addition.
 */

- (IBAction)toggleTheme:(id)sender {
    _darkModeOn = !_darkModeOn;
    
    if (_darkModeOn) {
        [self darkTheme];
    }
    else {
        [self lightTheme];
    }
}

- (void)darkTheme {
    // Set the desktop image
    [self desktopImageWithPath:[@"~/Documents/AppModes/dark.jpg" stringByExpandingTildeInPath]];
    
    // Call applescript to set appearance to dark mode
    NSAppleScript* appleScript = [[NSAppleScript alloc] initWithSource:
                                  @"\
                                  tell application \"System Events\"\n\
                                  tell appearance preferences\n\
                                  set dark mode to true\n\
                                  end tell\n\
                                  end tell"];
    [appleScript executeAndReturnError:nil];
    
    // To be sure
    self.darkModeOn = YES;
}

- (void)lightTheme {
    // Set the desktop image
    [self desktopImageWithPath:[@"~/Documents/AppModes/light.jpg" stringByExpandingTildeInPath]];
    
    // Call applescript to set appearance to light mode
    NSAppleScript* appleScript = [[NSAppleScript alloc] initWithSource:
                                  @"\
                                  tell application \"System Events\"\n\
                                  tell appearance preferences\n\
                                  set dark mode to false\n\
                                  end tell\n\
                                  end tell"];
    [appleScript executeAndReturnError:nil];
    
    // To be sure
    self.darkModeOn = NO;
}


- (void)desktopImageWithPath:(NSString *)path {
    // If the file does not exist, we assume there is no interest and nothing to do
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {

        NSError *error;
        [[NSWorkspace sharedWorkspace] setDesktopImageURL:[NSURL fileURLWithPath:path]
                                                forScreen:[NSScreen mainScreen]
                                                  options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSNumber numberWithBool:NO], NSWorkspaceDesktopImageAllowClippingKey,
                                                           [NSNumber numberWithInteger:NSImageScaleProportionallyUpOrDown], NSWorkspaceDesktopImageScalingKey,
                                                           /* [NSColor blackColor], NSWorkspaceDesktopImageFillColorKey, */
                                                           nil]
                                                    error:&error];
        if (error) {
            [[NSApplication sharedApplication] presentError: error
                                             modalForWindow: [[NSApplication sharedApplication] keyWindow]
                                                   delegate: nil
                                         didPresentSelector: nil
                                                contextInfo: NULL];
        }
    }
}

@end
