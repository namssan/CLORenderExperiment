//
//  NPStroke.m
//  NeoNotes
//
//  Created by Sang Nam on 2/20/16.
//  Copyright © 2016 Neolabconvergence. All rights reserved.
//

#import "NPStroke.h"


@implementation NPStroke


- (instancetype) initWithRawDataX:(float *)x Y:(float*)y pressure:(float *)p time_diff:(int *)time startTime:(UInt64)start_at size:(int)size
{
    self = [self init];
    if (!self) return nil;
    int time_lapse = 0;
    int i = 0;
    if (size < 3) {
        for (i = size; i < 3; i++) {
            x[i] = x[size -1];
            y[i] = y[size -1];
            p[i] = p[size -1];
            time[i]=0;
        }
        size = 3;
    }
    _dataCount = size;
    point_x = (float *)malloc(sizeof(float) * size);
    point_y = (float *)malloc(sizeof(float) * size);
    point_p = (float *)malloc(sizeof(float) * size);
    time_stamp = (UInt64 *)malloc(sizeof(UInt64) * size);
    start_time = start_at;

    for (i=0; i<size; i++) {
        point_x[i] = x[i];
        point_y[i] = y[i];
        point_p[i] = p[i];
        time_lapse += time[i];
        time_stamp[i] = start_at + time_lapse;
//        NSLog(@"(%f,%f) - %f : t: %llu",x[i],y[i],p[i],time_stamp[i]);
    }
    return self;
}

- (float) getX:(int)idx {
    return point_x[idx];
}

- (float) getY:(int)idx {
    return point_y[idx];
}

- (float) getP:(int)idx {
    return point_p[idx];
}

- (UInt64) getT:(int)idx {
    return time_stamp[idx];
}
 
- (UInt64) getStartTime {
    return start_time;
}


- (NPDot *) getDot:(int)idx {
    NPDot *dot = [[NPDot alloc] initWithPointX:point_x[idx] poinY:point_y[idx] pressure:point_p[idx]];
    return dot;
}
- (NPDot *) firstDot {
    return [self getDot:0];
}
- (NPDot *) midDot {
    int idx = _dataCount / 2.0;
    return [self getDot:idx];
}
- (NPDot *) lastDot {
    int idx = _dataCount - 1;
    if(idx < 0 ) { idx = 0; }
    return [self getDot:idx];
}

- (NPStroke *) makeCopy {
    
    int *time_diff = (int *)malloc(sizeof(int) * _dataCount);
    
    for (int i=0; i<_dataCount; i++) {
        UInt64 time = time_stamp[i];
        time_diff[i] = (int)(time - start_time);
    }
    
    NPStroke *stroke = [[NPStroke alloc] initWithRawDataX:point_x Y:point_y pressure:point_p time_diff:time_diff startTime:start_time size:_dataCount];
    return stroke;
}

@end
