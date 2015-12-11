//
//  DeviceCommunication.m
//  BLETest
//
//  Created by Brain Chen on 14/8/22.
//  Copyright (c) 2014年 brian. All rights reserved.
//

#import "DeviceCommunication.h"
#import "RKCentralManager.h"
#import "CBUUID+RKBlueKit.h"
#import "NSData+Hex.h"
#import "RKBlueKit.h"
#import "RKPeripheral.h"


@implementation DeviceCommunication
{
    NSDictionary * opts;
    RKCentralManager *central;
    RKPeripheral * mPeripheral;
    NSMutableDictionary * connections;
}

@synthesize require_service_uuid;




+ (DeviceCommunication *) sharedInstance
{
    
    static DeviceCommunication * sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
    
}

- (id)init
{
    
    self = [super init];
    
    //if ([[UIDevice currentDevice].systemVersion floatValue]>=7.0)
    opts = @{CBCentralManagerOptionShowPowerAlertKey:@YES};
    
    self->central = [[RKCentralManager alloc] initWithQueue:nil options:opts];
    connections=[[NSMutableDictionary alloc]init];
    
    if (self) {
        NSLog(@"DeviceCommunication generate");
    }

    return self;
}


//the method return no duplicated devices
-(void)searchNearbyDevices
{
     __weak DeviceCommunication * this = self;
     RKCentralManager *mCenter= self->central;
    

    
    if (self->central.state != CBCentralManagerStatePoweredOn)
    {
        self->central.onStateChanged = ^(NSError * error){
            
            //获得得到的
            [mCenter scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}  onUpdated:^(RKPeripheral *peripheral) {
                [peripheral readRSSIOnFinish:^(NSError *error) {
                    NSString * distance=[peripheral.RSSI stringValue];
                    //NSLog(@"distance:,peripheral.RSSI:%@",distance);
                    
                    
                }];
               
                if([this.delegate respondsToSelector:@selector(getDeviceName:identifier:)])
                   {
                       if(peripheral.identifier.UUIDString)
                       {
                           [connections setObject:peripheral.RSSI forKey:peripheral.identifier.UUIDString];
                           [this.delegate  getDeviceName:peripheral.name identifier:peripheral.identifier.UUIDString];
                       }
                       else
                       {
                           NSLog(@"perfipherial identifier is nil");
                       }
                   }
            }];
        };
        
    }
}
-(void)stopSearchAction
{
    [self->central stopScan];
}

//connect to target peripherial, once it is connected, start to listen from the device
-(void)connectToDevice:(NSString*)identifier
{
    
    //查看这个Device 存不存在，正常情况下，会存在, 如果不存在，返回错误，UI上需要刷新列表
    NSUUID * targetUUId= [[NSUUID alloc]initWithUUIDString:identifier];
    
    NSArray * TargetUUIds=[[NSArray alloc]initWithObjects:targetUUId, nil];
    NSArray * result=[self->central retrievePeripheralsWithIdentifiers:TargetUUIds];
    
    if(result.count>0)//if peripherial exist
    {
        self->mPeripheral=result[0];
         __weak DeviceCommunication * this =self;
      
            
            NSLog(@"try to Connect ble device with UUID String: %@",self->mPeripheral.identifier.UUIDString);
        
            [self->central connectPeripheral:self->mPeripheral options:nil onFinished:^(RKPeripheral *peripheral, NSError *error) {
                
                
                if(!error)
                {
                    NSLog(@"connect to device success!");
                    [self->mPeripheral discoverServices:nil onFinish:^(NSError *error) {
                        
                        
                        if(!error && [this CheckService:self->mPeripheral.services[0]])
                        {
                            NSLog(@"services found:%@",self->mPeripheral.services);
                            [self->mPeripheral discoverCharacteristics:nil forService: self->mPeripheral.services[0] onFinish:^(CBService *service, NSError *error) {
                                
                                //----------------------------Function Exit----------------------------
                                //get charactorastic，in this step, we think the connection steps is
                                //finished,start to listen from BLE, we should notice the User Interface.
                                [this startToListenFromBLEDevice];
                                
                                [self reportError:DeviceConnectionStateConnected indentifier:identifier];
                                //stop serach
                                [self->central stopScan];
                            }];
                        }
                        else
                        {
                       
                            //----------------------------Function Exit----------------------------
                            //the target device has not corrsponce service found
                            [self->central cancelPeripheralConnection:self->mPeripheral  onFinished:^(RKPeripheral *peripheral, NSError *error) { NSLog(@"disconnect incorrect target ");}];
                            NSLog(@"DeviceConnectionStateServiceNotFound");
                            [self reportError:DeviceConnectionStateServiceNotFound indentifier:identifier];
                            
                        }
                     }];
                    
                    
                }
                else
                {
                    //----------------------------Function Exit----------------------------
                    //error occur when connect to decvice
                    NSLog(@"error when trying to connect to device");
                    [self reportError:DeviceConnectionStateUnKnownError indentifier:identifier];
                }
                
            } onDisconnected:^(RKPeripheral *peripheral, NSError *error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    //----------------------------Function Exit----------------------------
                    //handle situation when device is away from cellphone disconnected
                     [self reportError:DeviceConnectionStateDisConnected indentifier:identifier];
                      NSLog(@"device beyond reach,state DisConnected");
                    
                });
                
            }];

    }
    else
    {
        //----------------------------Function Exit----------------------------
        //the selected  peripherial is not exists;
        //[self reportError:DeviceConnectionStatePeripherialNotExist];
        [self reportError:DeviceConnectionStatePeripherialNotExist indentifier:identifier];
        NSLog(@"this is not suppose to happend ,the target is not found,ReConnectPeripheralsWithIdentifiers");
    }
   
}

-(void)reportError:(NSInteger)error indentifier:(NSString *)indentifier
{
    if([self.delegate respondsToSelector:@selector(getConnectionError:identifier:)])
    {
        [self.delegate getConnectionError:error identifier:indentifier];
    }
}

// if the service is correct than we thought this is the target, if not ,disconnect, and show error message

-(BOOL)CheckService:(CBService *)service
{
    if(!self.require_service_uuid||(self.require_service_uuid&&[[self.require_service_uuid uppercaseString]isEqualToString:[service.UUID.UUIDString uppercaseString]]))
    {
        return YES;
    }
    else
    {
        return NO;
    }
}







//send Message to device in form of NSData
-(BOOL) SendMessageToDevice:(NSData*)message fromUser:(NSString *)userName
{
    if(self->mPeripheral.state !=CBPeripheralStateConnected)
    {
          return NO;
    }
    
    @try
    {
        CBCharacteristicWriteType type =CBCharacteristicPropertyWriteWithoutResponse;
        
        RKCharacteristicChangedBlock onfinish=nil;
        
        if(onfinish==nil)
        {
            onfinish = ^(CBCharacteristic * characteristic, NSError * error)
            {
                NSLog(@"write response %@",error);
                // tell the delegate the write action is not success.
            };
        }
        
        CBService * myservice =mPeripheral.services[0];
        CBCharacteristic *  write_characteristic =myservice.characteristics[2];
        
        [mPeripheral writeValue:message forCharacteristic:write_characteristic type:type onFinish:onfinish];

    }@catch (NSException * e) {
       
        NSLog(@"SendMessageToDevice fail");
    }
    
    return YES;
}



-(void)startToListenFromBLEDevice
{
    __weak CBService * myservice =self->mPeripheral.services[0];
    __weak  CBCharacteristic *  read_characteristic=myservice.characteristics[0];
     __weak DeviceCommunication * this = self;
    
     [self->mPeripheral setNotifyValue:YES forCharacteristic:read_characteristic onUpdated:^(CBCharacteristic *characteristic, NSError *error) {
        NSData * data=read_characteristic.value;
         NSString * msg =[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
         //NSLog(@"-get data %@", msg);
         //NSLog(@"-get hex value %@", [read_characteristic.value hexadecimalString]);
         if([this.delegate respondsToSelector:@selector(GetMessage:fromUser:)])
         {
           [this.delegate GetMessage:data fromUser:@""];
         }
     }];
}


-(void)reInit
{
    
    if(mPeripheral)
    {
    [central cancelPeripheralConnection:mPeripheral onFinished:^(RKPeripheral * peripheral,NSError * error) {
        
        NSLog(@"connection canceled");
    }];
    }

    
    
    [self init];
    
}


-(void)AddMessageToSendingQueue:(NSData *)message fromUser:(NSString *)userName
{

}


-(NSDictionary*)getConnectionParam
{
    return connections;
}

-(NSString *)getCurrentUUID
{
    return mPeripheral.identifier.UUIDString;
}

-(NSInteger)getDeviceState
{
    return central.state;
}


-(void)dealloc
{
    
    self.delegate=nil;
}







@end
