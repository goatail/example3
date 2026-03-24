//
//  ViewController.h
//  example3
//
//  Created by wetest on 2026/3/24.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

/// 供登录页、个人中心等切换根子控制器（不依赖 iOS 13+ API）
- (void)showAuth;
- (void)showMain;

@end

