//
//  RCTTwilioChatClient.m
//  TwilioIPExample
//
//  Created by Brad Bumbalough on 5/31/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "RCTTwilioChatClient.h"
#import "RCTTwilioAccessManager.h"
#import <React/RCTEventDispatcher.h>
#import "RCTConvert+TwilioChatClient.h"
#import <React/RCTUtils.h>

@interface RCTTwilioChatClient() <TwilioChatClientDelegate>
@end

@implementation RCTTwilioChatClient

@synthesize bridge = _bridge;
@synthesize client;

#pragma mark Singleton Methods

+ (id)sharedManager {
  static RCTTwilioChatClient *sharedMyManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedMyManager = [[self alloc] init];
  });
  return sharedMyManager;
}

RCT_EXPORT_MODULE()

RCT_REMAP_METHOD(createClient, token:(NSString*)token properties:(NSDictionary *)properties resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject){
    RCTTwilioChatClient *_client = [RCTTwilioChatClient sharedManager];

    [TwilioChatClient chatClientWithToken:token properties:NULL delegate:self completion:^(TCHResult *result, TwilioChatClient *chatClient) {
        _client.client = chatClient;
        NSDictionary* response = [RCTConvert TwilioChatClient:chatClient];
        resolve(response);
    }];
}

RCT_EXPORT_METHOD(updateToken:(NSString *)token) {
    RCTTwilioChatClient *_client = [RCTTwilioChatClient sharedManager];
    [[_client client] updateToken:token completion:NULL];
}

RCT_REMAP_METHOD(user, user_resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  RCTTwilioChatClient *_client = [RCTTwilioChatClient sharedManager];
  resolve([RCTConvert TCHUser:_client.client.user]);
}

RCT_REMAP_METHOD(getUser, identity:(NSString*)identity user_resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  RCTTwilioChatClient *_client = [RCTTwilioChatClient sharedManager];
    [_client.client.users userDescriptorWithIdentity:identity completion:^(TCHResult *result, TCHUserDescriptor * user) {
        if (result.isSuccessful) {
            resolve([RCTConvert TCHUserDescriptor:user]);
        }
        else {
            reject(@"set-friendly-name-error", @"Error occured while attempting to set friendly name for the user.", result.error);
        }
    }];
}


RCT_EXPORT_METHOD(synchronizationStatus:(RCTResponseSenderBlock)callback) {
  RCTTwilioChatClient *_client = [RCTTwilioChatClient sharedManager];
  callback(@[@(_client.client.synchronizationStatus)]);
}

RCT_EXPORT_METHOD(version:(RCTResponseSenderBlock)callback) {
  callback(@[client.version]);
}

RCT_EXPORT_METHOD(register:(NSString *)token) {
  RCTTwilioChatClient *_client = [RCTTwilioChatClient sharedManager];
    [[_client client] registerWithNotificationToken:[RCTConvert dataWithHexString:token] completion:NULL];
}

RCT_EXPORT_METHOD(unregister:(NSString *)token) {
  RCTTwilioChatClient *_client = [RCTTwilioChatClient sharedManager];
    [[_client client] deregisterWithNotificationToken:[RCTConvert dataWithHexString:token] completion:NULL];
}

RCT_EXPORT_METHOD(handleNotification:(NSDictionary *)notification) {
  RCTTwilioChatClient *_client = [RCTTwilioChatClient sharedManager];
    [[_client client] handleNotification:notification completion:NULL];
}

RCT_EXPORT_METHOD(shutdown) {
  RCTTwilioChatClient *_client = [RCTTwilioChatClient sharedManager];
  [[_client client] shutdown];
}

RCT_EXPORT_METHOD(setLogLevel:(TCHLogLevel)logLevel) {
  [TwilioChatClient setLogLevel:logLevel];
}

RCT_EXPORT_METHOD(logLevel:(TCHLogLevel)logLevel callback:(RCTResponseSenderBlock)callback) {
  callback(@[@(TwilioChatClient.logLevel)]);
}

RCT_REMAP_METHOD(setFriendlyName, friendlyName:(NSString *)friendlyName friendlyName_resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  RCTTwilioChatClient *_client = [RCTTwilioChatClient sharedManager];
  [[[_client client]user] setFriendlyName:friendlyName completion:^(TCHResult *result) {
    if (result.isSuccessful) {
      resolve(@[@TRUE]);
    }
    else {
      reject(@"set-friendly-name-error", @"Error occured while attempting to set friendly name for the user.", result.error);
    }
  }];
}

RCT_REMAP_METHOD(setAttributes, attributes:(NSDictionary *)attributes attributes_resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
  RCTTwilioChatClient *_client = [RCTTwilioChatClient sharedManager];
  [[[_client client]user] setAttributes:attributes completion:^(TCHResult *result) {
    if (result.isSuccessful) {
      resolve(@[@TRUE]);
    }
    else {
      reject(@"set-attributes-error", @"Error occured while attempting to set attributes for the user.", result.error);
    }
  }];
}

#pragma mark Twilio IP Messaging Client Delegates

- (void)chatClient:(TwilioChatClient *)client connectionStateUpdated:(TCHClientConnectionState)state {
    [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:connectionStateChanged"
                                                 body:@(state)];
}

- (void)chatClient:(TwilioChatClient *)client synchronizationStatusUpdated:(TCHClientSynchronizationStatus)status {
  [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:synchronizationStatusChanged"
                                               body:@(status)];
}

- (void)chatClient:(TwilioChatClient *)client channel:(TCHChannel *)channel updated:(TCHChannelUpdate)updated {
    [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:channelChanged"
                                                 body: [RCTConvert TCHChannel:channel]];
}

- (void)chatClient:(TwilioChatClient *)client channelAdded:(TCHChannel *)channel {
  [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:channelAdded"
                                               body: [RCTConvert TCHChannel:channel]];
}

- (void)chatClient:(TwilioChatClient *)client channelDeleted:(TCHChannel *)channel {
  [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:channelRemoved"
                                               body: [RCTConvert TCHChannel:channel]];
}


- (void)chatClient:(TwilioChatClient *)client channel:(TCHChannel *)channel synchronizationStatusUpdated:(TCHChannelSynchronizationStatus)status {
  NSString *channelSid;
  if (channel) {
    channelSid = channel.sid;
  }
  else {
    channelSid = RCTNullIfNil(nil);
  }
  [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:channel:synchronizationStatusChanged"
                                               body: @{
                                                       @"channelSid": channelSid,
                                                       @"status": @(status)
                                                       }];
}


- (void)chatClient:(TwilioChatClient *)client channel:(TCHChannel *)channel memberJoined:(TCHMember *)member {
  [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:channel:memberJoined"
                                               body: @{
                                                       @"channelSid": channel.sid,
                                                       @"member": [RCTConvert TCHMember:member]
                                                       }];
}

- (void)chatClient:(TwilioChatClient *)client channel:(TCHChannel *)channel member:(TCHMember *)member updated:(TCHMemberUpdate)updated {
    [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:channel:member:userInfoUpdated"
                                                 body: @{@"channelSid": channel.sid,
                                                         @"updated": @(updated),
                                                         }];
    
}

- (void)chatClient:(TwilioChatClient *)client channel:(TCHChannel *)channel memberLeft:(TCHMember *)member {
  [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:channel:memberLeft"
                                               body: @{
                                                       @"channelSid": channel.sid,
                                                       @"member": [RCTConvert TCHMember:member]
                                                       }];
}

- (void)chatClient:(TwilioChatClient *)client channel:(TCHChannel *)channel messageAdded:(TCHMessage *)message {
    NSString *sid = channel.sid;
    [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:channel:messageAdded"
                                               body: @{
                                                       @"channelSid": sid,
                                                       @"message": [RCTConvert TCHMessage:message]
                                                       }];
}

- (void)chatClient:(TwilioChatClient *)client channel:(TCHChannel *)channel messageDeleted:(TCHMessage *)message {
  [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:channel:messageDeleted"
                                               body: @{
                                                       @"channelSid": channel.sid,
                                                       @"message": [RCTConvert TCHMessage:message]
                                                       }];
}

- (void)chatClient:(TwilioChatClient *)client errorReceived:(TCHError *)error {
  [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:errorReceived"
                                               body:@{@"error": [error localizedDescription],
                                                      @"userInfo": [error userInfo]
                                                      }];
}

- (void)chatClient:(TwilioChatClient *)client typingStartedOnChannel:(TCHChannel *)channel member:(TCHMember *)member {
  [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:typingStartedOnChannel"
                                               body: @{
                                                       @"channelSid": channel.sid,
                                                       @"member": [RCTConvert TCHMember:member]
                                                       }];
}

- (void)chatClient:(TwilioChatClient *)client typingEndedOnChannel:(TCHChannel *)channel member:(TCHMember *)member {
  [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:typingEndedOnChannel"
                                               body: @{
                                                       @"channelSid": channel.sid,
                                                       @"member": [RCTConvert TCHMember:member]
                                                       }];
}

- (void)chatClient:(TwilioChatClient *)client notificationNewMessageReceivedForChannelSid:(nonnull NSString *)channelSid messageIndex:(NSUInteger)messageIndex {}

- (void)chatClient:(TwilioChatClient *)client notificationUpdatedBadgeCount:(NSUInteger)badgeCount {}

- (void)chatClient:(TwilioChatClient *)client user:(TCHUser *)user updated:(TCHUserUpdate)updated {
  [self.bridge.eventDispatcher sendAppEventWithName:@"chatClient:userInfoUpdated"
                                               body: @{@"updated": @(updated),
                                                       @"userInfo": [RCTConvert TCHUser:user]
                                                       }];
}

- (void)chatClient:(TwilioChatClient *)client userSubscribed:(TCHUser *)user {}

- (void)chatClient:(TwilioChatClient *)client userUnsubscribed:(TCHUser *)user {}



#pragma mark Enums

- (NSDictionary *)constantsToExport
{
  return @{ @"Constants": @{
                @"TCHClientSynchronizationStatus": @{
                    @"Started" : @(TCHClientSynchronizationStatusStarted),
                    @"ChannelsListCompleted" : @(TCHClientSynchronizationStatusChannelsListCompleted),
                    @"Completed" : @(TCHClientSynchronizationStatusCompleted),
                    @"Failed" : @(TCHClientSynchronizationStatusFailed)
                    },
                @"TCHChannelSynchronizationStatus": @{
                    @"None" : @(TCHChannelSynchronizationStatusNone),
                    @"Identifier" : @(TCHChannelSynchronizationStatusIdentifier),
                    @"Metadata" : @(TCHChannelSynchronizationStatusMetadata),
                    @"All" : @(TCHChannelSynchronizationStatusAll),
                    @"Failed" : @(TCHChannelSynchronizationStatusFailed)
                    },
                @"TCHChannelStatus": @{
                    @"Invited": @(TCHChannelStatusInvited),
                    @"Joined": @(TCHChannelStatusJoined),
                    @"NotParticipating": @(TCHChannelStatusNotParticipating)
                    },
                @"TCHChannelType": @{
                    @"Public": @(TCHChannelTypePublic),
                    @"Private": @(TCHChannelTypePrivate)
                    },
                @"TCHUserInfoUpdate": @{
                    @"FriendlyName": @(TCHUserUpdateFriendlyName),
                    @"Attributes": @(TCHUserUpdateAttributes),
                    @"ReachabilityOnline": @(TCHUserUpdateReachabilityOnline),
                    @"ReachabilityNotifiable": @(TCHUserUpdateReachabilityNotifiable)
                    },
                @"TCHLogLevel": @{
                    @"Fatal" : @(TCHLogLevelFatal),
                    @"Critical" : @(TCHLogLevelCritical),
                    @"Warning" : @(TCHLogLevelWarning),
                    @"Info" : @(TCHLogLevelInfo),
                    @"Debug" : @(TCHLogLevelDebug)
                    },
                @"TCHChannelOption": @{
                        @"FriendlyName" : TCHChannelOptionFriendlyName,
                        @"UniqueName" : TCHChannelOptionUniqueName,
                        @"Type" : TCHChannelOptionType,
                        @"Attributes" : TCHChannelOptionAttributes
                        },
                @"TCHClientConnectionState": @{
                        @"Unknown" : @(TCHClientConnectionStateUnknown),
                        @"Disconnected" : @(TCHClientConnectionStateDisconnected),
                        @"Connected" : @(TCHClientConnectionStateConnected),
                        @"Connecting" : @(TCHClientConnectionStateConnecting),
                        @"Denied" : @(TCHClientConnectionStateDenied),
                        @"Error" : @(TCHClientConnectionStateError)
                        }
                }
            };
};


@end
