//
//  NPDotChecker.h
//  IdeaNotes
//
//  Created by Sang Nam on 29/5/17.
//  Copyright © 2017 Sang Nam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NPDot.h"

@protocol NPDotCheckerDeleteage <NSObject>
- (void) appendDot:(NPDot *)dot isOffine:(BOOL)offline;
@end


@interface NPDotChecker : NSObject
// delegates
@property (nonatomic) BOOL isOffline;
@property (nonatomic, weak) id <NPDotCheckerDeleteage> delegate;


- (void) reset;
- (void) setSimplify:(BOOL)on;
- (void) setFirst;
- (void) setLast;
- (void) dotChecker:(NPDot *)dot;
- (void) dotCheckerLast;

@end
