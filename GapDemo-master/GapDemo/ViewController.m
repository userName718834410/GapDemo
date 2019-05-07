//
//  ViewController.m
//  GapDemo
//
//  Created by 金现代 on 2019/2/12.
//  Copyright © 2019 王广法. All rights reserved.
//

#import "ViewController.h"
#import "Other/GapFillingTextView.h"
#import "Other/YYTextEditBindingParser.h"

@interface ViewController ()<YYTextViewDelegate>
{
    GapFillingTextView *_StemContentView;
}
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
}
- (void)viewDidAppear:(BOOL)animated{
    GapFillingTextView *textView = [[GapFillingTextView alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, 200)];
    textView.backgroundColor = [UIColor yellowColor];
    YYTextEditBindingParser *parser = [[YYTextEditBindingParser alloc] init];
    textView.textParser = parser;
    textView.delegate = self;
    _StemContentView = textView;
    [self.view addSubview:textView];
    _StemContentView.text = @"床前明月光，            。举头望明月，            。";
}
#pragma mark YYTextViewDelegate
- (BOOL)textViewShouldBeginEditing:(YYTextView *)textView{
    
    BOOL editing = [self controllCursorRangeForTextView:textView];
    return editing;
    
}
- (BOOL)textViewShouldEndEditing:(YYTextView *)textView{
    NSInteger i = 1;
    for (NSString *obj in [self gapFillingContents]) {
        NSString *answerStr = [obj substringWithRange:NSMakeRange(GapBlankSpace, obj.length-GapBlankSpace*2)];
        if (answerStr.length > 0) {
            
            NSLog(@"%ld填空内容%@",i,obj);
        }
        i++;
    }
    return YES;
}
- (void)textViewDidChangeSelection:(YYTextView *)textView{
    if (![self controllCursorRangeForTextView:textView]) {
        [textView endEditing:YES];
    }
}

#pragma mark 光标控制
- (BOOL)controllCursorRangeForTextView:(YYTextView *)textView{
    YYTextEditBindingParser *textParser = (YYTextEditBindingParser *)textView.textParser;
    for (NSString *rangeStr in textParser.gapRangeArr) {
        NSRange range = NSRangeFromString(rangeStr);
        if (textView.selectedRange.location >= range.location && textView.selectedRange.location < range.location + GapBlankSpace) {
            textView.selectedRange = NSMakeRange(range.location + GapBlankSpace,0);
            return YES;
        }else if(textView.selectedRange.location > (range.location + range.length -GapBlankSpace)&&textView.selectedRange.location <= (range.location + range.length)){
            textView.selectedRange = NSMakeRange(range.location + range.length - GapBlankSpace,0);
            return YES;
        }else if(textView.selectedRange.location >=range.location+GapBlankSpace && textView.selectedRange.location <= (range.location + range.length-GapBlankSpace)){
            return YES;
        }else continue;
    }
    return NO;
}
//填空内容
- (NSArray <NSString *>*)gapFillingContents{
    NSMutableArray *tempArr = [NSMutableArray array];
    YYTextEditBindingParser *textParser = (YYTextEditBindingParser *)_StemContentView.textParser;
    for (NSString *rangeStr in textParser.gapRangeArr) {
        NSRange range = NSRangeFromString(rangeStr);
        NSString *gapContent = [_StemContentView.text substringWithRange:range];
        [tempArr addObject:gapContent];
    }
    return tempArr;
}
@end
