//
//  ESAppControllers.m
//  example3
//

#import "ESAppControllers.h"
#import "ViewController.h"
#import "ESStore.h"
#import "ESCompatibility.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - 登录/注册界面主题（与 example AppColors.primary #599e5e、LoginView 布局一致，兼容 iOS 11）

/// 主题主色，与 SwiftUI `AppColors.primary` 一致
static UIColor *ESAuthPrimaryColor(void) {
    return [UIColor colorWithRed:89.0 / 255.0 green:158.0 / 255.0 blue:94.0 / 255.0 alpha:1.0];
}

/// 次要说明文字色（接近 Label secondary）
static UIColor *ESAuthSecondaryLabelColor(void) {
    return [UIColor colorWithWhite:0.45 alpha:1.0];
}

/// 统一输入框外观（与 ESAuthLabeledFieldRow 内 UITextField 一致）
static void ESAuthApplyFieldChrome(UITextField *tf) {
    tf.borderStyle = UITextBorderStyleNone;
    tf.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
    tf.layer.cornerRadius = 10;
    tf.layer.masksToBounds = YES;
    tf.layer.borderWidth = 1;
    tf.layer.borderColor = [UIColor colorWithWhite:0.5 alpha:0.3].CGColor;
    UIView *leftPad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 36)];
    tf.leftView = leftPad;
    tf.leftViewMode = UITextFieldViewModeAlways;
    UIView *rightPad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 36)];
    tf.rightView = rightPad;
    tf.rightViewMode = UITextFieldViewModeAlways;
}

/// 在宿主视图底部插入渐变层（白底上半透明主色，与 LinearGradient 效果一致）
static CAGradientLayer *ESAuthAttachGradient(UIView *host) {
    CAGradientLayer *g = [CAGradientLayer layer];
    UIColor *p = ESAuthPrimaryColor();
    g.colors = @[
        (id)[p colorWithAlphaComponent:0.35].CGColor,
        (id)[p colorWithAlphaComponent:0.05].CGColor
    ];
    g.startPoint = CGPointMake(0, 0);
    g.endPoint = CGPointMake(1, 1);
    g.frame = host.bounds;
    [host.layer insertSublayer:g atIndex:0];
    return g;
}

/// 带标题的输入行：白底圆角描边，风格对齐 SwiftUI 登录卡片内 TextField
static UIView *ESAuthLabeledFieldRow(NSString *title, NSString *placeholder, BOOL secure, UITextField *__strong *outField) {
    UILabel *lab = [UILabel new];
    lab.translatesAutoresizingMaskIntoConstraints = NO;
    lab.text = title;
    lab.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    lab.textColor = ESAuthSecondaryLabelColor();

    UITextField *tf = [UITextField new];
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    tf.placeholder = placeholder;
    tf.secureTextEntry = secure;
    tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
    ESAuthApplyFieldChrome(tf);

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[ lab, tf ]];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 8;
    stack.alignment = UIStackViewAlignmentFill;

    [NSLayoutConstraint activateConstraints:@[
        [tf.heightAnchor constraintEqualToConstant:44]
    ]];

    if (outField) {
        *outField = tf;
    }
    return stack;
}

/// 电话/数字键盘无 Return 键：顶部工具条「完成」收起键盘
static void ESAuthAttachKeyboardDoneAccessory(UITextField *tf) {
    UIToolbar *bar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(UIScreen.mainScreen.bounds), 44)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:tf action:@selector(resignFirstResponder)];
    bar.items = @[ flex, done ];
    tf.inputAccessoryView = bar;
}

/// 同上，增加「下一步」跳到下一项（用于手机号 → 用户名）
static void ESAuthAttachKeyboardNextDoneAccessory(UITextField *tf, id target, SEL nextAction) {
    UIToolbar *bar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(UIScreen.mainScreen.bounds), 44)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *next = [[UIBarButtonItem alloc] initWithTitle:@"下一步" style:UIBarButtonItemStylePlain target:target action:nextAction];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:tf action:@selector(resignFirstResponder)];
    bar.items = @[ flex, next, done ];
    tf.inputAccessoryView = bar;
}

/// 主色实心圆角按钮（对齐 borderedProminent + tint primary）
static UIButton *ESAuthPrimaryButton(NSString *title) {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    btn.backgroundColor = ESAuthPrimaryColor();
    btn.layer.cornerRadius = 10;
    btn.layer.masksToBounds = YES;
    return btn;
}

@interface ESHomeViewController ()
@property (nonatomic, strong) UISegmentedControl *seg;
@property (nonatomic, strong) UIView *searchEntryBar;
@property (nonatomic, strong) UILabel *searchEntryLabel;
@property (nonatomic, copy) NSString *activeSearchKeyword;
@property (nonatomic, strong) UIScrollView *pageScroll;
@property (nonatomic, copy) NSArray<NSString *> *categories;
@property (nonatomic, strong) NSArray<UICollectionView *> *categoryCollections;
@property (nonatomic, assign) CGFloat lastPageScrollWidth;
@end

@interface ESFavoriteViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<ESProduct *> *list;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIStackView *emptyStack;
@end

@interface ESCartViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, copy) NSArray<ESProduct *> *list;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UILabel *totalLabel;
@property (nonatomic, strong) UIButton *checkoutButton;
@property (nonatomic, strong) UIStackView *emptyStack;
@property (nonatomic, strong) UIRefreshControl *cartRefresh;
@end

@interface ESCheckoutViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong, nullable) ESAddress *selected;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *bottomBar;
@property (nonatomic, strong) UIButton *submitOrderButton;
@end

void ESAlert(UIViewController *vc, NSString *msg) {
    UIAlertController *a = [UIAlertController alertControllerWithTitle:@"提示" message:msg preferredStyle:UIAlertControllerStyleAlert];
    [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    [vc presentViewController:a animated:YES completion:nil];
}

#pragma mark - Auth

@interface ESRegisterViewController () <UITextFieldDelegate>
@end

@interface ESLoginViewController () <UITextFieldDelegate>
@end

@implementation ESRegisterViewController {
    UITextField *_phone;
    UITextField *_user;
    UITextField *_pass;
    UITextField *_confirm;
    UITextField *_verifyInput;
    UILabel *_verifyHintLabel;
    NSString *_sentVerifyCode;
    UIScrollView *_scroll;
    CAGradientLayer *_gradient;
}

/// 随机生成 4 位数字字符串，各位之和为 20（与 Swift `RegisterView.generateVerifyCode` 一致）
- (void)generateVerifyCode {
    NSMutableArray<NSNumber *> *digits = [NSMutableArray arrayWithCapacity:4];
    NSInteger remaining = 20;
    for (NSInteger i = 0; i < 4; i++) {
        if (i == 3) {
            if (remaining > 9) {
                [self generateVerifyCode];
                return;
            }
            [digits addObject:@(remaining)];
        } else {
            NSInteger maxForThis = MIN(9, remaining);
            NSInteger value = (NSInteger)arc4random_uniform((uint32_t)maxForThis + 1);
            [digits addObject:@(value)];
            remaining -= value;
        }
    }
    NSMutableString *s = [NSMutableString stringWithCapacity:4];
    for (NSNumber *n in digits) {
        [s appendFormat:@"%@", n];
    }
    _sentVerifyCode = [s copy];
    _verifyInput.text = @"";
    [self refreshVerifyHint];
}

- (void)refreshVerifyHint {
    if (_sentVerifyCode.length == 0) {
        _verifyHintLabel.hidden = YES;
        _verifyHintLabel.text = @"";
        return;
    }
    _verifyHintLabel.hidden = NO;
    _verifyHintLabel.text = [NSString stringWithFormat:@"当前验证码：%@（模拟短信，仅用于测试）", _sentVerifyCode];
}

- (void)onSendVerify {
    [self generateVerifyCode];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"创建新账号";
    self.view.backgroundColor = UIColor.whiteColor;

    _gradient = ESAuthAttachGradient(self.view);

    _scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _scroll.translatesAutoresizingMaskIntoConstraints = NO;
    _scroll.showsVerticalScrollIndicator = NO;
    _scroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    [self.view addSubview:_scroll];

    UIView *content = [UIView new];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [_scroll addSubview:content];

    UILabel *headTitle = [UILabel new];
    headTitle.translatesAutoresizingMaskIntoConstraints = NO;
    headTitle.text = @"创建新账号";
    headTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    headTitle.adjustsFontForContentSizeCategory = YES;

    UILabel *headSub = [UILabel new];
    headSub.translatesAutoresizingMaskIntoConstraints = NO;
    headSub.text = @"填写手机号、账号信息完成注册";
    headSub.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    headSub.textColor = ESAuthSecondaryLabelColor();
    headSub.numberOfLines = 0;

    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[ headTitle, headSub ]];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    header.axis = UILayoutConstraintAxisVertical;
    header.spacing = 8;
    header.alignment = UIStackViewAlignmentCenter;

    UIView *rowPhone = ESAuthLabeledFieldRow(@"手机号", @"请输入手机号", NO, &_phone);
    _phone.keyboardType = UIKeyboardTypePhonePad;
    UIView *rowUser = ESAuthLabeledFieldRow(@"用户名", @"请输入用户名", NO, &_user);
    UIView *rowPass = ESAuthLabeledFieldRow(@"密码", @"请输入密码", YES, &_pass);
    UIView *rowConfirm = ESAuthLabeledFieldRow(@"确认密码", @"请再次输入密码", YES, &_confirm);

    UILabel *smsTitle = [UILabel new];
    smsTitle.translatesAutoresizingMaskIntoConstraints = NO;
    smsTitle.text = @"短信验证码";
    smsTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    smsTitle.textColor = ESAuthSecondaryLabelColor();
    UIView *smsSpacer = [UIView new];
    smsSpacer.translatesAutoresizingMaskIntoConstraints = NO;
    [smsSpacer setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    UIButton *sendCode = [UIButton buttonWithType:UIButtonTypeSystem];
    sendCode.translatesAutoresizingMaskIntoConstraints = NO;
    [sendCode setTitle:@"发送验证码" forState:UIControlStateNormal];
    sendCode.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    [sendCode setTitleColor:ESAuthPrimaryColor() forState:UIControlStateNormal];
    [sendCode addTarget:self action:@selector(onSendVerify) forControlEvents:UIControlEventTouchUpInside];
    UIStackView *smsHeader = [[UIStackView alloc] initWithArrangedSubviews:@[ smsTitle, smsSpacer, sendCode ]];
    smsHeader.translatesAutoresizingMaskIntoConstraints = NO;
    smsHeader.axis = UILayoutConstraintAxisHorizontal;
    smsHeader.alignment = UIStackViewAlignmentCenter;

    _verifyHintLabel = [UILabel new];
    _verifyHintLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _verifyHintLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    _verifyHintLabel.textColor = ESAuthSecondaryLabelColor();
    _verifyHintLabel.numberOfLines = 0;
    _verifyHintLabel.hidden = YES;

    _verifyInput = [UITextField new];
    _verifyInput.translatesAutoresizingMaskIntoConstraints = NO;
    _verifyInput.placeholder = @"请输入 4 位验证码";
    _verifyInput.keyboardType = UIKeyboardTypeNumberPad;
    _verifyInput.autocapitalizationType = UITextAutocapitalizationTypeNone;
    ESAuthApplyFieldChrome(_verifyInput);

    UIStackView *verifyCol = [[UIStackView alloc] initWithArrangedSubviews:@[ smsHeader, _verifyHintLabel, _verifyInput ]];
    verifyCol.translatesAutoresizingMaskIntoConstraints = NO;
    verifyCol.axis = UILayoutConstraintAxisVertical;
    verifyCol.spacing = 8;
    verifyCol.alignment = UIStackViewAlignmentFill;
    [NSLayoutConstraint activateConstraints:@[
        [_verifyInput.heightAnchor constraintEqualToConstant:44]
    ]];

    UIButton *submit = ESAuthPrimaryButton(@"注册");
    [submit addTarget:self action:@selector(onSubmit) forControlEvents:UIControlEventTouchUpInside];

    UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
    back.translatesAutoresizingMaskIntoConstraints = NO;
    [back setTitle:@"返回登录" forState:UIControlStateNormal];
    [back setTitleColor:ESAuthPrimaryColor() forState:UIControlStateNormal];
    back.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [back addTarget:self action:@selector(onBack) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *cardStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        rowPhone, rowUser, rowPass, rowConfirm, verifyCol, submit, back
    ]];
    cardStack.translatesAutoresizingMaskIntoConstraints = NO;
    cardStack.axis = UILayoutConstraintAxisVertical;
    cardStack.spacing = 20;
    cardStack.alignment = UIStackViewAlignmentFill;
    [cardStack setCustomSpacing:8 afterView:rowConfirm];
    [cardStack setCustomSpacing:8 afterView:verifyCol];

    UIView *card = [UIView new];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor colorWithWhite:1 alpha:0.92];
    card.layer.cornerRadius = 20;
    card.layer.masksToBounds = NO;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.06;
    card.layer.shadowOffset = CGSizeMake(0, 6);
    card.layer.shadowRadius = 12;
    [card addSubview:cardStack];
    [NSLayoutConstraint activateConstraints:@[
        [cardStack.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
        [cardStack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [cardStack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [cardStack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20]
    ]];

    UIStackView *mainCol = [[UIStackView alloc] initWithArrangedSubviews:@[ header, card ]];
    mainCol.translatesAutoresizingMaskIntoConstraints = NO;
    mainCol.axis = UILayoutConstraintAxisVertical;
    mainCol.spacing = 32;
    mainCol.alignment = UIStackViewAlignmentFill;
    [content addSubview:mainCol];

    UILayoutGuide *g = _scroll.frameLayoutGuide;
    UILayoutGuide *cg = _scroll.contentLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        [_scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [content.topAnchor constraintEqualToAnchor:cg.topAnchor],
        [content.leadingAnchor constraintEqualToAnchor:cg.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:cg.trailingAnchor],
        [content.bottomAnchor constraintEqualToAnchor:cg.bottomAnchor],
        [content.widthAnchor constraintEqualToAnchor:g.widthAnchor],

        [mainCol.topAnchor constraintEqualToAnchor:content.topAnchor constant:24],
        [mainCol.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:24],
        [mainCol.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-24],
        [mainCol.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-32],
        [mainCol.heightAnchor constraintGreaterThanOrEqualToAnchor:g.heightAnchor multiplier:0.88]
    ]];

    _phone.delegate = self;
    _user.delegate = self;
    _pass.delegate = self;
    _confirm.delegate = self;
    _verifyInput.delegate = self;
    _user.returnKeyType = UIReturnKeyNext;
    _pass.returnKeyType = UIReturnKeyNext;
    _confirm.returnKeyType = UIReturnKeyNext;
    _verifyInput.returnKeyType = UIReturnKeyDone;
    _user.enablesReturnKeyAutomatically = YES;
    _pass.enablesReturnKeyAutomatically = YES;
    _confirm.enablesReturnKeyAutomatically = YES;
    ESAuthAttachKeyboardNextDoneAccessory(_phone, self, @selector(es_authPhoneToolbarNext:));
    ESAuthAttachKeyboardDoneAccessory(_verifyInput);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _gradient.frame = self.view.bounds;
}

- (void)es_authPhoneToolbarNext:(id)sender {
    (void)sender;
    [_user becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _user) {
        [_pass becomeFirstResponder];
        return NO;
    }
    if (textField == _pass) {
        [_confirm becomeFirstResponder];
        return NO;
    }
    if (textField == _confirm) {
        [_verifyInput becomeFirstResponder];
        return NO;
    }
    if (textField == _verifyInput) {
        [textField resignFirstResponder];
        return NO;
    }
    if (textField == _phone) {
        [_user becomeFirstResponder];
        return NO;
    }
    return YES;
}

- (void)onBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onSubmit {
    if (_phone.text.length == 0 || _user.text.length == 0 || _pass.text.length == 0 || _confirm.text.length == 0) {
        ESAlert(self, @"请填写完整信息");
        return;
    }
    if (![_pass.text isEqualToString:_confirm.text]) {
        ESAlert(self, @"两次输入的密码不一致");
        return;
    }
    if (_sentVerifyCode.length == 0 || _verifyInput.text.length == 0) {
        ESAlert(self, @"请先发送并填写验证码");
        return;
    }
    NSMutableArray<NSNumber *> *inputDigits = [NSMutableArray array];
    for (NSUInteger i = 0; i < _verifyInput.text.length; i++) {
        unichar c = [_verifyInput.text characterAtIndex:i];
        if (c >= '0' && c <= '9') {
            [inputDigits addObject:@(c - '0')];
        }
    }
    if (inputDigits.count != 4) {
        ESAlert(self, @"验证码错误，请重新获取");
        [self generateVerifyCode];
        return;
    }
    NSInteger sum = 0;
    for (NSNumber *n in inputDigits) {
        sum += n.integerValue;
    }
    if (sum != 20) {
        ESAlert(self, @"验证码错误，请重新获取");
        [self generateVerifyCode];
        return;
    }

    NSString *msg = nil;
    if ([[ESStore shared] registerUser:_user.text phone:_phone.text pass:_pass.text message:&msg]) {
        UIAlertController *a = [UIAlertController alertControllerWithTitle:@"提示" message:@"注册成功，请登录" preferredStyle:UIAlertControllerStyleAlert];
        __weak typeof(self) ws = self;
        [a addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            __strong typeof(ws) s = ws;
            [s.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:a animated:YES completion:nil];
    } else {
        ESAlert(self, msg ?: @"注册失败");
    }
}

@end

@implementation ESLoginViewController {
    UITextField *_user;
    UITextField *_pass;
    UIScrollView *_scroll;
    CAGradientLayer *_gradient;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;

    _gradient = ESAuthAttachGradient(self.view);

    _scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _scroll.translatesAutoresizingMaskIntoConstraints = NO;
    _scroll.showsVerticalScrollIndicator = NO;
    _scroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    [self.view addSubview:_scroll];

    UIView *content = [UIView new];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [_scroll addSubview:content];

    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"splash_logo"]];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.layer.cornerRadius = 24;
    logo.layer.masksToBounds = YES;
    UIView *logoWrap = [UIView new];
    logoWrap.translatesAutoresizingMaskIntoConstraints = NO;
    logoWrap.layer.shadowColor = [UIColor blackColor].CGColor;
    logoWrap.layer.shadowOpacity = 0.08;
    logoWrap.layer.shadowOffset = CGSizeMake(0, 4);
    logoWrap.layer.shadowRadius = 10;
    [logoWrap addSubview:logo];
    if (!logo.image) {
        logoWrap.hidden = YES;
    }

    UILabel *welcome = [UILabel new];
    welcome.translatesAutoresizingMaskIntoConstraints = NO;
    welcome.text = @"欢迎来到 MyShopping";
    welcome.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    welcome.adjustsFontForContentSizeCategory = YES;
    welcome.textAlignment = NSTextAlignmentCenter;

    UILabel *tagline = [UILabel new];
    tagline.translatesAutoresizingMaskIntoConstraints = NO;
    tagline.text = @"随时随地，轻松购物";
    tagline.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    tagline.textColor = ESAuthSecondaryLabelColor();
    tagline.textAlignment = NSTextAlignmentCenter;

    UIStackView *topBlock = [[UIStackView alloc] initWithArrangedSubviews:@[ logoWrap, welcome, tagline ]];
    topBlock.translatesAutoresizingMaskIntoConstraints = NO;
    topBlock.axis = UILayoutConstraintAxisVertical;
    topBlock.spacing = 12;
    topBlock.alignment = UIStackViewAlignmentCenter;

    UIView *rowUser = ESAuthLabeledFieldRow(@"用户名", @"请输入用户名（可用 admin）", NO, &_user);
    UIView *rowPass = ESAuthLabeledFieldRow(@"密码", @"请输入密码（可用 admin）", YES, &_pass);

    UIButton *loginBtn = ESAuthPrimaryButton(@"登录");
    [loginBtn addTarget:self action:@selector(onLogin) forControlEvents:UIControlEventTouchUpInside];

    UILabel *hint = [UILabel new];
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    hint.text = @"还没有账号？";
    hint.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    hint.textColor = ESAuthSecondaryLabelColor();

    UIButton *regBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    regBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [regBtn setTitle:@"去注册" forState:UIControlStateNormal];
    regBtn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [regBtn setTitleColor:ESAuthPrimaryColor() forState:UIControlStateNormal];
    [regBtn addTarget:self action:@selector(onReg) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *footer = [[UIStackView alloc] initWithArrangedSubviews:@[ hint, regBtn ]];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    footer.axis = UILayoutConstraintAxisHorizontal;
    footer.spacing = 4;
    footer.alignment = UIStackViewAlignmentCenter;

    UIStackView *cardStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        rowUser, rowPass, loginBtn, footer
    ]];
    cardStack.translatesAutoresizingMaskIntoConstraints = NO;
    cardStack.axis = UILayoutConstraintAxisVertical;
    cardStack.spacing = 20;
    cardStack.alignment = UIStackViewAlignmentFill;
    [cardStack setCustomSpacing:8 afterView:rowPass];

    UIView *card = [UIView new];
    card.translatesAutoresizingMaskIntoConstraints = NO;
    card.backgroundColor = [UIColor colorWithWhite:1 alpha:0.92];
    card.layer.cornerRadius = 20;
    card.layer.masksToBounds = NO;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.06;
    card.layer.shadowRadius = 12;
    card.layer.shadowOffset = CGSizeMake(0, 6);
    [card addSubview:cardStack];
    [NSLayoutConstraint activateConstraints:@[
        [cardStack.topAnchor constraintEqualToAnchor:card.topAnchor constant:20],
        [cardStack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:20],
        [cardStack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-20],
        [cardStack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-20]
    ]];

    UIStackView *mainCol = [[UIStackView alloc] initWithArrangedSubviews:@[ topBlock, card ]];
    mainCol.translatesAutoresizingMaskIntoConstraints = NO;
    mainCol.axis = UILayoutConstraintAxisVertical;
    mainCol.spacing = 32;
    mainCol.alignment = UIStackViewAlignmentFill;
    [content addSubview:mainCol];

    UILayoutGuide *g = _scroll.frameLayoutGuide;
    UILayoutGuide *cg = _scroll.contentLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        [logo.topAnchor constraintEqualToAnchor:logoWrap.topAnchor],
        [logo.leadingAnchor constraintEqualToAnchor:logoWrap.leadingAnchor],
        [logo.trailingAnchor constraintEqualToAnchor:logoWrap.trailingAnchor],
        [logo.bottomAnchor constraintEqualToAnchor:logoWrap.bottomAnchor],
        [logo.widthAnchor constraintEqualToConstant:96],
        [logo.heightAnchor constraintEqualToConstant:96],

        [_scroll.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [content.topAnchor constraintEqualToAnchor:cg.topAnchor],
        [content.leadingAnchor constraintEqualToAnchor:cg.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:cg.trailingAnchor],
        [content.bottomAnchor constraintEqualToAnchor:cg.bottomAnchor],
        [content.widthAnchor constraintEqualToAnchor:g.widthAnchor],

        [mainCol.topAnchor constraintEqualToAnchor:content.topAnchor constant:48],
        [mainCol.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:24],
        [mainCol.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-24],
        [mainCol.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-32],
        [mainCol.heightAnchor constraintGreaterThanOrEqualToAnchor:g.heightAnchor multiplier:0.9]
    ]];

    _user.delegate = self;
    _pass.delegate = self;
    _user.returnKeyType = UIReturnKeyNext;
    _pass.returnKeyType = UIReturnKeyDone;
    _user.enablesReturnKeyAutomatically = YES;
    _pass.enablesReturnKeyAutomatically = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _gradient.frame = self.view.bounds;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _user) {
        [_pass becomeFirstResponder];
        return NO;
    }
    if (textField == _pass) {
        [textField resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)onLogin {
    if (_user.text.length == 0) {
        ESAlert(self, @"请输入用户名");
        return;
    }
    if (_pass.text.length == 0) {
        ESAlert(self, @"请输入密码");
        return;
    }
    NSString *msg = nil;
    if ([[ESStore shared] login:_user.text pass:_pass.text message:&msg]) {
        [self.root showMain];
    } else {
        ESAlert(self, msg ?: @"登录失败");
    }
}

- (void)onReg {
    [self.navigationController pushViewController:[ESRegisterViewController new] animated:YES];
}

@end

#pragma mark - Detail / Address / Order

/// 半屏/全屏弹窗打开商品详情（对齐 example `HomeView` / `FavoriteView` sheet，iOS 11+）
static void ESPresentProductDetailSheet(UIViewController *host, ESProduct *product) {
    ESProductDetailViewController *d = [[ESProductDetailViewController alloc] initWithProduct:product];
    __weak UIViewController *wHost = host;
    d.onGoToCartTab = ^{
        __strong UIViewController *h = wHost;
        if (!h) {
            return;
        }
        h.tabBarController.selectedIndex = 2;
    };
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:d];
    if (@available(iOS 13.0, *)) {
        nav.modalPresentationStyle = UIModalPresentationPageSheet;
    } else {
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    UIViewController *presenter = host.navigationController ?: host;
    [presenter presentViewController:nav animated:YES completion:nil];
}

@implementation ESProductDetailViewController {
    ESProduct *_product;
    UIImageView *_image;
    UILabel *_titleLb;
    UILabel *_descLb;
    UILabel *_priceLb;
    UILabel *_statsLb;
    UIStepper *_step;
    UILabel *_qtyLb;
}

- (instancetype)initWithProduct:(ESProduct *)product {
    if (self = [super init]) {
        _product = product;
    }
    return self;
}

/// 是否由首页以 present 方式套在导航栈中展示（与 push 的收藏入口区分）
- (BOOL)es_isPresentedDetailNav {
    return self.navigationController.presentingViewController != nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = (_product.shortName.length > 0) ? _product.shortName : (_product.title.length ? _product.title : @"商品详情");
    self.view.backgroundColor = ESBackgroundColor();

    if ([self es_isPresentedDetailNav]) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(es_closeModal)];
    }
    [self es_updateFavoriteBarButton];

    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.layoutMargins = UIEdgeInsetsMake(16, 16, 24, 16);
    stack.layoutMarginsRelativeArrangement = YES;

    _image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:_product.imageAssetName]];
    _image.translatesAutoresizingMaskIntoConstraints = NO;
    _image.contentMode = UIViewContentModeScaleAspectFill;
    _image.clipsToBounds = YES;
    _image.layer.cornerRadius = 12;
    _image.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    [_image.heightAnchor constraintEqualToConstant:280].active = YES;

    _titleLb = [UILabel new];
    _titleLb.text = _product.title;
    _titleLb.font = [UIFont boldSystemFontOfSize:22];
    _titleLb.numberOfLines = 0;

    _descLb = [UILabel new];
    _descLb.text = (_product.detailText.length > 0) ? _product.detailText : @"暂无详细说明。";
    _descLb.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _descLb.numberOfLines = 0;
    if (@available(iOS 13.0, *)) {
        _descLb.textColor = UIColor.secondaryLabelColor;
    } else {
        _descLb.textColor = [UIColor grayColor];
    }

    _priceLb = [UILabel new];
    _priceLb.text = [NSString stringWithFormat:@"¥ %.2f", _product.price];
    _priceLb.font = [UIFont boldSystemFontOfSize:28];
    _priceLb.textColor = ESPriceColor();

    NSString *stats = @"";
    if (_product.viewsCountText.length > 0 && _product.payCountText.length > 0) {
        stats = [NSString stringWithFormat:@"%@ · %@人付款", _product.viewsCountText, _product.payCountText];
    } else if (_product.payCountText.length > 0) {
        stats = [NSString stringWithFormat:@"%@人付款", _product.payCountText];
    } else {
        stats = _product.viewsCountText;
    }
    _statsLb = [UILabel new];
    _statsLb.text = stats;
    _statsLb.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    if (@available(iOS 13.0, *)) {
        _statsLb.textColor = UIColor.secondaryLabelColor;
    } else {
        _statsLb.textColor = [UIColor darkGrayColor];
    }

    UILabel *qtyTitle = [UILabel new];
    qtyTitle.text = @"数量";
    _qtyLb = [UILabel new];
    _qtyLb.text = @"1";
    _qtyLb.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _step = [UIStepper new];
    _step.translatesAutoresizingMaskIntoConstraints = NO;
    _step.minimumValue = 1;
    _step.maximumValue = 99;
    _step.value = 1;
    [_step addTarget:self action:@selector(es_onStepperChanged:) forControlEvents:UIControlEventValueChanged];

    UIStackView *qtyRow = [[UIStackView alloc] initWithArrangedSubviews:@[ qtyTitle, _step, _qtyLb ]];
    qtyRow.axis = UILayoutConstraintAxisHorizontal;
    qtyRow.spacing = 12;
    qtyRow.alignment = UIStackViewAlignmentCenter;

    [stack addArrangedSubview:_image];
    [stack addArrangedSubview:_titleLb];
    [stack addArrangedSubview:_descLb];
    [stack addArrangedSubview:_priceLb];
    [stack addArrangedSubview:_statsLb];
    [stack addArrangedSubview:qtyRow];

    UIView *bottomBar = [UIView new];
    bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        bottomBar.backgroundColor = UIColor.systemBackgroundColor;
    } else {
        bottomBar.backgroundColor = UIColor.whiteColor;
    }

    UIButton *add = [UIButton buttonWithType:UIButtonTypeSystem];
    add.translatesAutoresizingMaskIntoConstraints = NO;
    [add setTitle:@"加入购物车" forState:UIControlStateNormal];
    [add setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    add.backgroundColor = ESAuthPrimaryColor();
    add.layer.cornerRadius = 12;
    add.layer.masksToBounds = YES;
    [add addTarget:self action:@selector(onAdd) forControlEvents:UIControlEventTouchUpInside];
    [bottomBar addSubview:add];

    [scroll addSubview:stack];
    [self.view addSubview:scroll];
    [self.view addSubview:bottomBar];

    UILayoutGuide *contentG = scroll.contentLayoutGuide;
    UILayoutGuide *frameG = scroll.frameLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:contentG.topAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:frameG.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:frameG.trailingAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:contentG.bottomAnchor],
        [stack.widthAnchor constraintEqualToAnchor:frameG.widthAnchor],

        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:bottomBar.topAnchor],

        [bottomBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [bottomBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [bottomBar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [add.topAnchor constraintEqualToAnchor:bottomBar.safeAreaLayoutGuide.topAnchor constant:12],
        [add.leadingAnchor constraintEqualToAnchor:bottomBar.leadingAnchor constant:16],
        [add.trailingAnchor constraintEqualToAnchor:bottomBar.trailingAnchor constant:-16],
        [add.bottomAnchor constraintEqualToAnchor:bottomBar.safeAreaLayoutGuide.bottomAnchor constant:-12],
        [add.heightAnchor constraintEqualToConstant:48]
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self es_updateFavoriteBarButton];
}

- (void)es_onStepperChanged:(UIStepper *)s {
    _qtyLb.text = [NSString stringWithFormat:@"%.0f", s.value];
}

- (NSInteger)es_selectedQuantity {
    return (NSInteger)llround(_step.value);
}

- (void)es_updateFavoriteBarButton {
    BOOL fav = [[ESStore shared] isFavorite:_product.pid];
    UIImage *img = ESSystemImage(fav ? @"heart.fill" : @"heart");
    if (img) {
        img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:img style:UIBarButtonItemStylePlain target:self action:@selector(onFav)];
        self.navigationItem.rightBarButtonItem.tintColor = fav ? [UIColor redColor] : [UIColor colorWithWhite:0.55 alpha:1.0];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:(fav ? @"已收藏" : @"收藏") style:UIBarButtonItemStylePlain target:self action:@selector(onFav)];
        [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSForegroundColorAttributeName : (fav ? [UIColor redColor] : [UIColor darkGrayColor])} forState:UIControlStateNormal];
    }
}

- (void)es_closeModal {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)es_dismissAfterPurchaseFlow {
    if ([self es_isPresentedDetailNav]) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)es_switchToCartTab {
    UITabBarController *tab = self.tabBarController;
    if (tab) {
        tab.selectedIndex = 2;
    } else if (self.onGoToCartTab) {
        self.onGoToCartTab();
    }
}

- (void)onAdd {
    NSInteger n = [self es_selectedQuantity];
    if (n < 1) {
        n = 1;
    }
    [[ESStore shared] addToCart:_product.pid count:n];
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:@"已加入购物车" preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) ws = self;
    [ac addAction:[UIAlertAction actionWithTitle:@"继续逛逛" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *a) {
        __strong typeof(ws) s = ws;
        [s es_dismissAfterPurchaseFlow];
    }]];
    [ac addAction:[UIAlertAction actionWithTitle:@"去结算" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
        __strong typeof(ws) s = ws;
        [s es_switchToCartTab];
        [s es_dismissAfterPurchaseFlow];
    }]];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)onFav {
    [[ESStore shared] toggleFavorite:_product.pid];
    [self es_updateFavoriteBarButton];
}

@end

@implementation ESAddressEditViewController {
    ESAddress *_addr;
    UITextField *_name;
    UITextField *_phone;
    UITextField *_province;
    UITextField *_city;
    UITextField *_district;
    UITextField *_detail;
    UISwitch *_def;
}

- (instancetype)initWithAddress:(ESAddress *)addr {
    if (self = [super init]) {
        _addr = addr ?: [ESAddress new];
        if (!_addr.province) {
            _addr.province = @"";
        }
        if (!_addr.district) {
            _addr.district = @"";
        }
    }
    return self;
}

/// 与 example `AddressEditView` 一致：分组标题 + 收货人 / 地址 / 默认开关
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = _addr.aid.length ? @"编辑地址" : @"新增地址";
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    } else {
        self.view.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
    }
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(es_cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(onSave)];

    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.layoutMargins = UIEdgeInsetsMake(16, 16, 24, 16);
    stack.layoutMarginsRelativeArrangement = YES;

    [stack addArrangedSubview:[self es_sectionLabel:@"收货人"]];
    _name = [self es_tf:@"姓名" text:_addr.name];
    _phone = [self es_tf:@"电话" text:_addr.phone];
    _phone.keyboardType = UIKeyboardTypePhonePad;
    [stack addArrangedSubview:_name];
    [stack addArrangedSubview:_phone];

    [stack addArrangedSubview:[self es_sectionLabel:@"地址"]];
    _province = [self es_tf:@"省份" text:_addr.province];
    _city = [self es_tf:@"城市" text:_addr.city];
    _district = [self es_tf:@"区县" text:_addr.district];
    _detail = [self es_tf:@"详细地址" text:_addr.detail];
    [stack addArrangedSubview:_province];
    [stack addArrangedSubview:_city];
    [stack addArrangedSubview:_district];
    [stack addArrangedSubview:_detail];

    UIStackView *defRow = [[UIStackView alloc] init];
    defRow.axis = UILayoutConstraintAxisHorizontal;
    defRow.alignment = UIStackViewAlignmentCenter;
    defRow.spacing = 12;
    UILabel *dl = [UILabel new];
    dl.text = @"设为默认地址";
    dl.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    _def = [UISwitch new];
    _def.on = _addr.isDefault;
    [defRow addArrangedSubview:dl];
    [defRow addArrangedSubview:_def];
    [stack addArrangedSubview:defRow];

    [scroll addSubview:stack];
    [self.view addSubview:scroll];
    UILayoutGuide *cg = scroll.contentLayoutGuide;
    UILayoutGuide *fg = scroll.frameLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [stack.topAnchor constraintEqualToAnchor:cg.topAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:fg.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:fg.trailingAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:cg.bottomAnchor],
        [stack.widthAnchor constraintEqualToAnchor:fg.widthAnchor],
        [_name.heightAnchor constraintEqualToConstant:44],
        [_phone.heightAnchor constraintEqualToConstant:44],
        [_province.heightAnchor constraintEqualToConstant:44],
        [_city.heightAnchor constraintEqualToConstant:44],
        [_district.heightAnchor constraintEqualToConstant:44],
        [_detail.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (UILabel *)es_sectionLabel:(NSString *)t {
    UILabel *l = [UILabel new];
    l.text = t;
    l.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    if (@available(iOS 13.0, *)) {
        l.textColor = UIColor.secondaryLabelColor;
    } else {
        l.textColor = [UIColor grayColor];
    }
    return l;
}

- (UITextField *)es_tf:(NSString *)p text:(NSString *)t {
    UITextField *x = [UITextField new];
    x.translatesAutoresizingMaskIntoConstraints = NO;
    x.placeholder = p;
    x.text = t;
    x.borderStyle = UITextBorderStyleRoundedRect;
    if (@available(iOS 13.0, *)) {
        x.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    } else {
        x.backgroundColor = UIColor.whiteColor;
    }
    return x;
}

- (void)es_cancel {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onSave {
    _addr.name = _name.text ?: @"";
    _addr.phone = _phone.text ?: @"";
    _addr.province = _province.text ?: @"";
    _addr.city = _city.text ?: @"";
    _addr.district = _district.text ?: @"";
    _addr.detail = _detail.text ?: @"";
    _addr.isDefault = _def.isOn;
    [[ESStore shared] saveAddress:_addr];
    if (self.onSaved) {
        self.onSaved();
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end

#pragma mark - 地址列表 Cell（对齐 example AddressListView：姓名/电话/默认角标、完整地址、设默认）

@interface ESAddressListCell : UITableViewCell
@property (nonatomic, copy, nullable) void (^onSetDefault)(void);
@property (nonatomic, copy, nullable) void (^onDelete)(void);
- (void)configureWithAddress:(ESAddress *)addr selectMode:(BOOL)selectMode;
@end

@implementation ESAddressListCell {
    UILabel *_namePhone;
    UILabel *_badge;
    UILabel *_addr;
    UIButton *_setDef;
    UIButton *_delBtn;
    UIStackView *_actionsRow;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        _namePhone = [UILabel new];
        _namePhone.translatesAutoresizingMaskIntoConstraints = NO;
        _namePhone.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        _namePhone.numberOfLines = 1;

        _badge = [UILabel new];
        _badge.translatesAutoresizingMaskIntoConstraints = NO;
        _badge.text = @"默认";
        _badge.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        _badge.textAlignment = NSTextAlignmentCenter;
        _badge.layer.cornerRadius = 4;
        _badge.layer.masksToBounds = YES;
        if (@available(iOS 13.0, *)) {
            _badge.backgroundColor = [[UIColor systemOrangeColor] colorWithAlphaComponent:0.25];
        } else {
            _badge.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.3];
        }

        _addr = [UILabel new];
        _addr.translatesAutoresizingMaskIntoConstraints = NO;
        _addr.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _addr.numberOfLines = 0;
        if (@available(iOS 13.0, *)) {
            _addr.textColor = UIColor.secondaryLabelColor;
        } else {
            _addr.textColor = [UIColor darkGrayColor];
        }

        _setDef = [UIButton buttonWithType:UIButtonTypeSystem];
        _setDef.translatesAutoresizingMaskIntoConstraints = NO;
        _setDef.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        [_setDef setTitle:@"设为默认" forState:UIControlStateNormal];
        [_setDef addTarget:self action:@selector(es_tapSetDef) forControlEvents:UIControlEventTouchUpInside];
        _setDef.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

        _delBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _delBtn.translatesAutoresizingMaskIntoConstraints = NO;
        [_delBtn setTitle:@"删除" forState:UIControlStateNormal];
        _delBtn.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        if (@available(iOS 13.0, *)) {
            [_delBtn setTitleColor:UIColor.systemRedColor forState:UIControlStateNormal];
        } else {
            [_delBtn setTitleColor:UIColor.redColor forState:UIControlStateNormal];
        }
        [_delBtn addTarget:self action:@selector(es_tapDelete) forControlEvents:UIControlEventTouchUpInside];
        _delBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;

        UIView *flex = [UIView new];
        flex.translatesAutoresizingMaskIntoConstraints = NO;
        [flex setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

        _actionsRow = [[UIStackView alloc] initWithArrangedSubviews:@[ _setDef, flex, _delBtn ]];
        _actionsRow.translatesAutoresizingMaskIntoConstraints = NO;
        _actionsRow.axis = UILayoutConstraintAxisHorizontal;
        _actionsRow.spacing = 8;
        _actionsRow.alignment = UIStackViewAlignmentCenter;
        _actionsRow.distribution = UIStackViewDistributionFill;

        UIStackView *top = [[UIStackView alloc] initWithArrangedSubviews:@[ _namePhone, _badge ]];
        top.translatesAutoresizingMaskIntoConstraints = NO;
        top.axis = UILayoutConstraintAxisHorizontal;
        top.spacing = 8;
        top.alignment = UIStackViewAlignmentCenter;

        UIStackView *v = [[UIStackView alloc] initWithArrangedSubviews:@[ top, _addr, _actionsRow ]];
        v.translatesAutoresizingMaskIntoConstraints = NO;
        v.axis = UILayoutConstraintAxisVertical;
        v.spacing = 6;
        [self.contentView addSubview:v];
        [NSLayoutConstraint activateConstraints:@[
            [v.topAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.topAnchor constant:8],
            [v.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor],
            [v.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor],
            [v.bottomAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.bottomAnchor constant:-8],
            [_badge.widthAnchor constraintGreaterThanOrEqualToConstant:36]
        ]];
    }
    return self;
}

- (void)es_tapSetDef {
    if (self.onSetDefault) {
        self.onSetDefault();
    }
}

- (void)es_tapDelete {
    if (self.onDelete) {
        self.onDelete();
    }
}

- (void)configureWithAddress:(ESAddress *)addr selectMode:(BOOL)selectMode {
    _namePhone.text = [NSString stringWithFormat:@"%@  %@", addr.name ?: @"", addr.phone ?: @""];
    _addr.text = [addr fullAddressString].length ? [addr fullAddressString] : [addr fullText];
    _badge.hidden = !addr.isDefault;
    BOOL hideSetDef = selectMode || addr.isDefault;
    BOOL hideDelete = selectMode || addr.isDefault;
    _setDef.hidden = hideSetDef;
    _delBtn.hidden = hideDelete;
    _actionsRow.hidden = hideSetDef && hideDelete;
    self.accessoryType = selectMode ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
}

@end

@implementation ESAddressListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.onSelect ? @"选择地址" : @"地址管理";
    if (!self.onSelect) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"新增" style:UIBarButtonItemStylePlain target:self action:@selector(onAdd)];
    }
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 16);
    [self.tableView registerClass:[ESAddressListCell class] forCellReuseIdentifier:@"addr"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)onAdd {
    ESAddressEditViewController *v = [[ESAddressEditViewController alloc] initWithAddress:nil];
    __weak typeof(self) ws = self;
    v.onSaved = ^{
        __strong typeof(ws) s = ws;
        [s.tableView reloadData];
    };
    [self.navigationController pushViewController:v animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ESStore.shared.addresses.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ESAddressListCell *c = [tableView dequeueReusableCellWithIdentifier:@"addr" forIndexPath:indexPath];
    ESAddress *a = ESStore.shared.addresses[indexPath.row];
    BOOL selMode = (self.onSelect != nil);
    [c configureWithAddress:a selectMode:selMode];
    __weak typeof(self) ws = self;
    __weak ESAddress *wa = a;
    c.onSetDefault = ^{
        __strong ESAddress *addr = wa;
        if (!addr) {
            return;
        }
        addr.isDefault = YES;
        [[ESStore shared] saveAddress:addr];
        __strong typeof(ws) s = ws;
        [s.tableView reloadData];
    };
    c.onDelete = ^{
        __strong ESAddress *addr = wa;
        if (!addr) {
            return;
        }
        [ESStore.shared deleteAddress:addr];
        __strong typeof(ws) s = ws;
        [s.tableView reloadData];
    };
    return c;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ESAddress *addr = ESStore.shared.addresses[indexPath.row];
    if (self.onSelect) {
        self.onSelect(addr);
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    ESAddressEditViewController *v = [[ESAddressEditViewController alloc] initWithAddress:addr];
    __weak typeof(self) ws = self;
    v.onSaved = ^{
        __strong typeof(ws) s = ws;
        [s.tableView reloadData];
    };
    [self.navigationController pushViewController:v animated:YES];
}

@end

#pragma mark - 订单富文本 Cell（对齐 example OrderListView / MyOrdersView）

@interface ESOrderRichCell : UITableViewCell
/// compactItems：与 example `MyOrdersView` 一致仅「品名 + 小计」；NO 时与 `OrderListView` 一致含数量
- (void)configureWithOrder:(ESOrder *)order showAddressLine:(BOOL)showAddress compactItems:(BOOL)compactItems;
@end

@implementation ESOrderRichCell {
    UIStackView *_stack;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _stack = [[UIStackView alloc] init];
        _stack.translatesAutoresizingMaskIntoConstraints = NO;
        _stack.axis = UILayoutConstraintAxisVertical;
        _stack.spacing = 6;
        [self.contentView addSubview:_stack];
        [NSLayoutConstraint activateConstraints:@[
            [_stack.topAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.topAnchor constant:8],
            [_stack.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor],
            [_stack.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor],
            [_stack.bottomAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.bottomAnchor constant:-8]
        ]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (UIView *v in _stack.arrangedSubviews) {
        [_stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
}

- (UILabel *)es_caption {
    UILabel *l = [UILabel new];
    l.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
    if (@available(iOS 13.0, *)) {
        l.textColor = UIColor.secondaryLabelColor;
    } else {
        l.textColor = [UIColor grayColor];
    }
    return l;
}

- (void)configureWithOrder:(ESOrder *)order showAddressLine:(BOOL)showAddress compactItems:(BOOL)compactItems {
    for (UIView *v in _stack.arrangedSubviews) {
        [_stack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    UILabel *idLb = [self es_caption];
    idLb.text = compactItems ? (order.oid ?: @"") : [NSString stringWithFormat:@"订单号：%@", order.oid ?: @""];
    UILabel *stLb = [self es_caption];
    stLb.text = order.status ?: @"";
    if (@available(iOS 13.0, *)) {
        stLb.textColor = UIColor.systemOrangeColor;
    } else {
        stLb.textColor = [UIColor orangeColor];
    }
    stLb.textAlignment = NSTextAlignmentRight;
    UIStackView *top = [[UIStackView alloc] initWithArrangedSubviews:@[ idLb, stLb ]];
    top.axis = UILayoutConstraintAxisHorizontal;
    top.distribution = UIStackViewDistributionEqualSpacing;
    [_stack addArrangedSubview:top];

    if (order.items.count > 0) {
        for (ESOrderLineItem *li in order.items) {
            UILabel *line = [UILabel new];
            line.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            line.numberOfLines = 1;
            if (compactItems) {
                line.text = [NSString stringWithFormat:@"%@  ¥%.2f", li.productTitle, li.lineTotal];
            } else {
                line.text = [NSString stringWithFormat:@"%@  x%ld  ¥%.2f", li.productTitle, (long)li.quantity, li.lineTotal];
            }
            [_stack addArrangedSubview:line];
        }
    } else if (order.summary.length > 0) {
        UILabel *leg = [UILabel new];
        leg.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        leg.numberOfLines = 0;
        leg.text = order.summary;
        [_stack addArrangedSubview:leg];
    }

    UILabel *tot = [UILabel new];
    tot.font = [UIFont boldSystemFontOfSize:15];
    tot.text = [NSString stringWithFormat:@"合计：¥%.2f", order.total];
    if (showAddress && order.addressDisplayText.length > 0) {
        UILabel *ad = [UILabel new];
        ad.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        ad.numberOfLines = 0;
        ad.text = order.addressDisplayText;
        if (@available(iOS 13.0, *)) {
            ad.textColor = UIColor.secondaryLabelColor;
        } else {
            ad.textColor = [UIColor darkGrayColor];
        }
        UIStackView *bot = [[UIStackView alloc] initWithArrangedSubviews:@[ ad, tot ]];
        bot.axis = UILayoutConstraintAxisHorizontal;
        bot.alignment = UIStackViewAlignmentTop;
        bot.spacing = 8;
        bot.distribution = UIStackViewDistributionFill;
        [ad setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [tot setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_stack addArrangedSubview:bot];
    } else {
        UIStackView *bot = [[UIStackView alloc] initWithArrangedSubviews:@[ [[UIView alloc] init], tot ]];
        bot.axis = UILayoutConstraintAxisHorizontal;
        tot.textAlignment = NSTextAlignmentRight;
        [_stack addArrangedSubview:bot];
    }
}

@end

@implementation ESOrdersByStatusViewController {
    NSString *_status;
    NSString *_navTitle;
    NSArray<ESOrder *> *_list;
}

- (instancetype)initWithOrderStatus:(NSString *)status title:(NSString *)title {
    if (self = [super initWithStyle:ESGroupedInsetStyle()]) {
        _status = [status copy];
        _navTitle = [title copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = _navTitle;
    self.tableView.estimatedRowHeight = 160;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerClass:[ESOrderRichCell class] forCellReuseIdentifier:@"rich"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _list = [ESStore.shared ordersByStatus:_status ?: @"" keyword:@""];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ESOrderRichCell *c = [tableView dequeueReusableCellWithIdentifier:@"rich" forIndexPath:indexPath];
    [c configureWithOrder:_list[indexPath.row] showAddressLine:YES compactItems:NO];
    return c;
}

@end

@interface ESOrderListViewController () <UISearchBarDelegate>
@end

@implementation ESOrderListViewController {
    NSArray<ESOrder *> *_list;
    UISearchBar *_search;
    UIButton *_filterBtn;
    NSString *_statusFilter;
    UIView *_headerWrap;
    /// 仅在表头宽度变化时更新 frame 并赋值 tableHeaderView，避免每次 layout 重复赋值导致布局死循环卡死
    CGFloat _orderListHeaderAppliedWidth;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我的订单";
    _statusFilter = @"";
    _headerWrap = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 96)];
    _search = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 56)];
    _search.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _search.placeholder = @"搜索订单";
    _search.delegate = self;
    _filterBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _filterBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _filterBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    _filterBtn.frame = CGRectMake(16, 58, 288, 32);
    [_filterBtn addTarget:self action:@selector(es_showStatusPicker) forControlEvents:UIControlEventTouchUpInside];
    [_headerWrap addSubview:_search];
    [_headerWrap addSubview:_filterBtn];
    self.tableView.tableHeaderView = _headerWrap;
    self.tableView.estimatedRowHeight = 140;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerClass:[ESOrderRichCell class] forCellReuseIdentifier:@"rich"];
    [self es_updateFilterTitle];
    _orderListHeaderAppliedWidth = -1;
    [self es_reloadOrderList];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = CGRectGetWidth(self.tableView.bounds);
    if (w < 1 || !_headerWrap) {
        return;
    }
    if (fabs(w - _orderListHeaderAppliedWidth) < 1.0) {
        return;
    }
    _orderListHeaderAppliedWidth = w;
    _headerWrap.frame = CGRectMake(0, 0, w, 96);
    _search.frame = CGRectMake(0, 0, w, 56);
    _filterBtn.frame = CGRectMake(16, 58, w - 32, 32);
    self.tableView.tableHeaderView = _headerWrap;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self es_reloadOrderList];
}

- (void)es_updateFilterTitle {
    NSDictionary *map = @{
        @"": @"全部",
        @"待付款": @"待付款",
        @"待发货": @"待发货",
        @"待收货": @"待收货",
        @"待评价": @"待评价",
        @"退款/售后": @"退款/售后"
    };
    NSString *t = map[_statusFilter] ?: @"全部";
    [_filterBtn setTitle:[NSString stringWithFormat:@"订单类型：%@", t] forState:UIControlStateNormal];
}

- (void)es_reloadOrderList {
    _list = [ESStore.shared ordersByStatus:_statusFilter ?: @"" keyword:_search.text ?: @""];
    [self.tableView reloadData];
}

- (void)es_showStatusPicker {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"订单类型" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray<NSArray *> *opts = @[
        @[ @"", @"全部" ],
        @[ @"待付款", @"待付款" ],
        @[ @"待发货", @"待发货" ],
        @[ @"待收货", @"待收货" ],
        @[ @"待评价", @"待评价" ],
        @[ @"退款/售后", @"退款/售后" ]
    ];
    __weak typeof(self) ws = self;
    for (NSArray *pair in opts) {
        NSString *key = pair[0];
        NSString *label = pair[1];
        [ac addAction:[UIAlertAction actionWithTitle:label style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
            __strong typeof(ws) s = ws;
            if (!s) {
                return;
            }
            s->_statusFilter = key;
            [s es_updateFilterTitle];
            [s es_reloadOrderList];
        }]];
    }
    [ac addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *pop = ac.popoverPresentationController;
    if (pop) {
        pop.sourceView = _filterBtn;
        pop.sourceRect = _filterBtn.bounds;
    }
    [self presentViewController:ac animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _list.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"订单列表";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ESOrderRichCell *c = [tableView dequeueReusableCellWithIdentifier:@"rich" forIndexPath:indexPath];
    [c configureWithOrder:_list[indexPath.row] showAddressLine:NO compactItems:YES];
    return c;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self es_reloadOrderList];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self es_reloadOrderList];
}

@end

#pragma mark - 商品卡片 Cell（对齐 example ProductRowView：图、收藏、双行标题、价格、付款人数）

@interface ESProductCardCell : UICollectionViewCell
@property (nonatomic, copy, nullable) void (^onFavoriteTap)(void);
- (void)configureWithProduct:(ESProduct *)p store:(ESStore *)store;
@end

@implementation ESProductCardCell {
    UIView *_card;
    UIView *_imgBox;
    UIImageView *_pic;
    UIView *_ph;
    UILabel *_phLab;
    UIButton *_fav;
    UILabel *_title;
    UILabel *_price;
    UILabel *_pay;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = UIColor.clearColor;

        _card = [UIView new];
        _card.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 13.0, *)) {
            _card.backgroundColor = UIColor.secondarySystemBackgroundColor;
        } else {
            _card.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        }
        _card.layer.cornerRadius = 12;
        _card.layer.masksToBounds = YES;
        [self.contentView addSubview:_card];

        _imgBox = [UIView new];
        _imgBox.translatesAutoresizingMaskIntoConstraints = NO;
        _imgBox.layer.cornerRadius = 8;
        _imgBox.layer.masksToBounds = YES;
        _imgBox.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        [_card addSubview:_imgBox];

        _pic = [UIImageView new];
        _pic.translatesAutoresizingMaskIntoConstraints = NO;
        _pic.contentMode = UIViewContentModeScaleAspectFill;
        _pic.clipsToBounds = YES;
        [_imgBox addSubview:_pic];

        _ph = [UIView new];
        _ph.translatesAutoresizingMaskIntoConstraints = NO;
        _ph.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1.0];
        [_imgBox addSubview:_ph];

        _phLab = [UILabel new];
        _phLab.translatesAutoresizingMaskIntoConstraints = NO;
        _phLab.font = [UIFont boldSystemFontOfSize:28];
        _phLab.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
        _phLab.textAlignment = NSTextAlignmentCenter;
        [_ph addSubview:_phLab];

        _fav = [UIButton buttonWithType:UIButtonTypeSystem];
        _fav.translatesAutoresizingMaskIntoConstraints = NO;
        [_fav addTarget:self action:@selector(favPressed) forControlEvents:UIControlEventTouchUpInside];
        _fav.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.88];
        _fav.layer.cornerRadius = 16;
        _fav.layer.masksToBounds = YES;
        _fav.contentEdgeInsets = UIEdgeInsetsMake(4, 8, 4, 8);
        [_card addSubview:_fav];

        _title = [UILabel new];
        _title.translatesAutoresizingMaskIntoConstraints = NO;
        _title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _title.numberOfLines = 2;
        _title.adjustsFontForContentSizeCategory = YES;
        [_card addSubview:_title];

        _price = [UILabel new];
        _price.translatesAutoresizingMaskIntoConstraints = NO;
        _price.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        _price.textColor = ESPriceColor();
        _price.adjustsFontForContentSizeCategory = YES;
        [_card addSubview:_price];

        _pay = [UILabel new];
        _pay.translatesAutoresizingMaskIntoConstraints = NO;
        _pay.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        _pay.textColor = ESAuthSecondaryLabelColor();
        _pay.textAlignment = NSTextAlignmentRight;
        _pay.adjustsFontForContentSizeCategory = YES;
        [_card addSubview:_pay];

        [NSLayoutConstraint activateConstraints:@[
            [_card.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [_card.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_card.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],

            [_imgBox.topAnchor constraintEqualToAnchor:_card.topAnchor constant:8],
            [_imgBox.leadingAnchor constraintEqualToAnchor:_card.leadingAnchor constant:8],
            [_imgBox.trailingAnchor constraintEqualToAnchor:_card.trailingAnchor constant:-8],
            [_imgBox.heightAnchor constraintEqualToConstant:140],

            [_pic.topAnchor constraintEqualToAnchor:_imgBox.topAnchor],
            [_pic.leadingAnchor constraintEqualToAnchor:_imgBox.leadingAnchor],
            [_pic.trailingAnchor constraintEqualToAnchor:_imgBox.trailingAnchor],
            [_pic.bottomAnchor constraintEqualToAnchor:_imgBox.bottomAnchor],

            [_ph.topAnchor constraintEqualToAnchor:_imgBox.topAnchor],
            [_ph.leadingAnchor constraintEqualToAnchor:_imgBox.leadingAnchor],
            [_ph.trailingAnchor constraintEqualToAnchor:_imgBox.trailingAnchor],
            [_ph.bottomAnchor constraintEqualToAnchor:_imgBox.bottomAnchor],

            [_phLab.centerXAnchor constraintEqualToAnchor:_ph.centerXAnchor],
            [_phLab.centerYAnchor constraintEqualToAnchor:_ph.centerYAnchor],

            [_fav.topAnchor constraintEqualToAnchor:_imgBox.topAnchor constant:4],
            [_fav.trailingAnchor constraintEqualToAnchor:_imgBox.trailingAnchor constant:-4],

            [_title.topAnchor constraintEqualToAnchor:_imgBox.bottomAnchor constant:8],
            [_title.leadingAnchor constraintEqualToAnchor:_card.leadingAnchor constant:8],
            [_title.trailingAnchor constraintEqualToAnchor:_card.trailingAnchor constant:-8],

            [_price.topAnchor constraintEqualToAnchor:_title.bottomAnchor constant:6],
            [_price.leadingAnchor constraintEqualToAnchor:_card.leadingAnchor constant:8],
            [_price.bottomAnchor constraintEqualToAnchor:_card.bottomAnchor constant:-8],

            [_pay.centerYAnchor constraintEqualToAnchor:_price.centerYAnchor],
            [_pay.trailingAnchor constraintEqualToAnchor:_card.trailingAnchor constant:-8],
            [_pay.leadingAnchor constraintGreaterThanOrEqualToAnchor:_price.trailingAnchor constant:4]
        ]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.onFavoriteTap = nil;
    _pic.image = nil;
}

- (void)favPressed {
    if (self.onFavoriteTap) {
        self.onFavoriteTap();
    }
}

- (void)configureWithProduct:(ESProduct *)p store:(ESStore *)store {
    _title.text = p.title;
    _price.text = [NSString stringWithFormat:@"¥%.2f", p.price];
    NSString *rawPay = p.payCountText ?: @"";
    _pay.text = ([rawPay rangeOfString:@"人付款"].location != NSNotFound) ? rawPay : [NSString stringWithFormat:@"%@人付款", rawPay];

    UIImage *im = nil;
    if (p.imageAssetName.length > 0) {
        im = [UIImage imageNamed:p.imageAssetName];
    }
    if (im) {
        _pic.hidden = NO;
        _ph.hidden = YES;
        _pic.image = im;
    } else {
        _pic.hidden = YES;
        _ph.hidden = NO;
        _pic.image = nil;
        NSString *c = p.category ?: @"";
        _phLab.text = (c.length > 0) ? [c substringToIndex:1] : @"图";
    }

    BOOL fav = [store isFavorite:p.pid];
    UIImage *heart = ESSystemImage((fav ? @"heart.fill" : @"heart"));
    if (heart) {
        heart = [heart imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_fav setImage:heart forState:UIControlStateNormal];
        [_fav setTitle:nil forState:UIControlStateNormal];
        _fav.tintColor = fav ? [UIColor redColor] : [UIColor colorWithWhite:0.55 alpha:1.0];
    } else {
        [_fav setImage:nil forState:UIControlStateNormal];
        [_fav setTitle:(fav ? @"♥" : @"♡") forState:UIControlStateNormal];
        [_fav setTitleColor:(fav ? [UIColor redColor] : [UIColor colorWithWhite:0.55 alpha:1.0]) forState:UIControlStateNormal];
        _fav.titleLabel.font = [UIFont systemFontOfSize:20];
    }

    if (@available(iOS 13.0, *)) {
        _title.textColor = UIColor.labelColor;
    } else {
        _title.textColor = UIColor.darkTextColor;
    }
}

@end

/// 首页 / 收藏 / 搜索共用双列参数（与 `ESProductCardCell` 高度一致）
static UICollectionViewFlowLayout *ESMakeProductGridFlowLayout(void) {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 12;
    layout.minimumLineSpacing = 12;
    layout.sectionInset = UIEdgeInsetsMake(12, 12, 12, 12);
    return layout;
}

static CGSize ESProductGridItemSize(CGFloat collectionWidth) {
    if (collectionWidth < 1) {
        return CGSizeMake(160, 260);
    }
    UIEdgeInsets inset = UIEdgeInsetsMake(12, 12, 12, 12);
    CGFloat gap = 12;
    CGFloat w = floor((collectionWidth - inset.left - inset.right - gap) / 2.0);
    return CGSizeMake(MAX(w, 120), 260);
}

#pragma mark - Search（对齐 example SearchView；iOS 11 无 SF Symbol 则隐藏放大镜，逻辑不变）

static UIColor *ESSearchFieldWellColor(void) {
    if (@available(iOS 13.0, *)) {
        return UIColor.secondarySystemBackgroundColor;
    }
    return [UIColor colorWithWhite:0.95 alpha:1.0];
}

@interface ESSearchViewController ()
@property (nonatomic, copy) NSString *initialKeyword;
@property (nonatomic, strong) UITextField *field;
@property (nonatomic, strong) UIButton *goButton;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) NSArray<ESProduct *> *results;
@end

@implementation ESSearchViewController

- (instancetype)initWithInitialKeyword:(NSString *)kw {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _initialKeyword = [kw copy] ?: @"";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ESBackgroundColor();
    self.title = @"搜索";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(onCancel)];

    UIView *well = [UIView new];
    well.translatesAutoresizingMaskIntoConstraints = NO;
    well.backgroundColor = ESSearchFieldWellColor();
    well.layer.cornerRadius = 10;
    well.layer.masksToBounds = YES;

    self.field = [UITextField new];
    self.field.translatesAutoresizingMaskIntoConstraints = NO;
    self.field.placeholder = @"输入关键词搜索";
    self.field.borderStyle = UITextBorderStyleNone;
    self.field.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.field.returnKeyType = UIReturnKeySearch;
    self.field.delegate = self;
    self.field.autocapitalizationType = UITextAutocapitalizationTypeNone;

    UIImage *magImg = ESSystemImage(@"magnifyingglass");
    if (magImg) {
        magImg = [magImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    UIImageView *icon = [[UIImageView alloc] initWithImage:magImg];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.tintColor = ESAuthSecondaryLabelColor();
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.hidden = (magImg == nil);

    self.goButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.goButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.goButton setTitle:@"搜索" forState:UIControlStateNormal];
    [self.goButton addTarget:self action:@selector(runSearch) forControlEvents:UIControlEventTouchUpInside];
    self.goButton.hidden = YES;

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[ icon, self.field, self.goButton ]];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 8;
    row.alignment = UIStackViewAlignmentCenter;
    [well addSubview:row];

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:ESMakeProductGridFlowLayout()];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = ESBackgroundColor();
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.collectionView registerClass:[ESProductCardCell class] forCellWithReuseIdentifier:@"card"];

    [self.view addSubview:well];
    [self.view addSubview:self.collectionView];

    [NSLayoutConstraint activateConstraints:@[
        [icon.widthAnchor constraintEqualToConstant:22],
        [icon.heightAnchor constraintEqualToConstant:22],
        [row.topAnchor constraintEqualToAnchor:well.topAnchor constant:10],
        [row.leadingAnchor constraintEqualToAnchor:well.leadingAnchor constant:12],
        [row.trailingAnchor constraintEqualToAnchor:well.trailingAnchor constant:-12],
        [row.bottomAnchor constraintEqualToAnchor:well.bottomAnchor constant:-10],
        [well.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [well.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [well.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.collectionView.topAnchor constraintEqualToAnchor:well.bottomAnchor constant:12],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    [self.field addTarget:self action:@selector(onFieldChanged) forControlEvents:UIControlEventEditingChanged];

    self.field.text = self.initialKeyword;
    [self refreshGoButtonVisibility];
    if (self.field.text.length) {
        [self runSearch];
    } else {
        self.results = @[];
        [self.collectionView reloadData];
        [self updateEmptyHint];
    }
}

- (void)onFieldChanged {
    [self refreshGoButtonVisibility];
    if (self.field.text.length == 0) {
        self.results = @[];
        [self.collectionView reloadData];
        [self updateEmptyHint];
    }
}

- (void)refreshGoButtonVisibility {
    self.goButton.hidden = (self.field.text.length == 0);
}

- (void)onCancel {
    if (self.onFinish) {
        self.onFinish(nil);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)runSearch {
    [self.view endEditing:YES];
    self.results = [[ESStore shared] searchProductsWithKeywordTrimmed:self.field.text];
    [self.collectionView reloadData];
    [self updateEmptyHint];
}

- (void)updateEmptyHint {
    NSString *kw = [self.field.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.collectionView.backgroundView = nil;
    if (self.results.count > 0) {
        return;
    }
    UILabel *lb = [UILabel new];
    lb.textAlignment = NSTextAlignmentCenter;
    lb.textColor = ESAuthSecondaryLabelColor();
    lb.numberOfLines = 0;
    lb.text = (kw.length > 0) ? @"无结果" : @"输入关键词后搜索";
    self.collectionView.backgroundView = lb;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self runSearch];
    return YES;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.results.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ESProductCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"card" forIndexPath:indexPath];
    ESProduct *p = self.results[(NSUInteger)indexPath.item];
    [cell configureWithProduct:p store:[ESStore shared]];
    __weak UICollectionView *wcv = collectionView;
    NSString *pid = p.pid;
    cell.onFavoriteTap = ^{
        [[ESStore shared] toggleFavorite:pid];
        __strong UICollectionView *cv = wcv;
        [cv reloadData];
    };
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return ESProductGridItemSize(CGRectGetWidth(collectionView.bounds));
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *kw = [self.field.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [ESStore setLastDisplayedSearchKeyword:(kw.length > 0 ? kw : nil)];
    if (self.onFinish) {
        self.onFinish((kw.length > 0 ? kw : nil));
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end

#pragma mark - Home / Fav / Cart / Checkout / Profile / Tab

@implementation ESHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"首页";
    self.view.backgroundColor = ESBackgroundColor();
    self.categories = @[ @"手机", @"电脑", @"户外", @"衣服", @"零食" ];
    self.activeSearchKeyword = [ESStore lastDisplayedSearchKeyword] ?: @"";

    self.searchEntryBar = [UIView new];
    self.searchEntryBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchEntryBar.backgroundColor = ESSearchFieldWellColor();
    self.searchEntryBar.layer.cornerRadius = 10;
    self.searchEntryBar.layer.masksToBounds = YES;
    [self.searchEntryBar addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openSearchScreen)]];

    UIImage *hmag = ESSystemImage(@"magnifyingglass");
    if (hmag) {
        hmag = [hmag imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    UIImageView *entryIcon = [[UIImageView alloc] initWithImage:hmag];
    entryIcon.translatesAutoresizingMaskIntoConstraints = NO;
    entryIcon.tintColor = ESAuthSecondaryLabelColor();
    entryIcon.contentMode = UIViewContentModeScaleAspectFit;
    entryIcon.hidden = (hmag == nil);

    self.searchEntryLabel = [UILabel new];
    self.searchEntryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchEntryLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.searchEntryLabel.numberOfLines = 1;
    [self refreshSearchEntryTitle];

    UIStackView *entryRow = [[UIStackView alloc] initWithArrangedSubviews:@[ entryIcon, self.searchEntryLabel ]];
    entryRow.translatesAutoresizingMaskIntoConstraints = NO;
    entryRow.axis = UILayoutConstraintAxisHorizontal;
    entryRow.spacing = 8;
    entryRow.alignment = UIStackViewAlignmentCenter;
    entryRow.userInteractionEnabled = NO;
    [self.searchEntryBar addSubview:entryRow];

    [NSLayoutConstraint activateConstraints:@[
        [entryIcon.widthAnchor constraintEqualToConstant:20],
        [entryIcon.heightAnchor constraintEqualToConstant:20],
        [entryRow.topAnchor constraintEqualToAnchor:self.searchEntryBar.topAnchor constant:12],
        [entryRow.leadingAnchor constraintEqualToAnchor:self.searchEntryBar.leadingAnchor constant:12],
        [entryRow.trailingAnchor constraintEqualToAnchor:self.searchEntryBar.trailingAnchor constant:-12],
        [entryRow.bottomAnchor constraintEqualToAnchor:self.searchEntryBar.bottomAnchor constant:-12]
    ]];

    self.seg = [[UISegmentedControl alloc] initWithItems:self.categories];
    self.seg.translatesAutoresizingMaskIntoConstraints = NO;
    self.seg.selectedSegmentIndex = 0;
    [self.seg addTarget:self action:@selector(onCategorySegmentChanged) forControlEvents:UIControlEventValueChanged];

    self.pageScroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.pageScroll.translatesAutoresizingMaskIntoConstraints = NO;
    self.pageScroll.pagingEnabled = YES;
    self.pageScroll.showsHorizontalScrollIndicator = NO;
    self.pageScroll.showsVerticalScrollIndicator = NO;
    self.pageScroll.delegate = self;
    self.pageScroll.bounces = YES;
    self.pageScroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

    UIStackView *pageStack = [[UIStackView alloc] initWithFrame:CGRectZero];
    pageStack.translatesAutoresizingMaskIntoConstraints = NO;
    pageStack.axis = UILayoutConstraintAxisHorizontal;
    pageStack.spacing = 0;
    pageStack.distribution = UIStackViewDistributionFill;
    pageStack.alignment = UIStackViewAlignmentFill;

    // 必须先让 pageStack 进入 pageScroll 子树，再约束 page.width 到 frameLayoutGuide，否则二者无共同祖先会抛 Auto Layout 异常
    [self.pageScroll addSubview:pageStack];

    NSMutableArray<UICollectionView *> *tabs = [NSMutableArray array];
    for (NSInteger i = 0; i < (NSInteger)self.categories.count; i++) {
        UIView *page = [UIView new];
        page.translatesAutoresizingMaskIntoConstraints = NO;
        UICollectionView *cv = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:ESMakeProductGridFlowLayout()];
        cv.translatesAutoresizingMaskIntoConstraints = NO;
        cv.backgroundColor = ESBackgroundColor();
        cv.tag = (NSInteger)i;
        cv.dataSource = self;
        cv.delegate = self;
        cv.alwaysBounceVertical = YES;
        [cv registerClass:[ESProductCardCell class] forCellWithReuseIdentifier:@"card"];
        [page addSubview:cv];
        [NSLayoutConstraint activateConstraints:@[
            [cv.topAnchor constraintEqualToAnchor:page.topAnchor],
            [cv.leadingAnchor constraintEqualToAnchor:page.leadingAnchor],
            [cv.trailingAnchor constraintEqualToAnchor:page.trailingAnchor],
            [cv.bottomAnchor constraintEqualToAnchor:page.bottomAnchor]
        ]];
        [pageStack addArrangedSubview:page];
        [page.widthAnchor constraintEqualToAnchor:self.pageScroll.frameLayoutGuide.widthAnchor].active = YES;
        [tabs addObject:cv];
    }
    self.categoryCollections = tabs;
    [self.view addSubview:self.searchEntryBar];
    [self.view addSubview:self.seg];
    [self.view addSubview:self.pageScroll];

    UILayoutGuide *fcg = self.pageScroll.frameLayoutGuide;
    UILayoutGuide *ccg = self.pageScroll.contentLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        [self.searchEntryBar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [self.searchEntryBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.searchEntryBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        [self.seg.topAnchor constraintEqualToAnchor:self.searchEntryBar.bottomAnchor constant:8],
        [self.seg.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.seg.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        [self.pageScroll.topAnchor constraintEqualToAnchor:self.seg.bottomAnchor constant:8],
        [self.pageScroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.pageScroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.pageScroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [pageStack.topAnchor constraintEqualToAnchor:ccg.topAnchor],
        [pageStack.leadingAnchor constraintEqualToAnchor:ccg.leadingAnchor],
        [pageStack.trailingAnchor constraintEqualToAnchor:ccg.trailingAnchor],
        [pageStack.bottomAnchor constraintEqualToAnchor:ccg.bottomAnchor],
        [pageStack.heightAnchor constraintEqualToAnchor:fcg.heightAnchor]
    ]];

    [self reloadHomeLists];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.pageScroll.bounds.size.width;
    if (w < 1) {
        return;
    }
    if (fabs(w - self.lastPageScrollWidth) > 0.5) {
        self.lastPageScrollWidth = w;
        NSInteger i = self.seg.selectedSegmentIndex;
        self.pageScroll.contentOffset = CGPointMake(i * w, 0);
    }
}

- (void)onCategorySegmentChanged {
    CGFloat w = self.pageScroll.bounds.size.width;
    if (w > 1) {
        [self.pageScroll setContentOffset:CGPointMake(self.seg.selectedSegmentIndex * w, 0) animated:YES];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != self.pageScroll) {
        return;
    }
    [self syncSegmentWithPageScroll];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView != self.pageScroll) {
        return;
    }
    [self syncSegmentWithPageScroll];
}

- (void)syncSegmentWithPageScroll {
    CGFloat w = self.pageScroll.bounds.size.width;
    if (w < 1) {
        return;
    }
    NSInteger page = (NSInteger)llround(self.pageScroll.contentOffset.x / w);
    NSInteger maxI = (NSInteger)self.categories.count - 1;
    if (page < 0) {
        page = 0;
    }
    if (page > maxI) {
        page = maxI;
    }
    if (self.seg.selectedSegmentIndex != page) {
        self.seg.selectedSegmentIndex = page;
    }
}

- (NSArray<ESProduct *> *)productsForCategoryPage:(NSInteger)pageIndex {
    if (pageIndex < 0 || pageIndex >= (NSInteger)self.categories.count) {
        return @[];
    }
    NSString *kw = self.activeSearchKeyword ?: @"";
    return [[ESStore shared] productsForCategory:self.categories[(NSUInteger)pageIndex] keyword:kw];
}

- (void)reloadHomeLists {
    for (UICollectionView *c in self.categoryCollections) {
        [c reloadData];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.activeSearchKeyword = [ESStore lastDisplayedSearchKeyword] ?: @"";
    [self refreshSearchEntryTitle];
    [self reloadHomeLists];
}

- (void)refreshSearchEntryTitle {
    NSString *hint = @"搜索手机、电脑、户外、衣服";
    if (self.activeSearchKeyword.length > 0) {
        self.searchEntryLabel.text = self.activeSearchKeyword;
        if (@available(iOS 13.0, *)) {
            self.searchEntryLabel.textColor = UIColor.labelColor;
        } else {
            self.searchEntryLabel.textColor = UIColor.darkTextColor;
        }
    } else {
        self.searchEntryLabel.text = hint;
        self.searchEntryLabel.textColor = ESAuthSecondaryLabelColor();
    }
}

- (void)openSearchScreen {
    ESSearchViewController *s = [[ESSearchViewController alloc] initWithInitialKeyword:self.activeSearchKeyword];
    __weak typeof(self) ws = self;
    s.onFinish = ^(NSString *_Nullable kw) {
        __strong typeof(ws) strongSelf = ws;
        if (!strongSelf) {
            return;
        }
        if (kw.length) {
            [ESStore setLastDisplayedSearchKeyword:kw];
            strongSelf.activeSearchKeyword = [kw copy];
        } else {
            [ESStore setLastDisplayedSearchKeyword:nil];
            strongSelf.activeSearchKeyword = @"";
        }
        [strongSelf refreshSearchEntryTitle];
        [strongSelf reloadHomeLists];
    };
    [self.navigationController pushViewController:s animated:YES];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self productsForCategoryPage:collectionView.tag].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ESProductCardCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"card" forIndexPath:indexPath];
    NSArray<ESProduct *> *lst = [self productsForCategoryPage:collectionView.tag];
    ESProduct *p = lst[(NSUInteger)indexPath.item];
    [cell configureWithProduct:p store:[ESStore shared]];
    __weak UICollectionView *wcv = collectionView;
    NSString *pid = p.pid;
    cell.onFavoriteTap = ^{
        [[ESStore shared] toggleFavorite:pid];
        __strong UICollectionView *cv = wcv;
        [cv reloadData];
    };
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return ESProductGridItemSize(CGRectGetWidth(collectionView.bounds));
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray<ESProduct *> *lst = [self productsForCategoryPage:collectionView.tag];
    ESProduct *p = lst[(NSUInteger)indexPath.item];
    ESPresentProductDetailSheet(self, p);
}

@end

#pragma mark - 收藏列表行（对齐 example `ProductRowView` + `FavoriteView` List）

@interface ESProductTableRowCell : UITableViewCell
@property (nonatomic, copy, nullable) void (^onFavoriteTap)(void);
- (void)configureWithProduct:(ESProduct *)p store:(ESStore *)store;
@end

@implementation ESProductTableRowCell {
    UIView *_card;
    UIImageView *_thumb;
    UILabel *_title;
    UILabel *_price;
    UILabel *_pay;
    UIButton *_fav;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        _card = [UIView new];
        _card.translatesAutoresizingMaskIntoConstraints = NO;
        if (@available(iOS 13.0, *)) {
            _card.backgroundColor = UIColor.secondarySystemBackgroundColor;
        } else {
            _card.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        }
        _card.layer.cornerRadius = 12;
        _card.layer.masksToBounds = YES;
        [self.contentView addSubview:_card];

        _thumb = [UIImageView new];
        _thumb.translatesAutoresizingMaskIntoConstraints = NO;
        _thumb.contentMode = UIViewContentModeScaleAspectFill;
        _thumb.clipsToBounds = YES;
        _thumb.layer.cornerRadius = 8;
        _thumb.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];

        _title = [UILabel new];
        _title.translatesAutoresizingMaskIntoConstraints = NO;
        _title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _title.numberOfLines = 2;

        _price = [UILabel new];
        _price.translatesAutoresizingMaskIntoConstraints = NO;
        _price.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        _price.textColor = ESPriceColor();

        _pay = [UILabel new];
        _pay.translatesAutoresizingMaskIntoConstraints = NO;
        _pay.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        if (@available(iOS 13.0, *)) {
            _pay.textColor = UIColor.secondaryLabelColor;
        } else {
            _pay.textColor = [UIColor grayColor];
        }

        _fav = [UIButton buttonWithType:UIButtonTypeSystem];
        _fav.translatesAutoresizingMaskIntoConstraints = NO;
        [_fav addTarget:self action:@selector(favTap) forControlEvents:UIControlEventTouchUpInside];

        UIStackView *textCol = [[UIStackView alloc] initWithArrangedSubviews:@[ _title, _price, _pay ]];
        textCol.translatesAutoresizingMaskIntoConstraints = NO;
        textCol.axis = UILayoutConstraintAxisVertical;
        textCol.spacing = 6;
        textCol.alignment = UIStackViewAlignmentLeading;

        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[ _thumb, textCol, _fav ]];
        row.translatesAutoresizingMaskIntoConstraints = NO;
        row.axis = UILayoutConstraintAxisHorizontal;
        row.spacing = 12;
        row.alignment = UIStackViewAlignmentTop;
        [_card addSubview:row];

        [NSLayoutConstraint activateConstraints:@[
            [_card.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6],
            [_card.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:12],
            [_card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-12],
            [_card.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6],
            [row.topAnchor constraintEqualToAnchor:_card.topAnchor constant:8],
            [row.leadingAnchor constraintEqualToAnchor:_card.leadingAnchor constant:8],
            [row.trailingAnchor constraintEqualToAnchor:_card.trailingAnchor constant:-8],
            [row.bottomAnchor constraintEqualToAnchor:_card.bottomAnchor constant:-8],
            [_thumb.widthAnchor constraintEqualToConstant:72],
            [_thumb.heightAnchor constraintEqualToConstant:72],
            [_fav.widthAnchor constraintEqualToConstant:44],
            [_fav.heightAnchor constraintEqualToConstant:44]
        ]];
    }
    return self;
}

- (void)favTap {
    if (self.onFavoriteTap) {
        self.onFavoriteTap();
    }
}

- (void)configureWithProduct:(ESProduct *)p store:(ESStore *)store {
    _title.text = p.title;
    _price.text = [NSString stringWithFormat:@"¥%.2f", p.price];
    NSString *raw = p.payCountText ?: @"";
    _pay.text = ([raw rangeOfString:@"人付款"].location != NSNotFound) ? raw : [NSString stringWithFormat:@"%@人付款", raw];
    UIImage *im = (p.imageAssetName.length > 0) ? [UIImage imageNamed:p.imageAssetName] : nil;
    _thumb.image = im;
    BOOL fav = [store isFavorite:p.pid];
    UIImage *heart = ESSystemImage((fav ? @"heart.fill" : @"heart"));
    if (heart) {
        heart = [heart imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_fav setImage:heart forState:UIControlStateNormal];
        _fav.tintColor = fav ? [UIColor redColor] : [UIColor colorWithWhite:0.55 alpha:1];
        [_fav setTitle:nil forState:UIControlStateNormal];
    } else {
        [_fav setImage:nil forState:UIControlStateNormal];
        [_fav setTitle:(fav ? @"♥" : @"♡") forState:UIControlStateNormal];
        [_fav setTitleColor:(fav ? [UIColor redColor] : [UIColor grayColor]) forState:UIControlStateNormal];
    }
}

@end

@implementation ESFavoriteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ESBackgroundColor();
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = ESBackgroundColor();
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 120;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tableView registerClass:[ESProductTableRowCell class] forCellReuseIdentifier:@"row"];
    [self.view addSubview:self.tableView];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(es_onRefresh) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = self.refreshControl;

    UIImage *hi = ESSystemImage(@"heart.slash");
    UIImageView *icon = [[UIImageView alloc] initWithImage:hi];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.contentMode = UIViewContentModeScaleAspectFit;
    if (hi) {
        hi = [hi imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        icon.image = hi;
        icon.tintColor = [UIColor colorWithWhite:0.55 alpha:1];
    }
    UILabel *t1 = [UILabel new];
    t1.text = @"暂无收藏商品";
    t1.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    t1.textAlignment = NSTextAlignmentCenter;
    UILabel *t2 = [UILabel new];
    t2.text = @"去首页逛逛，收藏喜欢的商品吧";
    t2.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    t2.textColor = [UIColor colorWithWhite:0.45 alpha:1];
    t2.textAlignment = NSTextAlignmentCenter;
    t2.numberOfLines = 0;
    UIStackView *st = [[UIStackView alloc] initWithArrangedSubviews:@[ icon, t1, t2 ]];
    st.axis = UILayoutConstraintAxisVertical;
    st.spacing = 16;
    st.alignment = UIStackViewAlignmentCenter;
    st.translatesAutoresizingMaskIntoConstraints = NO;
    [icon.widthAnchor constraintEqualToConstant:60].active = YES;
    [icon.heightAnchor constraintEqualToConstant:60].active = YES;
    self.emptyStack = st;
    self.emptyStack.hidden = YES;
    [self.view addSubview:self.emptyStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.emptyStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.emptyStack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-40]
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self reloadFavorites];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)es_onRefresh {
    [self reloadFavorites];
    [self.refreshControl endRefreshing];
}

- (void)reloadFavorites {
    self.list = [[ESStore shared] favoriteProducts];
    self.emptyStack.hidden = (self.list.count > 0);
    self.tableView.hidden = (self.list.count == 0);
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ESProductTableRowCell *cell = [tableView dequeueReusableCellWithIdentifier:@"row" forIndexPath:indexPath];
    ESProduct *p = self.list[(NSUInteger)indexPath.row];
    [cell configureWithProduct:p store:[ESStore shared]];
    __weak UITableView *wtv = tableView;
    __weak typeof(self) ws = self;
    NSString *pid = p.pid;
    cell.onFavoriteTap = ^{
        [[ESStore shared] toggleFavorite:pid];
        __strong typeof(ws) s = ws;
        __strong UITableView *tv = wtv;
        [s reloadFavorites];
        [tv reloadData];
    };
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ESProduct *p = self.list[(NSUInteger)indexPath.row];
    ESPresentProductDetailSheet(self, p);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadFavorites];
}

@end

@implementation ESCheckoutViewController

/// 与 example `CheckoutView.shippingFee` 一致
static double ESCheckoutShippingFee(void) {
    return 10.0;
}

- (double)es_subtotal {
    return [ESStore.shared cartTotalPrice];
}

- (double)es_payableTotal {
    return [self es_subtotal] + ESCheckoutShippingFee();
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ESBackgroundColor();
    self.title = @"结算";
    self.selected = ESStore.shared.defaultAddress;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(es_back)];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:ESGroupedInsetStyle()];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = ESBackgroundColor();
    self.tableView.estimatedRowHeight = 56;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.view addSubview:self.tableView];

    self.bottomBar = [UIView new];
    self.bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        self.bottomBar.backgroundColor = UIColor.systemBackgroundColor;
    } else {
        self.bottomBar.backgroundColor = UIColor.whiteColor;
    }

    UIButton *submit = [UIButton buttonWithType:UIButtonTypeCustom];
    self.submitOrderButton = submit;
    submit.translatesAutoresizingMaskIntoConstraints = NO;
    [submit setTitle:@"提交订单" forState:UIControlStateNormal];
    [submit setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    submit.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    submit.backgroundColor = ESAuthPrimaryColor();
    submit.layer.cornerRadius = 12;
    submit.layer.masksToBounds = YES;
    [submit addTarget:self action:@selector(onSubmit) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomBar addSubview:submit];
    [self.view addSubview:self.bottomBar];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.bottomBar.topAnchor],

        [self.bottomBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.bottomBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.bottomBar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [submit.topAnchor constraintEqualToAnchor:self.bottomBar.safeAreaLayoutGuide.topAnchor constant:12],
        [submit.leadingAnchor constraintEqualToAnchor:self.bottomBar.leadingAnchor constant:16],
        [submit.trailingAnchor constraintEqualToAnchor:self.bottomBar.trailingAnchor constant:-16],
        [submit.bottomAnchor constraintEqualToAnchor:self.bottomBar.safeAreaLayoutGuide.bottomAnchor constant:-12],
        [submit.heightAnchor constraintEqualToConstant:48]
    ]];
}

- (void)es_back {
    if (self.onDismiss) {
        self.onDismiss();
    }
}

- (void)onSubmit {
    if (ESStore.shared.cartProducts.count == 0) {
        return;
    }
    if (!self.selected) {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"请选择收货地址" message:@"请先添加或选择收货地址后再提交订单" preferredStyle:UIAlertControllerStyleAlert];
        [ac addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:ac animated:YES completion:nil];
        return;
    }
    BOOL ok = NO;
    NSString *msg = nil;
    [ESStore.shared submitOrderWithAddress:self.selected orderTotal:[self es_payableTotal] success:&ok message:&msg];
    if (!ok) {
        ESAlert(self, msg ?: @"提交失败");
        return;
    }
    UIAlertController *done = [UIAlertController alertControllerWithTitle:@"订单提交成功" message:@"订单已生成，请在我的订单中查看" preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) ws = self;
    [done addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *a) {
        __strong typeof(ws) s = ws;
        if (!s) {
            return;
        }
        void (^dismiss)(void) = s.onDismiss;
        if (dismiss) {
            dismiss();
        }
    }]];
    [self presentViewController:done animated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    if (section == 1) {
        return ESStore.shared.cartProducts.count;
    }
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"收货地址";
    }
    if (section == 1) {
        return @"商品清单";
    }
    return @"费用";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *c = [tableView dequeueReusableCellWithIdentifier:@"addr"];
        if (!c) {
            c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"addr"];
        }
        c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        c.detailTextLabel.numberOfLines = 0;
        if (self.selected) {
            c.textLabel.text = [NSString stringWithFormat:@"%@ %@", self.selected.name ?: @"", self.selected.phone ?: @""];
            c.detailTextLabel.text = self.selected.fullAddressString.length ? self.selected.fullAddressString : self.selected.fullText;
        } else {
            c.textLabel.text = @"请添加收货地址";
            c.detailTextLabel.text = @"";
        }
        return c;
    }
    if (indexPath.section == 1) {
        UITableViewCell *c = [tableView dequeueReusableCellWithIdentifier:@"line"];
        if (!c) {
            c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"line"];
        }
        ESProduct *p = ESStore.shared.cartProducts[indexPath.row];
        NSInteger n = [ESStore.shared cartCountFor:p.pid];
        c.textLabel.text = p.title;
        c.textLabel.numberOfLines = 2;
        c.detailTextLabel.text = [NSString stringWithFormat:@"x%ld\n¥%.2f", (long)n, p.price * (double)n];
        c.detailTextLabel.numberOfLines = 2;
        c.accessoryType = UITableViewCellAccessoryNone;
        return c;
    }
    UITableViewCell *c = [tableView dequeueReusableCellWithIdentifier:@"fee"];
    if (!c) {
        c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"fee"];
    }
    c.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.row == 0) {
        c.textLabel.text = @"商品小计";
        c.detailTextLabel.text = [NSString stringWithFormat:@"¥%.2f", [self es_subtotal]];
        c.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        c.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    } else if (indexPath.row == 1) {
        c.textLabel.text = @"运费";
        c.detailTextLabel.text = [NSString stringWithFormat:@"¥%.2f", ESCheckoutShippingFee()];
        c.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        c.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    } else {
        c.textLabel.text = @"实付";
        c.detailTextLabel.text = [NSString stringWithFormat:@"¥%.2f", [self es_payableTotal]];
        c.textLabel.font = [UIFont boldSystemFontOfSize:17];
        c.detailTextLabel.font = [UIFont boldSystemFontOfSize:17];
        c.detailTextLabel.textColor = ESPriceColor();
    }
    return c;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 0) {
        return;
    }
    ESAddressListViewController *v = [[ESAddressListViewController alloc] initWithStyle:ESGroupedInsetStyle()];
    __weak typeof(self) ws = self;
    v.onSelect = ^(ESAddress *a) {
        __strong typeof(ws) s = ws;
        s.selected = a;
        [s.tableView reloadData];
    };
    [self.navigationController pushViewController:v animated:YES];
}

@end

#pragma mark - 购物车行（对齐 example `CartRowView`）

@interface ESCartRowCell : UITableViewCell
@property (nonatomic, copy, nullable) void (^onQuantityChange)(NSInteger newQty);
@property (nonatomic, copy, nullable) void (^onRemove)(void);
- (void)configureWithProduct:(ESProduct *)p quantity:(NSInteger)qty;
@end

@implementation ESCartRowCell {
    UIImageView *_thumb;
    UILabel *_title;
    UILabel *_unitPrice;
    UIStepper *_step;
    UILabel *_qtyLab;
    UIButton *_trash;
    UILabel *_lineTotal;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _thumb = [UIImageView new];
        _thumb.translatesAutoresizingMaskIntoConstraints = NO;
        _thumb.contentMode = UIViewContentModeScaleAspectFill;
        _thumb.clipsToBounds = YES;
        _thumb.layer.cornerRadius = 6;
        _thumb.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];

        _title = [UILabel new];
        _title.translatesAutoresizingMaskIntoConstraints = NO;
        _title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _title.numberOfLines = 2;

        _unitPrice = [UILabel new];
        _unitPrice.translatesAutoresizingMaskIntoConstraints = NO;
        _unitPrice.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _unitPrice.textColor = ESPriceColor();

        _step = [UIStepper new];
        _step.translatesAutoresizingMaskIntoConstraints = NO;
        _step.minimumValue = 1;
        _step.maximumValue = 99;
        [_step addTarget:self action:@selector(stepCh) forControlEvents:UIControlEventValueChanged];

        _qtyLab = [UILabel new];
        _qtyLab.translatesAutoresizingMaskIntoConstraints = NO;
        _qtyLab.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _qtyLab.textAlignment = NSTextAlignmentCenter;

        _trash = [UIButton buttonWithType:UIButtonTypeSystem];
        _trash.translatesAutoresizingMaskIntoConstraints = NO;
        UIImage *ti = ESSystemImage(@"trash");
        if (ti) {
            [_trash setImage:[ti imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            _trash.tintColor = [UIColor redColor];
        } else {
            [_trash setTitle:@"删" forState:UIControlStateNormal];
            [_trash setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        }
        [_trash addTarget:self action:@selector(trashTap) forControlEvents:UIControlEventTouchUpInside];

        _lineTotal = [UILabel new];
        _lineTotal.translatesAutoresizingMaskIntoConstraints = NO;
        _lineTotal.font = [UIFont boldSystemFontOfSize:15];
        _lineTotal.textAlignment = NSTextAlignmentRight;

        UIStackView *stepRow = [[UIStackView alloc] initWithArrangedSubviews:@[ _step, _qtyLab, _trash ]];
        stepRow.axis = UILayoutConstraintAxisHorizontal;
        stepRow.spacing = 8;
        stepRow.alignment = UIStackViewAlignmentCenter;

        UIStackView *mid = [[UIStackView alloc] initWithArrangedSubviews:@[ _title, _unitPrice, stepRow ]];
        mid.translatesAutoresizingMaskIntoConstraints = NO;
        mid.axis = UILayoutConstraintAxisVertical;
        mid.spacing = 6;

        UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[ _thumb, mid, _lineTotal ]];
        row.translatesAutoresizingMaskIntoConstraints = NO;
        row.axis = UILayoutConstraintAxisHorizontal;
        row.spacing = 12;
        row.alignment = UIStackViewAlignmentTop;
        [self.contentView addSubview:row];

        [NSLayoutConstraint activateConstraints:@[
            [row.topAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.topAnchor constant:8],
            [row.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor],
            [row.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor],
            [row.bottomAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.bottomAnchor constant:-8],
            [_thumb.widthAnchor constraintEqualToConstant:56],
            [_thumb.heightAnchor constraintEqualToConstant:56],
            [_qtyLab.widthAnchor constraintEqualToConstant:28],
            [_lineTotal.widthAnchor constraintEqualToConstant:72],
            [_trash.widthAnchor constraintEqualToConstant:36]
        ]];
    }
    return self;
}

- (void)stepCh {
    NSInteger v = (NSInteger)llround(_step.value);
    _qtyLab.text = [NSString stringWithFormat:@"%ld", (long)v];
    if (self.onQuantityChange) {
        self.onQuantityChange(v);
    }
}

- (void)trashTap {
    if (self.onRemove) {
        self.onRemove();
    }
}

- (void)configureWithProduct:(ESProduct *)p quantity:(NSInteger)qty {
    _title.text = p.title;
    _unitPrice.text = [NSString stringWithFormat:@"¥%.2f", p.price];
    _step.value = (double)MAX(1, qty);
    _qtyLab.text = [NSString stringWithFormat:@"%ld", (long)MAX(1, qty)];
    _lineTotal.text = [NSString stringWithFormat:@"¥%.2f", p.price * (double)MAX(1, qty)];
    UIImage *im = (p.imageAssetName.length > 0) ? [UIImage imageNamed:p.imageAssetName] : nil;
    _thumb.image = im;
}

@end

@implementation ESCartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ESBackgroundColor();
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 110;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerClass:[ESCartRowCell class] forCellReuseIdentifier:@"cart"];
    [self.view addSubview:self.tableView];

    self.bottomBar = [UIView new];
    self.bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        self.bottomBar.backgroundColor = UIColor.systemBackgroundColor;
    } else {
        self.bottomBar.backgroundColor = UIColor.whiteColor;
    }
    CALayer *hair = [CALayer layer];
    hair.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1].CGColor;
    hair.frame = CGRectMake(0, 0, 1000, 1.0 / [UIScreen mainScreen].scale);
    [self.bottomBar.layer addSublayer:hair];

    self.totalLabel = [UILabel new];
    self.totalLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.totalLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];

    self.checkoutButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.checkoutButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.checkoutButton setTitle:@"去结算" forState:UIControlStateNormal];
    if (@available(iOS 13.0, *)) {
        self.checkoutButton.backgroundColor = ESAuthPrimaryColor();
        [self.checkoutButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    } else {
        self.checkoutButton.backgroundColor = ESAuthPrimaryColor();
        [self.checkoutButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }
    self.checkoutButton.layer.cornerRadius = 10;
    self.checkoutButton.layer.masksToBounds = YES;
    self.checkoutButton.contentEdgeInsets = UIEdgeInsetsMake(10, 20, 10, 20);
    [self.checkoutButton addTarget:self action:@selector(onCheckout) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *barRow = [[UIStackView alloc] initWithArrangedSubviews:@[ self.totalLabel, self.checkoutButton ]];
    barRow.translatesAutoresizingMaskIntoConstraints = NO;
    barRow.axis = UILayoutConstraintAxisHorizontal;
    barRow.spacing = 12;
    barRow.alignment = UIStackViewAlignmentCenter;
    barRow.distribution = UIStackViewDistributionFillEqually;
    [self.bottomBar addSubview:barRow];

    UIImage *ci = ESSystemImage(@"cart");
    UIImageView *civ = [[UIImageView alloc] initWithImage:ci];
    civ.translatesAutoresizingMaskIntoConstraints = NO;
    civ.contentMode = UIViewContentModeScaleAspectFit;
    if (ci) {
        civ.image = [ci imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        civ.tintColor = [UIColor colorWithWhite:0.55 alpha:1];
    }
    UILabel *e1 = [UILabel new];
    e1.text = @"购物车是空的";
    e1.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    e1.textAlignment = NSTextAlignmentCenter;
    UILabel *e2 = [UILabel new];
    e2.text = @"快去选购心仪的商品吧～";
    e2.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    e2.textColor = [UIColor colorWithWhite:0.45 alpha:1];
    e2.textAlignment = NSTextAlignmentCenter;
    UIStackView *es = [[UIStackView alloc] initWithArrangedSubviews:@[ civ, e1, e2 ]];
    es.axis = UILayoutConstraintAxisVertical;
    es.spacing = 16;
    es.alignment = UIStackViewAlignmentCenter;
    es.translatesAutoresizingMaskIntoConstraints = NO;
    [civ.widthAnchor constraintEqualToConstant:60].active = YES;
    [civ.heightAnchor constraintEqualToConstant:60].active = YES;
    self.emptyStack = es;
    self.emptyStack.hidden = YES;
    [self.view addSubview:self.emptyStack];
    [self.view addSubview:self.bottomBar];

    self.cartRefresh = [[UIRefreshControl alloc] init];
    [self.cartRefresh addTarget:self action:@selector(es_cartRefresh) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = self.cartRefresh;

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.bottomBar.topAnchor],

        [self.bottomBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.bottomBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.bottomBar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [barRow.topAnchor constraintEqualToAnchor:self.bottomBar.safeAreaLayoutGuide.topAnchor constant:12],
        [barRow.leadingAnchor constraintEqualToAnchor:self.bottomBar.leadingAnchor constant:16],
        [barRow.trailingAnchor constraintEqualToAnchor:self.bottomBar.trailingAnchor constant:-16],
        [barRow.bottomAnchor constraintEqualToAnchor:self.bottomBar.safeAreaLayoutGuide.bottomAnchor constant:-12],

        [self.emptyStack.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.emptyStack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-40]
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self reloadCart];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)es_cartRefresh {
    [self reloadCart];
    [self.cartRefresh endRefreshing];
}

- (void)onCheckout {
    if (ESStore.shared.cart.count == 0) {
        ESAlert(self, @"购物车为空");
        return;
    }
    ESCheckoutViewController *ck = [ESCheckoutViewController new];
    __weak typeof(self) ws = self;
    UINavigationController *wrap = [[UINavigationController alloc] initWithRootViewController:ck];
    __weak UINavigationController *wWrap = wrap;
    wrap.modalPresentationStyle = UIModalPresentationFullScreen;
    ck.onDismiss = ^{
        __strong UINavigationController *nav = wWrap;
        if (!nav) {
            return;
        }
        [nav dismissViewControllerAnimated:YES completion:^{
            __strong typeof(ws) s = ws;
            [s reloadCart];
        }];
    };
    // 从导航控制器 present，避免购物车 Tab 隐藏了导航栏时偶发的展示上下文问题
    UIViewController *presenter = self.navigationController ?: self;
    [presenter presentViewController:wrap animated:YES completion:nil];
}

- (void)reloadCart {
    self.list = ESStore.shared.cartProducts;
    BOOL empty = (self.list.count == 0);
    self.emptyStack.hidden = !empty;
    self.tableView.hidden = empty;
    self.bottomBar.hidden = empty;
    self.totalLabel.text = [NSString stringWithFormat:@"总计：¥%.2f", ESStore.shared.cartTotalPrice];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ESCartRowCell *c = [tableView dequeueReusableCellWithIdentifier:@"cart" forIndexPath:indexPath];
    ESProduct *p = self.list[indexPath.row];
    NSInteger q = [ESStore.shared cartCountFor:p.pid];
    [c configureWithProduct:p quantity:q];
    __weak typeof(self) ws = self;
    NSString *pid = p.pid;
    c.onQuantityChange = ^(NSInteger newQty) {
        NSInteger cur = [ESStore.shared cartCountFor:pid];
        [ESStore.shared addToCart:pid count:(newQty - cur)];
        __strong typeof(ws) s = ws;
        [s reloadCart];
    };
    c.onRemove = ^{
        [ESStore.shared addToCart:pid count:-999];
        __strong typeof(ws) s = ws;
        [s reloadCart];
    };
    return c;
}

@end

@implementation ESProfileViewController {
    UILabel *_uname;
    UILabel *_uphone;
    NSMutableArray<UILabel *> *_pillCounts;
}

/// 与 example `ProfileView` 一致：分组背景、圆角卡片、订单横向入口、功能行、退出登录
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"我的";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    } else {
        self.view.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
    }

    _pillCounts = [NSMutableArray array];

    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;
    scroll.delaysContentTouches = NO;
    scroll.canCancelContentTouches = YES;
    [self.view addSubview:scroll];

    UIStackView *root = [[UIStackView alloc] init];
    root.axis = UILayoutConstraintAxisVertical;
    root.spacing = 16;
    root.translatesAutoresizingMaskIntoConstraints = NO;
    root.layoutMargins = UIEdgeInsetsMake(12, 16, 24, 16);
    root.layoutMarginsRelativeArrangement = YES;
    [scroll addSubview:root];

    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [root.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [root.leadingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.leadingAnchor],
        [root.trailingAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.trailingAnchor],
        [root.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [root.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor]
    ]];

    [root addArrangedSubview:[self es_profileCardView]];
    [root addArrangedSubview:[self es_orderSectionCard]];
    [root addArrangedSubview:[self es_featuresCard]];

    // 与 example `ProfileView` 中 `Button("退出登录", role: .destructive)` + `frame(maxWidth: .infinity)` + `padding(.vertical, 8)` 一致
    UIButton *logout = [UIButton buttonWithType:UIButtonTypeCustom];
    logout.translatesAutoresizingMaskIntoConstraints = NO;
    [logout setTitle:@"退出登录" forState:UIControlStateNormal];
    logout.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    if (@available(iOS 13.0, *)) {
        [logout setTitleColor:UIColor.systemRedColor forState:UIControlStateNormal];
        [logout setTitleColor:[UIColor.systemRedColor colorWithAlphaComponent:0.45] forState:UIControlStateHighlighted];
    } else {
        [logout setTitleColor:UIColor.redColor forState:UIControlStateNormal];
        [logout setTitleColor:[UIColor.redColor colorWithAlphaComponent:0.45] forState:UIControlStateHighlighted];
    }
    logout.backgroundColor = UIColor.clearColor;
    logout.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    logout.contentEdgeInsets = UIEdgeInsetsMake(10, 16, 10, 16);
    [logout addTarget:self action:@selector(es_logout) forControlEvents:UIControlEventTouchUpInside];
    [logout.heightAnchor constraintGreaterThanOrEqualToConstant:44].active = YES;
    [root addArrangedSubview:logout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self es_refreshUserLabels];
    [self es_refreshOrderPillCounts];
}

- (UIView *)es_cardContainer {
    UIView *card = [UIView new];
    if (@available(iOS 13.0, *)) {
        card.backgroundColor = UIColor.systemBackgroundColor;
    } else {
        card.backgroundColor = UIColor.whiteColor;
    }
    card.layer.cornerRadius = 10;
    card.layer.masksToBounds = YES;
    return card;
}

- (UILabel *)es_secondarySectionTitle:(NSString *)t {
    UILabel *l = [UILabel new];
    l.text = t;
    l.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    if (@available(iOS 13.0, *)) {
        l.textColor = UIColor.secondaryLabelColor;
    } else {
        l.textColor = [UIColor grayColor];
    }
    return l;
}

- (UIView *)es_profileCardView {
    UIView *card = [self es_cardContainer];
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.spacing = 16;
    row.alignment = UIStackViewAlignmentCenter;
    row.translatesAutoresizingMaskIntoConstraints = NO;

    UIImageView *av = [[UIImageView alloc] initWithImage:ESSystemImage(@"person.circle.fill")];
    av.translatesAutoresizingMaskIntoConstraints = NO;
    av.tintColor = [UIColor colorWithWhite:0.6 alpha:1];
    av.contentMode = UIViewContentModeScaleAspectFit;
    if (!av.image) {
        av.image = [UIImage imageNamed:@"splash_logo"];
        av.contentMode = UIViewContentModeScaleAspectFill;
        av.layer.cornerRadius = 25;
        av.clipsToBounds = YES;
        if (!av.image) {
            av.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
        }
    }
    [av.widthAnchor constraintEqualToConstant:50].active = YES;
    [av.heightAnchor constraintEqualToConstant:50].active = YES;

    UIStackView *col = [[UIStackView alloc] init];
    col.axis = UILayoutConstraintAxisVertical;
    col.spacing = 4;
    _uname = [UILabel new];
    _uname.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    _uphone = [UILabel new];
    _uphone.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    if (@available(iOS 13.0, *)) {
        _uphone.textColor = UIColor.secondaryLabelColor;
    } else {
        _uphone.textColor = [UIColor grayColor];
    }
    [col addArrangedSubview:_uname];
    [col addArrangedSubview:_uphone];

    [row addArrangedSubview:av];
    [row addArrangedSubview:col];
    [card addSubview:row];
    const CGFloat cardPad = 16;
    [NSLayoutConstraint activateConstraints:@[
        [row.topAnchor constraintEqualToAnchor:card.topAnchor constant:cardPad],
        [row.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:cardPad],
        [row.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-cardPad],
        [row.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-cardPad]
    ]];
    return card;
}

- (void)es_refreshUserLabels {
    NSString *u = ESStore.shared.currentUser;
    NSString *ph = ESStore.shared.currentPhone;
    _uname.text = (u.length > 0) ? u : @"未登录";
    _uphone.text = (ph.length > 0) ? ph : @"请登录";
}

- (UIView *)es_orderSectionCard {
    UIView *card = [self es_cardContainer];
    UIStackView *v = [[UIStackView alloc] init];
    v.axis = UILayoutConstraintAxisVertical;
    v.spacing = 0;
    v.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *sec = [self es_secondarySectionTitle:@"订单"];
    UIStackView *secPad = [[UIStackView alloc] initWithArrangedSubviews:@[ sec ]];
    secPad.layoutMargins = UIEdgeInsetsMake(12, 16, 6, 16);
    secPad.layoutMarginsRelativeArrangement = YES;

    NSArray<NSString *> *statuses = @[ @"待付款", @"待发货", @"待收货", @"待评价", @"退款/售后" ];
    UIScrollView *hscroll = [UIScrollView new];
    hscroll.translatesAutoresizingMaskIntoConstraints = NO;
    hscroll.showsHorizontalScrollIndicator = NO;
    hscroll.delaysContentTouches = NO;
    hscroll.canCancelContentTouches = YES;
    UIStackView *pills = [[UIStackView alloc] init];
    pills.axis = UILayoutConstraintAxisHorizontal;
    pills.spacing = 20;
    pills.translatesAutoresizingMaskIntoConstraints = NO;
    pills.layoutMargins = UIEdgeInsetsMake(10, 16, 10, 16);
    pills.layoutMarginsRelativeArrangement = YES;

    for (NSUInteger i = 0; i < statuses.count; i++) {
        NSString *st = statuses[i];
        // 与 Swift `orderPill` + `.buttonStyle(.plain)` 一致：整块区域可点；勿用仅 center 的 UIButton，否则宽 52 时文字溢出、点不到
        UIView *pillWrap = [UIView new];
        pillWrap.translatesAutoresizingMaskIntoConstraints = NO;
        pillWrap.tag = (NSInteger)i;
        pillWrap.userInteractionEnabled = YES;
        UITapGestureRecognizer *pillTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(es_onTapOrderPillWrap:)];
        [pillWrap addGestureRecognizer:pillTap];

        UILabel *cnt = [UILabel new];
        cnt.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        cnt.textAlignment = NSTextAlignmentCenter;
        cnt.text = @"0";
        [_pillCounts addObject:cnt];

        UILabel *ttl = [UILabel new];
        ttl.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
        ttl.textAlignment = NSTextAlignmentCenter;
        ttl.text = st;
        ttl.numberOfLines = 1;

        UIStackView *pill = [[UIStackView alloc] initWithArrangedSubviews:@[ cnt, ttl ]];
        pill.axis = UILayoutConstraintAxisVertical;
        pill.spacing = 4;
        pill.alignment = UIStackViewAlignmentCenter;
        pill.translatesAutoresizingMaskIntoConstraints = NO;
        [pillWrap addSubview:pill];
        [NSLayoutConstraint activateConstraints:@[
            [pill.topAnchor constraintEqualToAnchor:pillWrap.topAnchor constant:8],
            [pill.bottomAnchor constraintEqualToAnchor:pillWrap.bottomAnchor constant:-8],
            [pill.leadingAnchor constraintEqualToAnchor:pillWrap.leadingAnchor constant:12],
            [pill.trailingAnchor constraintEqualToAnchor:pillWrap.trailingAnchor constant:-12],
            [pillWrap.heightAnchor constraintGreaterThanOrEqualToConstant:56],
            [pillWrap.widthAnchor constraintGreaterThanOrEqualToConstant:72]
        ]];
        [pills addArrangedSubview:pillWrap];
    }

    [hscroll addSubview:pills];
    [NSLayoutConstraint activateConstraints:@[
        [pills.topAnchor constraintEqualToAnchor:hscroll.contentLayoutGuide.topAnchor],
        [pills.leadingAnchor constraintEqualToAnchor:hscroll.contentLayoutGuide.leadingAnchor],
        [pills.trailingAnchor constraintEqualToAnchor:hscroll.contentLayoutGuide.trailingAnchor],
        [pills.bottomAnchor constraintEqualToAnchor:hscroll.contentLayoutGuide.bottomAnchor],
        [pills.heightAnchor constraintEqualToAnchor:hscroll.frameLayoutGuide.heightAnchor]
    ]];

    UIView *line = [UIView new];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        line.backgroundColor = UIColor.separatorColor;
    } else {
        line.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
    }
    [line.heightAnchor constraintEqualToConstant:1.0 / [UIScreen mainScreen].scale].active = YES;

    // 标题靠左、箭头靠右：勿用 ForceRightToLeft（会把整块内容挤到右侧）
    UILabel *moTitle = [UILabel new];
    moTitle.translatesAutoresizingMaskIntoConstraints = NO;
    moTitle.text = @"我的订单";
    moTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    if (@available(iOS 13.0, *)) {
        moTitle.textColor = UIColor.labelColor;
    } else {
        moTitle.textColor = UIColor.darkTextColor;
    }
    UIView *moSpacer = [UIView new];
    moSpacer.translatesAutoresizingMaskIntoConstraints = NO;
    [moSpacer setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    UIStackView *moRow = [[UIStackView alloc] initWithArrangedSubviews:@[ moTitle, moSpacer ]];
    moRow.axis = UILayoutConstraintAxisHorizontal;
    moRow.alignment = UIStackViewAlignmentCenter;
    moRow.spacing = 8;
    moRow.translatesAutoresizingMaskIntoConstraints = NO;
    moRow.layoutMargins = UIEdgeInsetsMake(16, 16, 16, 16);
    moRow.layoutMarginsRelativeArrangement = YES;
    moRow.userInteractionEnabled = YES;
    [moRow addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(es_onTapMyOrdersRow:)]];
    UIImage *chImg = ESSystemImage(@"chevron.right");
    if (chImg) {
        UIImageView *chev = [[UIImageView alloc] initWithImage:[chImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        chev.translatesAutoresizingMaskIntoConstraints = NO;
        chev.contentMode = UIViewContentModeScaleAspectFit;
        if (@available(iOS 13.0, *)) {
            chev.tintColor = [UIColor colorWithWhite:0.55 alpha:1];
        }
        [moRow addArrangedSubview:chev];
        [chev.widthAnchor constraintEqualToConstant:11].active = YES;
        [chev.heightAnchor constraintEqualToConstant:14].active = YES;
    } else {
        UILabel *chevText = [UILabel new];
        chevText.text = @"›";
        chevText.font = [UIFont systemFontOfSize:20 weight:UIFontWeightRegular];
        chevText.textColor = [UIColor colorWithWhite:0.55 alpha:1];
        [moRow addArrangedSubview:chevText];
    }

    [v addArrangedSubview:secPad];
    [v addArrangedSubview:hscroll];
    [v addArrangedSubview:line];
    [v addArrangedSubview:moRow];

    // 与内容高度一致：上下 layoutMargins 各 10 + 胶囊至少 56，避免裁切导致点不到
    [hscroll.heightAnchor constraintEqualToConstant:80].active = YES;

    [card addSubview:v];
    [NSLayoutConstraint activateConstraints:@[
        [v.topAnchor constraintEqualToAnchor:card.topAnchor],
        [v.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [v.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [v.bottomAnchor constraintEqualToAnchor:card.bottomAnchor]
    ]];
    return card;
}

- (void)es_refreshOrderPillCounts {
    NSArray<NSString *> *statuses = @[ @"待付款", @"待发货", @"待收货", @"待评价", @"退款/售后" ];
    for (NSUInteger i = 0; i < _pillCounts.count && i < statuses.count; i++) {
        NSUInteger n = [ESStore.shared orderCountForStatus:statuses[i]];
        _pillCounts[i].text = [NSString stringWithFormat:@"%lu", (unsigned long)n];
    }
}

- (void)es_onTapOrderPillWrap:(UITapGestureRecognizer *)g {
    UIView *wrap = g.view;
    if (wrap.tag < 0) {
        return;
    }
    NSUInteger idx = (NSUInteger)wrap.tag;
    NSArray<NSString *> *statuses = @[ @"待付款", @"待发货", @"待收货", @"待评价", @"退款/售后" ];
    if (idx >= statuses.count) {
        return;
    }
    NSString *st = statuses[idx];
    ESOrdersByStatusViewController *vc = [[ESOrdersByStatusViewController alloc] initWithOrderStatus:st title:st];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)es_onTapMyOrdersRow:(UITapGestureRecognizer *)gr {
    (void)gr;
    [self es_openMyOrders];
}

- (void)es_openMyOrders {
    [self.navigationController pushViewController:[[ESOrderListViewController alloc] initWithStyle:ESGroupedInsetStyle()] animated:YES];
}

- (UIButton *)es_featureButtonTitle:(NSString *)title symbol:(NSString *)sym {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeading;
    b.contentEdgeInsets = UIEdgeInsetsMake(16, 16, 16, 16);
    UIImage *img = ESSystemImage(sym);
    if (img) {
        img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [b setImage:img forState:UIControlStateNormal];
        b.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
        b.imageEdgeInsets = UIEdgeInsetsMake(0, -2, 0, 0);
    }
    [b setTitle:title forState:UIControlStateNormal];
    if (@available(iOS 13.0, *)) {
        [b setTitleColor:UIColor.labelColor forState:UIControlStateNormal];
    } else {
        [b setTitleColor:UIColor.darkTextColor forState:UIControlStateNormal];
    }
    return b;
}

- (UIView *)es_featuresCard {
    UIView *card = [self es_cardContainer];
    UIStackView *v = [[UIStackView alloc] init];
    v.axis = UILayoutConstraintAxisVertical;
    v.spacing = 0;
    v.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *sec = [self es_secondarySectionTitle:@"功能"];
    UIStackView *secPad = [[UIStackView alloc] initWithArrangedSubviews:@[ sec ]];
    secPad.layoutMargins = UIEdgeInsetsMake(12, 16, 6, 16);
    secPad.layoutMarginsRelativeArrangement = YES;

    UIButton *addr = [self es_featureButtonTitle:@"地址管理" symbol:@"location"];
    [addr addTarget:self action:@selector(es_openAddresses) forControlEvents:UIControlEventTouchUpInside];
    UIButton *fav = [self es_featureButtonTitle:@"我的收藏" symbol:@"heart"];
    [fav addTarget:self action:@selector(es_openFavoritesTab) forControlEvents:UIControlEventTouchUpInside];
    UIButton *set = [self es_featureButtonTitle:@"设置" symbol:@"gearshape"];
    [set addTarget:self action:@selector(es_openSettingsPlaceholder) forControlEvents:UIControlEventTouchUpInside];

    UIView *d1 = [self es_hairline];
    UIView *d2 = [self es_hairline];

    [v addArrangedSubview:secPad];
    [v addArrangedSubview:addr];
    [v addArrangedSubview:d1];
    [v addArrangedSubview:fav];
    [v addArrangedSubview:d2];
    [v addArrangedSubview:set];

    [card addSubview:v];
    [NSLayoutConstraint activateConstraints:@[
        [v.topAnchor constraintEqualToAnchor:card.topAnchor],
        [v.leadingAnchor constraintEqualToAnchor:card.leadingAnchor],
        [v.trailingAnchor constraintEqualToAnchor:card.trailingAnchor],
        [v.bottomAnchor constraintEqualToAnchor:card.bottomAnchor]
    ]];
    return card;
}

- (UIView *)es_hairline {
    UIView *line = [UIView new];
    line.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        line.backgroundColor = UIColor.separatorColor;
    } else {
        line.backgroundColor = [UIColor colorWithWhite:0.88 alpha:1];
    }
    [line.heightAnchor constraintEqualToConstant:1.0 / [UIScreen mainScreen].scale].active = YES;
    return line;
}

- (void)es_openAddresses {
    [self.navigationController pushViewController:[[ESAddressListViewController alloc] initWithStyle:ESGroupedInsetStyle()] animated:YES];
}

- (void)es_openFavoritesTab {
    self.tabBarController.selectedIndex = 1;
}

- (void)es_openSettingsPlaceholder {
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:@"应用设置功能待实现" preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:ac animated:YES completion:nil];
}

/// 与 Swift `MainTabView` 注入 `onLogout` 一致；若未设置 weak root，从父链查找根 `ViewController`
- (nullable ViewController *)es_profileAppRoot {
    if (self.root) {
        return self.root;
    }
    UIViewController *vc = self.parentViewController;
    while (vc) {
        if ([vc isKindOfClass:[ViewController class]]) {
            return (ViewController *)vc;
        }
        vc = vc.parentViewController;
    }
    return nil;
}

- (void)es_logout {
    [ESStore.shared logout];
    ViewController *r = [self es_profileAppRoot];
    if (r) {
        [r showAuth];
    }
}

@end

#pragma mark - TabBar 图标（iOS 11 无 SF Symbol，自绘模板图；与 example BottomBar 配色一致）

typedef NS_ENUM(NSInteger, ESDrawableTabKind) {
    ESDrawableTabKindHome = 0,
    ESDrawableTabKindHeart,
    ESDrawableTabKindCart,
    ESDrawableTabKindPerson,
};

/// 自绘单色图标，AlwaysTemplate 供 tintColor / unselectedItemTintColor 着色
static UIImage *ESDrawableTabImage(ESDrawableTabKind kind, BOOL filled) {
    static const CGFloat kS = 25.0;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(kS, kS), NO, 0);

    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineCapStyle = kCGLineCapRound;
    path.lineJoinStyle = kCGLineJoinRound;

    switch (kind) {
        case ESDrawableTabKindHome: {
            [path moveToPoint:CGPointMake(12.5, 4.5)];
            [path addLineToPoint:CGPointMake(4.5, 12.5)];
            [path addLineToPoint:CGPointMake(7, 12.5)];
            [path addLineToPoint:CGPointMake(7, 20.5)];
            [path addLineToPoint:CGPointMake(18, 20.5)];
            [path addLineToPoint:CGPointMake(18, 12.5)];
            [path addLineToPoint:CGPointMake(20.5, 12.5)];
            [path closePath];
            break;
        }
        case ESDrawableTabKindHeart: {
            [path moveToPoint:CGPointMake(12.5, 21)];
            [path addCurveToPoint:CGPointMake(4.5, 12) controlPoint1:CGPointMake(12.5, 17) controlPoint2:CGPointMake(4.5, 15.5)];
            [path addArcWithCenter:CGPointMake(8.5, 10.5) radius:3.2 startAngle:(CGFloat)M_PI endAngle:0 clockwise:YES];
            [path addArcWithCenter:CGPointMake(16.5, 10.5) radius:3.2 startAngle:(CGFloat)M_PI endAngle:0 clockwise:YES];
            [path addCurveToPoint:CGPointMake(12.5, 21) controlPoint1:CGPointMake(20.5, 15.5) controlPoint2:CGPointMake(12.5, 17)];
            [path closePath];
            break;
        }
        case ESDrawableTabKindCart: {
            [path moveToPoint:CGPointMake(7, 9.5)];
            [path addLineToPoint:CGPointMake(18, 9.5)];
            [path addLineToPoint:CGPointMake(19.5, 12)];
            [path addLineToPoint:CGPointMake(18.5, 19.5)];
            [path addLineToPoint:CGPointMake(6.5, 19.5)];
            [path addLineToPoint:CGPointMake(5.5, 12)];
            [path closePath];
            if (filled) {
                [[UIColor blackColor] setFill];
                [path fill];
            } else {
                path.lineWidth = 1.6;
                [[UIColor blackColor] setStroke];
                [path stroke];
            }
            UIBezierPath *handle = [UIBezierPath bezierPath];
            [handle moveToPoint:CGPointMake(18, 9.5)];
            [handle addQuadCurveToPoint:CGPointMake(20.5, 7) controlPoint:CGPointMake(20, 8)];
            handle.lineWidth = filled ? 2.0 : 1.6;
            [[UIColor blackColor] setStroke];
            [handle stroke];
            UIBezierPath *w1 = [UIBezierPath bezierPathWithArcCenter:CGPointMake(9, 20.5) radius:1.6 startAngle:0 endAngle:(CGFloat)(M_PI * 2) clockwise:YES];
            UIBezierPath *w2 = [UIBezierPath bezierPathWithArcCenter:CGPointMake(16, 20.5) radius:1.6 startAngle:0 endAngle:(CGFloat)(M_PI * 2) clockwise:YES];
            if (filled) {
                [[UIColor blackColor] setFill];
                [w1 fill];
                [w2 fill];
            } else {
                w1.lineWidth = w2.lineWidth = 1.5;
                [[UIColor blackColor] setStroke];
                [w1 stroke];
                [w2 stroke];
            }
            UIImage *cartImg = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return [cartImg imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
        case ESDrawableTabKindPerson:
        default: {
            UIBezierPath *head = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(8.5, 4.5, 8, 8)];
            UIBezierPath *body = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(5.5, 14, 14, 10) cornerRadius:5];
            if (filled) {
                [[UIColor blackColor] setFill];
                [head fill];
                [body fill];
            } else {
                head.lineWidth = body.lineWidth = 1.6;
                [[UIColor blackColor] setStroke];
                [head stroke];
                [body stroke];
            }
            UIImage *raw = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return [raw imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
    }

    if (filled) {
        [[UIColor blackColor] setFill];
        [path fill];
    } else {
        path.lineWidth = 1.6;
        [[UIColor blackColor] setStroke];
        [path stroke];
    }

    UIImage *raw = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [raw imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

static void ESTabBarApplyItemImages(UITabBarItem *item, NSString *symOutline, NSString *symFill, ESDrawableTabKind fallback) {
    UIImage *o = ESSystemImage(symOutline);
    UIImage *f = ESSystemImage(symFill);
    if (o && f) {
        item.image = [o imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        item.selectedImage = [f imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } else {
        item.image = ESDrawableTabImage(fallback, NO);
        item.selectedImage = ESDrawableTabImage(fallback, YES);
    }
}

@implementation ESRootTabBarController {
    CALayer *_tabHairline;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tabBar.tintColor = ESTabBarSelectedColor();
    self.tabBar.unselectedItemTintColor = ESTabBarUnselectedColor();
    self.tabBar.translucent = NO;
    self.tabBar.barTintColor = ESTabBarBackgroundColor();

    UINavigationController *home = [[UINavigationController alloc] initWithRootViewController:[ESHomeViewController new]];
    home.tabBarItem.title = @"首页";
    ESTabBarApplyItemImages(home.tabBarItem, @"house", @"house.fill", ESDrawableTabKindHome);

    UINavigationController *fav = [[UINavigationController alloc] initWithRootViewController:[ESFavoriteViewController new]];
    fav.tabBarItem.title = @"收藏";
    ESTabBarApplyItemImages(fav.tabBarItem, @"heart", @"heart.fill", ESDrawableTabKindHeart);

    UINavigationController *cart = [[UINavigationController alloc] initWithRootViewController:[ESCartViewController new]];
    cart.tabBarItem.title = @"购物车";
    ESTabBarApplyItemImages(cart.tabBarItem, @"cart", @"cart.fill", ESDrawableTabKindCart);

    ESProfileViewController *pro = [ESProfileViewController new];
    pro.root = self.root;
    UINavigationController *profile = [[UINavigationController alloc] initWithRootViewController:pro];
    profile.tabBarItem.title = @"我的";
    ESTabBarApplyItemImages(profile.tabBarItem, @"person", @"person.fill", ESDrawableTabKindPerson);

    self.viewControllers = @[ home, fav, cart, profile ];

    _tabHairline = [CALayer layer];
    _tabHairline.backgroundColor = ESTabBarTopBorderColor().CGColor;
    [self.tabBar.layer addSublayer:_tabHairline];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat h = 1.0 / [UIScreen mainScreen].scale;
    _tabHairline.frame = CGRectMake(0, 0, CGRectGetWidth(self.tabBar.bounds), h);
}

@end
