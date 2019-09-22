//
//  QRDataPersistence.h
//  QYReaderApp
//
//  Created by 杨帆 on 2018/6/20.
//  Copyright © 2018年 com.qiyi.reader. All rights reserved.
//

#import <UIKit/UIKit.h>

/*
 UserDefault ORM
 支持的数据类型:
 NSString NSDate NSData NSNumber NSArray NSDictionary
 UInt8 int8_t UInt16 int16_t UInt32 int32_t UInt64 int64_t float double
 CGFloat CGSize CGPoint CGRect CGAffineTransform UIEdgeInsets
 */

@interface QRDataPersistence : NSObject

+ (QRDataPersistence *)shareInstance;

//在下面声明存储的数据即可
@property (nonatomic)NSArray *tips;

@property (nonatomic)BOOL bShowAlert;

@end
