//
//  NPDotChecker.m
//  IdeaNotes
//
//  Created by Sang Nam on 29/5/17.
//  Copyright © 2017 Sang Nam. All rights reserved.
//

#import "NPDotChecker.h"


typedef enum {
    DOT_CHECK_NONE,
    DOT_CHECK_FIRST,
    DOT_CHECK_SECOND,
    DOT_CHECK_THIRD,
    DOT_CHECK_NORMAL
} DOT_CHECK_STATE;


@implementation NPDotChecker {
    
    BOOL _simplifyOn;
    NPDot *_dot0, *_dot1, *_dot2;
    DOT_CHECK_STATE _dotCheckState;
}

- (void)reset {
    _dot0 = nil;
    _dot1 = nil;
    _dot2 = nil;
}

- (void)setSimplify:(BOOL)on {
    _simplifyOn = on;
}
- (void)setFirst {
    _dotCheckState = DOT_CHECK_FIRST;
}
- (void)setLast {
    _dotCheckState = DOT_CHECK_NONE;
}
- (void) dotChecker:(NPDot *)dot
{
    if (_dotCheckState == DOT_CHECK_NORMAL) {
        if ([self dotCheckerForMiddle:dot]) {
            [self dotAppend:_dot2];
            _dot0 = _dot1;
            _dot1 = _dot2;
        }
        else {
            NSLog(@"dotChecker error : middle");
        }
        _dot2 = dot;
    }
    else if(_dotCheckState == DOT_CHECK_FIRST) {
        _dot0 = dot;
        _dot1 = dot;
        _dot2 = dot;
        _dotCheckState = DOT_CHECK_SECOND;
    }
    else if(_dotCheckState == DOT_CHECK_SECOND) {
        _dot2 = dot;
        _dotCheckState = DOT_CHECK_THIRD;
    }
    else if(_dotCheckState == DOT_CHECK_THIRD) {
        if ([self dotCheckerForStart:dot]) {
            [self dotAppend:_dot1];
            if ([self dotCheckerForMiddle:dot]) {
                [self dotAppend:_dot2];
                _dot0 = _dot1;
                _dot1 = _dot2;
            }
            else {
                NSLog(@"dotChecker error : middle2");
            }
        }
        else {
            _dot1 = _dot2;
            NSLog(@"dotChecker error : start");
        }
        _dot2 = dot;
        _dotCheckState = DOT_CHECK_NORMAL;
    }
}
- (void) dotCheckerLast
{
    if ([self dotCheckerForEnd]) {
        [self dotAppend:_dot2];
        //        dotData2.x = 0.0f;
        //        dotData2.y = 0.0f;
    }
    else {
        NSLog(@"dotChecker error : end");
    }
}
- (BOOL) dotCheckerForStart:(NPDot *)dot
{
    static const float delta = 2.0f;
    if (_dot1.x > 150 || _dot1.x < 1) return NO;
    if (_dot1.y > 150 || _dot1.y < 1) return NO;
    if ((dot.x - _dot1.x) * (_dot2.x - _dot1.x) > 0 && ABS(dot.x - _dot1.x) > delta && ABS(_dot1.x - _dot2.x) > delta)
    {
        return NO;
    }
    if ((dot.y - _dot1.y) * (_dot2.y - _dot1.y) > 0 && ABS(dot.y - _dot1.y) > delta && ABS(_dot1.y - _dot2.y) > delta)
    {
        return NO;
    }
    return YES;
}
- (BOOL) dotCheckerForMiddle:(NPDot *)dot
{
    static const float delta = 2.0f;
    if (_dot2.x > 150 || _dot2.x < 1) return NO;
    if (_dot2.y > 150 || _dot2.y < 1) return NO;
    if ((_dot1.x - _dot2.x) * (dot.x - _dot2.x) > 0 && ABS(_dot1.x - _dot2.x) > delta && ABS(dot.x - _dot2.x) > delta)
    {
        return NO;
    }
    if ((_dot1.y - _dot2.y) * (dot.y - _dot2.y) > 0 && ABS(_dot1.y - _dot2.y) > delta && ABS(dot.y - _dot2.y) > delta)
    {
        return NO;
    }
    
    return YES;
}
- (BOOL) dotCheckerForEnd
{
    static const float delta = 2.0f;
    if (_dot2.x > 150 || _dot2.x < 1) return NO;
    if (_dot2.y > 150 || _dot2.y < 1) return NO;
    if ((_dot2.x - _dot0.x) * (_dot2.x - _dot1.x) > 0 && ABS(_dot2.x - _dot0.x) > delta && ABS(_dot2.x - _dot1.x) > delta)
    {
        return NO;
    }
    if ((_dot2.y - _dot0.y) * (_dot2.y - _dot1.y) > 0 && ABS(_dot2.y - _dot0.y) > delta && ABS(_dot2.y - _dot1.y) > delta)
    {
        return NO;
    }
    return YES;
}

static float np_sdk_last_x = 0.0;
static float np_sdk_last_y = 0.0;

- (void) dotAppend:(NPDot *)dot
{
//    if(_simplifyOn) {
//        float diff_x = fabsf(np_sdk_last_x - dot.x);
//        if(diff_x < 0.1) return;
//        
//        float diff_y = fabsf(np_sdk_last_y - dot.y);
//        if(diff_y < 0.1) return;
//        
//    }
//    np_sdk_last_x = dot.x;
//    np_sdk_last_y = dot.y;
    
    if(self.delegate) {
        [self.delegate appendDot:dot isOffine:_isOffline];
    }
}


@end
