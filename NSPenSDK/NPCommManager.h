//
//  PenCommManager.h
//  BlueOcean
//
//  Created by Sang Nam on 17/5/17.
//  Copyright © 2017 Paper Band. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "NeoPenService.h"
#import "NPPenRegInfo.h"
#import "NPStroke.h"

static NSString * const NPRegistrationNotification              = @"NPRegistrationNotification";
static NSString * const NPConnectionStatusNotification          = @"NPConnectionStatusNotification";

static NSString * const NPDidPageChangeNotification             = @"NPCommParserDidPageChangeNotification";
static NSString * const NPPasswordSetupSuccessNotification      = @"NPCommParserPenPasswordSetupSuccessNotification";
static NSString * const NPPasswordValidationFailNotification    = @"NPCommParserPenPasswordValidationFailNotification";
static NSString * const NPBatteryLowWarningNotification         = @"NPBatteryLowWarningNotification";


typedef enum {
    OFFLINE_DATA_RECEIVE_START,
    OFFLINE_DATA_RECEIVE_PROGRESSING,
    OFFLINE_DATA_RECEIVE_END,
    OFFLINE_DATA_RECEIVE_FAIL
} OFFLINE_DATA_STATUS;




@protocol NPPenConnectDelegate <NSObject>
- (NSArray <NPPenRegInfo *> *) penInfoList;
@end

@protocol NPOfflineDataDelegate <NSObject>
- (void) offlineDataDidReceiveNoteList:(NSDictionary *)noteListDictionary;
- (void) didReceiveOfflineStrokes:(NSArray <NPStroke *> *)strokes notebookId:(NSUInteger)notebookId pageNumber:(NSUInteger)pageNum section:(NSUInteger)section owner:(NSUInteger)owner;
@optional
- (void) offlineDataReceiveStatus:(OFFLINE_DATA_STATUS)status percent:(float)percent;
- (void) offlineDataPathBeforeParsed:(NSString *)path;
@end

@protocol NPPenPasswordDelegate <NSObject>
- (void) performComparePasswordWithCount:(int)countLeft;
@end

@protocol NPDocumentHandler <NSObject>
- (void) addStroke:(NPStroke *)stroke;
@optional
- (void) activeNoteDidChangeNotebookId:(NSUInteger)notebookId pageNumber:(NSUInteger)pageNumber section:(NSUInteger)section owner:(NSUInteger)owner strokeStartTime:(NSTimeInterval)startTime;
@end

@protocol NPDotHandler <NSObject>
- (void) processDot:(NSDictionary *)dotDic;
@end



typedef NS_ENUM (NSInteger, NPConnectionStatus) {
    NPConnectionStatusNone,
    NPConnectionStatusScanStarted,
    NPConnectionStatusConnecting,
    NPConnectionStatusConnected,
    NPConnectionStatusDisconnected,
};


typedef NS_ENUM (NSInteger, NPConnectionTrace) {
    NPConnectionTraceNone,
    NPConnectionTraceFailConnect,
    NPConnectionTraceFailTimeOut,
    NPConnectionTraceBTPowerOff,
    NPConnectionTraceNoMac,
    NPConnectionTraceNoPen,
    NPConnectionTraceMatchedMacFound,

};

typedef NS_ENUM (NSInteger, NPConnectionSort) {
    NPConnectionSortRecentUsed,
    NPConnectionSortStrongSignal,
};


@interface NPCommManager : NSObject



// delegates
@property (nonatomic, weak) id <NPPenConnectDelegate> delegatePenConnect;
@property (nonatomic, weak) id <NPPenPasswordDelegate> delegatePenPassword;
@property (nonatomic, weak) id <NPOfflineDataDelegate> delegateOffline;
// handlers
@property (nonatomic, weak) id <NPDocumentHandler> documentHandler;
@property (nonatomic, weak) id <NPDotHandler> dotHandler;



@property (nonatomic, readwrite) NPConnectionStatus penConnectionStatus;
@property (nonatomic, readwrite) NPConnectionTrace penConnectionTrace;

@property (nonatomic, strong) NSString *penUUID;
@property (nonatomic, strong) NSString *penName;
@property (nonatomic) BOOL isPenSDK2;
@property (nonatomic) BOOL isPenConnected;
@property (nonatomic) BOOL initialConnect;
@property (nonatomic) NSInteger mtu;
@property (nonatomic) NPConnectionSort connectSort;



+ (NPCommManager *) sharedInstance;

- (void) setSimplify:(BOOL)on;

- (void) requestNewPageNotification;
- (BOOL) requestOfflineFileList;
- (BOOL) requestOfflineDataWithOwnerId:(UInt32)ownerId noteId:(UInt32)noteId;


- (void) btStart;
- (void) btStartForRegister;
- (void) disConnect;
- (void) stopConnectTimer;

- (void) setBTComparePassword:(NSString *)pinNumber;
- (void) setPressureFilter:(NPPressureFilter)filter;
- (void) setPressureFilterBezier:(float)ctr0 ctr1:(float)ctr1 ctr2:(float)ctr2;

- (void) writePen2SetData:(NSData *)data;
- (void) writeSetPenState:(NSData *)data;
- (void) writeNoteIdList:(NSData *)data;
- (void) writeReadyExchangeData:(NSData *)data;
- (void) writePenPasswordResponseData:(NSData *)data;
- (void) writeRequestOfflineFileList:(NSData *)data;
- (void) writeRequestOfflineFile:(NSData *)data;
- (void) writeOfflineFileAck:(NSData *)data;


@end
