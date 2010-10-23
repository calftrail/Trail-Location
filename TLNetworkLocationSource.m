//
//  TLNetworkLocationSource.m
//  TrailLocation
//
//  Created by Nathan Vander Wilt on 8/3/09.
//  Copyright 2009 Calf Trail Software, LLC. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Calf Trail Software, LLC nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "TLNetworkLocationSource.h"

#import <CoreLocation/CoreLocation.h>
#import "CLLocation+TLLocationAdditions.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>


void TLNLSCallbackWrapper(CFSocketRef theSocket, CFSocketCallBackType callbackType,
						  CFDataRef address, const void* data, void* info);

@interface TLNetworkLocationSource ()
@end




@implementation TLNetworkLocationSource

@synthesize name;

- (id)init {
	self = [super init];
	if (self) {
		// ...
	}
	return self;
}

- (void)dealloc {
	NSAssert(!listenerSocket && !serviceAdvertisement,
			 @"Lifecycle error, must stopListening before deallocation");
	[name release];
	[super dealloc];
}


- (void)startListening {
	// socket(PF_INET, SOCK_DGRAM, 0);
	CFSocketContext sockCtx = {};
	sockCtx.info = self;
	listenerSocket = CFSocketCreate(kCFAllocatorDefault,
									PF_INET, SOCK_DGRAM, 0,
									kCFSocketDataCallBack,
									TLNLSCallbackWrapper, &sockCtx);
	NSAssert1(listenerSocket, @"Couldn't create listener socket (%s)!", strerror(errno));
	
	CFRunLoopSourceRef socketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault,
																  listenerSocket, 0);
	CFRunLoopAddSource(CFRunLoopGetMain(), socketSource, kCFRunLoopCommonModes);
	CFRelease(socketSource);
	
	// bind(theSocket, (struct sockaddr*)&portInfo, sizeof(portInfo));
	struct sockaddr_in portInfo = {};
	portInfo.sin_family = AF_INET;
	portInfo.sin_port = htons(0);
	portInfo.sin_addr.s_addr = htonl(INADDR_ANY);
	CFDataRef addressData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault,
														(UInt8*)&portInfo, sizeof(portInfo),
														kCFAllocatorNull);
	CFSocketError err = CFSocketSetAddress(listenerSocket, addressData);
	NSAssert(!err, @"Couldn't bind listener socket.");
	CFRelease(addressData);
	
	// getsockname(theSocket, (struct sockaddr*)&boundInfo, &nameLen);
	CFDataRef boundAddressData = CFSocketCopyAddress(listenerSocket);
	struct sockaddr_in* boundInfoPtr = (void*)CFDataGetBytePtr(boundAddressData);
	int registeredPort = ntohs(boundInfoPtr->sin_port);
	CFRelease(boundAddressData);
	
	//printf("Registered on port %i\n", registeredPort);
	
	NSString* serviceName = [self name] ?: @"Location requester";
	// TODO: finalize name and register
	serviceAdvertisement = [[NSNetService alloc] initWithDomain:@""
														   type:@"_geoloc-client._udp."
														   name:serviceName
														   port:registeredPort];
	[serviceAdvertisement publish];
}

- (void)stopListening {
	[serviceAdvertisement stop];
	[serviceAdvertisement release], serviceAdvertisement = nil;
	CFSocketInvalidate(listenerSocket);
	CFRelease(listenerSocket), listenerSocket = NULL;
}

@end


void TLNLSCallbackWrapper(CFSocketRef theSocket, CFSocketCallBackType callbackType,
						  CFDataRef address, const void* data, void* info)
{
	(void)theSocket;
	(void)address;
	
	if (callbackType == kCFSocketDataCallBack) {
		NSData* incomingData = (NSData*)data;
		NSDictionary* locationInfo = [NSPropertyListSerialization propertyListFromData:incomingData
																	  mutabilityOption:kCFPropertyListImmutable
																				format:NULL
																	  errorDescription:NULL];
		CLLocation* location = [[CLLocation alloc] tl_initWithDictionaryRepresentation:locationInfo];
		//NSLog(@"Got location: %@", location);
		TLNetworkLocationSource* source = info;
		[source updateLocation:location];
		[location release];
	}
}
