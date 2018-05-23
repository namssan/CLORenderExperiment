//
//  NPPenRegInfo.h
//  BlueOcean
//
//  Created by Sang Nam on 17/5/17.
//  Copyright © 2017 Paper Band. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NPPenRegInfo : NSObject <NSCoding>

@property (strong, nonatomic) NSString  *penName;
@property (strong, nonatomic) NSString  *penMac;
@property (strong, nonatomic) NSString  *penPasswd;
@property (strong, nonatomic) NSDate    *dateRegister;
@property (strong, nonatomic) NSDate    *dateLastUse;

@end
