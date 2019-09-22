//
//  QRDataPersistence.m
//  QYReaderApp
//
//  Created by 杨帆 on 2018/6/20.
//  Copyright © 2018年 com.qiyi.reader. All rights reserved.
//

#import "QRDataPersistence.h"
#import <objc/runtime.h>

static inline NSString *persistenceKeyForProperty(NSString *pro) {
    return [NSString stringWithFormat:@"com.company.%@",pro];
}

static inline NSString *getPropertyNameFromGetter(SEL getter) {
    return NSStringFromSelector(getter);
}

static inline NSString *getPropertyNameFromSetter(SEL setter) {
    NSString *setterName = NSStringFromSelector(setter);
    char headerChar = [setterName characterAtIndex:3];
    if (headerChar <=90 && headerChar >=65) headerChar += 32;
    NSString *propertyName = [setterName stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:[NSString stringWithFormat:@"%c",headerChar]];
    propertyName = [propertyName stringByReplacingOccurrencesOfString:@":" withString:@""];
    return propertyName;
}

@interface QRDataPersistence ()

@end

@implementation QRDataPersistence

//key名转换，使用场景如老数据迁移
+ (NSDictionary *)customPropertyMapper {
    return @{@"bShowAlert" : @"命名规范_showAlert"};
    // return @{@"bShowAlert" : @"老key"};
}

+ (void)initialize {
    unsigned int count = 0;
    objc_property_t *propertys= class_copyPropertyList(self, &count);
    for (int i=0; i<count; i++) {
        objc_property_t property = propertys[i];
        const char *name = property_getName(property);
        const char *attributes = property_getAttributes(property);
        char *getter = strstr(attributes, ",G");
        if (getter) {
            getter = strdup(getter + 2);
            getter = strsep(&getter, ",");
        } else {
            getter = strdup(name);
        }
        SEL getterSel = sel_registerName(getter);
        
        char *setter = strstr(attributes, ",S");
        if (setter) {
            setter = strdup(setter + 2);
            setter = strsep(&setter, ",");
        } else {
            asprintf(&setter, "set%c%s:", toupper(name[0]), name + 1);
        }
        SEL setterSel = sel_registerName(setter);
        
        Method getterMethod = class_getInstanceMethod(self, getterSel);
        Method setterMethod = class_getInstanceMethod(self, setterSel);
        IMP generalGetterIMP = NULL;
        IMP generalSetterIMP = NULL;
        
        char *returnType = method_copyReturnType(getterMethod);
        size_t len = strlen(returnType);
        switch (*returnType) {
            case '@':
            {
                NSString *att = [[NSString alloc] initWithUTF8String:attributes];
                NSAssert(len==1, @"不支持的属性类型!");
                NSAssert([att containsString:@"NSString"]||[att containsString:@"NSDate"]||[att containsString:@"NSData"]||[att containsString:@"NSNumber"]||[att containsString:@"NSArray"]||[att containsString:@"NSDictionary"], @"不支持的属性类型!");
                generalGetterIMP = class_getMethodImplementation(self, @selector(generalObjGetter));
                generalSetterIMP = class_getMethodImplementation(self, @selector(generalObjSetter:));
                break;
            }
            case 'B':
            {
                generalGetterIMP = class_getMethodImplementation(self, @selector(generalBoolGetter));
                generalSetterIMP = class_getMethodImplementation(self, @selector(generalBoolSetter:));
                break;
            }
            case '{':
            {
                NSString *str = [[NSString alloc] initWithUTF8String:returnType];
                if ([str containsString:@"CGSize"]) {
                    generalGetterIMP = class_getMethodImplementation(self, @selector(generalCGSizeGetter));
                    generalSetterIMP = class_getMethodImplementation(self, @selector(generalCGSizeSetter:));
                }
                else if ([str containsString:@"CGPoint"]) {
                    generalGetterIMP = class_getMethodImplementation(self, @selector(generalCGPointGetter));
                    generalSetterIMP = class_getMethodImplementation(self, @selector(generalCGPointSetter:));
                }
                else if ([str containsString:@"CGRect"]) {
                    generalGetterIMP = class_getMethodImplementation(self, @selector(generalCGRectGetter));
                    generalSetterIMP = class_getMethodImplementation(self, @selector(generalCGRectSetter:));
                }
                else if ([str containsString:@"CGAffineTransform"]) {
                    generalGetterIMP = class_getMethodImplementation(self, @selector(generalCGAffineTransformGetter));
                    generalSetterIMP = class_getMethodImplementation(self, @selector(generalCGAffineTransformSetter:));
                }
                else if ([str containsString:@"UIEdgeInsets"]) {
                    generalGetterIMP = class_getMethodImplementation(self, @selector(generalUIEdgeInsetsGetter));
                    generalSetterIMP = class_getMethodImplementation(self, @selector(generalUIEdgeInsetsSetter:));
                }
                else if ([str containsString:@"UIOffset"]) {
                    generalGetterIMP = class_getMethodImplementation(self, @selector(generalUIOffsetGetter));
                    generalSetterIMP = class_getMethodImplementation(self, @selector(generalUIOffsetSetter:));
                }
                break;
            }
            case 'C':
            {
                generalGetterIMP = class_getMethodImplementation(self, @selector(generalUInt8Getter));
                generalSetterIMP = class_getMethodImplementation(self, @selector(generalUInt8Setter:));
                break;
            }
            case 'c':
            {
                generalGetterIMP = class_getMethodImplementation(self, @selector(generalInt8Getter));
                generalSetterIMP = class_getMethodImplementation(self, @selector(generalInt8Setter:));
                break;
            }
            case 'S':
            {
                generalGetterIMP = class_getMethodImplementation(self, @selector(generalUInt16Getter));
                generalSetterIMP = class_getMethodImplementation(self, @selector(generalUInt16Setter:));
                break;
            }
            case 's':
            {
                generalGetterIMP = class_getMethodImplementation(self, @selector(generalInt16Getter));
                generalSetterIMP = class_getMethodImplementation(self, @selector(generalInt16Setter:));
                break;
            }
            case 'I':
            case 'L':
            {
                generalGetterIMP = class_getMethodImplementation(self, @selector(generalUInt32Getter));
                generalSetterIMP = class_getMethodImplementation(self, @selector(generalUInt32Setter:));
                break;
            }
            case 'i':
            case 'l':
            {
                generalGetterIMP = class_getMethodImplementation(self, @selector(generalInt32Getter));
                generalSetterIMP = class_getMethodImplementation(self, @selector(generalInt32Setter:));
                break;
            }
            case 'Q':
            {
                generalGetterIMP = class_getMethodImplementation(self, @selector(generalUInt64Getter));
                generalSetterIMP = class_getMethodImplementation(self, @selector(generalUInt64Setter:));
                break;
            }
            case 'q':
            {
                generalGetterIMP = class_getMethodImplementation(self, @selector(generalInt64Getter));
                generalSetterIMP = class_getMethodImplementation(self, @selector(generalInt64Setter:));
                break;
            }
            case 'f':
            {
                generalGetterIMP = class_getMethodImplementation(self, @selector(generalFloatGetter));
                generalSetterIMP = class_getMethodImplementation(self, @selector(generalFloatSetter:));
                break;
            }
            case 'd':
            {
                generalGetterIMP = class_getMethodImplementation(self, @selector(generalDoubleGetter));
                generalSetterIMP = class_getMethodImplementation(self, @selector(generalDoubleSetter:));
                break;
            }
            default:
                NSAssert(NO, @"不支持的属性类型!");
                break;
        }
        
        method_setImplementation(getterMethod, generalGetterIMP);
        free(getter);
        method_setImplementation(setterMethod, generalSetterIMP);
        free(setter);
    }
    free(propertys);
}

- (NSDictionary *)defaultValues {
    NSString *cfgPath = [[NSBundle mainBundle] pathForResource:@"QRDataDefaultCfg" ofType:@"plist"];
    NSDictionary *cfgDic = [[NSDictionary alloc] initWithContentsOfFile:cfgPath];
    NSMutableDictionary *res = [@{} mutableCopy];
    for (NSString *propertyName in cfgDic.allKeys) {
        NSString *key = [[self propertyKeyMap] objectForKey:propertyName];
        if (!key) continue;
        [res setObject:cfgDic[propertyName] forKey:key];
    }
    return res;
}

+ (QRDataPersistence *)shareInstance {
    static QRDataPersistence *one = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        one = [QRDataPersistence new];
    });
    return one;
}

- (instancetype)init {
    if (self = [super init]) {
        [[self persistenceContainer] registerDefaults:[self defaultValues]];
    }
    return self;
}

- (NSUserDefaults *)persistenceContainer {
    return [NSUserDefaults standardUserDefaults];
}

- (NSDictionary *)propertyKeyMap {
    static NSMutableDictionary *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = [[NSMutableDictionary alloc] initWithDictionary:[[self class] customPropertyMapper]];
        unsigned int count = 0;
        objc_property_t *propertys= class_copyPropertyList([self class], &count);
        for (int i=0; i<count; i++) {
            objc_property_t property = propertys[i];
            NSString *propertyName = [[NSString alloc] initWithUTF8String:property_getName(property)];
            if (![map objectForKey:propertyName]) {
                [map setObject:persistenceKeyForProperty(propertyName) forKey:propertyName];
            }
        }
        free(propertys);
    });
    return map;
}

- (id)generalGetter:(SEL )sel{
    NSString *key = [[self propertyKeyMap] objectForKey:getPropertyNameFromGetter(sel)];
    return [[self persistenceContainer] objectForKey:key];
}

- (void)generalSetter:(SEL )sel newValue:(id)newValue {
    NSString *key = [[self propertyKeyMap] objectForKey:getPropertyNameFromSetter(sel)];
    [[self persistenceContainer] setObject:newValue forKey:key];
}

- (id)generalObjGetter {
    return [self generalGetter:_cmd];
}

- (void)generalObjSetter:(id)newValue {
    [self generalSetter:_cmd newValue:newValue];
}

- (BOOL)generalBoolGetter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value boolValue];
    }
    return NO;
}

- (void)generalBoolSetter:(BOOL)b {
    [self generalSetter:_cmd newValue:[NSNumber numberWithBool:b]];
}

- (UInt8)generalUInt8Getter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value unsignedCharValue];
    }
    return 0;
}

- (void)generalUInt8Setter:(UInt8)ui {
    [self generalSetter:_cmd newValue:[NSNumber numberWithUnsignedChar:ui]];
}

- (int8_t)generalInt8Getter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value charValue];
    }
    return 0;
}

- (void)generalInt8Setter:(int8_t)i {
    [self generalSetter:_cmd newValue:[NSNumber numberWithChar:i]];
}

- (UInt16)generalUInt16Getter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value unsignedShortValue];
    }
    return 0;
}

- (void)generalUInt16Setter:(UInt16)ui {
    [self generalSetter:_cmd newValue:[NSNumber numberWithUnsignedShort:ui]];
}

- (int16_t)generalInt16Getter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value shortValue];
    }
    return 0;
}

- (void)generalInt16Setter:(int16_t)i {
    [self generalSetter:_cmd newValue:[NSNumber numberWithShort:i]];
}

- (UInt32)generalUInt32Getter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value unsignedIntValue];
    }
    return 0;
}

- (void)generalUInt32Setter:(UInt32)ui {
    [self generalSetter:_cmd newValue:[NSNumber numberWithUnsignedInt:ui]];
}

- (int32_t)generalInt32Getter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value intValue];
    }
    return 0;
}

- (void)generalInt32Setter:(int32_t)i {
    [self generalSetter:_cmd newValue:[NSNumber numberWithInt:i]];
}

- (UInt64)generalUInt64Getter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value unsignedLongLongValue];
    }
    return 0;
}

- (void)generalUInt64Setter:(UInt64)ul {
    [self generalSetter:_cmd newValue:[NSNumber numberWithUnsignedLongLong:ul]];
}

- (int64_t)generalInt64Getter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value longLongValue];
    }
    return 0;
}

- (void)generalInt64Setter:(int64_t)l {
    [self generalSetter:_cmd newValue:[NSNumber numberWithLongLong:l]];
}

- (float)generalFloatGetter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value floatValue];
    }
    return 0.0;
}

- (void)generalFloatSetter:(float)f {
    [self generalSetter:_cmd newValue:[NSNumber numberWithFloat:f]];
}

- (double)generalDoubleGetter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value doubleValue];
    }
    return 0.0;
}

- (void)generalDoubleSetter:(double)d {
    [self generalSetter:_cmd newValue:[NSNumber numberWithDouble:d]];
}

- (CGSize)generalCGSizeGetter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSString class]]) {
        return [value CGSizeValue];
    }
    return CGSizeZero;
}

- (void)generalCGSizeSetter:(CGSize)size {
    [self generalSetter:_cmd newValue:NSStringFromCGSize(size)];
}

- (CGPoint)generalCGPointGetter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSString class]]) {
        return [value CGPointValue];
    }
    return CGPointZero;
}

- (void)generalCGPointSetter:(CGPoint)point {
    [self generalSetter:_cmd newValue:NSStringFromCGPoint(point)];
}

- (CGRect)generalCGRectGetter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSString class]]) {
        return [value CGRectValue];
    }
    return CGRectZero;
}

- (void)generalCGRectSetter:(CGRect)rect {
    [self generalSetter:_cmd newValue:NSStringFromCGRect(rect)];
}

- (CGAffineTransform)generalCGAffineTransformGetter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSString class]]) {
        return [value CGAffineTransformValue];
    }
    return CGAffineTransformIdentity;
}

- (void)generalCGAffineTransformSetter:(CGAffineTransform)trans {
    [self generalSetter:_cmd newValue:NSStringFromCGAffineTransform(trans)];
}

- (UIEdgeInsets)generalUIEdgeInsetsGetter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSString class]]) {
        return [value UIEdgeInsetsValue];
    }
    return UIEdgeInsetsZero;
}

- (void)generalUIEdgeInsetsSetter:(UIEdgeInsets)inset {
    [self generalSetter:_cmd newValue:NSStringFromUIEdgeInsets(inset)];
}

- (UIOffset)generalUIOffsetGetter {
    id value = [self generalGetter:_cmd];
    if ([value isKindOfClass:[NSString class]]) {
        return [value UIOffsetValue];
    }
    return UIOffsetZero;
}

- (void)generalUIOffsetSetter:(UIOffset)offset {
    [self generalSetter:_cmd newValue:NSStringFromUIOffset(offset)];
}



@end
