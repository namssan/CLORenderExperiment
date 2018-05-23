//
//  NPStroke.h
//  NeoNotes
//
//  Created by Sang Nam on 2/20/16.
//  Copyright © 2016 Neolabconvergence. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPDot.h"

@interface NPStroke : NSObject
{
    @public
    float *point_x, *point_y, *point_p;
    UInt64 *time_stamp;
    UInt64 start_time;
}

@property (nonatomic) int dataCount;

- (instancetype) initWithRawDataX:(float *)x Y:(float*)y pressure:(float *)p time_diff:(int *)time startTime:(UInt64)start_at size:(int)size;
- (float) getX:(int)idx;
- (float) getY:(int)idx;
- (float) getP:(int)idx;
- (UInt64) getT:(int)idx;
- (UInt64) getStartTime;

- (NPDot *) getDot:(int)idx;
- (NPDot *) firstDot;
- (NPDot *) midDot;
- (NPDot *) lastDot;
    
- (NPStroke *) makeCopy;

@end
