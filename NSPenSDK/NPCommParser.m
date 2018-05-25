//
//  NPCommParser.m
//  BlueOcean
//
//  Created by Sang Nam on 17/5/17.
//  Copyright © 2017 Paper Band. All rights reserved.
//
#import "NPCommParser.h"
#import "NPCommManager.h"
#import "NPDot.h"
#import "NPDotChecker.h"

#import <zlib.h>
#import "ZipZap.h"


#define POINT_COUNT_MAX 1024
#define MAX_NODE_NUMBER 1024

@interface NPCommParser () <NPDotCheckerDeleteage>

@property (strong, nonatomic) NPCommManager *commManager;

@property (nonatomic) PenStateStruct *penStatus;
@property (nonatomic) PenStateStruct *penState;
@property (nonatomic) PenState2Struct *penStatus2;
@property (nonatomic) BOOL penDown;

@end

@implementation NPCommParser {
    
    BOOL _hasPenReset;
    NSString * _penPassword;
    NSUInteger _passwdCounter;
    NSUInteger _ownerId,_sectionId,_noteId,_pageId;
    
    // pressure filter
    NPPressureFilter _pressureFilterType;
    CGPoint _ctr0,_ctr1,_ctr2;
    
    float point_x[POINT_COUNT_MAX];
    float point_y[POINT_COUNT_MAX];
    float point_p[POINT_COUNT_MAX];
    int time_diff[POINT_COUNT_MAX];
    int point_count;
    UInt64 startTime;
    UInt16 pressureMax;
    
    float point_x_offline[POINT_COUNT_MAX];
    float point_y_offline[POINT_COUNT_MAX];
    float point_p_offline[POINT_COUNT_MAX];
    int time_diff_offline[POINT_COUNT_MAX];
    int point_count_offline;
    BOOL _offlineFileProcessing;
    
    NSMutableDictionary *_offlineFileList;
    UInt32 _offlineOwnerIdRequested;
    UInt32 _offlineNoteIdRequested;
    UInt16 _offlinePacketCount;
    UInt16 _offlinePacketSize;
    UInt16 _offlineSliceCount;
    UInt16 _offlineSliceSize;
    int _offlineLastPacketIndex;
    int _offlineLastSliceIndex;
    int _offlineLastSliceSize;
    int _offlineTotalDataSize;
    int _offlineTotalDataReceived;
    int _offlinePacketOffset;
    
    
    NSMutableData *_offlineData;
    NSMutableData *_offlinePacketData;
    int _offlineDataOffset;
    int _offlineDataSize;
    BOOL _cancelOfflineSync;


    NPDotChecker *_onDotChecker;
    NPDotChecker *_offDotChecker;
    
    
    // SDK2 packet parameters
    int _pcount;
    int _dleCount;
    bool _isSOFReceived;
    bool _isDLEData;
    
    NSMutableData *_packetData;
}


+ (NPCommParser *) sharedInstance {
    static NPCommParser *shared = nil;
    @synchronized(self) {
        if(!shared){
            shared = [[NPCommParser alloc] init];
        }
    }
    return shared;
}


- (instancetype)init {
    [self reInit];
    _ctr0 = CGPointMake(0.0, 0.0);
    _ctr1 = CGPointMake(0.5, 0.5);
    _ctr2 = CGPointMake(1.0, 1.0);
    _pressureFilterType = NPPressureFilterDefault;
    
    return self;
}


- (void)reInit {
    _hasPenReset = false;
    _passwdCounter = 0;
    _ownerId = 0;
    _sectionId = 0;
    _noteId = 0;
    _pageId = 0;
    
    point_count = 0;
    
    _onDotChecker = [[NPDotChecker alloc] init];
    _offDotChecker = [[NPDotChecker alloc] init];
    _onDotChecker.delegate = self;
    _onDotChecker.isOffline = NO;
    _offDotChecker.delegate = self;
    _offDotChecker.isOffline = YES;
    [_onDotChecker setSimplify:true];
    [_offDotChecker setSimplify:true];

}
- (NPCommManager *) commManager {
    if(_commManager == nil) {
        _commManager = [NPCommManager sharedInstance];
    }
    return _commManager;
}
- (id <NPOfflineDataDelegate>) delegateOffline {
    return self.commManager.delegateOffline;
}
- (id <NPPenPasswordDelegate>) delegatePenPassword {
    return self.commManager.delegatePenPassword;
}
- (id <NPDocumentHandler>) documentHandler {
    return self.commManager.documentHandler;
}
- (id <NPDotHandler>) dotHandler {
    return self.commManager.dotHandler;
}

- (void) setSimplify:(BOOL)on {
    [_onDotChecker setSimplify:on];
}
- (void) setPenPasswd:(NSString *)passwd {
    _penPassword = passwd;
}

- (void) setPenDown:(BOOL)penDown
{
    if (point_count > 0) { // both penDown YES and NO
        NPStroke *stroke = [[NPStroke alloc] initWithRawDataX:point_x Y:point_y pressure:point_p time_diff:time_diff startTime:startTime size:point_count];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.documentHandler && [self.documentHandler respondsToSelector:@selector(addStroke:)]) {
                [self.documentHandler addStroke:stroke];
            }
        });
        point_count = 0;
    }
    
    if (penDown == YES) {
        UInt64 timeInMiliseconds = (UInt64)([[NSDate date] timeIntervalSince1970]*1000);
        startTime = timeInMiliseconds;
        [_onDotChecker setFirst];
    }
    else {
        [_onDotChecker setLast];
    }
    _penDown = penDown;
}
// 1)
- (void) parsePenNewIdData:(unsigned char *)data withLength:(int) length {
    
    COMM_CHANGEDID2_DATA *newIdData = (COMM_CHANGEDID2_DATA *)data;
    unsigned char section = (newIdData->owner_id >> 24) & 0xFF;
    UInt32 owner = newIdData->owner_id & 0x00FFFFFF;
    UInt32 noteId = newIdData->note_id;
    UInt32 pageNumber = newIdData->page_id;
    
    if (!_notifyNewPage && ((_pageId == pageNumber) && (_noteId == noteId) && (_sectionId == section) && (_ownerId == owner)))  return;
    _ownerId = owner;
    _sectionId = section;
    _noteId = noteId;
    _pageId = pageNumber;
    _notifyNewPage = NO;
    
    NSLog(@"New Id Data noteId %u, pageNumber %u", (unsigned int)noteId, (unsigned int)pageNumber);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ((self.documentHandler != nil) && [self.documentHandler respondsToSelector:@selector(activeNoteDidChangeNotebookId:pageNumber:section:owner:strokeStartTime:)])
            [self.documentHandler activeNoteDidChangeNotebookId:noteId pageNumber:pageNumber section:section owner:owner strokeStartTime:startTime];
    });
}
// 2)
- (void) parsePenUpDowneData:(unsigned char *)data withLength:(int) length {
    // see the setter for _penDown. It is doing something important.
    COMM_PENUP_DATA *updownData = (COMM_PENUP_DATA *)data;
    if (updownData->upDown == 0) {
        [_onDotChecker reset];
        self.penDown = YES;
    } else {
        [_onDotChecker dotCheckerLast];
        self.penDown = NO;
    }
    UInt64 time = updownData->time;
    NSNumber *timeNumber = [NSNumber numberWithLongLong:time];
    NSNumber *noteid = [NSNumber numberWithInteger:_noteId];
    NSNumber *pageid = [NSNumber numberWithInteger:_pageId];
    NSString *status = (_penDown) ? @"down":@"up";
    NSDictionary *dotDic = [NSDictionary dictionaryWithObjectsAndKeys:
                               @"updown", @"type",
                               timeNumber, @"time",
                               status, @"status",
                               noteid, @"note_id",
                               pageid, @"page_id",
                               nil];
    if (self.dotHandler != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dotHandler processDot:dotDic];
        });
    }
}
// 3)
- (void) parsePenStrokeData:(unsigned char *)data withLength:(int) length {
    
    #define STROKE_PACKET_LEN   8
    if (self.penDown == NO) return;
    unsigned char packet_count = data[0];
    int strokeDataLength = length - 1;
    data++;
    
    for ( int i =0 ; i < packet_count; i++){
        if ((STROKE_PACKET_LEN * (i+1)) > strokeDataLength) break;
        [self parsePenStrokePacket:data];
        data = data + STROKE_PACKET_LEN;
    }
}
// 4) par pen coordinate
- (void) parsePenStrokePacket:(unsigned char *)data
{
    float int_x, int_y;
    float float_x, float_y;
    unsigned char diff;
    float pressure;
    
    if(self.commManager.isPenSDK2) {
        
        COMM2_WRITE_DATA *strokeData = (COMM2_WRITE_DATA *)data;
        int_x = (float)strokeData->x;
        int_y = (float)strokeData->y;
        float_x = (float)strokeData->f_x  * 0.01f;
        float_y = (float)strokeData->f_y  * 0.01f;
        diff = strokeData->diff_time;
        pressure = (float)strokeData->force;
        
    } else {
        COMM_WRITE_DATA *strokeData = (COMM_WRITE_DATA *)data;
        int_x = (float)strokeData->x;
        int_y = (float)strokeData->y;
        float_x = (float)strokeData->f_x  * 0.01f;
        float_y = (float)strokeData->f_y  * 0.01f;
        diff = strokeData->diff_time;
        pressure = (float)strokeData->force;
        
    }
    
    NPDot *dot = [NPDot new];
    dot.timeDiff = diff;
    dot.pressure = [self processPressure:pressure];
    dot.x = int_x + float_x;
    dot.y = int_y + float_y;
//    NSLog(@"Raw X %f, Y %f, P %f", int_x + float_x, int_y + float_y,dot.pressure);
//    NSLog(@"time %d, x %f, y %f, pressure %f", dot.diff_time, dot.x, dot.y, dot.pressure);
    [_onDotChecker dotChecker:dot];
}
- (void)appendDot:(NPDot *)dot isOffine:(BOOL)offline {

    if(offline) {
        point_x_offline[point_count_offline] = dot.x;
        point_y_offline[point_count_offline] = dot.y;
        point_p_offline[point_count_offline] = dot.pressure;
        time_diff_offline[point_count_offline] = dot.timeDiff;
        point_count_offline++;
        return;
    }
    
    point_x[point_count] = dot.x;
    point_y[point_count] = dot.y;
    point_p[point_count] = dot.pressure;
    time_diff[point_count] = dot.timeDiff;
    point_count++;
    
    if(point_count >= MAX_NODE_NUMBER){
        // call _penDown setter
        self.penDown = NO;
        self.penDown = YES;
    }
    
    NSNumber *noteid = [NSNumber numberWithInteger:_noteId];
    NSNumber *pageid = [NSNumber numberWithInteger:_pageId];
    NSDictionary *new_dot = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"stroke", @"type",
                             dot, @"dot",
                             noteid, @"note_id",
                             pageid, @"page_id",
                             nil];
    
    if (self.dotHandler != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dotHandler processDot:new_dot];
        });
    }
}



//////////////////////////////////////////////////////////////////
//
//
//             Offline
//
//////////////////////////////////////////////////////////////////
- (BOOL) reqOfflineNoteList {
    if (_offlineFileProcessing) return NO;
    
    _offlineFileList = [[NSMutableDictionary alloc] init];
    RequestOfflineFileListStruct request;
    request.status = 0x00;
    NSData *data = [NSData dataWithBytes:&request length:sizeof(request)];
    [self.commManager writeRequestOfflineFileList:data];
    return YES;
}
- (BOOL) requestOfflineDataWithOwnerId:(UInt32)ownerId noteId:(UInt32)noteId {
    NSArray *noteList = [_offlineFileList objectForKey:[NSNumber numberWithUnsignedInt:ownerId]];
    if (noteList == nil) return NO;
    if ([noteList indexOfObject:[NSNumber numberWithUnsignedInt:noteId]] == NSNotFound) return NO;
    
    RequestOfflineFileStruct request;
    request.sectionOwnerId = ownerId;
    request.noteCount = 1;
    request.noteId[0] = noteId;
    NSData *data = [NSData dataWithBytes:&request length:sizeof(request)];
    [self.commManager writeRequestOfflineFile:data];
    return YES;
}
- (void) offlineFileAckForType:(unsigned char)type index:(unsigned char)index {
    OfflineFileAckStruct fileAck;
    fileAck.type = type;
    fileAck.index = index;
    NSData *data = [NSData dataWithBytes:&fileAck length:sizeof(fileAck)];
    [self.commManager writeOfflineFileAck:data];
}
- (void) parseOfflineFileList:(unsigned char *)data withLength:(int) length {
    OfflineFileListStruct *fileList = (OfflineFileListStruct *)data;
    int noteCount = MIN(fileList->noteCount, 10);
//    unsigned char section = (fileList->sectionOwnerId >> 24) & 0xFF;
//    UInt32 ownerId = fileList->sectionOwnerId & 0x00FFFFFF;
    if (noteCount == 0) return;
    
    NSNumber *sectionOwnerId = [NSNumber numberWithUnsignedInteger:fileList->sectionOwnerId];
    NSMutableArray *noteArray = [_offlineFileList objectForKey:sectionOwnerId];
    if (noteArray == nil) {
        noteArray = [[NSMutableArray alloc] initWithCapacity:noteCount];
        [_offlineFileList setObject:noteArray forKey:sectionOwnerId];
    }
    NSLog(@"OfflineFileList owner : %@", sectionOwnerId);
    for (int i=0; i < noteCount; i++) {
        NSNumber *noteId = [NSNumber numberWithUnsignedInteger:fileList->noteId[i]];
        NSLog(@"OfflineFileList note : %@", noteId);
        [noteArray addObject:noteId];
    }
    
    if (fileList->status == 0) {
        NSLog(@"More offline File List remained");
    } else {
        if ([[_offlineFileList allKeys] count] > 0) {
            NSLog(@"Getting offline File List finished");
            dispatch_async(dispatch_get_main_queue(), ^{
                if(self.delegateOffline && [self.delegateOffline respondsToSelector:@selector(offlineDataDidReceiveNoteList:)])
                    [self.delegateOffline offlineDataDidReceiveNoteList:_offlineFileList];
            });
        }
    }
}
- (void) parseOfflineFileListInfo:(unsigned char *)data withLength:(int) length
{
    OfflineFileListInfoStruct *fileInfo = (OfflineFileListInfoStruct *)data;
    NSLog(@"OfflineFileListInfo file Count %d, size %d", (unsigned int)fileInfo->fileCount, (unsigned int)fileInfo->fileSize);
    _offlineTotalDataSize = fileInfo->fileSize;
    _offlineTotalDataReceived = 0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegateOffline offlineDataReceiveStatus:OFFLINE_DATA_RECEIVE_START percent:0.0];
    });
}

-(BOOL) requestNextOfflineNote
{
    _offlineFileProcessing = YES;
    BOOL needNext = YES;
    NSEnumerator *enumerator = [_offlineFileList keyEnumerator];
    while (needNext) {
        NSNumber *ownerId = [enumerator nextObject];
        if (ownerId == nil) {
            _offlineFileProcessing = NO;
            NSLog(@"Offline data : no more file left");
            return NO;
        }
        NSArray *noteList = [_offlineFileList objectForKey:ownerId];
        if ([noteList count] == 0) {
            [_offlineFileList removeObjectForKey:ownerId];
            continue;
        }
        NSNumber *noteId = [noteList objectAtIndex:0];
        _offlineOwnerIdRequested = (UInt32)[ownerId unsignedIntegerValue];
        _offlineNoteIdRequested = (UInt32)[noteId unsignedIntegerValue];
        [self requestOfflineDataWithOwnerId:_offlineOwnerIdRequested noteId:_offlineNoteIdRequested];
        needNext = NO;
    }
    return YES;
}
-(void) didReceiveOfflineFileForOwnerId:(UInt32)ownerId noteId:(UInt32)noteId {
    NSNumber *ownerNumber = [NSNumber numberWithUnsignedInteger:ownerId];
    NSNumber *noteNumber = [NSNumber numberWithUnsignedInteger:noteId];
    NSMutableArray *noteList = [_offlineFileList objectForKey:ownerNumber];
    if (noteList == nil) {
        return;
    }
    NSUInteger index = [noteList indexOfObject:noteNumber];
    if (index == NSNotFound) {
        return;
    }
    [noteList removeObjectAtIndex:index];
}

- (void) parseOfflineFileInfoData:(unsigned char *)data withLength:(int) length {
    OFFLINE_FILE_INFO_DATA *fileInfo = (OFFLINE_FILE_INFO_DATA *)data;
    if (fileInfo->type == 1) {
        NSLog(@"Offline File Info : Zip file");
    } else {
        NSLog(@"Offline File Info : Normal file");
    }
    UInt32 fileSize = fileInfo->file_size;
    _offlinePacketCount = fileInfo->packet_count;
    _offlinePacketSize = fileInfo->packet_size;
    _offlineSliceCount = fileInfo->slice_count;
    _offlineSliceSize = fileInfo->slice_size;

    //    UInt16 packetSize = fileInfo->packet_size;
    NSLog(@"File size : %d, packet count : %d, packet size : %d", (unsigned int)fileSize, _offlinePacketCount, _offlinePacketSize);
    NSLog(@"Slice count : %d, slice size : %d", (unsigned int)_offlineSliceCount, _offlineSliceSize);
    _offlineLastPacketIndex = fileSize/_offlinePacketSize;
    int lastPacketSize = fileSize % _offlinePacketSize;
    if (lastPacketSize == 0) {
        _offlineLastPacketIndex -= 1;
        _offlineLastSliceIndex = _offlineSliceCount - 1;
        _offlineLastSliceSize = _offlineSliceSize;
    }
    else {
        _offlineLastSliceIndex = lastPacketSize / _offlineSliceSize;
        _offlineLastSliceSize = lastPacketSize % _offlineSliceSize;
        if (_offlineLastSliceSize == 0) {
            _offlineLastSliceIndex -= 1;
            _offlineLastSliceSize = _offlineSliceSize;
        }
    }
    _offlineData = [[NSMutableData alloc] initWithLength:fileSize];
    _offlinePacketData = nil;
    NSLog(@"self.offlinePacketData :nil");
    _offlineDataOffset = 0;
    _offlineDataSize = fileSize;
    [self offlineFileAckForType:1 index:0];  // 1 : header, index 0
}
- (void) parseOfflineFileData:(unsigned char *)data withLength:(int) length
{
    static int expected_slice = -1;
    static BOOL slice_valid = YES;
    
    OFFLINE_FILE_DATA *fileData = (OFFLINE_FILE_DATA *)data;
    int index = fileData->index;
    int slice_index = fileData->slice_index;
    unsigned char *dataReceived = &(fileData->data);
    if (slice_index == 0) {
        expected_slice = -1;
        slice_valid = YES;
        _offlinePacketOffset = 0;
        _offlinePacketData = [[NSMutableData alloc] initWithCapacity:_offlinePacketSize];
        NSLog(@"slice_index : 0, self.offlinePacketData : object creation");
    }
    int lengthToCopy = length - sizeof(fileData->index) - sizeof(fileData->slice_index);
    lengthToCopy = MIN(lengthToCopy, _offlineSliceSize);
    if (index == _offlineLastPacketIndex && slice_index == _offlineLastSliceIndex) {
        lengthToCopy = _offlineLastSliceSize;
    }
    else if ((_offlinePacketOffset + lengthToCopy) > _offlinePacketSize) {
        lengthToCopy = _offlinePacketSize - _offlinePacketOffset;
    }
    if (slice_valid == NO) return;
        
    expected_slice++;
    if (expected_slice != slice_index ) {
        NSLog(@"Bad slice index : expected %d, received %d", expected_slice, slice_index);
        slice_valid = NO;
        return; // Wait for next start
    }
    [_offlinePacketData appendBytes:dataReceived length:lengthToCopy];
    _offlinePacketOffset += lengthToCopy;
    if (slice_index == (_offlineSliceCount - 1) || (index == _offlineLastPacketIndex && slice_index == _offlineLastSliceIndex)) {
        [self offlineFileAckForType:2 index:(unsigned char)index]; // 2 : data
        NSRange range = {index*_offlinePacketSize, _offlinePacketOffset};
        NSLog(@"_offlinePacketData : %@",_offlinePacketData? @"YES":@"NO");
        [_offlineData replaceBytesInRange:range withBytes:[_offlinePacketData bytes]];
        _offlineDataOffset += _offlinePacketOffset;
        _offlinePacketOffset = 0;
        float percent = (float)((_offlineTotalDataReceived + _offlineDataOffset) * 100.0)/(float)_offlineTotalDataSize;
        [self notifyOfflineDataStatus:OFFLINE_DATA_RECEIVE_PROGRESSING percent:percent];
        NSLog(@"offlineDataOffset=%d, offlineDataSize=%d", _offlineDataOffset, _offlineDataSize);
    }
    if (_offlineDataOffset >= _offlineDataSize) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = paths[0];
        NSString *offlineFilePath = [documentDirectory stringByAppendingPathComponent:@"OfflineFile"];
        NSURL *url = [NSURL fileURLWithPath:offlineFilePath];
        NSFileManager *fm = [NSFileManager defaultManager];
        __block NSError *error = nil;
        [fm createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error];
        NSString *path = [offlineFilePath stringByAppendingPathComponent:@"offlineFile.zip"];
        [fm createFileAtPath:path contents:_offlineData attributes:nil];

        ZZArchive* offlineZip = [ZZArchive archiveWithURL:[NSURL fileURLWithPath:path] error:nil];
        ZZArchiveEntry* penDataEntry = offlineZip.entries[0];
        if ([penDataEntry check:&error]) {
            // GOOD
            NSLog(@"Offline zip file received successfully");
            NSData *penData = [penDataEntry newDataWithError:&error];
            if (penData != nil) {
                [self parseOfflinePenData:penData];
            }
            _offlineTotalDataReceived += _offlineDataSize;
        }
        else {
            // BAD
            NSLog(@"Offline zip file received badly");
        }
        _offlinePacketOffset = 0;
        _offlinePacketData = nil;
        NSLog(@"self.offlinePacketData2 :nil");
    }
}
- (void) parseOfflineFileStatus:(unsigned char *)data withLength:(int) length {
    OfflineFileStatusStruct *fileStatus = (OfflineFileStatusStruct *)data;
    if (fileStatus->status == 1) {
        [self didReceiveOfflineFileForOwnerId:_offlineOwnerIdRequested noteId:_offlineNoteIdRequested];
        [self notifyOfflineDataStatus:OFFLINE_DATA_RECEIVE_END percent:100.0f];
    } else {
        NSLog(@"OfflineFileStatus fail");
        [self notifyOfflineDataStatus:OFFLINE_DATA_RECEIVE_FAIL percent:0.0f];
    }
}
/* Parse data in a file from Pen. Need to know offline file format.*/
- (BOOL) parseOfflinePenData:(NSData *)penData
{
    int dataPosition = 0;
    unsigned long dataLength = [penData length];
    int headerSize = sizeof(OffLineDataFileHeaderStruct);
    dataLength -= headerSize;
    NSRange range = {dataLength, headerSize};
    OffLineDataFileHeaderStruct header;
    [penData getBytes:&header range:range];
    UInt32 noteId = header.nNoteId;
    UInt32 pageId = header.nPageId;
    UInt32 ownerId = (header.nOwnerId & 0x00FFFFFF);
    UInt32 sectionId = ((header.nOwnerId >> 24) & 0x000000FF);
    NSMutableArray *offlineStrokeArray = [NSMutableArray array];
    
    unsigned char char1, char2;
    OffLineDataStrokeHeaderStruct strokeHeader;
    
    UInt64 offlineLastStrokeStartTime = 0;
    while (dataPosition < dataLength) {
        if ((dataLength - dataPosition) < (sizeof(OffLineDataStrokeHeaderStruct) + 2)) break;
        range.location = dataPosition++;
        range.length = 1;
        [penData getBytes:&char1 range:range];
        range.location = dataPosition++;
        [penData getBytes:&char2 range:range];
        if (char1 == 'L' && char2 == 'N') {
            range.location = dataPosition;
            range.length = sizeof(OffLineDataStrokeHeaderStruct);
            [penData getBytes:&strokeHeader range:range];
            dataPosition += sizeof(OffLineDataStrokeHeaderStruct);
            if ((dataLength - dataPosition) < (strokeHeader.nDotCount * sizeof(OffLineDataDotStruct))) break;
            NPStroke *stroke = [self parseOfflineDots:penData startAt:dataPosition strokeHeader:&strokeHeader];
            dataPosition += (strokeHeader.nDotCount * sizeof(OffLineDataDotStruct));
            offlineLastStrokeStartTime = strokeHeader.nStrokeStartTime; // addedby namSSan 2015-03-10
            [offlineStrokeArray addObject:stroke];
        }
    }

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.delegateOffline && [self.delegateOffline respondsToSelector:@selector(didReceiveOfflineStrokes:notebookId:pageNumber:section:owner:)])
            [self.delegateOffline didReceiveOfflineStrokes:offlineStrokeArray notebookId:noteId pageNumber:pageId section:sectionId owner:ownerId];
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return YES;
}

- (void) notifyOfflineDataStatus:(OFFLINE_DATA_STATUS)status percent:(float)percent {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegateOffline offlineDataReceiveStatus:status percent:percent];
    });
}







































- (void)setNoteIdList {
    SetNoteIdListStruct noteIdList;
    NSData *data;
    
    noteIdList.type = 3;
    int index = 0;
    
    noteIdList.count = index;
    data = [NSData dataWithBytes:&noteIdList length:sizeof(noteIdList)];
    [self.commManager writeNoteIdList:data];
}
- (void) writePenStateData:(SetPenStateStruct)setPenStateData {
    NSData *data = [NSData dataWithBytes:&setPenStateData length:sizeof(setPenStateData)];
    [self.commManager writeSetPenState:data];
}
- (void) writeReadyExchangeData:(BOOL)ready {
    ReadyExchangeDataStruct request;
    request.ready = ready ? 1 : 0;
    NSData *data = [NSData dataWithBytes:&request length:sizeof(ReadyExchangeDataStruct)];
    [self.commManager writeReadyExchangeData:data];
    if (ready == YES) {
        [self reInit]; // pen is now ready --> reinit
        NSLog(@"isReadyExchangeSent set into YES because it is sent to Pen");
    } else if (ready == NO) {
        NSLog(@"isReadyExchangeSent set into NO because of disconnected signal");
    }
}
- (void) writePasswordData:(NSString *)password {
    PenPasswordResponseStruct response;
    NSData *stringData = [password dataUsingEncoding:NSUTF8StringEncoding];
    memcpy(response.password, [stringData bytes], sizeof(stringData));
    for(int i = 0 ; i < 12 ; i++) {
        response.password[i+4] = (unsigned char)NULL;
    }
    NSData *data = [NSData dataWithBytes:&response length:sizeof(PenPasswordResponseStruct)];
    [self.commManager writePenPasswordResponseData:data];
}




- (SetPenStateStruct)penStateData {

    SetPenStateStruct setPenStateData;
    UInt32 color = (self.penStatus)? self.penStatus->colorState : 0xFF000000;
    setPenStateData.colorState = (color & 0x00FFFFFF) | (0x01000000);
    setPenStateData.usePenTipOnOff = (self.penStatus)? self.penStatus->usePenTipOnOff : 1;
    setPenStateData.useAccelerator = (self.penStatus)? self.penStatus->useAccelerator : 1;
    setPenStateData.useHover = 2;
    setPenStateData.beepOnOff = (self.penStatus)? self.penStatus->beepOnOff : 1;
    setPenStateData.autoPwrOnTime = (self.penStatus)? self.penStatus->autoPwrOffTime : 15;
    setPenStateData.penPressure = (self.penStatus)? self.penStatus->penPressure : 20;
    
    NSTimeInterval timeInMiliseconds = [[NSDate date] timeIntervalSince1970]*1000;
    NSTimeZone *localTimeZone = [NSTimeZone localTimeZone];
    NSInteger millisecondsFromGMT = 1000 * [localTimeZone secondsFromGMT] + [localTimeZone daylightSavingTimeOffset]*1000;
    setPenStateData.timeTick=(UInt64)timeInMiliseconds;
    setPenStateData.timezoneOffset=(int32_t)millisecondsFromGMT;
    
    return setPenStateData;
}
- (void) parsePenStatusData:(unsigned char *)data withLength:(int) length {
    
    self.penStatus = (PenStateStruct *)data;
    
    
    //SDK2.0
    if (self.commManager.isPenSDK2) {
        if (self.penStatus2->offlineOnOff == 0) {
            unsigned char pOfflineOnOff = 1;
            [self requestPenStateType:PENSTATETYPE_OFFLINESAVE value:pOfflineOnOff];
        }
    } else {
        NSLog(@"penStatus %d, timezoneOffset %d, timeTick %llu", self.penStatus->penStatus, self.penStatus->timezoneOffset, self.penStatus->timeTick);
        NSLog(@"pressureMax %d, battery %d, memory %d", self.penStatus->pressureMax, self.penStatus->battLevel, self.penStatus->memoryUsed);
        NSLog(@"autoPwrOffTime %d, penPressure %d", self.penStatus->autoPwrOffTime, self.penStatus->penPressure);
        pressureMax = self.penStatus->pressureMax;
    }

    
    NSTimeInterval timeInMiliseconds = [[NSDate date] timeIntervalSince1970]*1000;
    NSTimeZone *localTimeZone = [NSTimeZone localTimeZone];
    NSInteger millisecondsFromGMT = 1000 * [localTimeZone secondsFromGMT] + [localTimeZone daylightSavingTimeOffset]*1000;
    
    if ((fabs(self.penStatus->timeTick - timeInMiliseconds) > 2000) || (self.penStatus->timezoneOffset != millisecondsFromGMT)) {
        NSLog(@"setPenStateWithTimeTick difference over 2000");
    }
}
- (BOOL) parseReadyExchangeDataRequest:(unsigned char *)data withLength:(int) length {
    ReadyExchangeDataRequestStruct *request = (ReadyExchangeDataRequestStruct *)data;
    return (request->ready == 1);
}
- (NSString *) parseFWVersion:(unsigned char *)data withLength:(int) length {
    return [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
    
}

- (void) parsePenPasswordRequest:(unsigned char *)data
{
    PenPasswordRequestStruct *request = (PenPasswordRequestStruct *)data;
    int maxCount = (int)request->resetCount;
    int retryCount = (int)request->retryCount;
    [self handlePenPasswordWithMaxCount:maxCount andRetryCount:retryCount];
}
// paswword
- (void) handlePenPasswordWithMaxCount:(int)resetCount andRetryCount:(int)retryCount {
    
    NSString *password = @"0000";
    if(!isEmpty(_penPassword)) password = _penPassword;
    int count = resetCount - retryCount;
    BOOL isSDK2 = self.commManager.isPenSDK2;
    if(!isSDK2) count -= 1; // SKD 1.0 start from 11
    
    NSLog(@"[PenCommParser] Perform Compare Passwd ==> reset count: %d , retry count: %d, self password counter: %tu",resetCount,retryCount,_passwdCounter);
    
    if(count <= 0) {
        // last attempt was failed we delete registration and disconnect pen
        _hasPenReset = true;
        NSLog(@"FAILED PASSWD VALIDATION ==> DISCONNECT PEN");
        if(!isSDK2) { [self.commManager setBTComparePassword:@"0000"]; }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.commManager disConnect];
            [[NSNotificationCenter defaultCenter] postNotificationName:NPPasswordValidationFailNotification object:nil userInfo:nil];
        });
        return;
    }
    if ((_passwdCounter == 0) && (count > 2)) {
        // try "0000" first in case when app does not recognize that pen has been reset
        NSLog(@"[PenCommParser] 1. try \"0000\" first");
        [self.commManager setBTComparePassword:@"0000"];
        _passwdCounter++;
        return;
    }
    if(_passwdCounter == 1 && !isEmpty(password) && (![password isEqualToString:@"0000"])) {
        NSLog(@"[PenCommParser] 2. try \"app password\"");
        [self.commManager setBTComparePassword:password];
//        [self writePasswordData:password];
        _passwdCounter++;
        return;
    }
    if(!_hasPenReset && self.delegatePenPassword && ([self.delegatePenPassword respondsToSelector:@selector(performComparePasswordWithCount:)])) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegatePenPassword performComparePasswordWithCount:count];
        });
    }
}
- (void) parsePenPasswordChangeResponse:(unsigned char *)data withLength:(int) length
{
    PenPasswordChangeResponseStruct *response = (PenPasswordChangeResponseStruct *)data;
    if (response->passwordState == 0x00) {
        NSLog(@"password change success");
    }else if(response->passwordState == 0x01){
        NSLog(@"password change fail");
    }
    BOOL PasswordChangeResult = (response->passwordState)? NO : YES;
    NSDictionary *info = @{@"result":[NSNumber numberWithBool:PasswordChangeResult]};
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:NPPasswordSetupSuccessNotification object:nil userInfo:info];
    });
}















- (void) setPressureFilter:(NPPressureFilter)filter {
    _pressureFilterType = filter;
}
- (void) setPressureFilterBezier:(CGPoint)ctr0 ctr1:(CGPoint)ctr1 ctr2:(CGPoint)ctr2 {
//    if(ctr0 < 0.0) { ctr0 = 0.0; }
//    if(ctr0 > 1.0) { ctr0 = 1.0; }
//    if(ctr1 < 0.0) { ctr1 = 0.0; }
//    if(ctr1 > 1.0) { ctr1 = 1.0; }
//    if(ctr2 < 0.0) { ctr2 = 0.0; }
//    if(ctr2 > 1.0) { ctr2 = 1.0; }
    
    _ctr0 = ctr0;
    _ctr1 = ctr1;
    _ctr2 = ctr2;
}
- (float) processPressure:(float)pressure
{
    if(pressureMax == 0) { pressureMax = 255.0; }
    float p = (pressure)/pressureMax;
    float px,py = p;
    if(_pressureFilterType == NPPressureFilterBezier) { // quadratic bezier function
        px = ((1 - p)*(1 - p)*_ctr0.x) + (2*p*(1 - p)*_ctr1.x) + (p*p*_ctr2.x);
        py = ((1 - p)*(1 - p)*_ctr0.y) + (2*p*(1 - p)*_ctr1.y) + (p*p*_ctr2.y);
    }
    if (py < 0.1) { py = 0.1; }
    if (py > 1.0) { py = 1.0; }
    NSLog(@"Pressure change: %f ---> (%f,%f)",p,px,py);
    return py;
}





























#define PACKET_START 0xC0
#define PACKET_END 0xC1
#define PACKET_DLE 0x7D
#define PACKET_MAX_LEN 32000
#define STROKE_SDK2_PACKET_LEN   13
#define STROKE2_SDK2_PACKET_LEN   7
#define STROKE3_SDK2_PACKET_LEN   5

//SDK2.0
- (void) parsePen2Data:(unsigned char *)data withLength:(int) length {
    int dataLength = length;
    //NSLog(@"Received:length = %d", dataLength);
    for ( int i =0 ; i < dataLength; i++) {
        [self _buildPacket:data];
        data = data + 1;
    }
}



- (void) _buildPacket:(unsigned char *)data
{
    int int_data = (int) (data[0] & 0xFF);
    
    // handle DLE
    if(int_data == PACKET_DLE) {
        _isDLEData = true;
        _dleCount++;
        return;
    }
    
    if(_isDLEData) {
        _isDLEData = false;
        data[0] = data[0] ^ 0x20;
        
        if(data[0] != PACKET_START && data[0] != PACKET_END && data[0] != PACKET_DLE) {
            NSLog(@"DLE WAS ACTUALLY DATA NOT DLE");
            int dle = PACKET_DLE;
            [_packetData appendBytes:&dle length:sizeof(dle)];
        }
    }
    
    if(int_data == PACKET_START) {
        if(_isSOFReceived) { // EOF is not received so we just try to parse previouse packet
            [self _parsePen2DataPacket:_packetData];
        }
        _pcount = 0;
        _dleCount = 0;
        _isSOFReceived = true;
        _packetData = [[NSMutableData alloc] init];
        return;
    }

    if (int_data == PACKET_END || (_pcount > PACKET_MAX_LEN)) {
        if(_isSOFReceived) { // normal case
            [self _parsePen2DataPacket:_packetData];
        }
        _isSOFReceived = false;
        return;
    }
    
    [_packetData appendBytes:data length:sizeof(data[0])];
    _pcount++;
}

- (BOOL) _getDataError:(NSMutableData *)data position:(int *)position {
    
    unsigned char char0;
    NSRange range;
    range.location = *position;
    range.length = 1;
    [data getBytes:&char0 range:range];
    (*position)++;
    
    return (char0 != 0); // 0: success , 1: faile , 3: forbidden
}

- (int) _getDataLength:(NSMutableData *)data position:(int *)position {
    
    unsigned char char0, char1;
    NSRange range;
    range.location = *position;
    range.length = 1;
    [data getBytes:&char0 range:range];
    (*position)++;
    
    range.location = *position;
    [data getBytes:&char1 range:range];
    (*position)++;
    int packetDataLength = (((int)char1 << 8) & 0xFF00) | ((int)char0 & 0xFF);
    
//    NSLog(@"data length :%d",packetDataLength);
    if(packetDataLength > (data.length - *position)) {
        NSLog(@"WRONG TOO SHORT PACKET");
        return -1;
    }
    return packetDataLength;
}

- (void) _parsePen2DataPacket:(NSMutableData*)packetData
{
    int packetDataLength = (int)packetData.length - _dleCount;
    if(packetDataLength <= 3) { return; }
    
    COMM2_WRITE_DATA *strokeData;
    COMM_CHANGEDID2_DATA *newIdData;
    COMM_PENUP_DATA *updownData;
    ReadyExchangeDataRequestStruct *exchange;
    PenPasswordRequestStruct *request;
    PenPasswordChangeResponseStruct *response;
    
    int dataPosition = 0;
    NSRange range;
    unsigned char char0, char1, char2, char3;
    range.location = dataPosition;
    range.length = 1;
    [packetData getBytes:&char0 range:range];
    PacketResponseCommand cmd = (PacketResponseCommand)char0;
    dataPosition++;
    
//    if(char0 != 0x65) { NSLog(@"CMD received: 0x%2X",char0); }
//    if(_dleCount > 0) { NSLog(@"DLE COUNT: %d",_dleCount); }

    switch ( cmd )
    {
        case PACKET_CMD_EVENT_PEN_DOTCODE:
        {
            strokeData = malloc(sizeof(COMM2_WRITE_DATA));
            
            unsigned char time, f_x, f_y; UInt16 force, x, y;
            
            packetDataLength = [self _getDataLength:packetData position:&dataPosition];
            int packet_count = packetDataLength / STROKE_SDK2_PACKET_LEN;
            
            BOOL shouldCheck = NO;
            int mid = packet_count / 2;
            
            for ( int i =0 ; i < packet_count; i++){
                if ((STROKE_SDK2_PACKET_LEN * (i+1)) > packetDataLength) {
                    break;
                }
                
                if ((dataPosition + STROKE_SDK2_PACKET_LEN) > packetData.length) {
                    NSLog(@"WILL BREAK STROKE LENTH SHORTER");
                    break;
                }
                
                
                shouldCheck = NO;
                if(i == mid) shouldCheck = YES;
                
                range.location = dataPosition;
                [packetData getBytes:&time range:range];
                strokeData->diff_time = time;
                dataPosition++;
                
                range.location = dataPosition;
                range.length = 2;
                [packetData getBytes:&force range:range];
                strokeData->force = force;
                dataPosition += 2;
                
                range.location = dataPosition;
                range.length = 2;
                [packetData getBytes:&x range:range];
                strokeData->x = x;
                dataPosition += 2;
                
                range.location = dataPosition;
                range.length = 2;
                [packetData getBytes:&y range:range];
                strokeData->y = y;
                dataPosition += 2;
                
                range.location = dataPosition;
                range.length = 1;
                [packetData getBytes:&f_x range:range];
                strokeData->f_x = f_x;
                dataPosition++;
                
                range.location = dataPosition;
                range.length = 1;
                [packetData getBytes:&f_y range:range];
                strokeData->f_y = f_y;
                dataPosition ++;
                
                [self parsePenStrokePacket:(unsigned char *)strokeData];
                dataPosition += 4; //x tilt 1, y tilt 1, twist 2
                
            }
            if(strokeData != nil) free(strokeData);
        }
            break;
            
        case PACKET_CMD_EVENT_PEN_DOTCODE2:
        {
            
            strokeData = malloc(sizeof(COMM2_WRITE_DATA));
            
            unsigned char time, f_x, f_y; UInt16 force, x, y;
            
            packetDataLength = [self _getDataLength:packetData position:&dataPosition];
            int packet_count = packetDataLength / STROKE2_SDK2_PACKET_LEN;
            
            BOOL shouldCheck = NO;
            int mid = packet_count / 2;
            
            for ( int i =0 ; i < packet_count; i++){
                if ((STROKE2_SDK2_PACKET_LEN * (i+1)) > packetDataLength) {
                    break;
                }
                
                shouldCheck = NO;
                if(i == mid) shouldCheck = YES;
                
                range.location = dataPosition;
                [packetData getBytes:&time range:range];
                strokeData->diff_time = time;
                dataPosition++;
                
                range.location = dataPosition;
                range.length = 2;
                [packetData getBytes:&x range:range];
                strokeData->x = x;
                dataPosition += 2;
                
                range.location = dataPosition;
                range.length = 2;
                [packetData getBytes:&y range:range];
                strokeData->y = y;
                dataPosition += 2;
                
                range.location = dataPosition;
                range.length = 1;
                [packetData getBytes:&f_x range:range];
                strokeData->f_x = f_x;
                dataPosition++;
                
                range.location = dataPosition;
                range.length = 1;
                [packetData getBytes:&f_y range:range];
                strokeData->f_y = f_y;
                
                force = 500;
                strokeData->force = force;
                
//                [self parsePenStrokePacket:(unsigned char *)strokeData withLength:sizeof(COMM2_WRITE_DATA) withCoordCheck:shouldCheck];
                
            }
            if(strokeData != nil) free(strokeData);
        }
            break;
            
        case PACKET_CMD_EVENT_PEN_DOTCODE3:
        {
            
            strokeData = malloc(sizeof(COMM2_WRITE_DATA));
            
            unsigned char time, f_x, f_y, x, y; UInt16 force;
            
            packetDataLength = [self _getDataLength:packetData position:&dataPosition];
            int packet_count = packetDataLength / STROKE3_SDK2_PACKET_LEN;
            
            BOOL shouldCheck = NO;
            int mid = packet_count / 2;
            
            for ( int i =0 ; i < packet_count; i++){
                if ((STROKE3_SDK2_PACKET_LEN * (i+1)) > packetDataLength) {
                    break;
                }
                
                shouldCheck = NO;
                if(i == mid) shouldCheck = YES;
                
                range.location = dataPosition;
                [packetData getBytes:&time range:range];
                strokeData->diff_time = time;
                dataPosition++;
                
                range.location = dataPosition;
                range.length = 1;
                [packetData getBytes:&x range:range];
                
                strokeData->x = (unsigned short)x;
                dataPosition++;
                
                range.location = dataPosition;
                range.length = 1;
                [packetData getBytes:&y range:range];
                strokeData->y = (unsigned short)y;
                dataPosition++;
                
                range.location = dataPosition;
                range.length = 1;
                [packetData getBytes:&f_x range:range];
                strokeData->f_x = f_x;
                dataPosition++;
                
                range.location = dataPosition;
                range.length = 1;
                [packetData getBytes:&f_y range:range];
                strokeData->f_y = f_y;
                
                force = 500;
                strokeData->force = force;
                
//                [self parsePenStrokePacket:(unsigned char *)strokeData withLength:sizeof(COMM2_WRITE_DATA) withCoordCheck:shouldCheck];
                
            }
            if(strokeData != nil) free(strokeData);
        }
            break;
            
        case PACKET_CMD_EVENT_PEN_UPDOWN:
        {
            updownData = malloc(sizeof(COMM_PENUP_DATA));
            
            packetDataLength = [self _getDataLength:packetData position:&dataPosition];
            
            UInt8 updown; UInt64 time_stamp; UInt8 penTipType; UInt32 penTipColor;
            
            range.location = dataPosition;
            [packetData getBytes:&updown range:range];
            updownData->upDown = updown;
            dataPosition++;
            
            range.location = dataPosition;
            range.length = 8;
            [packetData getBytes:&time_stamp range:range];
            updownData->time = time_stamp;
            dataPosition += 8;
            
            range.location = dataPosition;
            range.length = 1;
            [packetData getBytes:&penTipType range:range];
            dataPosition++;
            
            range.location = dataPosition;
            range.length = 4;
            [packetData getBytes:&penTipColor range:range];
            updownData->penColor = penTipColor;
            
            [self parsePenUpDowneData:(unsigned char *)updownData withLength:sizeof(COMM_PENUP_DATA)];
            
            if(updownData != nil) free(updownData);
        }
            break;
            
        case PACKET_CMD_EVENT_PEN_NEWID:
        {
            
            newIdData = malloc(sizeof(COMM_CHANGEDID2_DATA));
            
            packetDataLength = [self _getDataLength:packetData position:&dataPosition];
            
            UInt32 section_owner, noteID, pageID;
            
            range.location = dataPosition;
            range.length = 4;
            [packetData getBytes:&section_owner range:range];
            newIdData->owner_id = section_owner;
            dataPosition += 4;
            
            range.location = dataPosition;
            [packetData getBytes:&noteID range:range];
            newIdData->note_id = noteID;
            dataPosition += 4;
            
            range.location = dataPosition;
            [packetData getBytes:&pageID range:range];
            newIdData->page_id = pageID;
            
            [self parsePenNewIdData:(unsigned char*)newIdData withLength:sizeof(COMM_CHANGEDID2_DATA)];
            
            if(newIdData != nil) free(newIdData);
        }
            break;
            
        case PACKET_CMD_EVENT_PWR_OFF:
        {
            
            exchange = malloc(sizeof(ReadyExchangeDataRequestStruct));
            
            packetDataLength = [self _getDataLength:packetData position:&dataPosition];
            
            UInt8 reason;
            
            range.location = dataPosition;
            [packetData getBytes:&reason range:range];
            dataPosition++;
            
            //0: auto pwr off, 1:low batt, 2: update, 3: pwr key, 4: pen can pwr off, 5: system alert, 6: usb disk in, 7: wrong pw
            exchange->ready = 0;
            //[self parseReadyExchangeDataRequest:(unsigned char*)exchange withLength:sizeof(ReadyExchangeDataRequestStruct)];
            [self.commManager disConnect];
            
            if (reason == 2){
                //[self notifyFWUpdateStatus:FW_UPDATE_DATA_RECEIVE_END percent:100];
            }
            if(exchange != nil) free(exchange);
        }
            break;
//
//        case PACKET_CMD_EVENT_BATT_ALARM:
//        {
//            self.penState = malloc(sizeof(PenStateStruct));
//            
//            range.location = dataPosition;
//            [packetData getBytes:&char1 range:range];
//            dataPosition++;
//            
//            range.location = dataPosition;
//            [packetData getBytes:&char2 range:range];
//            dataPosition++;
//            _packetDataLength = (((int)char2 << 8) & 0xFF00) | ((int)char1 & 0xFF);
//            
//            UInt8 battery;
//            
//            range.location = dataPosition;
//            [packetData getBytes:&battery range:range];
//            dataPosition++;
//            self.penState->battLevel = battery;
//            
//            if(self.penStatus2 == nil) return;
//            
//            self.penState->timeTick = self.penStatus2->timeTick;
//            self.penState->autoPwrOffTime = self.penStatus2->autoPwrOffTime;
//            self.penState->memoryUsed = self.penStatus2->memoryUsed;
//            self.penState->usePenTipOnOff = self.penStatus2->usePenTipOnOff;
//            self.penState->beepOnOff = self.penStatus2->beepOnOff;
//            self.penState->useHover = self.penStatus2->useHover;
//            self.penState->penPressure = self.penStatus2->penPressure;
//            
//            [self parsePenStatusData:(unsigned char *)self.penState withLength:sizeof(PenStateStruct)];
//            
//            
//        }
//            break;
//            
        
            
        
            
        case PACKET_CMD_RES1_FW_FILE:
        {
            //error code
            range.location = dataPosition;
            [packetData getBytes:&char1 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char2 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char3 range:range];
            dataPosition++;
            packetDataLength = (((int)char3 << 8) & 0xFF00) | ((int)char2 & 0xFF);
            
            NSLog(@"Res1 FW File error code : %d, %@", char1, (char1 == 0)? @"Success":@"Fail");
            
            if ((char1 != 0) || (packetData.length < (packetDataLength + 4))) return;
            
            UInt8 transPermission;
            
            range.location = dataPosition;
            range.length = 1;
            [packetData getBytes:&transPermission range:range];
            
            NSLog(@"transPermission: %d", transPermission);
            
        }
            
            break;
            
        case PACKET_CMD_REQ2_FW_FILE:
            
        {
            range.location = dataPosition;
            [packetData getBytes:&char1 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char2 range:range];
            dataPosition++;
            packetDataLength = (((int)char2 << 8) & 0xFF00) | ((int)char1 & 0xFF);
            
            UInt8 status; UInt32 fileOffset;
            
            range.location = dataPosition;
            range.length = 1;
            [packetData getBytes:&status range:range];
            dataPosition++;
            
            NSLog(@"status:%d, %@", status, (status!= 3)? @"Success":@"Fail");
            
            range.location = dataPosition;
            range.length = 4;
            [packetData getBytes:&fileOffset range:range];
            
//            [self sendUpdateFileData2At:fileOffset AndStatus:status];
            
        }
            
            
            break;
        
            
        // OFFLINE 1 - res notebook list
        case PACKET_CMD_RES_OFFLINE_NOTE_LIST:
            [self _receiveOfflineNoteList:packetData position:dataPosition];
            break;

        // SKIP - OFFLINE PAGE REQ / RES
        // OFFLINE 2 - res stroke cnt and
        case PACKET_CMD_RES_OFFLINE_STROKE_META:
            [self _receiveOfflineStrokeMeta:packetData position:dataPosition];
            break;
            
        // OFFLINE 3 - res stroke data
        case PACKET_CMD_RES_OFFLINE_DATA:
            [self _receiveOfflineStrokeData:packetData position:dataPosition];
            break;
            
        case PACKET_CMD_RES_OFFLINE_PAGE_LIST:
        {
            //error code
            range.location = dataPosition;
            [packetData getBytes:&char1 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char2 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char3 range:range];
            dataPosition++;
            packetDataLength = (((int)char3 << 8) & 0xFF00) | ((int)char2 & 0xFF);
            
            NSLog(@"Res2 offline page list error code : %d, %@", char1, (char1 == 0)? @"Success":@"Fail");
            
            if ((char1 != 0) || (packetData.length < (packetDataLength + 4))) return;
            
            UInt32 pageId[10], page_ID; UInt16 pageCount;
            
            range.location = dataPosition;
            range.length = 2;
            [packetData getBytes:&pageCount range:range];
            dataPosition += 2;
            
            range.length = 4;
            for(int i = 0 ; i < pageCount ; i++) {
                range.location = dataPosition;
                [packetData getBytes:&page_ID range:range];
                pageId[i] = page_ID;
                dataPosition += 4;
            }
            
        }
            break;
            
        case PACKET_CMD_RES_SET_NOTE_LIST:
        {
            //error code
            range.location = dataPosition;
            [packetData getBytes:&char1 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char2 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char3 range:range];
            dataPosition++;
            packetDataLength = (((int)char3 << 8) & 0xFF00) | ((int)char2 & 0xFF);
            
            NSLog(@"Res set note list error code : %d, %@", char1, (char1 == 0)? @"Success":@"Fail");
            
            if (char1 != 0){
                return;
            }else if (char1 == 0){
                self.commManager.penConnectionStatus = NPConnectionStatusConnected;
            }
        }
            break;
            
        case PACKET_CMD_RES_DEL_OFFLINE_DATA:
        {
            //error code
            range.location = dataPosition;
            [packetData getBytes:&char1 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char2 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char3 range:range];
            dataPosition++;
            packetDataLength = (((int)char3 << 8) & 0xFF00) | ((int)char2 & 0xFF);
            
            NSLog(@"Res delete offline data error code : %d, %@", char1, (char1 == 0)? @"Success":@"Fail");
            
            if ((char1 != 0) || (packetData.length < (packetDataLength + 4))) return;
            
            UInt8 noteCount; UInt32 note_ID_;
            
            range.location = dataPosition;
            [packetData getBytes:&noteCount range:range]; //deleted note count
            dataPosition++;
            
            range.length = 4;
            
            if (noteCount > 0) {
                for (int i = 0; i < noteCount; i ++) {
                    range.location = dataPosition;
                    [packetData getBytes:&note_ID_ range:range];
                    NSLog(@"note Id deleted %d", note_ID_);
                    dataPosition += 4;
                }
            }
            
        }
            break;
            
        case PACKET_CMD_RES_SET_PEN_STATE:
        {
            
            //error code
            range.location = dataPosition;
            [packetData getBytes:&char1 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char2 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char3 range:range];
            dataPosition++;
            packetDataLength = (((int)char3 << 8) & 0xFF00) | ((int)char2 & 0xFF);
            
            NSLog(@"Res set penState error code : %d, %@", char1, (char1 == 0)? @"Success":@"Fail");
            
            if (char1 != 0) return;
        }
            
            break;
            
        case PACKET_CMD_RES_VERSION_INFO:
        {
            
            //error code
            range.location = dataPosition;
            [packetData getBytes:&char1 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char2 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char3 range:range];
            dataPosition++;
            packetDataLength = (((int)char3 << 8) & 0xFF00) | ((int)char2 & 0xFF);
            
            NSLog(@"Res version info error code : %d, %@", char1, (char1 == 0)? @"Success":@"Fail");
            
            if ((char1 != 0) || (packetData.length < (packetDataLength + 4))) return;
            
            unsigned char deviceName[16]; unsigned char fwVer[16]; unsigned char protocolVer[8];
            unsigned char subName[16]; unsigned char mac[6]; UInt16 penType;
            
            range.location = dataPosition;
            range.length = 16;
            [packetData getBytes:&deviceName range:range];
            dataPosition += 16;
            
            range.location = dataPosition;
            range.length = 16;
            [packetData getBytes:&fwVer range:range];
            dataPosition += 16;
            
            range.location = dataPosition;
            range.length = 8;
            [packetData getBytes:&protocolVer range:range];
//            self.protocolVerStr = [NSString stringWithCString:protocolVer encoding:NSASCIIStringEncoding];
            dataPosition += 8;
            
            range.location = dataPosition;
            range.length = 16;
            [packetData getBytes:&subName range:range];
            dataPosition += 16;
            
            range.location = dataPosition;
            range.length = 2;
            [packetData getBytes:&penType range:range];
            dataPosition += 2;
            
            range.location = dataPosition;
            range.length = 6;
            [packetData getBytes:&mac range:range];
            
            NSString *dName = [[NSString alloc] initWithBytes:deviceName length:sizeof(deviceName) encoding:NSUTF8StringEncoding];
//            _commManager.deviceName = [NSString stringWithCString:[dName UTF8String] encoding:NSUTF8StringEncoding];
            
            NSString *sName = [[NSString alloc] initWithBytes:subName length:sizeof(subName) encoding:NSUTF8StringEncoding];
//            _commManager.subName = [NSString stringWithCString:[sName UTF8String] encoding:NSUTF8StringEncoding];
            
            [self requestPenState];
            
        }
            break;
            
        case PACKET_CMD_RES_COMPARE_PWD:
        {
            request = malloc(sizeof(PenPasswordRequestStruct));
            
            //error code
            range.location = dataPosition;
            [packetData getBytes:&char1 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char2 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char3 range:range];
            dataPosition++;
            packetDataLength = (((int)char3 << 8) & 0xFF00) | ((int)char2 & 0xFF);
            
            NSLog(@"Res compare password error code : %d, %@", char1, (char1 == 0)? @"Success":@"Fail");
            
            if ((char1 != 0) || (packetData.length < (packetDataLength + 4))) {
                if(request != nil) free(request);
                return;
            }
            
            UInt8 status,retryCount, maxCount;
            
            range.location = dataPosition;
            [packetData getBytes:&status range:range];
            //request->status = status;
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&retryCount range:range];
            request->retryCount = retryCount;
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&maxCount range:range];
            request->resetCount = maxCount;
            
            if(status == 1) {
                [self sendNoteList];
                if (request != nil) free(request);
                
            } else {
                [self handlePenPasswordWithMaxCount:maxCount andRetryCount:retryCount];
            }
        }
            break;
            
            
        case PACKET_CMD_RES_CHANGE_PWD:
        {
            response = malloc(sizeof(PenPasswordChangeResponseStruct));
            
            //error code
            range.location = dataPosition;
            [packetData getBytes:&char1 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char2 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char3 range:range];
            dataPosition++;
            packetDataLength = (((int)char3 << 8) & 0xFF00) | ((int)char2 & 0xFF);
            
            NSLog(@"Res change password error code : %d, %@", char1, (char1 == 0)? @"Success":@"Fail");
            
            if ((char1 != 0) || (packetData.length < (packetDataLength + 4))) {
                if(response != nil) free(response);
                return;
            }
            
            UInt8 retryCount, maxCount;
            
            range.location = dataPosition;
            [packetData getBytes:&retryCount range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&maxCount range:range];
            
            response -> passwordState = char1;
            
            [self parsePenPasswordChangeResponse:(unsigned char*)response withLength:sizeof(PenPasswordChangeResponseStruct)];
            
            if(response != nil) free(response);
        }
            break;
            
        case PACKET_CMD_RES_PEN_STATE:
        {
            if(self.penStatus2 != nil) free(self.penStatus2);
            self.penState = malloc(sizeof(PenStateStruct));
            self.penStatus2 = malloc(sizeof(PenState2Struct));
            
            //error code
            range.location = dataPosition;
            [packetData getBytes:&char1 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char2 range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&char3 range:range];
            dataPosition++;
            packetDataLength = (((int)char3 << 8) & 0xFF00) | ((int)char2 & 0xFF);
            
            NSLog(@"Res pen state error code : %d, %@", char1, (char1 == 0)? @"Success":@"Fail");
            
            if ((char1 != 0) || (packetData.length < (packetDataLength + 4))){
                return;
            }
            
            UInt64 timeTick; UInt16 autoPwrOffTime, pressure_Max;
            UInt8 lock, maxRetryCnt, retryCnt, memory_Used, usePenCapOnOff, usePenTipOnOff, beepOnOff, useHover, battLevel, offlineOnOff, fsrStep, usbMode, downSampling;
            unsigned char btLocalName[16]; NSString *localName;
            
            range.location = dataPosition;
            [packetData getBytes:&lock range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&maxRetryCnt range:range];
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&retryCnt range:range];
            dataPosition++;
            
            range.location = dataPosition;
            range.length = sizeof(timeTick);
            [packetData getBytes:&timeTick range:range];
            self.penState->timeTick = timeTick;
            self.penStatus2->timeTick = timeTick;
            dataPosition += 8;
            
            range.location = dataPosition;
            range.length = 2;
            [packetData getBytes:&autoPwrOffTime range:range];
            self.penState->autoPwrOffTime = autoPwrOffTime;
            self.penStatus2->autoPwrOffTime = autoPwrOffTime;
            dataPosition += 2;
            
            range.location = dataPosition;
            range.length = 2;
            [packetData getBytes:&pressure_Max range:range];
            self.penState->pressureMax = pressure_Max;
            pressureMax = pressure_Max;
            dataPosition += 2;
            
            range.location = dataPosition;
            range.length = 1;
            [packetData getBytes:&memory_Used range:range];
            self.penState->memoryUsed = memory_Used;
            dataPosition++;
            
            range.location = dataPosition;
            [packetData getBytes:&usePenCapOnOff range:range];
            self.penStatus2->usePenCapOnOff = usePenCapOnOff;
            dataPosition ++;
            
            //auto power on
            range.location = dataPosition;
            [packetData getBytes:&usePenTipOnOff range:range];
            self.penState->usePenTipOnOff = usePenTipOnOff;
            self.penStatus2->usePenTipOnOff = usePenTipOnOff;
            dataPosition ++;
            
            range.location = dataPosition;
            [packetData getBytes:&beepOnOff range:range];
            self.penState->beepOnOff = beepOnOff;
            self.penStatus2->beepOnOff = beepOnOff;
            dataPosition ++;
            
            range.location = dataPosition;
            [packetData getBytes:&useHover range:range];
            self.penState->useHover = useHover;
            self.penStatus2->useHover = useHover;
            dataPosition ++;
            
            range.location = dataPosition;
            [packetData getBytes:&battLevel range:range];
            self.penState->battLevel = battLevel;
            dataPosition ++;
            
            range.location = dataPosition;
            [packetData getBytes:&offlineOnOff range:range];
            self.penStatus2->offlineOnOff = offlineOnOff;
            dataPosition ++;
            
            range.location = dataPosition;
            [packetData getBytes:&fsrStep range:range];
            self.penState->penPressure = (UInt16)fsrStep;
            self.penStatus2->penPressure = fsrStep;
            dataPosition ++;
            
            if ([packetData length] > dataPosition) {
                range.location = dataPosition;
                [packetData getBytes:&usbMode range:range];
                self.penStatus2->usbMode = usbMode;
                dataPosition ++;
                
                range.location = dataPosition;
                [packetData getBytes:&downSampling range:range];
                self.penStatus2->downSampling = downSampling;
                dataPosition ++;
                
                if ([packetData length] > (dataPosition + sizeof(btLocalName))) {
                    range.location = dataPosition;
                    range.length = 16;
                    [packetData getBytes:&btLocalName range:range];
                    NSString *lName = [[NSString alloc] initWithBytes:btLocalName length:sizeof(btLocalName) encoding:NSUTF8StringEncoding];
                    if(!isEmpty(lName))
                        localName = [NSString stringWithCString:[lName UTF8String] encoding:NSUTF8StringEncoding];
                }
            }
            
            if (char1 != 0){
                return;
            } else if (char1 == 0){
                [self parsePenStatusData:(unsigned char *)self.penState withLength:sizeof(PenStateStruct)];
                
                if(self.commManager.initialConnect) {
                    [self reInit];
                    if (lock == 1) { // lock == 1 : pen has a password
                        NSLog(@"PEN IS LOCKED!!!!");
                        [self handlePenPasswordWithMaxCount:maxRetryCnt andRetryCount:retryCnt];
                        [self.commManager stopConnectTimer];
                        
                    } else if (lock == 0){
                        [self sendNoteList];
                    }
                    self.commManager.initialConnect = NO;
                }
            }
            
        }
            break;
            
        default:
            NSLog(@"parsePen2DataPacket cmd error");
            break;
    }
}



// **************************************
// *
//          OFFLINE RES HANDLE
// *
// **************************************
- (void)_receiveOfflineNoteList:(NSMutableData *)packetData position:(int)dataPosition {
    
    //error code
    BOOL error = [self _getDataError:packetData position:&dataPosition];
    int packetDataLength = [self _getDataLength:packetData position:&dataPosition];
    
    if ((error) || (packetData.length < (packetDataLength + 4))) { return; }
    
    UInt32 sectionOwnerId[10], noteId[10], note_ID, section_ownerID; UInt16 setCount;
    
    NSRange range;
    range.location = dataPosition;
    range.length = 2;
    [packetData getBytes:&setCount range:range];
    
    dataPosition += 2;
    
    range.length = 4;
    for(int i = 0 ; i < setCount ; i++) {
        range.location = dataPosition;
        [packetData getBytes:&section_ownerID range:range];
        sectionOwnerId[i] = section_ownerID;
        dataPosition += 4;
        
        range.location = dataPosition;
        [packetData getBytes:&note_ID range:range];
        noteId[i] = note_ID;
        dataPosition += 4;
    }
    
    for(int i = 0 ; i < setCount ; i++) {
        
        NSNumber *sectionOwnerID = [NSNumber numberWithUnsignedInteger:sectionOwnerId[i]];
        NSMutableArray *noteArray = [_offlineFileList objectForKey:sectionOwnerID];
        
        if (noteArray == nil) {
            noteArray = [NSMutableArray array];
            [_offlineFileList setObject:noteArray forKey:sectionOwnerID];
        }
        NSNumber *noteID = [NSNumber numberWithUnsignedInteger:noteId[i]];
        [noteArray addObject:noteID];
    }
    
    if ([[_offlineFileList allKeys] count] > 0) {
        NSLog(@"Getting offline File List finished");
        dispatch_async(dispatch_get_main_queue(), ^{
            if((self.delegateOffline) && [self.delegateOffline respondsToSelector:@selector(offlineDataDidReceiveNoteList:)])
                [self.delegateOffline offlineDataDidReceiveNoteList:_offlineFileList];
        });
    }
}
- (void)_receiveOfflineStrokeMeta:(NSMutableData *)packetData position:(int)dataPosition {
    
    BOOL error = [self _getDataError:packetData position:&dataPosition];
    int packetDataLength = [self _getDataLength:packetData position:&dataPosition];
    
    if ((error) || (packetData.length < (packetDataLength + 4))){
        NSLog(@"OfflineFileStatus fail");
        [self notifyOfflineDataStatus:OFFLINE_DATA_RECEIVE_FAIL percent:0.0f];
        return;
    }
    
    UInt32 strokeNum; UInt32 offlineDataSize; UInt8 isZipped;
    
    NSRange range;
    range.location = dataPosition;
    range.length = 4;
    [packetData getBytes:&strokeNum range:range];
    dataPosition += 4;
    
    range.location = dataPosition;
    [packetData getBytes:&offlineDataSize range:range];
    dataPosition += 4;
    
    range.location = dataPosition;
    range.length = 1;
    [packetData getBytes:&isZipped range:range];
    
    _offlineTotalDataReceived = 0;
    _offlineTotalDataSize = offlineDataSize;
    
    [self notifyOfflineDataStatus:OFFLINE_DATA_RECEIVE_START percent:0.0f];
    NSLog(@"Res1 offline data info strokeCount: %d, offlineDataSize: %d isZipped: %d", strokeNum, offlineDataSize, isZipped);
}

- (void)_receiveOfflineStrokeData:(NSMutableData *)packetData position:(int)dataPosition {
    
    int packetDataLength = [self _getDataLength:packetData position:&dataPosition];
    
    UInt8 isZip, trasPosition; UInt16 packetId, sizeBeforeZip, sizeAfterZip, strokeCnt;
    UInt32 sectionOwnerId, noteId;
    OffLineData2HeaderStruct offlineDataHeader;
    
    NSRange range;
    range.location = dataPosition;
    range.length = 2;
    [packetData getBytes:&packetId range:range];
    dataPosition += 2;
    
    range.location = dataPosition;
    range.length = 1;
    [packetData getBytes:&isZip range:range];
    dataPosition ++;
    
    range.location = dataPosition;
    range.length = 2;
    [packetData getBytes:&sizeBeforeZip range:range];
    dataPosition +=2;
    
    range.location = dataPosition;
    [packetData getBytes:&sizeAfterZip range:range];
    dataPosition +=2;
    
    range.location = dataPosition;
    range.length = 1;
    [packetData getBytes:&trasPosition range:range];
    dataPosition ++;
    
    range.location = dataPosition;
    range.length = 4;
    [packetData getBytes:&sectionOwnerId range:range];
    dataPosition +=4;
    
    range.location = dataPosition;
    range.length = 4;
    [packetData getBytes:&noteId range:range];
    dataPosition +=4;
    
    range.location = dataPosition;
    range.length = 2;
    [packetData getBytes:&strokeCnt range:range];
    dataPosition +=2;
    
    NSLog(@"isZip:%d, sizeBeforeZip:%d, sizeAfterZip:%d, transPos:%d, sectionOwnerId:%d, noteId:%d, storkCnt:%d",isZip,sizeBeforeZip,sizeAfterZip,trasPosition,sectionOwnerId,noteId,strokeCnt);
    NSLog(@"packetDataSize:%lu, zipped Data size:%lu", packetData.length, packetData.length - dataPosition);
    
    offlineDataHeader.nSectionOwnerId = sectionOwnerId;
    offlineDataHeader.nNoteId = noteId;
    offlineDataHeader.nNumOfStrokes = strokeCnt;
    int transOption = (_cancelOfflineSync) ? 0 : 1;
    
    if (isZip) {
        
        NSData* zippedData = [NSData dataWithBytesNoCopy:(char *)[packetData bytes] + dataPosition
                                                  length:sizeAfterZip
                                            freeWhenDone:NO];
        
        NSMutableData* penData = [NSMutableData dataWithLength:sizeBeforeZip];
        
        uLongf destLen = penData.length;
        
        int result = uncompress OF(((Bytef*)penData.mutableBytes, &destLen,
                                    (Bytef*)zippedData.bytes, sizeAfterZip));
        
        if (result == Z_OK) {
            // GOOD
            NSLog(@"Offline zip file received successfully");
            if (penData != nil) {
                [self _parseOfflineStrokeData:penData offlineDataHeader:&offlineDataHeader];
            }
            _offlineTotalDataReceived += sizeBeforeZip;
            [self _ackOfflineDataWithPacketID:packetId errCode:0 AndTransOption:transOption];
        }
        else {
            // BAD
            NSLog(@"Offline zip file received badly, OfflineFileStatus fail");
            [self notifyOfflineDataStatus:OFFLINE_DATA_RECEIVE_FAIL percent:0.0f];
            [self _ackOfflineDataWithPacketID:packetId errCode:1 AndTransOption:transOption];
            
        }
    } else {
            [self _ackOfflineDataWithPacketID:packetId errCode:0 AndTransOption:transOption];
    }
    
    if (trasPosition == 2) {
        [self notifyOfflineDataStatus:OFFLINE_DATA_RECEIVE_END percent:100.0f];
    }else{
        float percent = (float)(_offlineTotalDataReceived * 100.0)/(float)_offlineTotalDataSize;
        NSLog(@"_offlineTotalDataReceived:%d sizeBeforeZip:%d, _offlineTotalDataSize:%d",_offlineTotalDataReceived,sizeBeforeZip,_offlineTotalDataSize);
        
        [self notifyOfflineDataStatus:OFFLINE_DATA_RECEIVE_PROGRESSING percent:percent];
    }
}
- (void)_ackOfflineDataWithPacketID:(UInt16)packetId errCode:(UInt8)errCode AndTransOption: (UInt8)transOption {
    
    Response2OffLineData request;
    request.cmd = 0xA4;
    request.errorCode = errCode;
    request.length = 3;
    request.packetId = packetId;
    request.transOption = transOption;
    
    NSMutableData *data = [NSMutableData dataWithBytes:&request length:sizeof(request)];
    [self sendPacketData:data];
}
- (void)_parseOfflineStrokeData:(NSData *)penData offlineDataHeader:(OffLineData2HeaderStruct* )offlineDataHeader
{
    UInt32 pageId = 0;
    UInt32 noteId = offlineDataHeader->nNoteId;
    UInt32 ownerId = (offlineDataHeader->nSectionOwnerId & 0x00FFFFFF);
    UInt32 sectionId = ((offlineDataHeader->nSectionOwnerId >> 24) & 0x000000FF);
    
    
    int dataPosition=0;
    unsigned long dataLength = [penData length];
    NSRange range;
    NSMutableDictionary *offlineDic = [[NSMutableDictionary alloc] init];
    
    OffLineData2StrokeHeaderStruct strokeHeader;
    UInt64 offlineLastStrokeStartTime = 0;
    
    while (dataPosition < dataLength) {
        
        NSMutableArray *offlineStrokeArray = [NSMutableArray array];
        if ((dataLength - dataPosition) < (sizeof(OffLineData2StrokeHeaderStruct) + 2)) break;
        range.location = dataPosition;
        range.length = sizeof(OffLineData2StrokeHeaderStruct);
        [penData getBytes:&strokeHeader range:range];
        dataPosition += sizeof(OffLineData2StrokeHeaderStruct);
        if ((dataLength - dataPosition) < (strokeHeader.nDotCount * sizeof(OffLineData2DotStruct))) {
            break;
        }
        pageId = strokeHeader.nPageId;
        NSString *pageStr = [NSString stringWithFormat:@"%03d",pageId];
        if([offlineDic objectForKey:pageStr] == nil) {
            [offlineDic setObject:offlineStrokeArray forKey:pageStr];
        } else {
            offlineStrokeArray = (NSMutableArray *)[offlineDic objectForKey:pageStr];
        }
        
        NPStroke *stroke = [self parseSDK2OfflineDots:penData startAt:dataPosition strokeHeader:&strokeHeader];
        [offlineStrokeArray addObject:stroke];
        
        dataPosition += (strokeHeader.nDotCount * sizeof(OffLineData2DotStruct));
        offlineLastStrokeStartTime = strokeHeader.nStrokeStartTime;
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.delegateOffline && [self.delegateOffline respondsToSelector:@selector(didReceiveOfflineStrokes:notebookId:pageNumber:section:owner:)])
            for (NSString *key in offlineDic.allKeys) {
                NSArray *strokes = offlineDic[key];
                UInt32 pId = key.integerValue;
                [self.delegateOffline didReceiveOfflineStrokes:strokes notebookId:noteId pageNumber:pId section:sectionId owner:ownerId];
            }
        
        dispatch_semaphore_signal(semaphore);
    });
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}
- (NPStroke *) parseOfflineDots:(NSData *)penData startAt:(int)position strokeHeader:(OffLineDataStrokeHeaderStruct *)pStrokeHeader {
    
    NSRange range = {position, sizeof(OffLineDataDotStruct)};
    int dotCount = MIN(MAX_NODE_NUMBER, (pStrokeHeader->nDotCount));
    point_count_offline = 0;
    UInt64 start_time_offline = pStrokeHeader->nStrokeStartTime;
    
    [_offDotChecker setFirst];
    for (int i =0; i < dotCount; i++) {
        
        OffLineDataDotStruct dt;
        [penData getBytes:&dt range:range];
        
        NPDot *dot = [NPDot new];
        dot.timeDiff = dt.nTimeDelta;
        dot.pressure = [self processPressure:dt.force];
        dot.x = dt.x + (dt.fx * 0.01f);
        dot.y = dt.y + (dt.fy * 0.01f);
        
        [_offDotChecker dotChecker:dot];
        position += sizeof(OffLineDataDotStruct);
        range.location = position;
    }
    [_offDotChecker setLast];
    NPStroke *stroke = [[NPStroke alloc] initWithRawDataX:point_x_offline Y:point_y_offline pressure:point_p_offline time_diff:time_diff_offline startTime:start_time_offline size:point_count_offline];
    
    return stroke;
}
- (NPStroke *) parseSDK2OfflineDots:(NSData *)penData startAt:(int)position strokeHeader:(OffLineData2StrokeHeaderStruct *)pStrokeHeader {
    
    NSRange range = {position, sizeof(OffLineData2DotStruct)};
    int dotCount = MIN(MAX_NODE_NUMBER, (pStrokeHeader->nDotCount));
    point_count_offline = 0;
    UInt64 start_time_offline = pStrokeHeader->nStrokeStartTime;
    
    [_offDotChecker setFirst];
    for (int i =0; i < dotCount; i++) {
        
        OffLineData2DotStruct dt;
        [penData getBytes:&dt range:range];
        
        NPDot *dot = [NPDot new];
        dot.timeDiff = dt.nTimeDelta;
        dot.pressure = [self processPressure:dt.force];
        dot.x = dt.x + (dt.fx * 0.01f);
        dot.y = dt.y + (dt.fy * 0.01f);
        
        [_offDotChecker dotChecker:dot];
        position += sizeof(OffLineData2DotStruct);
        range.location = position;
    }
    [_offDotChecker setLast];
    NPStroke *stroke = [[NPStroke alloc] initWithRawDataX:point_x_offline Y:point_y_offline pressure:point_p_offline time_diff:time_diff_offline startTime:start_time_offline size:point_count_offline];
    
    return stroke;
}


















- (void)requestPenStateType:(UInt8)type value:(UInt8)value
{
    NSLog(@"request pen state change : %d",type);
    UInt8 cmd; UInt16 length;
    NSMutableData *data = [[NSMutableData alloc] init];
    
    cmd = 0x05;
    length = sizeof(type) + sizeof(value);
    [data appendBytes:&cmd length:sizeof(UInt8)];
    [data appendBytes:&length length:sizeof(UInt16)];
    [data appendBytes:&type length:sizeof(UInt8)];
    [data appendBytes:&value length:sizeof(UInt8)];
    
    [self sendPacketData:data];
}

- (void) sendNoteList
{
    SetNoteIdList2Struct noteIdList;
    
    UInt8 cmd; UInt16 length, count;
    UInt32 sectionOwnerId, note_Id;
    unsigned char section_id;
    UInt32 owner_id;

    NSMutableData *data = [[NSMutableData alloc] init];
    cmd = 0x11;
    length = sizeof(noteIdList) - sizeof(cmd) - sizeof(length);
    count = 0xFFFF;
    [data appendBytes:&cmd length:sizeof(UInt8)];
    [data appendBytes:&length length:sizeof(UInt16)];
    [data appendBytes:&count length:sizeof(UInt16)];
    
    [self sendPacketData:data];
}
- (void) sendPenPassword:(NSString *)pinNumber
{
    SetPenPasswordStruct passwordStruct;
    
    UInt8 cmd; UInt16 length;
    unsigned char password[16];
    
    NSMutableData *data = [[NSMutableData alloc] init];
    cmd = 0x02;
    [data appendBytes:&cmd length:sizeof(UInt8)];
    
    length = sizeof(passwordStruct) - sizeof(cmd) - sizeof(length);// - 2;
    [data appendBytes:&length length:sizeof(UInt16)];
    
    memset(password, 0, sizeof(password));
    NSData *stringData = [pinNumber dataUsingEncoding:NSUTF8StringEncoding];
    memcpy(password, [stringData bytes], sizeof(stringData));
    for(int i = 0 ; i < 12 ; i++)
    {
        password[i+4] = (unsigned char)NULL;
    }
    [data appendBytes:&password length:sizeof(password)];
    [self sendPacketData:data];
}

- (void) requestPenState
{
    SetRequestPenStateStruct requestPenState;
    
    UInt8 cmd;
    UInt16 length;
    NSMutableData *data = [[NSMutableData alloc] init];
    
    cmd = 0x04;
    [data appendBytes:&cmd length:sizeof(UInt8)];
    length = sizeof(requestPenState) - sizeof(cmd) - sizeof(length);// - 2;
    [data appendBytes:&length length:sizeof(UInt16)];
    
    [self sendPacketData:data];
}


- (void) sendAppInfo {
    
    N2VersionInfoStruct setVersionInfo;
    UInt8  cmd;
    UInt16 length, appType;
    unsigned char connectionCode[16]; unsigned char appVer[16];
    NSMutableData *data = [[NSMutableData alloc] init];
    
    cmd = 0x01;
    [data appendBytes:&cmd length:sizeof(UInt8)];
    length = sizeof(setVersionInfo) - sizeof(cmd) - sizeof(length);// - 2;
    [data appendBytes:&length length:sizeof(UInt16)];
    memset(connectionCode, 0, sizeof(connectionCode));
    [data appendBytes:&connectionCode length:sizeof(connectionCode)];
    appType = 0x1001; // iOS
    [data appendBytes:&appType length:sizeof(UInt16)];
    
    memset(appVer, 0, sizeof(appVer));
    NSString *inputStr = @"1.0";
    NSData *stringData = [inputStr dataUsingEncoding:NSUTF8StringEncoding];
    memcpy(appVer, [stringData bytes], sizeof(stringData));
    [data appendBytes:&appVer length:sizeof(appVer)];
    
    [self sendPacketData:data];
}




// OFFLINE REQ 1 - note list
- (BOOL) reqOffline2NoteList {
    if (_offlineFileProcessing) return NO;
    
    _offlineFileList = [[NSMutableDictionary alloc] init];
    SetRequestOfflineFileListStruct request;
    
    request.cmd = 0x21;
    request.length = sizeof(request) - sizeof(request.cmd) - sizeof(request.length);
    request.sectionOwnerId = 0xFFFFFFFF;
    
    NSMutableData *data = [NSMutableData dataWithBytes:&request length:sizeof(request)];
    [self sendPacketData:data];
    return YES;
}
- (BOOL) requestOffline2DataWithOwnerId:(UInt32)ownerId noteId:(UInt32)noteId {
    SetRequestOfflineDataStruct request;
    UInt8 cmd, transOption, dataZipOption; UInt16 length;
    UInt32 sectionOwnerId, note_Id, pageCnt;
    NSUInteger count = 0; // 0 means for all pages
    
    NSMutableData *data = [[NSMutableData alloc] init];
    cmd = 0x23;
    [data appendBytes:&cmd length:sizeof(UInt8)];
    
    length = sizeof(request) - sizeof(cmd) - sizeof(length) + count*sizeof(pageCnt);
    [data appendBytes:&length length:sizeof(UInt16)];
    
    transOption = 1; // 1: delete file from the pen after transmission
    [data appendBytes:&transOption length:sizeof(UInt8)];
    
    dataZipOption = 1; // 1: zipped 0 : normal
    [data appendBytes:&dataZipOption length:sizeof(UInt8)];
    
    sectionOwnerId = ownerId;
    [data appendBytes:&sectionOwnerId length:sizeof(UInt32)];
    
    note_Id = noteId;
    [data appendBytes:&note_Id length:sizeof(UInt32)];
    pageCnt = count;
    [data appendBytes:&pageCnt length:sizeof(UInt32)];
    
    [self sendPacketData:data];
    return YES;
}

- (void) sendPacketData:(NSData *)data {
    
    UInt8  sof, eof;
    unsigned char dleData[1]; unsigned char packetData[1];
    unsigned char *tempDataBytes = (unsigned char *)[data bytes];
    NSMutableData *filteredPacketData = [[NSMutableData alloc] init];
    NSMutableData *wholePacketData = [[NSMutableData alloc] init];
    
    for ( int i =0 ; i < data.length; i++) {
        int int_data = (int) (tempDataBytes[0] & 0xFF);
        if ((int_data == PACKET_START) || (int_data == PACKET_END) || (int_data == PACKET_DLE)) {
            dleData[0] = PACKET_DLE;
            [filteredPacketData appendBytes:dleData length:sizeof(unsigned char)];
            packetData[0] = tempDataBytes[0] ^ 0x20;
            [filteredPacketData appendBytes:packetData length:sizeof(unsigned char)];
        } else {
            [filteredPacketData appendBytes:tempDataBytes length:sizeof(unsigned char)];
        }
        tempDataBytes = tempDataBytes + 1;
    }
    sof = PACKET_START;
    [wholePacketData appendBytes:&sof length:sizeof(UInt8)];
    [wholePacketData appendBytes:[filteredPacketData bytes] length:filteredPacketData.length];
    eof = PACKET_END;
    [wholePacketData appendBytes:&eof length:sizeof(UInt8)];
    
//    NSData *packet = [NSData dataWithData:wholePacketData];
//    NSLog(@"send Packet: %@", packet);
//    [self.commManager writePen2SetData:packet];
    
    
    NSUInteger btMtu = DEFAULT_BT_MTU;
    if(self.commManager.mtu > DEFAULT_BT_MTU) {
        btMtu = self.commManager.mtu;
    }
    
    if (wholePacketData.length > btMtu) {
        NSData *data = [NSData dataWithData:wholePacketData];
        //NSLog(@"setNoteList 0x11 data %@", data);
        
        NSUInteger dataLocation =  0;
        NSUInteger dataLength = 0;
        
        while (dataLocation < data.length) {
            if ((dataLocation + btMtu) > data.length ){
                dataLength = data.length - dataLocation;
            }
            else {
                dataLength = btMtu;
            }
            
            NSData *splitData = [NSData dataWithBytesNoCopy:(char *)[data bytes] + dataLocation
                                                     length:dataLength
                                               freeWhenDone:NO];
            
            NSLog(@"setNoteList 0x11 splitData %@", splitData);
            [self.commManager writePen2SetData:splitData];
            [NSThread sleepForTimeInterval:0.2];
            dataLocation += btMtu;
        }
        
    }  else {
        NSData *data = [NSData dataWithData:wholePacketData];
        [self.commManager writePen2SetData:data];
    }
}


@end
