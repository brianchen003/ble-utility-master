//
//  DeviceCommunication.h
//
//  Created by Brain Chen on 14/8/22.
//  Copyright (c) 2014年 brian. All rights reserved.
//

#import <Foundation/Foundation.h>




typedef NS_ENUM(NSInteger,DeviceConnectionState) {
    DeviceConnectionStateConnected=0,  //connection success
	DeviceConnectionStatePeripherialNotExist, //device is not exists
	DeviceConnectionStateIsNotDisConnected, //in great chance the device is connected
    DeviceConnectionStateServiceNotFound, //user define the service uuid. Target is not
    DeviceConnectionStateUnKnownError, //unknown error occurs, it is advisable to restart all over
    DeviceConnectionStateDisConnected,//the blueTooth device is disconnected.
};



@protocol DeviceCommunicationDelegata<NSObject>

-(void)getDeviceName:(NSString *)deviceName identifier:(NSString *)identifier;
-(void)getConnectionError:(NSInteger)errorCode identifier:(NSString*)indentifier;
-(void)GetMessage:(NSData*)message fromUser:(NSString*)userName;


@end

@interface DeviceCommunication : NSObject
{
      id<DeviceCommunicationDelegata> delegate; //the delegate handel the delayed operation from this class
}

/*!
 *  @property require_service_uuid
 *
 *  @discussion this set the required service UUID in the connection request
 */
@property (nonatomic, copy)NSString *require_service_uuid;




/*!
 *  @property require_name_content
 *
 *  @discussion this set the required name or part of the name in the connection request
 */
@property (nonatomic, copy)NSString *require_name_content;



/*!
 *  @property delegate
 *
 *  @discussion the delegate receive the reaction from the ble
 */
@property (nonatomic, assign)id<DeviceCommunicationDelegata> delegate;

/*!
 *  @property check_interval
 *
 *  @discussion define the checking interval for sendding message in the message queue.
 */
@property (nonatomic, assign)NSInteger check_interval;
/*!
 *  @property device_status
 *
 *  @discussion define the checking interval for sendding message in the message queue.
 */
@property (nonatomic, assign)NSInteger device_status;


-(void)reInit;

/*!
 *  @property sharedInstance
 *
 *  @discussion singleton method return the only one instance of the ble talk handler
 */
+ (DeviceCommunication *) sharedInstance;

/*!
 *  @method searchNearbyDevices:
 *
 *  @param peripheral   no
 *
 *  @discussion   search the nearby device, once a device is found,the instance will inform the delegate

 *
 */
-(void) searchNearbyDevices;

/*!
 *  @method stopSearchAction:
 *
 *  @param peripheral   no
 *
 *  @discussion      stop the scan progress,normally ,user do not need to call it  directly
 *
 *  @see
 *
 */

-(void) stopSearchAction;

/*!
 *  @method connectToDevice:
 *
 *  @param device   UUID
 *
 *  @discussion
 *
 *  @see
 *
 */
-(void) connectToDevice:(NSString*)identifier;

/*!
 *  @method SendMessagegToDevice:
 *
 *  @param Message
 *
 *  @discussion this method will return immidietaly
 *
 *  @see YES send ,NO the decive is not connected
 *
 */




-(BOOL) SendMessageToDevice:(NSData*)message  fromUser:(NSString*)userName;

/*!
 *  @method SendMessagegToDevice:
 *
 *  @param Message
 *
 *  @discussion this method will not return anything ,it adds the content need sending to the operation queue, there is a timer which check time and again  to make sure the message send to the distinantion.
 *
 */


/*!
 *  @method getConnectionParam:
 *
 *  @param Message
 *
 *  @discussion this method will not return anything ,it adds the content need sending to the operation queue, there is a timer which check time and again  to make sure the message send to the distinantion.
 *
 */

-(NSDictionary*)getConnectionParam;

/*!
 *  @method getDeviceState:
 *
 *  @param Message
 *
 *  @discussion this method will return the current ble device power state or authorized states as well
 *
 */
-(NSInteger)getDeviceState;

/*!
 *  @method getCurrentUUID:
 *
 *  @param Message
 *
 *  @discussion this method will not return anything ,it adds the content need sending to the operation queue, there is a timer which check time and again  to make sure the message send to the distinantion.
 *
 */

-(NSString *)getCurrentUUID;









@end
