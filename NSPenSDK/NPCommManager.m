//
//  PenCommMannager.m
//  BlueOcean
//
//  Created by Sang Nam on 17/5/17.
//  Copyright © 2017 Paper Band. All rights reserved.
//
#import "NPCommManager.h"
#import "NPCommParser.h"

@interface NPPeripheralInfo : NSObject

@property (strong, nonatomic) NSString *mac;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *neoPenServiceUuid;
@property (nonatomic) NSInteger rssi;
@property (nonatomic) BOOL isSDK2;

@end
@implementation NPPeripheralInfo
@end

@interface NPCommManager() <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) NPCommParser *penCommParser;
// Pen Service
@property (strong, nonatomic) CBUUID *neoPenServiceUuid;
@property (strong, nonatomic) CBUUID *neoSystemServiceUuid;
@property (strong, nonatomic) NSArray *supportedServices;

@property (strong, nonatomic) CBUUID *neoOfflineDataServiceUuid;
@property (strong, nonatomic) CBUUID *neoOffline2DataServiceUuid;
@property (strong, nonatomic) CBUUID *neoUpdateServiceUuid;
@property (strong, nonatomic) CBUUID *neoDeviceInfoServiceUuid;
@property (strong, nonatomic) CBUUID *neoSystem2ServiceUuid;







// Pen Service
@property (strong, nonatomic) CBService *penService;
@property (strong, nonatomic) CBUUID *strokeDataUuid;
@property (strong, nonatomic) CBUUID *updownDataUuid;
@property (strong, nonatomic) CBUUID *idDataUuid;
@property (strong, nonatomic) NSArray *penCharacteristics;

// Pen SDK2.0 Service
@property (strong, nonatomic) CBService *pen2Service;
@property (strong, nonatomic) CBUUID *neoPen2ServiceUuid;
@property (strong, nonatomic) CBUUID *neoPen2SystemServiceUuid;
@property (strong, nonatomic) CBUUID *pen2DataUuid;
@property (strong, nonatomic) CBUUID *pen2SetDataUuid;
@property (strong, nonatomic) NSArray *pen2Characteristics;
@property (strong, nonatomic) CBCharacteristic *pen2SetDataCharacteristic;



@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheral *connectedPeripheral;


@property (strong, nonatomic) NSTimer *scanTimer;
@property (strong, nonatomic) NSTimer *connectTimer;

@property (nonatomic) NSInteger rssiIndex;
//@property (nonatomic) NSMutableArray *rssiArray;
//@property (nonatomic) NSMutableArray *macArray;
@property (strong, nonatomic) NSMutableArray *foundPeriphalralInfos;
@property (strong, nonatomic) NSMutableArray *discoveredPeripherals;


// System Service
@property (strong, nonatomic) CBService *systemService;
@property (strong, nonatomic) CBUUID *penStateDataUuid;
@property (strong, nonatomic) CBUUID *setPenStateUuid;
@property (strong, nonatomic) CBUUID *setNoteIdListUuid;
@property (strong, nonatomic) CBUUID *readyExchangeDataUuid;
@property (strong, nonatomic) CBUUID *readyExchangeDataRequestUuid;

@property (strong, nonatomic) NSArray *systemCharacteristics;
@property (strong, nonatomic) CBCharacteristic *setPenStateCharacteristic;
@property (strong, nonatomic) CBCharacteristic *setNoteIdListCharacteristic;
@property (strong, nonatomic) CBCharacteristic *readyExchangeDataCharacteristic;


// System Service 2
@property (strong, nonatomic) CBService *system2Service;
@property (strong, nonatomic) CBUUID *penPasswordRequestUuid;
@property (strong, nonatomic) CBUUID *penPasswordResponseUuid;
@property (strong, nonatomic) CBUUID *penPasswordChangeRequestUuid;
@property (strong, nonatomic) CBUUID *penPasswordChangeResponseUuid;

@property (strong, nonatomic) NSArray *system2Characteristics;
@property (strong, nonatomic) CBCharacteristic *penPasswordResponseCharacteristic;
@property (strong, nonatomic) CBCharacteristic *penPasswordChangeRequestCharacteristic;



// Offline Service
@property (strong, nonatomic) CBService *offlineService;
@property (strong, nonatomic) CBUUID *offlineFileInfoUuid;
@property (strong, nonatomic) CBUUID *offlineFileDataUuid;
@property (strong, nonatomic) CBUUID *offlineFileListInfoUuid;
@property (strong, nonatomic) CBUUID *requestOfflineFileUuid;
@property (strong, nonatomic) CBUUID *offlineFileStatusUuid;
@property (strong, nonatomic) CBUUID *requestOfflineFileListUuid;
@property (strong, nonatomic) CBUUID *offlineFileListUuid;
@property (strong, nonatomic) CBUUID *requestDelOfflineFileUuid;

@property (strong, nonatomic) NSArray *offlineCharacteristics;
@property (strong, nonatomic) CBCharacteristic *requestDelOfflineFileCharacteristic;
@property (strong, nonatomic) CBCharacteristic *requestOfflineFileCharacteristic;
@property (strong, nonatomic) CBCharacteristic *requestOfflineFileListCharacteristic;


// Offline Service 2
@property (strong, nonatomic) CBService *offline2Service;
@property (strong, nonatomic) CBUUID *offline2FileAckUuid;

@property (strong, nonatomic) NSArray *offline2Characteristics;
@property (strong, nonatomic) CBCharacteristic *offline2FileAckCharacteristic;



// Update Service
@property (strong, nonatomic) CBService *updateService;
@property (strong, nonatomic) CBUUID *updateFileInfoUuid;
@property (strong, nonatomic) CBUUID *requestUpdateUuid;
@property (strong, nonatomic) CBUUID *updateFileDataUuid;
@property (strong, nonatomic) CBUUID *updateFileStatusUuid;

@property (strong, nonatomic) NSArray *updateCharacteristics;
@property (strong, nonatomic) CBCharacteristic *sendUpdateFileInfoCharacteristic;
@property (strong, nonatomic) CBCharacteristic *updateFileDataCharacteristic;


// Device Information Service
@property (strong, nonatomic) CBService *deviceInfoService;
@property (strong, nonatomic) CBUUID *fwVersionUuid;
@property (strong, nonatomic) NSArray *deviceInfoCharacteristics;




@end

@interface NPCommManager (Relation)

@end


@implementation NPCommManager {
    
    dispatch_queue_t bt_write_dispatch_queue;
    BOOL _isForRegister;
    BOOL _idDataReady,_strokeDataReady,_upDownDataReady;
    NSUInteger _mtuReadRetry;
}

+ (NPCommManager *) sharedInstance {
    static NPCommManager *shared = nil;
    @synchronized(self) {
        if(!shared){
            shared = [[NPCommManager alloc] init];
        }
    }
    return shared;
}

- (instancetype)init {
    
    self.neoPenServiceUuid = [CBUUID UUIDWithString:NEO_PEN_SERVICE_UUID];
    
    // Pen Service
    self.strokeDataUuid = [CBUUID UUIDWithString:STROKE_DATA_UUID];
    self.updownDataUuid = [CBUUID UUIDWithString:UPDOWN_DATA_UUID];
    self.idDataUuid = [CBUUID UUIDWithString:ID_DATA_UUID];
    self.penCharacteristics = @[self.strokeDataUuid, self.updownDataUuid, self.idDataUuid];
    
    
    // Pen Service 2
    self.neoPen2ServiceUuid = [CBUUID UUIDWithString:NEO_PEN2_SERVICE_UUID];
    self.neoPen2SystemServiceUuid = [CBUUID UUIDWithString:NEO_PEN2_SYSTEM_SERVICE_UUID];
    self.pen2DataUuid = [CBUUID UUIDWithString:PEN2_DATA_UUID];
    self.pen2SetDataUuid = [CBUUID UUIDWithString:PEN2_SET_DATA_UUID];
    self.pen2Characteristics = @[self.pen2DataUuid, self.pen2SetDataUuid];
    
    
    // System Service
    self.neoSystemServiceUuid = [CBUUID UUIDWithString:NEO_SYSTEM_SERVICE_UUID];
    self.penStateDataUuid = [CBUUID UUIDWithString:PEN_STATE_UUID];
    self.setPenStateUuid = [CBUUID UUIDWithString:SET_PEN_STATE_UUID];
    self.setNoteIdListUuid = [CBUUID UUIDWithString:SET_NOTE_ID_LIST_UUID];
    self.readyExchangeDataUuid = [CBUUID UUIDWithString:READY_EXCHANGE_DATA_UUID];
    self.readyExchangeDataRequestUuid = [CBUUID UUIDWithString:READY_EXCHANGE_DATA_REQUEST_UUID];
    self.systemCharacteristics = @[self.penStateDataUuid, self.setPenStateUuid, self.setNoteIdListUuid , self.readyExchangeDataUuid, self.readyExchangeDataRequestUuid];
    
    
    // System2 Service
    self.neoSystem2ServiceUuid = [CBUUID UUIDWithString:NEO_SYSTEM2_SERVICE_UUID];
    self.penPasswordRequestUuid = [CBUUID UUIDWithString:PEN_PASSWORD_REQUEST_UUID];
    self.penPasswordResponseUuid = [CBUUID UUIDWithString:PEN_PASSWORD_RESPONSE_UUID];
    self.penPasswordChangeRequestUuid = [CBUUID UUIDWithString:PEN_PASSWORD_CHANGE_REQUEST_UUID];
    self.penPasswordChangeResponseUuid = [CBUUID UUIDWithString:PEN_PASSWORD_CHANGE_RESPONSE_UUID];
    self.system2Characteristics = @[self.penPasswordRequestUuid, self.penPasswordResponseUuid, self.penPasswordChangeRequestUuid, self.penPasswordChangeResponseUuid];
    
    
    
    // Offline data Service
    self.neoOfflineDataServiceUuid = [CBUUID UUIDWithString:NEO_OFFLINE_SERVICE_UUID];
    self.offlineFileListUuid = [CBUUID UUIDWithString:OFFLINE_FILE_LIST_UUID];
    self.requestOfflineFileListUuid = [CBUUID UUIDWithString:REQUEST_OFFLINE_FILE_LIST_UUID];
    self.requestDelOfflineFileUuid = [CBUUID UUIDWithString:REQUEST_DEL_OFFLINE_FILE_UUID];
    self.offlineCharacteristics = @[self.offlineFileListUuid, self.requestOfflineFileListUuid, _requestDelOfflineFileUuid];
    
    
    // Offline2 data Service
    self.neoOffline2DataServiceUuid = [CBUUID UUIDWithString:NEO_OFFLINE2_SERVICE_UUID];
    self.offlineFileInfoUuid = [CBUUID UUIDWithString:OFFLINE2_FILE_INFO_UUID];
    self.offlineFileDataUuid = [CBUUID UUIDWithString:OFFLINE2_FILE_DATA_UUID];
    self.offlineFileListInfoUuid = [CBUUID UUIDWithString:OFFLINE2_FILE_LIST_INFO_UUID];
    self.requestOfflineFileUuid = [CBUUID UUIDWithString:REQUEST_OFFLINE2_FILE_UUID];
    self.offlineFileStatusUuid = [CBUUID UUIDWithString:OFFLINE2_FILE_STATUS_UUID];
    self.offline2FileAckUuid = [CBUUID UUIDWithString:OFFLINE2_FILE_ACK_UUID];
    self.offline2Characteristics = @[self.offlineFileInfoUuid, self.offlineFileDataUuid, self.offlineFileListInfoUuid,
                                     self.requestOfflineFileUuid, self.offlineFileStatusUuid, self.offline2FileAckUuid];
    
    
    // Update Service
    self.neoUpdateServiceUuid = [CBUUID UUIDWithString:NEO_UPDATE_SERVICE_UUID];
    self.updateFileInfoUuid = [CBUUID UUIDWithString:UPDATE_FILE_INFO_UUID];
    self.requestUpdateUuid = [CBUUID UUIDWithString:REQUEST_UPDATE_FILE_UUID];
    self.updateFileDataUuid = [CBUUID UUIDWithString:UPDATE_FILE_DATA_UUID];
    self.updateFileStatusUuid = [CBUUID UUIDWithString:UPDATE_FILE_STATUS_UUID];
    self.updateCharacteristics = @[self.updateFileInfoUuid, self.requestUpdateUuid, self.updateFileDataUuid,
                                   self.updateFileStatusUuid];
    
    
    // Device Information Service
    self.neoDeviceInfoServiceUuid = [CBUUID UUIDWithString:NEO_DEVICE_INFO_SERVICE_UUID];
    self.fwVersionUuid = [CBUUID UUIDWithString:FW_VERSION_UUID];
    self.deviceInfoCharacteristics = @[self.fwVersionUuid];
    
    
    
    // Device Services
    self.supportedServices = @[self.neoPen2ServiceUuid, self.neoPen2SystemServiceUuid, self.neoPenServiceUuid, self.neoSystemServiceUuid, self.neoOfflineDataServiceUuid, self.neoOffline2DataServiceUuid, self.neoUpdateServiceUuid, self.neoDeviceInfoServiceUuid, self.neoSystem2ServiceUuid];
    
    
    
    _penConnectionStatus = NPConnectionStatusNone;
    _connectSort = NPConnectionSortRecentUsed;
    _isForRegister = NO;
    bt_write_dispatch_queue = dispatch_queue_create("bt_write_dispatch_queue", DISPATCH_QUEUE_SERIAL);
    return self;
}


- (NPCommParser *) penCommParser {
    if(_penCommParser == nil) {
        _penCommParser = [NPCommParser sharedInstance];
    }
    return _penCommParser;
}
- (CBCentralManager *) centralManager {
    if (_centralManager == nil) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue: (dispatch_queue_create("kr.neolab.penBT", NULL)) options:@{CBCentralManagerOptionShowPowerAlertKey:@YES}];
    }
    return _centralManager;
}
- (NSMutableArray *) discoveredPeripherals
{
    if (_discoveredPeripherals == nil) {
        _discoveredPeripherals = [[NSMutableArray alloc] init];
    }
    return _discoveredPeripherals;
}
- (NSMutableArray *) foundPeriphalralInfos {
    
    if (_foundPeriphalralInfos == nil) {
        _foundPeriphalralInfos = [[NSMutableArray alloc] init];
    }
    return _foundPeriphalralInfos;
}

- (void)setSimplify:(BOOL)on
{
    [self.penCommParser setSimplify:on];
}

- (void) setPressureFilter:(NPPressureFilter)filter {
    [self.penCommParser setPressureFilter:filter];
}
- (void) setPressureFilterBezier:(float)ctr0 ctr1:(float)ctr1 ctr2:(float)ctr2 {
    [self.penCommParser setPressureFilterBezier:ctr0 ctr1:ctr1 ctr2:ctr2];
}

// setters...

- (void)setPenConnectionStatus:(NPConnectionStatus)penConnectionStatus
{
    if(_penConnectionStatus != penConnectionStatus) {
        
        _penConnectionStatus = penConnectionStatus;
        if(_penConnectionStatus == NPConnectionStatusConnected) {
            self.isPenConnected = YES;
        } else if (_penConnectionStatus == NPConnectionStatusDisconnected) {
            self.isPenConnected = NO;
        }
        
        NSString *msg = (isEmpty(self.penUUID))? @"nil" : self.penUUID;
        NSString *penName = (isEmpty(self.penName))? @"Unknown" : self.penName;
        
        NSDictionary *info = @{@"info":[NSNumber numberWithInteger:penConnectionStatus],@"uuid":msg, @"pen_name":penName};
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:NPConnectionStatusNotification object:nil userInfo:info];
        });
    }
}


- (void) startScanTimer:(float)duration {
    
    if (!_scanTimer) {
        _scanTimer = [NSTimer timerWithTimeInterval:duration
                                             target:self
                                           selector:@selector(selectRSSI)
                                           userInfo:nil
                                            repeats:NO];
        
        [[NSRunLoop mainRunLoop] addTimer:_scanTimer forMode:NSDefaultRunLoopMode];
    }
}
- (void) stopScanTimer {
    if(_scanTimer != nil) {
        [_scanTimer invalidate];
        _scanTimer = nil;
    }
}
- (void) startConnectTimer:(NSTimeInterval)interval {
    
    [self stopConnectTimer];
    if(!_connectTimer) {
        _connectTimer = [NSTimer timerWithTimeInterval:interval
                                                target:self
                                              selector:@selector(checkConnection)
                                              userInfo:nil
                                               repeats:NO];
        
        [[NSRunLoop mainRunLoop] addTimer:_connectTimer forMode:NSDefaultRunLoopMode];
    }
}
- (void) stopConnectTimer {
    if(_connectTimer != nil) {
        [_connectTimer invalidate];
        _connectTimer = nil;
    }
}


- (void) btStart {
    [self btStartForRegister:false];
}
- (void) btStartForRegister {
    [self btStartForRegister:true];
}
- (void) btStartForRegister:(BOOL)forRegister {
    
    _isForRegister = forRegister;
    self.penConnectionStatus = NPConnectionStatusNone;
    if(self.centralManager.state == CBCentralManagerStatePoweredOn) {
        [self btScanStart];
    } else {
        [self startConnectTimer:10.0];
    }
}
- (void) btScanStart {
    //[self disConnect];
    
    _mtuReadRetry = 0;
    self.penUUID = nil;
    [self.discoveredPeripherals removeAllObjects];
    [self.foundPeriphalralInfos removeAllObjects];
    [self.centralManager stopScan];
    
    if (!_isForRegister) {
        [self.centralManager scanForPeripheralsWithServices:@[self.neoPenServiceUuid,self.neoPen2ServiceUuid]
                                                    options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
        [self startScanTimer:3.0f];
    }else{
        [self.centralManager scanForPeripheralsWithServices:@[self.neoSystemServiceUuid,self.neoPen2SystemServiceUuid]
                                                    options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES }];
        [self startScanTimer:7.0f];
    }
}

- (void) checkConnection {
    
    [self stopConnectTimer];
    if (self.penConnectionStatus == NPConnectionStatusConnecting || self.penConnectionStatus == NPConnectionStatusNone) {
        NSLog(@"[PenCommMan] Connection Timer Over!");
        _penConnectionTrace = NPConnectionTraceFailTimeOut;
        if(self.centralManager.state == CBManagerStatePoweredOff) { _penConnectionTrace = NPConnectionTraceBTPowerOff; }
        self.penConnectionStatus = NPConnectionStatusDisconnected;
    }
}


- (void) selectRSSI
{
    NSLog(@"[selectRSSI] slectRSSI started....");
    _penConnectionTrace = NPConnectionTraceNone;
    [self.centralManager stopScan];
    [self stopScanTimer];
    
    if(self.centralManager.state == CBCentralManagerStatePoweredOff) {
        NSLog(@"[selectRSSI] BT powered off....");
        _penConnectionTrace = NPConnectionTraceBTPowerOff;
        self.penConnectionStatus = NPConnectionStatusDisconnected;
        return;
    }
    
    NSInteger noPeripherals = [self.discoveredPeripherals count];
    if (noPeripherals == 0) {
        NSLog(@"[selectRSSI] no peripherals found....");
        // we have not any discovered peripherals
        _penConnectionTrace = NPConnectionTraceNoPen;
        self.penConnectionStatus = NPConnectionStatusDisconnected;
        
        return;
    }
    
    _rssiIndex = -1;
    NSDate *mostRecentDate = nil;
    NSInteger maxRssi = NSIntegerMin;
    NSInteger rssi = 0;
    NSString * pname = @"";
    
    if (!_isForRegister) {
        
        _penConnectionTrace = NPConnectionTraceNoMac;
        [self.penCommParser setPenPasswd:nil];
        NSArray <NPPenRegInfo *> *penInfoArray = nil;
        if(self.delegatePenConnect != nil) {
            penInfoArray = [self.delegatePenConnect penInfoList];
        }
        if(isEmpty(penInfoArray)) {
            NSLog(@"[selectRSSI] No Mac provided try register first....");
            self.penConnectionStatus = NPConnectionStatusDisconnected;
            return;
        }
        
        // we have some registration
        NSLog(@"[selectRSSI] registration Info proviced from app....: %ld I have searched %ld",penInfoArray.count,noPeripherals);
        NSLog(@"*** LIST FROM APP ***");
        int count = 0;
        for (NPPenRegInfo * penInfo in penInfoArray) {
            NSLog(@"%d -- [%@] : %@ at %@",++count,penInfo.penName,penInfo.penMac,penInfo.dateLastUse);
        }
        NSLog(@"*** LIST THAT I SEARCHED ***");
        for (int i = 0; i < noPeripherals; i++) {
            NPPeripheralInfo *pInfo = [self.foundPeriphalralInfos objectAtIndex:i];
            NSLog(@"%d -- [%@] : %@",(i + 1),pInfo.name,pInfo.mac);
        }
        
        // 1. MAC address --> try new method
        NSString *passwd = @"0000";
        for (int i = 0; i < noPeripherals; i++) {
            NPPeripheralInfo *pInfo = [self.foundPeriphalralInfos objectAtIndex:i];
            
            // check uid exists in user's list
            for (NPPenRegInfo * penInfo in penInfoArray) {
                if([penInfo.penMac isEqualToString:pInfo.mac]) {
                    NSLog(@"FOUND =>  [%@] : %@ at %@",penInfo.penName,penInfo.penMac,penInfo.dateLastUse);
                    
                    if(_connectSort == NPConnectionSortStrongSignal) {
                        if(pInfo.rssi > maxRssi) {
                            _rssiIndex = i;
                            maxRssi = pInfo.rssi;
                            passwd = penInfo.penPasswd;
                        }
                    } else if(_connectSort == NPConnectionSortRecentUsed) {
                        if(mostRecentDate == nil) {
                            _rssiIndex = i;
                            mostRecentDate = penInfo.dateLastUse;
                            passwd = penInfo.penPasswd;
                        } else {
                            if(penInfo.dateLastUse != nil) {
                                if(mostRecentDate.timeIntervalSinceReferenceDate < penInfo.dateLastUse.timeIntervalSinceReferenceDate) {
                                    _rssiIndex = i;
                                    pname = penInfo.penName;
                                    mostRecentDate = penInfo.dateLastUse;
                                    passwd = penInfo.penPasswd;
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // now we found strongest one
        if(_rssiIndex >= 0) {
            if(mostRecentDate != nil) { NSLog(@"Try to Connect to most recent pen used at %@ - %@ - passwd: %@",pname,mostRecentDate,passwd); }
            _penConnectionTrace = NPConnectionTraceMatchedMacFound;
            [self.penCommParser setPenPasswd:passwd];
            [self connectPeripheralAt:_rssiIndex];
            return;
        }
        
    } else {
        // For registration
        NSInteger noRssi = [self.foundPeriphalralInfos count];
        for (int i = 0; i < noRssi; i++) {
            NPPeripheralInfo *pInfo = [self.foundPeriphalralInfos objectAtIndex:i];
            if (pInfo.rssi > maxRssi){
                _rssiIndex = i;
                maxRssi = rssi;
            }
        }
        
        if ((self.connectedPeripheral == nil) && (_rssiIndex != -1)) {
            // 1.try macAddr first
            CBPeripheral *foundPeripheral = self.discoveredPeripherals[_rssiIndex];
            NPPeripheralInfo *pInfo = [self.foundPeriphalralInfos objectAtIndex:_rssiIndex];
            NSString *uid = pInfo.mac;
            NSString *penName = foundPeripheral.name;
            if(isEmpty(penName)) { penName = @"Unknown"; }
            [self connectPeripheralAt:_rssiIndex];
            NSLog(@"registration success uuid %@",uid);
            NSDictionary *info = @{@"pen_name":penName,@"uuid":uid};
            [[NSNotificationCenter defaultCenter] postNotificationName:NPRegistrationNotification object:nil userInfo:info];
            return;
        }
    }
    
    // if we reached here --> we failed, and try the scan again
    NSLog(@"[selectRSSI] not found any eligible peripheral....");
    self.penConnectionStatus = NPConnectionStatusDisconnected;
}
- (void) disConnect
{
    [self.penCommParser writeReadyExchangeData:NO];
    // Give some time to pen, before actual disconnect.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500*NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [self disConnectInternal];
    });
}
- (void) disConnectInternal
{
    if (self.connectedPeripheral) {
        [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
        self.connectedPeripheral = nil;
        self.penConnectionStatus = NPConnectionStatusDisconnected;
    }
}
- (void) connectPeripheralAt:(NSInteger)index
{
    if (index >= [self.discoveredPeripherals count] ) return;
    CBPeripheral *peripheral = [self.discoveredPeripherals objectAtIndex:index];
    
    if (self.connectedPeripheral != peripheral) {
        NPPeripheralInfo *pInfo = [self.foundPeriphalralInfos objectAtIndex:index];
        NSLog(@"Connecting to peripheral %@", peripheral);
        
        self.penUUID = pInfo.mac;
        self.penName = pInfo.name;
        
        self.isPenSDK2 = pInfo.isSDK2;
        [self.centralManager connectPeripheral:peripheral options:nil];
        
        [self startConnectTimer:7.0];
        self.penConnectionStatus = NPConnectionStatusConnecting;
    }
}

- (void) requestNewPageNotification {
    
    self.penCommParser.notifyNewPage = YES;
}


- (NSString *)getMacAddrFromString:(NSData *)data
{
    NSString *macAddrStr =[NSString stringWithFormat:@"%@",data];
    macAddrStr = [macAddrStr stringByReplacingOccurrencesOfString:@"<" withString:@""];
    macAddrStr = [macAddrStr stringByReplacingOccurrencesOfString:@">" withString:@""];
    macAddrStr = [macAddrStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    return macAddrStr;
}



/** This callback comes whenever a peripheral that is advertising the NEO_PEN_SERVICE_UUID is discovered.
 *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
 *  we start the connection process
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Reject any where the value is above reasonable range
    if (RSSI.integerValue > -15) {
        NSLog(@"Too Strong %@ at %@", peripheral.name, RSSI);
        //return;
    }
    self.penConnectionStatus = NPConnectionStatusScanStarted;
    
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    NSLog(@"advertisement.localname %@", [advertisementData objectForKey:@"kCBAdvDataLocalName"]);
    
    NSString *macAddrStr = nil;
    if([[advertisementData allKeys] containsObject:@"kCBAdvDataManufacturerData"])
        macAddrStr = [self getMacAddrFromString:[advertisementData objectForKey:@"kCBAdvDataManufacturerData"]];
    
    NSLog(@"advertisement.manufactureData %@",macAddrStr);
    NSArray *serviceUUIDs = [advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"];
    NSLog(@"advertisement.serviceUUIDs %@", serviceUUIDs);
    BOOL isSDK2 = NO;
    
    if(!_isForRegister) {
        // if the peripheral has no pen service --> ignore the peripheral
        if(![serviceUUIDs containsObject:self.neoPenServiceUuid] && ![serviceUUIDs containsObject:self.neoPen2ServiceUuid]) return;
        if([serviceUUIDs containsObject:self.neoPen2ServiceUuid]) isSDK2 = YES;
        NSLog(@"CONNECT -- found service %@",(isSDK2)? @"19F1 (SDK2)" : @"18F1");
        
    } else {
        // if the peripheral has no pen service --> ignore the peripheral
        if(![serviceUUIDs containsObject:self.neoSystemServiceUuid] && ![serviceUUIDs containsObject:self.neoPen2SystemServiceUuid]) return;
        if([serviceUUIDs containsObject:self.neoPen2SystemServiceUuid]) isSDK2 = YES;
        NSLog(@"REGISTER -- found service %@",(isSDK2)? @"19F0 (SDK2)" : @"18F5");
    }
    
    if (![self.discoveredPeripherals containsObject:peripheral]) {
        [self.discoveredPeripherals addObject:peripheral];
        NPPeripheralInfo *pInfo = [NPPeripheralInfo new];
        pInfo.rssi = [RSSI integerValue];
        pInfo.mac = (macAddrStr == nil)? @"" : macAddrStr;
        pInfo.name = peripheral.name;
        pInfo.isSDK2 = isSDK2;
        [self.foundPeriphalralInfos addObject:pInfo];
        NSLog(@"new discoveredPeripherals, rssi %@ mac: %@",RSSI,macAddrStr);
    }
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        NSLog(@"[BTCENTRAL] BT Powered On");
        [self btScanStart];
    } else if(central.state == CBCentralManagerStatePoweredOff) {
        NSLog(@"[BTCENTRAL] BT Powered Off");
        [self disConnect];
    }
    
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    _penConnectionTrace = NPConnectionTraceFailConnect;
    [self cleanup];
}
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    NSLog(@"Peripheral Connected");
    self.connectedPeripheral = peripheral;
    peripheral.delegate = self;
    
    // Initialize some value.
    _idDataReady = _strokeDataReady = _upDownDataReady = NO;
    _initialConnect = YES;
    
    // Search only for services that match our UUID
    [peripheral discoverServices:self.supportedServices];
}
- (void)cleanup
{
    NSLog(@"[PenCommMan] cleanup()");
    // Don't do anything if we're not connected
    if (self.connectedPeripheral.state != CBPeripheralStateConnected) return;
    
    // See if we are subscribed to a characteristic on the peripheral
    if (self.connectedPeripheral.services != nil) {
        for (CBService *service in self.connectedPeripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:STROKE_DATA_UUID]]) {
                        if (characteristic.isNotifying) {
                            // It is notifying, so unsubscribe
                            [self.connectedPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                        }
                    }
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
    //    self.penConnectionStatus = NPConnectionStatusDisconnected;
}





















/*
 
 
 
 
 
 */


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    // Discover the characteristic we want...
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
        NSLog(@"Service UUID : %@", [[service UUID] UUIDString]);
        if ([[[service UUID] UUIDString] isEqualToString:NEO_SYSTEM_SERVICE_UUID]) {
            self.systemService = service;
            [peripheral discoverCharacteristics:self.systemCharacteristics forService:service];
        }
        else if ([[[service UUID] UUIDString] isEqualToString:NEO_PEN2_SERVICE_UUID]) {
            self.pen2Service = service;
            [peripheral discoverCharacteristics:self.pen2Characteristics forService:service];
        }
        else if ([[[service UUID] UUIDString] isEqualToString:NEO_SYSTEM2_SERVICE_UUID]) {
            self.system2Service = service;
            [peripheral discoverCharacteristics:self.system2Characteristics forService:service];
        }
        else if ([[[service UUID] UUIDString] isEqualToString:NEO_PEN_SERVICE_UUID]) {
            self.penService = service;
            [peripheral discoverCharacteristics:self.penCharacteristics forService:service];
        }
        else if ([[[service UUID] UUIDString] isEqualToString:NEO_OFFLINE_SERVICE_UUID]) {
            self.offlineService = service;
            [peripheral discoverCharacteristics:self.offlineCharacteristics forService:service];
        }
        else if ([[[service UUID] UUIDString] isEqualToString:NEO_OFFLINE2_SERVICE_UUID]) {
            self.offline2Service = service;
            [peripheral discoverCharacteristics:self.offline2Characteristics forService:service];
        }
        else if ([[[service UUID] UUIDString] isEqualToString:NEO_UPDATE_SERVICE_UUID]) {
            self.updateService = service;
            [peripheral discoverCharacteristics:self.updateCharacteristics forService:service];
        }
        else if ([[[service UUID] UUIDString] isEqualToString:NEO_DEVICE_INFO_SERVICE_UUID]) {
            self.deviceInfoService = service;
            [peripheral discoverCharacteristics:self.deviceInfoCharacteristics forService:service];
        }
    }
}


/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    if (service == self.penService) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            // And check if it's the right one
            if ([self.penCharacteristics containsObject:characteristic.UUID]) {
                if ([[characteristic UUID] isEqual:self.strokeDataUuid]) {
                    NSLog(@"strokeDataUuid");
                    _strokeDataReady = YES;
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if ([[characteristic UUID] isEqual:self.updownDataUuid]) {
                    NSLog(@"updownDataUuid");
                    _upDownDataReady = YES;
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if ([[characteristic UUID] isEqual:self.idDataUuid]) {
                    NSLog(@"idDataUuid");
                    _idDataReady = YES;
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if([[characteristic UUID] isEqual:self.offlineFileInfoUuid]) {
                    NSLog(@"offlineFileInfoUuid");
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if([[characteristic UUID] isEqual:self.offlineFileDataUuid]) {
                    NSLog(@"offlineFileDataUuid");
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
            else {
                NSLog(@"Unknown characteristic %@ for service %@", service.UUID, characteristic.UUID);
            }
        }
    }
    else if (service == self.pen2Service) { // SDK 2.0
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([self.pen2Characteristics containsObject:characteristic.UUID]) {
                if ([[characteristic UUID] isEqual:self.pen2DataUuid]) {
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if([[characteristic UUID] isEqual:self.pen2SetDataUuid]) {
                    self.pen2SetDataCharacteristic = characteristic;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.penCommParser sendAppInfo];
                    });
                }
            }
            else {
                NSLog(@"Unknown characteristic %@ for service %@", service.UUID, characteristic.UUID);
            }
        }
    }
    else if (service == self.systemService) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            // And check if it's the right one
            if ([self.systemCharacteristics containsObject:characteristic.UUID]) {
                if ([[characteristic UUID] isEqual:self.penStateDataUuid]) {
                    NSLog(@"penStateDataUuid");
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if([[characteristic UUID] isEqual:self.setPenStateUuid]) {
                    NSLog(@"setPenStateUuid");
                    _setPenStateCharacteristic = characteristic;
                    //[self.penCommParser setPenState];
                }
                else if([[characteristic UUID] isEqual:self.setNoteIdListUuid]) {
                    NSLog(@"setNoteIdListUuid");
                    _setNoteIdListCharacteristic = characteristic;
                    [self.penCommParser setNoteIdList];
                }
                else if([[characteristic UUID] isEqual:_readyExchangeDataUuid]) {
                    NSLog(@"readyExchangeDataUuid");
                    _readyExchangeDataCharacteristic = characteristic;
                }
                else if([[characteristic UUID] isEqual:_readyExchangeDataRequestUuid]) {
                    NSLog(@"readyExchangeDataRequestUuid");
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
            else {
                NSLog(@"Unknown characteristic %@ for service %@", service.UUID, characteristic.UUID);
            }
        }
    }
    else if (service == self.system2Service) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            // And check if it's the right one
            if ([self.system2Characteristics containsObject:characteristic.UUID]) {
                if ([[characteristic UUID] isEqual:_penPasswordRequestUuid]) {
                    NSLog(@"penPasswordRequestUuid");
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if([[characteristic UUID] isEqual:_penPasswordResponseUuid]) {
                    NSLog(@"penPasswordResponseUuid");
                    _penPasswordResponseCharacteristic = characteristic;
                }
                else if([[characteristic UUID] isEqual:_penPasswordChangeRequestUuid]) {
                    NSLog(@"penPasswordChangeRequestUuid");
                    _penPasswordChangeRequestCharacteristic = characteristic;
                }
                else if([[characteristic UUID] isEqual:_penPasswordChangeResponseUuid]) {
                    NSLog(@"penPasswordChangeResponseUuid");
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
            else {
                NSLog(@"Unknown characteristic %@ for service %@", service.UUID, characteristic.UUID);
            }
        }
        
    }
    else if (service == self.offline2Service) {
        // Again, we loop through the array, just in case.
        for (CBCharacteristic *characteristic in service.characteristics) {
            // And check if it's the right one
            if ([self.offline2Characteristics containsObject:characteristic.UUID]) {
                if([[characteristic UUID] isEqual:self.offlineFileInfoUuid]) {
                    NSLog(@"offlineFileInfoUuid");
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if([[characteristic UUID] isEqual:self.offlineFileDataUuid]) {
                    NSLog(@"offlineFileDataUuid");
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if([[characteristic UUID] isEqual:self.offlineFileListInfoUuid]) {
                    NSLog(@"offlineFileListInfoUuid");
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if([[characteristic UUID] isEqual:self.requestOfflineFileUuid]) {
                    NSLog(@"requestOfflineFileUuid");
                    self.requestOfflineFileCharacteristic = characteristic;
                }
                else if([[characteristic UUID] isEqual:self.offlineFileStatusUuid]) {
                    NSLog(@"offlineFileStatusUuid");
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if([[characteristic UUID] isEqual:self.offline2FileAckUuid]) {
                    NSLog(@"offline2FileAckUuid");
                    self.offline2FileAckCharacteristic = characteristic;
                }
                else {
                    NSLog(@"Unhandled characteristic %@ for service %@", service.UUID, characteristic.UUID);
                }
                
            }
            else {
                NSLog(@"Unknown characteristic %@ for service %@", service.UUID, characteristic.UUID);
            }
        }
        
    }
    else if (service == self.offlineService) {
        // Again, we loop through the array, just in case.
        for (CBCharacteristic *characteristic in service.characteristics) {
            // And check if it's the right one
            if ([self.offlineCharacteristics containsObject:characteristic.UUID]) {
                if([[characteristic UUID] isEqual:self.requestOfflineFileListUuid]) {
                    NSLog(@"requestOfflineFileListUuid");
                    self.requestOfflineFileListCharacteristic = characteristic;
                }
                else if([[characteristic UUID] isEqual:self.offlineFileListUuid]) {
                    NSLog(@"offlineFileListUuid");
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if([[characteristic UUID] isEqual:self.requestDelOfflineFileUuid]) {
                    NSLog(@"requestDelOfflineFileUuid");
                    _requestDelOfflineFileCharacteristic = characteristic;
                }
                else {
                    NSLog(@"Unhandled characteristic %@ for service %@", service.UUID, characteristic.UUID);
                }
                
            }
            else {
                NSLog(@"Unknown characteristic %@ for service %@", service.UUID, characteristic.UUID);
            }
        }
        
    }
    else if (service == self.updateService) {
        // Again, we loop through the array, just in case.
        for (CBCharacteristic *characteristic in service.characteristics) {
            // And check if it's the right one
            if ([self.updateCharacteristics containsObject:characteristic.UUID]) {
                if([[characteristic UUID] isEqual:self.updateFileInfoUuid]) {
                    NSLog(@"updateFileInfoUuid");
                    self.sendUpdateFileInfoCharacteristic = characteristic;
                }
                else if([[characteristic UUID] isEqual:self.requestUpdateUuid]) {
                    NSLog(@"requestUpdateFileInfoUuid");
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else if([[characteristic UUID] isEqual:self.updateFileDataUuid]) {
                    NSLog(@"updateFileDataUuid");
                    self.updateFileDataCharacteristic = characteristic;
                }
                else if([[characteristic UUID] isEqual:self.updateFileStatusUuid]) {
                    NSLog(@"updateFileStatusUuid");
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
                else {
                    NSLog(@"Unhandled characteristic %@ for service %@", service.UUID, characteristic.UUID);
                }
                
            }
            else {
                NSLog(@"Unknown characteristic %@ for service %@", service.UUID, characteristic.UUID);
            }
        }
        
    }
    else if (service == self.deviceInfoService) {
        // Again, we loop through the array, just in case.
        for (CBCharacteristic *characteristic in service.characteristics) {
            // And check if it's the right one
            if ([self.deviceInfoCharacteristics containsObject:characteristic.UUID]) {
                if([[characteristic UUID] isEqual:self.fwVersionUuid]) {
                    NSLog(@"fwVersionUuid");
                    [peripheral readValueForCharacteristic:characteristic];
                }
            }
            else {
                NSLog(@"Unknown characteristic %@ for service %@", service.UUID, characteristic.UUID);
            }
        }
        
    }
    // Once this is complete, we just need to wait for the data to come in.
}


/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        return;
    }
    
    NSData* received_data = characteristic.value;
    int dataLength = (int)[received_data length];
    unsigned char *packet = (unsigned char *) [received_data bytes];
    
    if([ characteristic.UUID isEqual: self.pen2DataUuid] ) // This is only characteristic when we use SDK 2.0
    {
        [self.penCommParser parsePen2Data:packet withLength:dataLength];
    }
    else if([ characteristic.UUID isEqual: self.strokeDataUuid] )
    {
        [self.penCommParser parsePenStrokeData:packet withLength:dataLength];
    }
    else if([ characteristic.UUID isEqual: self.updownDataUuid] )
    {
        [self.penCommParser parsePenUpDowneData:packet withLength:dataLength];
    }
    else if([ characteristic.UUID isEqual: self.idDataUuid] )
    {
        [self.penCommParser parsePenNewIdData:packet withLength:dataLength];
    }
    else if([ characteristic.UUID isEqual: self.offlineFileDataUuid] ){
        //FLog(@"Received: offline file data");
        [self.penCommParser parseOfflineFileData:packet withLength:dataLength];
    }
    else if([ characteristic.UUID isEqual: self.offlineFileInfoUuid] ) {
        NSLog(@"Received: offline file info data");
        [self.penCommParser parseOfflineFileInfoData:packet withLength:dataLength];
    }
    else if([ characteristic.UUID isEqual: self.penStateDataUuid] ) {
        //        NSLog(@"Received: pen status data");
        if (_initialConnect) {
            NSLog(@"PEN CONNECTED!!!");
            self.penConnectionStatus = NPConnectionStatusConnected;
            _initialConnect = NO;
        }
        [self.penCommParser parsePenStatusData:packet withLength:dataLength];
    }
    else if([ characteristic.UUID isEqual: self.offlineFileListUuid] ) {
        NSLog(@"Received: offline File list");
        [self.penCommParser parseOfflineFileList:packet withLength:dataLength];
    }
    else if([ characteristic.UUID isEqual: self.offlineFileListInfoUuid] ) {
        NSLog(@"Received: offline File List info");
        [self.penCommParser parseOfflineFileListInfo:packet withLength:dataLength];
    }
    else if([ characteristic.UUID isEqual: self.offlineFileStatusUuid] ) {
        NSLog(@"Received: offline File Status");
        [self.penCommParser parseOfflineFileStatus:packet withLength:dataLength];
    }
    //    // Update FW
    //    else if([ characteristic.UUID isEqual: self.requestUpdateUuid] ) {
    //        NSLog(@"Received: request update file");
    //        [self.penCommParser parseRequestUpdateFile:packet withLength:dataLength];
    //    }
    //    else if([ characteristic.UUID isEqual: self.updateFileStatusUuid] ) {
    //        NSLog(@"Received: update file status ");
    //        [self.penCommParser parseUpdateFileStatus:packet withLength:dataLength];
    //    }
    
    else if([ characteristic.UUID isEqual: _readyExchangeDataRequestUuid] ) {
        //        NSLog(@"Received: readyExchangeDataRequestUuid");
        BOOL ready = [self.penCommParser parseReadyExchangeDataRequest:packet withLength:dataLength];
        if(ready & (_strokeDataReady && _idDataReady && _upDownDataReady)) {
            [self.penCommParser writeReadyExchangeData:YES]; // response back to pen
        } else {
            [self disConnect];
        }
    }
    else if([ characteristic.UUID isEqual: _penPasswordRequestUuid] ) {
        //        NSLog(@"Received: penPasswordRequestUuid");
        [self stopConnectTimer];
        [self.penCommParser parsePenPasswordRequest:packet];
    }
    else if([ characteristic.UUID isEqual: _penPasswordChangeResponseUuid] ) {
        //        NSLog(@"Received: penPasswordResponseUuid");
        //        [self.penCommParser parsePenPasswordChangeResponse:packet withLength:dataLength];
    }
    else if([ characteristic.UUID isEqual: self.fwVersionUuid] ) {
        NSString *fwVersion = [self.penCommParser parseFWVersion:packet withLength:dataLength];
        NSLog(@"Received: FW version: %@",fwVersion);
    }
    else {
        NSLog(@"Un-handled data characteristic.UUID %@", [characteristic.UUID UUIDString]);
        return;
    }
}


/** The peripheral letting us know whether our subscribe/unsubscribe happened or not
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error changing notification state: %@ characteristic : %@", error.localizedDescription, characteristic.UUID);
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Error WriteValueForCharacteristic: %@ characteristic : %@", error.localizedDescription, characteristic.UUID);
        return;
    }
    
    if (characteristic == self.pen2SetDataCharacteristic) {
        if (_mtuReadRetry++ < 5) {
            self.mtu = [peripheral maximumWriteValueLengthForType:CBCharacteristicWriteWithoutResponse];
            //            NSLog(@"MTU %zi",self.mtu);
        }
    }
    //    if (characteristic == self.setPenStateCharacteristic) {
    //        NSLog(@"Set Pen Status successful");
    //    }
    //    else if (characteristic == self.requestOfflineFileListCharacteristic) {
    //        NSLog(@"requestOfflineFileList successful");
    //    }
    //    else if (characteristic == self.sendUpdateFileInfoCharacteristic) {
    //        NSLog(@"sendUpdateFileInfoCharacteristic successful");
    //    }
    //    else if (characteristic == self.updateFileDataCharacteristic) {
    //        NSLog(@"updateFileDataCharacteristic successful");
    //    }
    //    else if (characteristic == self.offline2FileAckCharacteristic) {
    //        NSLog(@"offline2FileAckCharacteristic successful");
    //    }
    //    else if (characteristic == self.setNoteIdListCharacteristic) {
    //        NSLog(@"setNoteIdListCharacteristic successful");
    //    }
    //    else if (characteristic == self.requestOfflineFileCharacteristic) {
    //        NSLog(@"requestOfflineFileCharacteristic successful");
    //    }
    //    else if (characteristic == self.requestDelOfflineFileCharacteristic) {
    //        NSLog(@"requestDelOfflineFileCharacteristic successful");
    //    }
    //    else {
    //        NSLog(@"Unknown characteristic %@ didWriteValueForCharacteristic successful", characteristic.UUID);
    //    }
}


- (BOOL)requestOfflineFileList {
    if (self.isPenSDK2) {
        return [self.penCommParser reqOffline2NoteList];
    }
    return [self.penCommParser reqOfflineNoteList];
}
- (BOOL) requestOfflineDataWithOwnerId:(UInt32)ownerId noteId:(UInt32)noteId {
    if (self.isPenSDK2) {
        return [self.penCommParser requestOffline2DataWithOwnerId:ownerId noteId:noteId];
    }
    return [self.penCommParser requestOfflineDataWithOwnerId:ownerId noteId:noteId];
}
- (void) setBTComparePassword:(NSString *)pinNumber {
    if (self.isPenSDK2) {
        [self.penCommParser sendPenPassword:pinNumber];
    } else {
        [self.penCommParser writePasswordData:pinNumber];
    }
}


- (void)writeNoteIdList:(NSData *)data {
    dispatch_async(bt_write_dispatch_queue, ^{
        [self.connectedPeripheral writeValue:data forCharacteristic:self.setNoteIdListCharacteristic type:CBCharacteristicWriteWithResponse];
    });
}
- (void)writeReadyExchangeData:(NSData *)data {
    dispatch_async(bt_write_dispatch_queue, ^{
        if (_readyExchangeDataCharacteristic) {
            [self.connectedPeripheral writeValue:data forCharacteristic:self.readyExchangeDataCharacteristic type:CBCharacteristicWriteWithResponse];
        }
    });
}
- (void)writePenPasswordResponseData:(NSData *)data {
    dispatch_async(bt_write_dispatch_queue, ^{
        if (_penPasswordResponseCharacteristic) {
            NSLog(@"[PenCommMan -writePenPasswordResponseData] writing data to pen");
            [self.connectedPeripheral writeValue:data forCharacteristic:self.penPasswordResponseCharacteristic type:CBCharacteristicWriteWithResponse];
        }
    });
}
- (void)writeSetPenState:(NSData *)data {
    dispatch_async(bt_write_dispatch_queue, ^{
        [self.connectedPeripheral writeValue:data forCharacteristic:self.setPenStateCharacteristic type:CBCharacteristicWriteWithResponse];
    });
}
- (void)writeRequestOfflineFileList:(NSData *)data {
    dispatch_async(bt_write_dispatch_queue, ^{
        if (_requestOfflineFileListCharacteristic) {
            [self.connectedPeripheral writeValue:data forCharacteristic:self.requestOfflineFileListCharacteristic type:CBCharacteristicWriteWithResponse];
        }
    });
}
- (void)writeRequestOfflineFile:(NSData *)data {
    dispatch_async(bt_write_dispatch_queue, ^{
        if (_requestOfflineFileCharacteristic) {
            [self.connectedPeripheral writeValue:data forCharacteristic:self.requestOfflineFileCharacteristic type:CBCharacteristicWriteWithResponse];
        }
    });
}
- (void)writeOfflineFileAck:(NSData *)data {
    dispatch_async(bt_write_dispatch_queue, ^{
        [self.connectedPeripheral writeValue:data forCharacteristic:self.offline2FileAckCharacteristic type:CBCharacteristicWriteWithResponse];
    });
}



// SDK2
- (void)writePen2SetData:(NSData *)data {
    dispatch_async(bt_write_dispatch_queue, ^{
        [self.connectedPeripheral writeValue:data forCharacteristic:self.pen2SetDataCharacteristic type:CBCharacteristicWriteWithResponse];
    });
}
@end


