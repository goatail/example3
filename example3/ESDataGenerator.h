//
//  ESDataGenerator.h
//  example3
//
//  与 example `DataGenerator.generateProducts()` 一致的商品 Mock（iOS 11+）
//

#import <Foundation/Foundation.h>

@class ESProduct;

NS_ASSUME_NONNULL_BEGIN

/// 生成全部商品（约 175 条，与 Swift 逻辑一致）
NSArray<ESProduct *> *ESDataGeneratorAllProducts(void);

NS_ASSUME_NONNULL_END
