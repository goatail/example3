//
//  ESCompatibility.h
//  example3
//
//  iOS 11 最低版本兼容：颜色、图片、列表样式（避免使用仅 iOS 13+ API）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 与系统背景色一致：iOS 13+ 用 systemBackground，否则白色
static inline UIColor *ESBackgroundColor(void) {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemBackgroundColor;
    }
    return UIColor.whiteColor;
}

/// 价格等强调色：iOS 13+ 用 systemRed，否则 red
static inline UIColor *ESPriceColor(void) {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemRedColor;
    }
    return UIColor.redColor;
}

/// SF Symbol 仅 iOS 13+；低版本返回 nil（Tab 图标由 `ESRootTabBarController` 自绘模板图兜底）
static inline UIImage *_Nullable ESSystemImage(NSString *name) {
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:name];
    }
    return nil;
}

/// iOS 13+ 使用 inset grouped，iOS 11–12 使用 grouped
static inline UITableViewStyle ESGroupedInsetStyle(void) {
    if (@available(iOS 13.0, *)) {
        return UITableViewStyleInsetGrouped;
    }
    return UITableViewStyleGrouped;
}

// MARK: - 底部 Tab（与 Swift `AppColors.bottomNav*` 一致，供 UITabBar 与自定义栏使用）

/// 选中：主色 #599e5e
static inline UIColor *ESTabBarSelectedColor(void) {
    return [UIColor colorWithRed:89.0 / 255.0 green:158.0 / 255.0 blue:94.0 / 255.0 alpha:1.0];
}

/// 未选中图标/文字 #383a42
static inline UIColor *ESTabBarUnselectedColor(void) {
    return [UIColor colorWithRed:56.0 / 255.0 green:58.0 / 255.0 blue:66.0 / 255.0 alpha:1.0];
}

/// 底栏背景，接近 `FAFFFFFF`（近白、略透）
static inline UIColor *ESTabBarBackgroundColor(void) {
    return [UIColor colorWithRed:1 green:1 blue:1 alpha:250.0 / 255.0];
}

/// 顶部分割线 #E0E0E1
static inline UIColor *ESTabBarTopBorderColor(void) {
    return [UIColor colorWithRed:224.0 / 255.0 green:224.0 / 255.0 blue:225.0 / 255.0 alpha:1.0];
}

NS_ASSUME_NONNULL_END
