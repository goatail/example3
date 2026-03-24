//
//  ESDataGenerator.m
//  example3
//
//  逻辑对齐 example/DataGenerator.swift（generateProducts），兼容 iOS 11+
//

#import "ESDataGenerator.h"
#import "ESStore.h"

NSArray<ESProduct *> *ESDataGeneratorAllProducts(void) {
    NSMutableArray<ESProduct *> *products = [NSMutableArray arrayWithCapacity:200];

    NSArray *mImg = @[ @"mobile_1", @"mobile_2", @"mobile_3", @"mobile_4", @"mobile_5", @"mobile_6" ];
    NSArray *mBrand = @[ @"苹果", @"苹果", @"苹果", @"华为", @"华为", @"华为" ];
    NSArray *mTitles = @[
        @"Apple/苹果 17 Pro",
        @"Apple/苹果 17 Air",
        @"Apple/苹果 17",
        @"HUAWEI/华为 Mate 70 Pro 鸿蒙AI 红枫原色影像 超可靠玄武架构 旗舰智能手机-178",
        @"华为nova15 Pro 新品麒麟9系芯片 前后红枫影像 华为直屏鸿蒙手机官方旗舰店正品2127",
        @"华为畅享 80 超能续航玄甲架构双五星超耐摔鸿蒙手机百亿补贴官方",
    ];
    NSArray *mSeller = @[ @"苹果官方旗舰店", @"苹果官方旗舰店", @"苹果官方旗舰店", @"华为官方旗舰店", @"华为官方旗舰店", @"华为官方旗舰店" ];
    NSArray *mViews = @[ @"180万", @"160万" ];
    NSArray *mTrans = @[ @"2万+", @"3万+" ];
    NSArray *mNames = @[ @"苹果 17 Pro", @"苹果 17 Air", @"苹果 17", @"华为 Mate 70 Pro", @"华为 nova15 Pro", @"华为 畅享 80" ];
    NSArray *mDesc = @[
        @"Apple/苹果 17 Pro 支持国补，性能强悍，顶尖的 Pro 拍摄系统，后摄 4800 万",
        @"Apple/苹果 17 Air 支持 eSIM，性能强悍",
        @"Apple/苹果 17，性能强悍",
        @"【晒单享好礼】HUAWEI/华为 Mate 70 Pro 鸿蒙AI 红枫原色影像 超可靠玄武架构 旗舰智能手机-178",
        @"【国家补贴15%】华为nova15 Pro 新品麒麟9系芯片 前后红枫影像 华为直屏鸿蒙手机官方旗舰店正品2127",
        @"华为畅享 80 超能续航玄甲架构双五星超耐摔鸿蒙手机百亿补贴官方",
    ];
    NSArray *mPrice = @[ @8999.0, @6999.0, @7999.0, @6999.0, @5999.0, @2999.0 ];

    for (NSInteger i = 0; i < 35; i++) {
        NSInteger idx = i % (NSInteger)mTitles.count;
        ESProduct *p = [ESProduct new];
        p.pid = [NSString stringWithFormat:@"phone%ld", (long)i];
        p.title = mTitles[(NSUInteger)idx];
        p.shortName = mNames[(NSUInteger)idx];
        p.sellerName = mSeller[(NSUInteger)(idx % (NSInteger)mSeller.count)];
        p.brand = mBrand[(NSUInteger)idx];
        p.category = @"手机";
        p.imageAssetName = mImg[(NSUInteger)(i % (NSInteger)mImg.count)];
        p.viewsCountText = [NSString stringWithFormat:@"%@浏览", mViews[(NSUInteger)(i % (NSInteger)mViews.count)]];
        p.payCountText = mTrans[(NSUInteger)(i % (NSInteger)mTrans.count)];
        p.detailText = mDesc[(NSUInteger)idx];
        p.price = [mPrice[(NSUInteger)(i % (NSInteger)mPrice.count)] doubleValue];
        [products addObject:p];
    }

    NSArray *pcImg = @[ @"pc_1", @"pc_2", @"pc_3", @"pc_4" ];
    NSArray *pcBrand = @[ @"宏基", @"联想", @"惠普", @"戴尔", @"神舟" ];
    NSArray *pcTitles = @[
        @"【国补】Acer宏碁超薄品牌电脑一体机2025新款24英寸家用办公游戏壁挂14代高配I5i7宏基27大屏台式机全套整机",
        @"【人气爆款】联想小新14SE/小新15/小新16 SE可选 2025锐龙轻薄本笔记本电脑 学生办公性价比电脑 官方正品",
        @"【国家补贴15%】HP/惠普可选星book 14/15可选锐龙R5处理器笔记本电脑学生办公本惠普官方旗舰店",
        @"DELL/戴尔 灵越16 Plus 英特尔酷睿i7/core7笔记本电脑轻薄本商务便携办公电脑灵越7000轻薄笔记本电脑",
        @"神舟战神s8/z8游戏笔记本电脑5060独显13代酷睿i7满血学生电竞本",
    ];
    NSArray *pcSeller = @[ @"宏基官方旗舰店", @"联想官方旗舰店", @"惠普官方旗舰店", @"戴尔官方旗舰店", @"神舟官方旗舰店" ];
    NSArray *pcViews = @[ @"90万", @"120万", @"200万", @"100万", @"300万" ];
    NSArray *pcTrans = @[ @"5千+", @"1万+", @"2万+", @"3千+", @"5万+" ];
    NSArray *pcNames = @[ @"Acer非凡", @"联想 14SE", @"惠普 book14", @"戴尔灵越 16Plus", @"神舟战神 s8" ];
    NSArray *pcDesc = @[
        @"【国补】Acer宏碁超薄品牌电脑一体机2025新款24英寸家用办公游戏壁挂14代高配I5i7宏基27大屏台式机全套整机",
        @"【人气爆款】联想小新14SE/小新15/小新16 SE可选 2025锐龙轻薄本笔记本电脑 学生办公性价比电脑 官方正品",
        @"【国家补贴15%】HP/惠普可选星book 14/15可选锐龙R5处理器笔记本电脑学生办公本惠普官方旗舰店",
        @"DELL/戴尔 灵越16 Plus 英特尔酷睿i7/core7笔记本电脑轻薄本商务便携办公电脑灵越7000轻薄笔记本电脑",
        @"神舟战神s8/z8游戏笔记本电脑5060独显13代酷睿i7满血学生电竞本",
    ];
    NSArray *pcPrice = @[ @3789.9, @3399.15, @2889.06, @4599.0, @2899.3 ];

    for (NSInteger i = 0; i < 35; i++) {
        NSInteger idx = i % (NSInteger)pcTitles.count;
        ESProduct *p = [ESProduct new];
        p.pid = [NSString stringWithFormat:@"pc%ld", (long)i];
        p.title = pcTitles[(NSUInteger)idx];
        p.shortName = pcNames[(NSUInteger)idx];
        p.sellerName = pcSeller[(NSUInteger)(idx % (NSInteger)pcSeller.count)];
        p.brand = pcBrand[(NSUInteger)(idx % (NSInteger)pcBrand.count)];
        p.category = @"电脑";
        p.imageAssetName = pcImg[(NSUInteger)(i % (NSInteger)pcImg.count)];
        p.viewsCountText = [NSString stringWithFormat:@"%@浏览", pcViews[(NSUInteger)(i % (NSInteger)pcViews.count)]];
        p.payCountText = pcTrans[(NSUInteger)(i % (NSInteger)pcTrans.count)];
        p.detailText = pcDesc[(NSUInteger)idx];
        p.price = [pcPrice[(NSUInteger)(i % (NSInteger)pcPrice.count)] doubleValue];
        [products addObject:p];
    }

    NSArray *odImg = @[ @"outdoor_1", @"outdoor_2", @"outdoor_3", @"outdoor_4", @"outdoor_5" ];
    NSArray *odTitles = @[
        @"骆驼户外折叠椅月亮椅露营野餐椅子沙滩便携凳子野外写生钓鱼桌椅",
        @"骆驼清风帐篷户外黑胶全自动便携式折叠加厚防雨野营露营装备套餐",
        @"camel户外露营聚拢手推车折叠野餐营地车大容量旅行拉车儿童可躺",
        @"骆驼专业户外登山爬山徒步7系铝合金伸缩登山杖手杖",
        @"骆驼双人户外吊床秋千成人加厚防侧翻寝室室内学生吊椅露营大吊床",
    ];
    NSArray *odSeller = @[ @"骆驼官方旗舰店", @"骆驼官方旗舰店", @"骆驼官方旗舰店", @"骆驼官方旗舰店", @"骆驼官方旗舰店" ];
    NSArray *odViews = @[ @"20万+", @"30万+", @"10万+", @"40万+", @"50万+" ];
    NSArray *odTrans = @[ @"5千+", @"6千+", @"3千+", @"7千+", @"8千+" ];
    NSArray *odNames = @[ @"折叠椅", @"帐篷", @"手推车", @"登山杖", @"吊床" ];
    NSArray *odDesc = odTitles;
    NSArray *odPrice = @[ @120.0, @356.0, @209.0, @87.66, @209.0 ];

    for (NSInteger i = 0; i < 35; i++) {
        NSInteger idx = i % (NSInteger)odTitles.count;
        ESProduct *p = [ESProduct new];
        p.pid = [NSString stringWithFormat:@"outdoor%ld", (long)i];
        p.title = odTitles[(NSUInteger)idx];
        p.shortName = odNames[(NSUInteger)idx];
        p.sellerName = odSeller[(NSUInteger)idx];
        p.brand = @"骆驼";
        p.category = @"户外";
        p.imageAssetName = odImg[(NSUInteger)(i % (NSInteger)odImg.count)];
        p.viewsCountText = [NSString stringWithFormat:@"%@浏览", odViews[(NSUInteger)(i % (NSInteger)odViews.count)]];
        p.payCountText = odTrans[(NSUInteger)(i % (NSInteger)odTrans.count)];
        p.detailText = odDesc[(NSUInteger)idx];
        p.price = [odPrice[(NSUInteger)(i % (NSInteger)odPrice.count)] doubleValue];
        [products addObject:p];
    }

    NSArray *clImg = @[ @"cloth_1", @"cloth_2", @"cloth_3", @"cloth_4", @"cloth_5" ];
    NSArray *clTitles = @[
        @"HM女装毛呢外套25冬季新款静奢老钱风双面呢长款羊毛大衣1000031",
        @"HM女装红色毛针织衫长袖宽松圆领上衣1269572",
        @"HM女装毛呢外套冬季宽松毛毡纽扣翻领及膝大衣1255546",
        @"HM男装卫衣冬季半拉链加绒立领宽松美式慵懒重磅套头上衣1245648",
        @"HM男装羽绒服冬季户外运动防风疏水女装轻薄防寒服外套1238584",
    ];
    NSArray *clSeller = @[ @"HM官方旗舰店", @"HM官方旗舰店", @"HM官方旗舰店", @"HM官方旗舰店", @"HM官方旗舰店" ];
    NSArray *clViews = @[ @"100万+", @"120万+", @"150万+", @"250万+", @"300万+" ];
    NSArray *clTrans = @[ @"1万+", @"1万+", @"1万+", @"2万+", @"3万+" ];
    NSArray *clNames = @[ @"羊毛大衣", @"针织衫", @"毛呢外套", @"卫衣", @"羽绒服" ];
    NSArray *clDesc = clTitles;
    NSArray *clPrice = @[ @659.0, @132.0, @523.0, @163.0, @242.0 ];

    for (NSInteger i = 0; i < 35; i++) {
        NSInteger idx = i % (NSInteger)clTitles.count;
        ESProduct *p = [ESProduct new];
        p.pid = [NSString stringWithFormat:@"cloth%ld", (long)i];
        p.title = clTitles[(NSUInteger)idx];
        p.shortName = clNames[(NSUInteger)idx];
        p.sellerName = clSeller[(NSUInteger)idx];
        p.brand = @"HM";
        p.category = @"衣服";
        p.imageAssetName = clImg[(NSUInteger)(i % (NSInteger)clImg.count)];
        p.viewsCountText = [NSString stringWithFormat:@"%@浏览", clViews[(NSUInteger)(i % (NSInteger)clViews.count)]];
        p.payCountText = clTrans[(NSUInteger)(i % (NSInteger)clTrans.count)];
        p.detailText = clDesc[(NSUInteger)idx];
        p.price = [clPrice[(NSUInteger)(i % (NSInteger)clPrice.count)] doubleValue];
        [products addObject:p];
    }

    NSArray *fdImg = @[ @"food_1", @"food_2", @"food_3", @"food_4", @"food_5" ];
    NSArray *fdTitles = @[
        @"杏花楼中华老字号万家灯火糕点年货礼盒上海特产伴手礼礼物1210g",
        @"杏花楼广式腊肠 香肠227g 煲仔饭腊肠 腊味 中华老字号",
        @"杏花楼老字号咸蛋黄肉松青团礼盒装糯米团子上海豆沙团子麻薯糕点",
        @"杏花楼中华老字号上海腊海鸭风干腊味年货熟食真空包装750g",
        @"杏花楼中华老字号 鸡仔饼250g袋糕点传统点心散装袋装零食上海",
    ];
    NSArray *fdSeller = @[ @"杏花楼旗舰店", @"杏花楼旗舰店", @"杏花楼旗舰店", @"杏花楼旗舰店", @"杏花楼旗舰店" ];
    NSArray *fdViews = @[ @"10万+", @"4万+", @"3万+", @"5万+", @"6万+" ];
    NSArray *fdTrans = @[ @"4千+", @"2千+", @"1千+", @"1千+", @"5千+" ];
    NSArray *fdNames = @[ @"糕点", @"腊肠", @"肉松", @"腊鸭", @"鸡仔饼" ];
    NSArray *fdDesc = fdTitles;
    NSArray *fdPrice = @[ @191.16, @49.3, @14.30, @147.05, @49.3 ];

    for (NSInteger i = 0; i < 35; i++) {
        NSInteger idx = i % (NSInteger)fdTitles.count;
        ESProduct *p = [ESProduct new];
        p.pid = [NSString stringWithFormat:@"food%ld", (long)i];
        p.title = fdTitles[(NSUInteger)idx];
        p.shortName = fdNames[(NSUInteger)idx];
        p.sellerName = fdSeller[(NSUInteger)idx];
        p.brand = @"杏花楼";
        p.category = @"零食";
        p.imageAssetName = fdImg[(NSUInteger)(i % (NSInteger)fdImg.count)];
        p.viewsCountText = [NSString stringWithFormat:@"%@浏览", fdViews[(NSUInteger)(i % (NSInteger)fdViews.count)]];
        p.payCountText = fdTrans[(NSUInteger)(i % (NSInteger)fdTrans.count)];
        p.detailText = fdDesc[(NSUInteger)idx];
        p.price = [fdPrice[(NSUInteger)(i % (NSInteger)fdPrice.count)] doubleValue];
        [products addObject:p];
    }

    return products.copy;
}
