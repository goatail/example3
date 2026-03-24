//
//  ESStore.m
//  example3
//

#import "ESStore.h"
#import "ESDataGenerator.h"

@implementation ESProduct
@end

@implementation ESAddress
- (NSString *)fullAddressString {
    return [NSString stringWithFormat:@"%@%@%@%@", self.province ?: @"", self.city ?: @"", self.district ?: @"", self.detail ?: @""];
}
- (NSString *)fullText {
    NSString *s = [self fullAddressString];
    if (s.length > 0) {
        return s;
    }
    return [NSString stringWithFormat:@"%@ %@", self.city ?: @"", self.detail ?: @""];
}
- (NSString *)displayText {
    return [NSString stringWithFormat:@"%@ %@\n%@", self.name ?: @"", self.phone ?: @"", self.fullText];
}
@end

@implementation ESOrderLineItem
- (double)lineTotal {
    return self.unitPrice * (double)MAX(0, self.quantity);
}
@end

@implementation ESOrder
@end

@implementation ESStore

+ (instancetype)shared {
    static ESStore *s;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s = [[ESStore alloc] init];
    });
    return s;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _favoriteIds = [NSMutableSet set];
        _cart = [NSMutableDictionary dictionary];
        _addresses = [NSMutableArray array];
        _orders = [NSMutableArray array];
        _users = [NSMutableDictionary dictionary];
        _products = [self buildMockProducts];
    }
    return self;
}

- (NSArray<ESProduct *> *)buildMockProducts {
    return ESDataGeneratorAllProducts();
}

- (void)bootstrap {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    NSDictionary *savedUsers = [ud objectForKey:@"es_users"];
    if (savedUsers) {
        [self.users addEntriesFromDictionary:savedUsers];
    }
    if (!self.users[@"admin"]) {
        self.users[@"admin"] = @{@"pass": @"admin", @"phone": @"18800000000"};
    }
    self.currentUser = [ud stringForKey:@"es_user"];
    self.currentPhone = [ud stringForKey:@"es_phone"];
    NSArray *f = [ud objectForKey:@"es_fav"];
    if ([f isKindOfClass:NSArray.class]) {
        [self.favoriteIds addObjectsFromArray:f];
    }
    NSArray *a = [ud objectForKey:@"es_addr"];
    for (NSDictionary *d in a) {
        ESAddress *addr = [ESAddress new];
        addr.aid = d[@"id"];
        addr.name = d[@"name"];
        addr.phone = d[@"phone"];
        addr.province = d[@"prov"] ?: @"";
        addr.city = d[@"city"];
        addr.district = d[@"dist"] ?: @"";
        addr.detail = d[@"detail"];
        addr.isDefault = [d[@"def"] boolValue];
        [self.addresses addObject:addr];
    }
    if (self.addresses.count == 0) {
        ESAddress *def = [ESAddress new];
        def.aid = @"addr_default";
        def.name = @"张三";
        def.phone = @"13800138000";
        def.province = @"北京市";
        def.city = @"市辖区";
        def.district = @"朝阳区";
        def.detail = @"中关村大街1号";
        def.isDefault = YES;
        [self.addresses addObject:def];
        [self persist];
    }
    NSArray *ordSaved = [ud objectForKey:@"es_orders"];
    if ([ordSaved isKindOfClass:NSArray.class]) {
        for (NSDictionary *d in ordSaved) {
            ESOrder *o = [ESOrder new];
            o.oid = d[@"id"] ?: @"";
            o.status = d[@"status"] ?: @"";
            o.summary = d[@"summary"] ?: @"";
            o.total = [d[@"total"] doubleValue];
            o.createTime = [d[@"time"] doubleValue];
            o.addressDisplayText = d[@"addr"] ?: @"";
            NSMutableArray<ESOrderLineItem *> *lines = [NSMutableArray array];
            NSArray *rawItems = d[@"items"];
            if ([rawItems isKindOfClass:NSArray.class]) {
                for (NSDictionary *it in rawItems) {
                    ESOrderLineItem *li = [ESOrderLineItem new];
                    li.pid = it[@"pid"] ?: @"";
                    li.productTitle = it[@"title"] ?: @"";
                    li.quantity = [it[@"qty"] integerValue];
                    li.unitPrice = [it[@"price"] doubleValue];
                    [lines addObject:li];
                }
            }
            o.items = lines.copy;
            [self.orders addObject:o];
        }
    }
}

- (void)persist {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    [ud setObject:self.users.copy forKey:@"es_users"];
    [ud setObject:self.currentUser forKey:@"es_user"];
    [ud setObject:self.currentPhone forKey:@"es_phone"];
    [ud setObject:self.favoriteIds.allObjects forKey:@"es_fav"];
    NSMutableArray *arr = [NSMutableArray array];
    for (ESAddress *a in self.addresses) {
        [arr addObject:@{
            @"id": a.aid ?: @"",
            @"name": a.name ?: @"",
            @"phone": a.phone ?: @"",
            @"prov": a.province ?: @"",
            @"city": a.city ?: @"",
            @"dist": a.district ?: @"",
            @"detail": a.detail ?: @"",
            @"def": @(a.isDefault)
        }];
    }
    [ud setObject:arr.copy forKey:@"es_addr"];
    NSMutableArray *ordOut = [NSMutableArray array];
    for (ESOrder *o in self.orders) {
        NSMutableArray *items = [NSMutableArray array];
        for (ESOrderLineItem *li in o.items) {
            [items addObject:@{
                @"pid": li.pid ?: @"",
                @"title": li.productTitle ?: @"",
                @"qty": @(li.quantity),
                @"price": @(li.unitPrice)
            }];
        }
        [ordOut addObject:@{
            @"id": o.oid ?: @"",
            @"status": o.status ?: @"",
            @"summary": o.summary ?: @"",
            @"total": @(o.total),
            @"time": @(o.createTime),
            @"addr": o.addressDisplayText ?: @"",
            @"items": items.copy
        }];
    }
    [ud setObject:ordOut.copy forKey:@"es_orders"];
}

- (BOOL)isLoggedIn {
    return self.currentUser.length > 0;
}

- (BOOL)registerUser:(NSString *)user phone:(NSString *)phone pass:(NSString *)pass message:(NSString **)msg {
    if (user.length == 0 || phone.length == 0 || pass.length == 0) {
        if (msg) {
            *msg = @"请填写完整信息";
        }
        return NO;
    }
    if (self.users[user]) {
        if (msg) {
            *msg = @"用户名已存在";
        }
        return NO;
    }
    self.users[user] = @{@"pass": pass, @"phone": phone};
    [self persist];
    if (msg) {
        *msg = @"注册成功";
    }
    return YES;
}

- (BOOL)login:(NSString *)user pass:(NSString *)pass message:(NSString **)msg {
    NSDictionary *u = self.users[user];
    if (!u || ![u[@"pass"] isEqualToString:pass]) {
        if (msg) {
            *msg = @"用户名或密码错误";
        }
        return NO;
    }
    self.currentUser = user;
    self.currentPhone = u[@"phone"];
    [self persist];
    if (msg) {
        *msg = @"登录成功";
    }
    return YES;
}

- (void)logout {
    self.currentUser = nil;
    self.currentPhone = nil;
    [self persist];
}

- (NSArray<ESProduct *> *)productsForCategory:(NSString *)category keyword:(NSString *)keyword {
    NSString *kw = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSPredicate *p = [NSPredicate predicateWithBlock:^BOOL(ESProduct *obj, NSDictionary<NSString *, id> *_Nullable b) {
        BOOL c = category.length == 0 || [obj.category isEqualToString:category];
        if (!c) {
            return NO;
        }
        if (kw.length == 0) {
            return YES;
        }
        return [obj.title localizedCaseInsensitiveContainsString:kw] || [obj.category localizedCaseInsensitiveContainsString:kw] ||
               [obj.shortName localizedCaseInsensitiveContainsString:kw] || [obj.detailText localizedCaseInsensitiveContainsString:kw] ||
               [obj.brand localizedCaseInsensitiveContainsString:kw] || [obj.sellerName localizedCaseInsensitiveContainsString:kw];
    }];
    return [self.products filteredArrayUsingPredicate:p];
}

- (ESProduct *)productById:(NSString *)pid {
    for (ESProduct *p in self.products) {
        if ([p.pid isEqualToString:pid]) {
            return p;
        }
    }
    return nil;
}

- (BOOL)isFavorite:(NSString *)pid {
    return [self.favoriteIds containsObject:pid];
}

- (void)toggleFavorite:(NSString *)pid {
    if ([self.favoriteIds containsObject:pid]) {
        [self.favoriteIds removeObject:pid];
    } else {
        [self.favoriteIds addObject:pid];
    }
    [self persist];
}

- (void)addToCart:(NSString *)pid count:(NSInteger)count {
    NSInteger n = MAX(0, [self.cart[pid] integerValue] + count);
    if (n == 0) {
        [self.cart removeObjectForKey:pid];
    } else {
        self.cart[pid] = @(n);
    }
}

- (NSInteger)cartCountFor:(NSString *)pid {
    return [self.cart[pid] integerValue];
}

- (double)cartTotalPrice {
    double t = 0;
    for (NSString *pid in self.cart) {
        t += [self productById:pid].price * [self.cart[pid] integerValue];
    }
    return t;
}

- (NSArray<ESProduct *> *)favoriteProducts {
    return [self.products filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(ESProduct *o, NSDictionary *b) {
        return [self.favoriteIds containsObject:o.pid];
    }]];
}

- (NSArray<ESProduct *> *)cartProducts {
    return [self.products filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(ESProduct *o, NSDictionary *b) {
        return self.cart[o.pid] != nil;
    }]];
}

- (ESAddress *)defaultAddress {
    for (ESAddress *a in self.addresses) {
        if (a.isDefault) {
            return a;
        }
    }
    return self.addresses.firstObject;
}

- (void)saveAddress:(ESAddress *)addr {
    if (addr.isDefault) {
        for (ESAddress *a in self.addresses) {
            a.isDefault = NO;
        }
        addr.isDefault = YES;
    }
    if (addr.aid.length == 0) {
        addr.aid = [NSUUID UUID].UUIDString;
        [self.addresses addObject:addr];
    }
    [self persist];
}

- (void)deleteAddress:(ESAddress *)addr {
    [self.addresses removeObject:addr];
    if (self.addresses.count && ![self defaultAddress]) {
        self.addresses.firstObject.isDefault = YES;
    }
    [self persist];
}

- (void)submitOrderWithAddress:(ESAddress *)addr success:(BOOL *)success message:(NSString **)msg {
    [self submitOrderWithAddress:addr orderTotal:[self cartTotalPrice] success:success message:msg];
}

- (void)submitOrderWithAddress:(ESAddress *)addr orderTotal:(double)orderTotal success:(BOOL *)success message:(NSString **)msg {
    if (self.cart.count == 0) {
        if (success) {
            *success = NO;
        }
        if (msg) {
            *msg = @"购物车为空";
        }
        return;
    }
    if (!addr) {
        if (success) {
            *success = NO;
        }
        if (msg) {
            *msg = @"请选择收货地址";
        }
        return;
    }
    NSMutableArray<ESOrderLineItem *> *lines = [NSMutableArray array];
    NSMutableString *sumParts = [NSMutableString string];
    for (NSString *pid in [self.cart.allKeys copy]) {
        NSInteger qty = [self.cart[pid] integerValue];
        if (qty <= 0) {
            continue;
        }
        ESProduct *p = [self productById:pid];
        if (!p) {
            continue;
        }
        ESOrderLineItem *li = [ESOrderLineItem new];
        li.pid = pid;
        li.productTitle = p.title ?: @"";
        li.quantity = qty;
        li.unitPrice = p.price;
        [lines addObject:li];
        if (sumParts.length) {
            [sumParts appendString:@"、"];
        }
        [sumParts appendString:(p.title ?: @"")];
    }
    ESOrder *o = [ESOrder new];
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *hex = [[uuid stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
    NSString *head = (hex.length >= 8) ? [hex substringToIndex:8] : hex;
    o.oid = [NSString stringWithFormat:@"ORD_%@", head];
    o.total = orderTotal;
    o.status = @"待发货";
    o.createTime = [[NSDate date] timeIntervalSince1970];
    o.items = lines.copy;
    o.addressDisplayText = [addr displayText];
    o.summary = [NSString stringWithFormat:@"%@，共%lu件", sumParts, (unsigned long)lines.count];
    [self.orders insertObject:o atIndex:0];
    [self.cart removeAllObjects];
    [self persist];
    if (success) {
        *success = YES;
    }
    if (msg) {
        *msg = @"订单提交成功";
    }
}

- (NSArray<ESOrder *> *)ordersByStatus:(NSString *)status keyword:(NSString *)keyword {
    NSString *kw = [keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSPredicate *p = [NSPredicate predicateWithBlock:^BOOL(ESOrder *o, NSDictionary *b) {
        BOOL s = status.length == 0 || [o.status isEqualToString:status];
        if (!s) {
            return NO;
        }
        if (kw.length == 0) {
            return YES;
        }
        if ([o.oid localizedCaseInsensitiveContainsString:kw] || [o.summary localizedCaseInsensitiveContainsString:kw] ||
            [o.addressDisplayText localizedCaseInsensitiveContainsString:kw]) {
            return YES;
        }
        for (ESOrderLineItem *li in o.items) {
            if ([li.productTitle localizedCaseInsensitiveContainsString:kw]) {
                return YES;
            }
        }
        return NO;
    }];
    return [self.orders filteredArrayUsingPredicate:p];
}

- (NSUInteger)orderCountForStatus:(NSString *)status {
    return [self ordersByStatus:status ?: @"" keyword:@""].count;
}

static NSString *const kESLastSearchKeyword = @"es_last_search_keyword";

- (NSArray<ESProduct *> *)searchProductsWithKeywordTrimmed:(NSString *)keyword {
    NSString *kw = [[keyword stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    if (kw.length == 0) {
        return self.products;
    }
    NSMutableArray<ESProduct *> *out = [NSMutableArray array];
    for (ESProduct *p in self.products) {
        if ([p.title.lowercaseString containsString:kw] || [p.shortName.lowercaseString containsString:kw] ||
            [p.detailText.lowercaseString containsString:kw] || [p.category.lowercaseString containsString:kw] ||
            [p.brand.lowercaseString containsString:kw] || [p.sellerName.lowercaseString containsString:kw]) {
            [out addObject:p];
        }
    }
    return out.copy;
}

+ (NSString *)lastDisplayedSearchKeyword {
    return [NSUserDefaults.standardUserDefaults stringForKey:kESLastSearchKeyword];
}

+ (void)setLastDisplayedSearchKeyword:(NSString *)kw {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    if (kw.length) {
        [ud setObject:kw forKey:kESLastSearchKeyword];
    } else {
        [ud removeObjectForKey:kESLastSearchKeyword];
    }
}

@end
