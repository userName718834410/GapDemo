//
//  YYTextEditBindingParser.m
//  YYTextDemo
//
//  Created by sdzn on 2018/9/1.
//  Copyright © 2018年 ibireme. All rights reserved.
//

#import "YYTextEditBindingParser.h"
#define ICScreenWidth [UIScreen mainScreen].bounds.size.width
#define LOCK(...) dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(_lock);

@interface YYTextEditBindingParser()
{
    dispatch_semaphore_t _lock;
}
@end
@implementation YYTextEditBindingParser

- (instancetype)init {
    self = [super init];
    _lock = dispatch_semaphore_create(1);
    NSString *pattern1 = @"#([^#]*)#";
    self.regex = [[NSRegularExpression alloc] initWithPattern:pattern1 options:kNilOptions error:nil];
    NSString *pattern2 = [NSString stringWithFormat:@"\\s{%d}([^\\s{3}]*)\\s{%d}",GapBlankSpace,GapBlankSpace];
    self.gapRegex = [[NSRegularExpression alloc] initWithPattern:pattern2 options:kNilOptions error:nil];
    NSString *pattern3 = @"\U0000fffc";
    self.imageRegex = [[NSRegularExpression alloc] initWithPattern:pattern3 options:kNilOptions error:nil];
    //self.imgPlaceRangeArr = [NSMutableArray array];
    return self;
}
- (void)setImageMapper:(NSArray *)imageMapper{
    LOCK(_imageMapper = imageMapper.copy);
}

- (NSRange)_replaceTextInRange:(NSRange)range withLength:(NSUInteger)length selectedRange:(NSRange)selectedRange {
    // no change
    if (range.length == length) return selectedRange;
    // right
    if (range.location >= selectedRange.location + selectedRange.length) return selectedRange;
    // left
    if (selectedRange.location >= range.location + range.length) {
        selectedRange.location = selectedRange.location + length - range.length;
        return selectedRange;
    }
    // same
    if (NSEqualRanges(range, selectedRange)) {
        selectedRange.length = length;
        return selectedRange;
    }
    // one edge same
    if ((range.location == selectedRange.location && range.length < selectedRange.length) ||
        (range.location + range.length == selectedRange.location + selectedRange.length && range.length < selectedRange.length)) {
        selectedRange.length = selectedRange.length + length - range.length;
        return selectedRange;
    }
    selectedRange.location = range.location + length;
    selectedRange.length = 0;
    return selectedRange;
}
- (BOOL)parseText:(NSMutableAttributedString *)text selectedRange:(NSRangePointer)range {
    __block BOOL changed = NO;
    NSArray *mapper;
    LOCK(mapper = _imageMapper);
    NSRange selectedRange = range ? *range : NSMakeRange(0, 0);
    
    NSArray *imageMatches = [_imageRegex matchesInString:text.string options:kNilOptions range:NSMakeRange(0, text.length)];
    NSUInteger cutLengthForImg = 0;
    for (NSInteger i = 0,max = MIN(imageMatches.count, mapper.count); i < max; i++) {
        NSTextCheckingResult *one = imageMatches[i];
        NSRange oneRange = one.range;
        if (oneRange.length == 0) continue;
        oneRange.location -= cutLengthForImg;
        UIImage *imageContent = mapper[i];
        [self text:text addAttchmentInRange:oneRange imageContent:imageContent selectedRange:selectedRange];
        cutLengthForImg += oneRange.length-1;
        //[self.imgPlaceRangeArr addObject:NSStringFromRange(NSMakeRange(oneRange.location, 1))];
    }
    
    NSArray *gapMatches = [_gapRegex matchesInString:text.string options:kNilOptions range:NSMakeRange(0, text.length)];
    if (gapMatches.count == 0) return NO;
    
    NSRange lastOneRange = NSMakeRange(0, 0);
    NSMutableArray *stemRangeArr = [NSMutableArray array];
    NSMutableArray *gapRangeTempArr = [NSMutableArray array];
    for (NSUInteger i = 0, max = gapMatches.count; i < max; i++) {
        NSTextCheckingResult *one = gapMatches[i];
        NSRange oneRange = one.range;
        YYTextDecoration *decoration = [YYTextDecoration new];
        [text yy_setTextUnderline:decoration range:oneRange];
        [gapRangeTempArr addObject:NSStringFromRange(oneRange)];
        NSRange range = NSMakeRange(lastOneRange.location+lastOneRange.length, oneRange.location-lastOneRange.location - lastOneRange.length);
        [stemRangeArr addObject:NSStringFromRange(range)];
        lastOneRange = oneRange;
        if (i == max-1) {
            if (oneRange.location + oneRange.length < text.string.length) {
                NSRange range = NSMakeRange(lastOneRange.location+lastOneRange.length, text.string.length-lastOneRange.location - lastOneRange.length);
                [stemRangeArr addObject:NSStringFromRange(range)];
            }
        }
    }
    
    self.gapRangeArr  = gapRangeTempArr;
    if (range) *range = selectedRange;
    return changed;
}
- (NSAttributedString *)layoutText:(NSMutableAttributedString *)text{
    NSArray *mapper;
    LOCK(mapper = _imageMapper);
    NSArray *imageMatches = [_imageRegex matchesInString:text.string options:kNilOptions range:NSMakeRange(0, text.length)];
    NSUInteger cutLengthForImg = 0;
    for (NSInteger i = 0,max = MIN(imageMatches.count, mapper.count); i < max; i++) {
        NSTextCheckingResult *one = imageMatches[i];
        NSRange oneRange = one.range;
        if (oneRange.length == 0) continue;
        oneRange.location -= cutLengthForImg;
        CGFloat fontSize = 16; // CoreText default value
        CTFontRef font = (__bridge CTFontRef)([text yy_attribute:NSFontAttributeName atIndex:oneRange.location]);
        if (font) fontSize = CTFontGetSize(font);
        UIImage *imageContent = mapper[i];
        [self text:text addAttchmentInRange:oneRange imageContent:imageContent selectedRange:NSMakeRange(NSNotFound, 0)];
        cutLengthForImg += oneRange.length-1;
    }
    return text;
}
- (NSMutableAttributedString *)text:(NSMutableAttributedString *)text addAttchmentInRange:(NSRange)oneRange imageContent:(UIImage *)imageContent selectedRange:(NSRange)selectedRange {
    
    CGFloat fontSize = 17; // CoreText default value
    CTFontRef font = (__bridge CTFontRef)([text yy_attribute:NSFontAttributeName atIndex:oneRange.location]);
    if (font) fontSize = CTFontGetSize(font);
    CGSize attachmentSize = CGSizeMake(100, 100);
    if (![imageContent isKindOfClass:[UIImage class]]) {
        imageContent = [UIImage imageNamed:@"图片.png"];
    }else{
        attachmentSize = imageContent.size;
        if (attachmentSize.width > (ICScreenWidth - 100)) {
            attachmentSize = CGSizeMake(ICScreenWidth *0.6, (ICScreenWidth *0.6)*attachmentSize.height/attachmentSize.width);
        }else if(attachmentSize.height > 200){
            attachmentSize = CGSizeMake(200*(attachmentSize.width/attachmentSize.height), 200);
        }
    }
    NSMutableAttributedString *atr = [NSAttributedString yy_attachmentStringWithContent:imageContent contentMode:UIViewContentModeScaleAspectFit attachmentSize:attachmentSize alignToFont:[UIFont systemFontOfSize:fontSize] alignment:YYTextVerticalAlignmentCenter];
    YYTextHighlight *highlight = [YYTextHighlight new];
    if (imageContent) {
        highlight.userInfo = @{@"img":imageContent};
    }
    
    [atr yy_setTextHighlight:highlight range:NSMakeRange(0,atr.length)];
//    [atr yy_setTextHighlightRange:NSMakeRange(0,atr.length) color:nil backgroundColor:nil tapAction:^(UIView * _Nonnull containerView, NSAttributedString * _Nonnull text, NSRange range, CGRect rect) {
//        NSLog(@"点击图片");
//
//    }];
    [text replaceCharactersInRange:oneRange withString:atr.string];
    [text yy_removeDiscontinuousAttributesInRange:NSMakeRange(oneRange.location, atr.length)];
    [text addAttributes:atr.yy_attributes range:NSMakeRange(oneRange.location, atr.length)];
    if (selectedRange.location != NSNotFound) {
        selectedRange = [self _replaceTextInRange:oneRange withLength:atr.length selectedRange:selectedRange];
    }
    return text;
}
@end
