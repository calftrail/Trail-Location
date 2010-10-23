//
//  TLLocationTarget.m
//  TrailLocation
//
//  Created by Nathan Vander Wilt on 8/4/09.
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

#import "TLLocationTarget.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>


static const NSTimeInterval TLLTResolveTimeout = 5.0;


@implementation TLLocationTarget

@synthesize name;
@synthesize serviceRecord;

- (id)initWithRecord:(NSNetService*)netServiceRecord {
	self = [super init];
	if (self) {
		serviceRecord = [netServiceRecord retain];
		[serviceRecord setDelegate:self];
		// TODO: NSNetServices header says "robust clients may wish...to resolve more than once"
		[[self serviceRecord] resolveWithTimeout:TLLTResolveTimeout];
		
		sendQueue = [NSMutableArray new];
	}
	return self;
}

- (void)dealloc {
	[name release];
	[serviceRecord setDelegate:nil];
	[serviceRecord release];
	[sendQueue release];
	[super dealloc];
}


- (BOOL)sendInfo:(NSDictionary*)info toAddress:(NSData*)addressData {
	const struct sockaddr* addressPtr = [addressData bytes];
	// NOTE: socket() actually wants PF_ instead of sockaddr's AF_, but they are currently compatible
	int testSocket = socket(addressPtr->sa_family, SOCK_DGRAM, 0);
	if (testSocket < 0) {
		return NO;
	}
	
	// TODO: serialize as JSON, rather than XML plist
	NSData* messageData = [NSPropertyListSerialization dataFromPropertyList:info
																	 format:NSPropertyListXMLFormat_v1_0
														   errorDescription:NULL];
	const void* message = [messageData bytes];
	ssize_t messageLength = [messageData length];
	
	ssize_t sentAmount = sendto(testSocket, message, messageLength, 0, addressPtr, addressPtr->sa_len);
	if (sentAmount != messageLength) {
		return NO;
	}
	return YES;
}

- (BOOL)sendQueuedInfoToAddress:(NSData*)addressData {
	NSUInteger sentCount = 0;
	for (NSDictionary* info in sendQueue) {
		BOOL success = [self sendInfo:info toAddress:addressData];
		if (!success) break;
		++sentCount;
	}
	NSUInteger originalQueueCount = [sendQueue count];
	[sendQueue removeObjectsInRange:NSMakeRange(0, sentCount)];
	return (sentCount == originalQueueCount);
}

- (void)flushQueue {
	for (NSData* addressData in [[self serviceRecord] addresses]) {
		BOOL success = [self sendQueuedInfoToAddress:addressData];
		if (success) break;
	}
}

- (void)sendLocationInfo:(NSDictionary*)info {
	NSDictionary* ourInfo = [[info copy] autorelease];
	[sendQueue addObject:ourInfo];
	[self flushQueue];
}

- (void)netServiceDidResolveAddress:(NSNetService*)sender {
	(void)sender;
	[self flushQueue];
}

- (void)netService:(NSNetService*)sender didNotResolve:(NSDictionary*)errorDict {
	(void)sender;
	NSLog(@"Error resolving - %@", errorDict);
	// TODO: retry resolve a few times
}

- (void)invalidateService {
	// TODO: implement
}

@end
