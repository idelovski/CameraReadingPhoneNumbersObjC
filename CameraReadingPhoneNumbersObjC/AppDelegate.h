/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Application delegate
*/

#import <UIKit/UIKit.h>

#ifdef _NIJE_
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
}
#endif

@interface AppDelegate: UIResponder <UIApplicationDelegate>

@property (strong, nonatomic)  UIWindow  *window;

@end
