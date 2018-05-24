//
//  NPCommParser.h
//  BlueOcean
//
//  Created by Sang Nam on 17/5/17.
//  Copyright © 2017 Paper Band. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NeoPenService.h"

static inline BOOL isEmpty(id thing) {
    return (thing == nil  || [thing isKindOfClass:[NSNull class]] || ([thing respondsToSelector:@selector(length)] && [(NSData *)thing length] == 0) || ([thing respondsToSelector:@selector(count)] && [(NSArray *)thing count] == 0) || ([thing isKindOfClass:[NSString class]] && ([thing isEqualToString:@"null"] || [thing isEqualToString:@"NULL"])));
}

@interface NPCommParser : NSObject
    
@property (nonatomic) BOOL notifyNewPage;

+ (NPCommParser *) sharedInstance;

- (void) setSimplify:(BOOL)on;
- (void) setPressureFilter:(NPPressureFilter)filter;
- (void) setPressureFilterBezier:(CGPoint)ctr0 ctr1:(CGPoint)ctr1 ctr2:(CGPoint)ctr2;

- (void) setNoteIdList;
- (void) setPenPasswd:(NSString *)passwd;


- (void) writeReadyExchangeData:(BOOL)ready;
- (void) writePasswordData:(NSString *)password;


- (void) parsePenNewIdData:(unsigned char *)data withLength:(int) length;
- (void) parsePenUpDowneData:(unsigned char *)data withLength:(int) length;
- (void) parsePenStrokeData:(unsigned char *)data withLength:(int) length;
            

- (BOOL) parseReadyExchangeDataRequest:(unsigned char *)data withLength:(int) length;
- (NSString *) parseFWVersion:(unsigned char *)data withLength:(int) length;
- (void) parsePenPasswordRequest:(unsigned char *)data;
- (void) parsePenStatusData:(unsigned char *)data withLength:(int) length;
- (void) parseOfflineFileList:(unsigned char *)data withLength:(int) length;
- (void) parseOfflineFileListInfo:(unsigned char *)data withLength:(int) length;
- (void) parseOfflineFileStatus:(unsigned char *)data withLength:(int) length;
- (void) parseOfflineFileData:(unsigned char *)data withLength:(int) length;
- (void) parseOfflineFileInfoData:(unsigned char *)data withLength:(int) length;
- (BOOL) requestOfflineDataWithOwnerId:(UInt32)ownerId noteId:(UInt32)noteId;
- (BOOL) reqOfflineNoteList;



// SDK 2
- (void) sendAppInfo;
- (void) sendPenPassword:(NSString *)pinNumber;
- (void) parsePen2Data:(unsigned char *)data withLength:(int) length;
- (BOOL) reqOffline2NoteList;
- (BOOL) requestOffline2DataWithOwnerId:(UInt32)ownerId noteId:(UInt32)noteId;
@end
