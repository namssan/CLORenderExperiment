//
//  NPPenRegInfo.m
//  BlueOcean
//
//  Created by Sang Nam on 17/5/17.
//  Copyright © 2017 Paper Band. All rights reserved.
//

#import "NPPenRegInfo.h"

#define kNPPenRegInfoPenName                            @"kNPPenRegInfoPenName"
#define kNPPenRegInfoPenMac                             @"kNPPenRegInfoPenMac"
#define kNPPenRegInfoPenPasswd                          @"kNPPenRegInfoPenPasswd"
#define kNPPenRegInfoDateRegister                       @"kNPPenRegInfoDateRegister"
#define kNPPenRegInfoDateLastUse                        @"kNPPenRegInfoDateLastUse"


@implementation NPPenRegInfo

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(self) {
        [self setPenName:[aDecoder decodeObjectForKey:@"kNPPenRegInfoPenName"]];
        [self setPenMac:[aDecoder decodeObjectForKey:@"kNPPenRegInfoPenMac"]];
        [self setPenPasswd:[aDecoder decodeObjectForKey:@"kNPPenRegInfoPenPasswd"]];
        [self setDateRegister:[aDecoder decodeObjectForKey:@"kNPPenRegInfoDateRegister"]];
        [self setDateLastUse:[aDecoder decodeObjectForKey:@"kNPPenRegInfoDateLastUse"]];
        
        if(self.dateLastUse == nil) self.dateLastUse = [NSDate date];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if(_dateRegister == nil) _dateRegister = [NSDate date];
    if(_dateLastUse == nil) _dateLastUse = [NSDate date];
    
    [aCoder encodeObject:_penName forKey:@"kNPPenRegInfoPenName"];
    [aCoder encodeObject:_penMac forKey:@"kNPPenRegInfoPenMac"];
    [aCoder encodeObject:_penPasswd forKey:@"kNPPenRegInfoPenPasswd"];
    [aCoder encodeObject:_dateRegister forKey:@"kNPPenRegInfoDateRegister"];
    [aCoder encodeObject:_dateLastUse forKey:@"kNPPenRegInfoDateLastUse"];
    
}
- (BOOL)isEqual:(id)object
{
    NPPenRegInfo *rhs = (NPPenRegInfo *)object;
    return [self.penMac isEqualToString:rhs.penMac];
}

@end
