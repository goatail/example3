//
//  ESAppControllers.h
//  example3
//
//  除根控制器外的业务界面控制器（与 ESStore、ViewController 协作）
//

#import <UIKit/UIKit.h>

@class ViewController;
@class ESProduct;
@class ESAddress;

NS_ASSUME_NONNULL_BEGIN

void ESAlert(UIViewController *vc, NSString *msg);

@interface ESRegisterViewController : UIViewController
@end

@interface ESLoginViewController : UIViewController
@property (nonatomic, weak) ViewController *root;
@end

@interface ESProductDetailViewController : UIViewController
- (instancetype)initWithProduct:(ESProduct *)product;
/// 加购弹窗点「去结算」时回调（首页可切到购物车 Tab）
@property (nonatomic, copy, nullable) void (^onGoToCartTab)(void);
@end

@interface ESAddressEditViewController : UIViewController
- (instancetype)initWithAddress:(nullable ESAddress *)addr;
@property (nonatomic, copy, nullable) void (^onSaved)(void);
@end

@interface ESAddressListViewController : UITableViewController
@property (nonatomic, copy, nullable) void (^onSelect)(ESAddress *addr);
@end

@interface ESOrderListViewController : UITableViewController
@end

/// 与 example `OrderListView` 一致：按单一状态展示订单（待付款/待发货/…）
@interface ESOrdersByStatusViewController : UITableViewController
- (instancetype)initWithOrderStatus:(NSString *)status title:(NSString *)title;
@end

/// 全屏搜索（与 example `SearchView` 一致：取消 / 选结果回传关键词；商品区与首页同款双列卡片）
@interface ESSearchViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>
- (instancetype)initWithInitialKeyword:(nullable NSString *)kw;
@property (nonatomic, copy, nullable) void (^onFinish)(NSString *_Nullable keyword);
@end

@interface ESHomeViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@end

@interface ESFavoriteViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@end

@interface ESCheckoutViewController : UITableViewController
/// 全屏结算关闭回调（与 example `CheckoutView.onDismiss` 一致）
@property (nonatomic, copy, nullable) void (^onDismiss)(void);
@end

@interface ESCartViewController : UIViewController
@end

@interface ESProfileViewController : UIViewController
@property (nonatomic, weak) ViewController *root;
@end

@interface ESRootTabBarController : UITabBarController
@property (nonatomic, weak) ViewController *root;
@end

NS_ASSUME_NONNULL_END
