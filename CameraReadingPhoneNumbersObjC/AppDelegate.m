/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Application delegate
*/

#ifdef _NIJE_
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
}
#endif

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
   // What about makeKeyAndVisible and all that jazz?
#ifdef _NIJE_
   // Configure audio session for playback and record

   AVAudioSession  *session = [AVAudioSession sharedInstance];
   [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
   [session setActive:YES error:nil];
#endif
   
   return (YES);
}

- (void)applicationWillResignActive:(UIApplication *)application {
   
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
   
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
   
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
   
}

- (void)applicationWillTerminate:(UIApplication *)application {
   
}

@end
