//
//  ESStore.h
//  example3
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ESProduct : NSObject
@property (nonatomic, copy) NSString *pid;
@property (nonatomic, copy) NSString *title;
/// 与 Swift `Product.name` 一致，详情页导航标题优先用此字段
@property (nonatomic, copy) NSString *shortName;
@property (nonatomic, copy) NSString *brand;
@property (nonatomic, copy) NSString *sellerName;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, assign) double price;
/// 与 example 资源名一致（如 mobile_1）；无图时用占位
@property (nonatomic, copy, nullable) NSString *imageAssetName;
/// 与 Swift `transactionCount` 一致，展示时拼接「人付款」
@property (nonatomic, copy) NSString *payCountText;
/// 详情页说明文案（与 Swift `Product.description` 对应）
@property (nonatomic, copy) NSString *detailText;
/// 如「2.3万次浏览」，与 `payCountText` 组合展示
@property (nonatomic, copy) NSString *viewsCountText;
@end

@interface ESAddress : NSObject
@property (nonatomic, copy) NSString *aid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *phone;
/// 省 / 市 / 区，与 example `Address` 一致
@property (nonatomic, copy) NSString *province;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *district;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, assign) BOOL isDefault;
/// 省市区+详细，等同 Swift `fullAddress`
- (NSString *)fullAddressString;
/// 单行展示用（兼容旧代码）
- (NSString *)fullText;
/// 订单/结算展示：姓名 电话 + 换行 + 完整地址
- (NSString *)displayText;
@end

@interface ESOrderLineItem : NSObject
@property (nonatomic, copy) NSString *pid;
@property (nonatomic, copy) NSString *productTitle;
@property (nonatomic, assign) NSInteger quantity;
@property (nonatomic, assign) double unitPrice;
- (double)lineTotal;
@end

@interface ESOrder : NSObject
@property (nonatomic, copy) NSString *oid;
@property (nonatomic, copy) NSString *status;
/// 摘要，用于搜索与旧数据展示
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, assign) double total;
@property (nonatomic, assign) NSTimeInterval createTime;
/// 下单快照，等同 Swift `order.address.displayText`
@property (nonatomic, copy) NSString *addressDisplayText;
@property (nonatomic, copy) NSArray<ESOrderLineItem *> *items;
@end

@interface ESStore : NSObject
@property (nonatomic, strong) NSArray<ESProduct *> *products;
@property (nonatomic, strong) NSMutableSet<NSString *> *favoriteIds;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *cart;
@property (nonatomic, strong) NSMutableArray<ESAddress *> *addresses;
@property (nonatomic, strong) NSMutableArray<ESOrder *> *orders;
@property (nonatomic, copy, nullable) NSString *currentUser;
@property (nonatomic, copy, nullable) NSString *currentPhone;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *users;

+ (instancetype)shared;
- (void)bootstrap;
- (void)persist;
- (BOOL)isLoggedIn;
- (BOOL)registerUser:(NSString *)user phone:(NSString *)phone pass:(NSString *)pass message:(NSString * _Nullable * _Nullable)msg;
- (BOOL)login:(NSString *)user pass:(NSString *)pass message:(NSString * _Nullable * _Nullable)msg;
- (void)logout;
- (NSArray<ESProduct *> *)productsForCategory:(NSString *)category keyword:(NSString *)keyword;
- (nullable ESProduct *)productById:(NSString *)pid;
- (BOOL)isFavorite:(NSString *)pid;
- (void)toggleFavorite:(NSString *)pid;
- (void)addToCart:(NSString *)pid count:(NSInteger)count;
- (NSInteger)cartCountFor:(NSString *)pid;
- (double)cartTotalPrice;
- (NSArray<ESProduct *> *)favoriteProducts;
- (NSArray<ESProduct *> *)cartProducts;
- (nullable ESAddress *)defaultAddress;
- (void)saveAddress:(ESAddress *)addr;
- (void)deleteAddress:(ESAddress *)addr;
/// orderTotal 含运费等与 example `CheckoutView` 实付一致；旧调用可用 `cartTotalPrice` 仅商品小计
- (void)submitOrderWithAddress:(nullable ESAddress *)addr orderTotal:(double)orderTotal success:(BOOL *)success message:(NSString * _Nullable * _Nullable)msg;
- (void)submitOrderWithAddress:(nullable ESAddress *)addr success:(BOOL *)success message:(NSString * _Nullable * _Nullable)msg;
- (NSArray<ESOrder *> *)ordersByStatus:(NSString *)status keyword:(NSString *)keyword;
/// 与 example `OrderManager.getPendingPaymentCount()` 等一致，status 为完整中文状态文案
- (NSUInteger)orderCountForStatus:(NSString *)status;

/// 关键词全局搜商品（trim 后为空则返回全部，与 example `searchByKeyword(nil)` 一致）
- (NSArray<ESProduct *> *)searchProductsWithKeywordTrimmed:(nullable NSString *)keyword;

/// 首页搜索条展示用，对应 Swift `SearchState.lastDisplayedKeyword`
+ (nullable NSString *)lastDisplayedSearchKeyword;
+ (void)setLastDisplayedSearchKeyword:(nullable NSString *)kw;

@end

NS_ASSUME_NONNULL_END
