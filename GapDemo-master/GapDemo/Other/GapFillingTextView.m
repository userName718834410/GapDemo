//
//  GapFillingTextView.m
//  YYTextDemo
//
//  Created by sdzn on 2018/9/5.
//  Copyright © 2018年 ibireme. All rights reserved.
//

#import "GapFillingTextView.h"
#import "YYTextKeyboardManager.h"
@implementation GapFillingTextView

//- (BOOL)canPerformAction:(SEL)action withSender:(id)sender{
//    if ([UIMenuController sharedMenuController])
//    {
//        [UIMenuController   sharedMenuController].menuVisible = NO;
//    }
//    return NO;
//}
- (void)_scrollRangeToVisible:(YYTextRange *)range {
    CGRect rect = [self.textLayout rectForRange:range];
    if (CGRectIsNull(rect)) return;
    YYTextKeyboardManager *mgr = [YYTextKeyboardManager defaultManager];
    rect = [self _convertRectFromLayout:rect];
    UIApplication *app = [UIApplication sharedApplication];
    rect = [self convertRect:rect toView:app.keyWindow];
    
    if (rect.size.width < 1) rect.size.width = 1;
    if (rect.size.height < 1) rect.size.height = 1;
    
    if (mgr.keyboardVisible && self.window && self.superview && self.isFirstResponder && !self.verticalForm) {
        if (rect.origin.y>  mgr.keyboardFrame.origin.y) {
            [[NSNotificationCenter defaultCenter] postNotificationName:GapFillingTextViewKeyBoardShowNotifiName object:@{@"offectForKeyBoard":@(rect.origin.y -  mgr.keyboardFrame.origin.y + 40)}];
        }
    }
}
- (CGRect)_convertRectFromLayout:(CGRect)rect {
    rect.origin = [self _convertPointFromLayout:rect.origin];
    return rect;
}
- (CGPoint)_convertPointFromLayout:(CGPoint)point {
    CGSize boundingSize = self.textLayout.textBoundingSize;
    if (self.textLayout.container.isVerticalForm) {
        CGFloat w = self.textLayout.textBoundingSize.width;
        if (w < self.bounds.size.width) w = self.bounds.size.width;
        point.x -= self.textLayout.container.size.width - w;
        if (boundingSize.width < self.bounds.size.width) {
            if (self.textVerticalAlignment == YYTextVerticalAlignmentCenter) {
                point.x -= (self.bounds.size.width - boundingSize.width) * 0.5;
            } else if (self.textVerticalAlignment == YYTextVerticalAlignmentBottom) {
                point.x -= (self.bounds.size.width - boundingSize.width);
            }
        }
        return point;
    } else {
        if (boundingSize.height < self.bounds.size.height) {
            if (self.textVerticalAlignment == YYTextVerticalAlignmentCenter) {
                point.y += (self.bounds.size.height - boundingSize.height) * 0.5;
            } else if (self.textVerticalAlignment == YYTextVerticalAlignmentBottom) {
                point.y += (self.bounds.size.height - boundingSize.height);
            }
        }
        return point;
    }
}

@end
