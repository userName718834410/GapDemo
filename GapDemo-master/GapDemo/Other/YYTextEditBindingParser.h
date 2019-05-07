//
//  YYTextEditBindingParser.h
//  YYTextDemo
//
//  Created by sdzn on 2018/9/1.
//  Copyright © 2018年 ibireme. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYText.h"
#define GapBlankSpace 6 //首尾空格长度
@interface YYTextEditBindingParser : NSObject<YYTextParser>
@property (nonatomic, strong) NSRegularExpression *regex;
@property (nonatomic, strong) NSRegularExpression *gapRegex;
@property (nonatomic, strong) NSRegularExpression *imageRegex;
@property (nonatomic, strong) NSArray <NSString *> *gapRangeArr;
@property (nonatomic, strong) NSArray *imageMapper;
@property (nonatomic, strong) NSArray *imgSrcArr;

- (NSAttributedString *)layoutText:(NSMutableAttributedString *)text;
@end
