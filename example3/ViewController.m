//
//  ViewController.m
//  example3
//

#import "ViewController.h"
#import "ESStore.h"
#import "ESAppControllers.h"
#import "ESCompatibility.h"

@interface ViewController ()
@property (nonatomic, assign) BOOL mounted;
@property (nonatomic, strong, nullable) UIViewController *currentChild;
- (void)mountChild:(UIViewController *)vc;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ESBackgroundColor();
    [[ESStore shared] bootstrap];
}

/// 应用内闪屏：与 example 的 SplashView 一致（Logo + 标题 + 淡入），全程兼容 iOS 11
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.mounted) {
        return;
    }
    self.mounted = YES;

    UIImage *logoImage = [UIImage imageNamed:@"splash_logo"];
    UIImageView *logoView = [[UIImageView alloc] initWithImage:logoImage];
    logoView.contentMode = UIViewContentModeScaleAspectFit;
    logoView.translatesAutoresizingMaskIntoConstraints = NO;
    logoView.alpha = 0;
    if (!logoImage) {
        logoView.hidden = YES;
    }

    UILabel *titleLabel = [UILabel new];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"MyShopping";
    titleLabel.font = [UIFont boldSystemFontOfSize:28];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.alpha = 0;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[ logoView, titleLabel ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 20;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-40],
        [logoView.widthAnchor constraintEqualToConstant:120],
        [logoView.heightAnchor constraintEqualToConstant:120]
    ]];

    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         titleLabel.alpha = 1;
                         if (!logoView.hidden) {
                             logoView.alpha = 1;
                         }
                     }
                     completion:nil];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [stack removeFromSuperview];
        [ESStore.shared isLoggedIn] ? [self showMain] : [self showAuth];
    });
}

- (void)mountChild:(UIViewController *)vc {
    [self.currentChild willMoveToParentViewController:nil];
    [self.currentChild.view removeFromSuperview];
    [self.currentChild removeFromParentViewController];
    self.currentChild = vc;
    [self addChildViewController:vc];
    vc.view.frame = self.view.bounds;
    vc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:vc.view];
    [vc didMoveToParentViewController:self];
}

- (void)showAuth {
    ESLoginViewController *l = [ESLoginViewController new];
    l.root = self;
    [self mountChild:[[UINavigationController alloc] initWithRootViewController:l]];
}

- (void)showMain {
    ESRootTabBarController *tab = [ESRootTabBarController new];
    tab.root = self;
    [self mountChild:tab];
}

@end
