//
//  AppDelegate+GPSD.m
//  Mainframe Sends Location
//
//  Created by Nathan Vander Wilt on 8/31/09.
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


#import "AppDelegate.h"
#import "AppDelegate+GPSD.h"

#include "gps_wrapper.h"


@interface PollGPSDOperation : NSOperation {
@private
	TLLocationSender* sender;
	NSOperationQueue* queue;
	NSDictionary* previousLocationInfo;
}
@property (nonatomic, retain) TLLocationSender* sender;
@property (nonatomic, retain) NSOperationQueue* queue;
@property (nonatomic, retain) NSDictionary* previousLocationInfo;
@end

@implementation AppDelegate (UseGPSD)

static struct gps_data_t* gpsData = NULL;
static NSOperationQueue* backgroundQueue = nil;

- (void)gpsd_keepSending {
	if (!gpsData) {
		gpsData = gps_open("127.0.0.1", DEFAULT_GPSD_PORT);
		gps_query(gpsData, "w+");
	}
	if (!backgroundQueue) {
		backgroundQueue = [NSOperationQueue new];
		[backgroundQueue setMaxConcurrentOperationCount:1];
	}
	PollGPSDOperation* op = [[PollGPSDOperation new] autorelease];
	op.sender = locationSender;
	op.queue = backgroundQueue;
	[backgroundQueue addOperation:op];
}

- (void)gpsd_cleanup {
	gps_close(gpsData), gpsData = NULL;
	[backgroundQueue setSuspended:YES];
	[backgroundQueue release], backgroundQueue = nil;
}

@end


@implementation PollGPSDOperation

@synthesize sender;
@synthesize queue;
@synthesize previousLocationInfo;

- (void)dealloc {
	[sender release];
	[queue release];
	[previousLocationInfo release];
	[super dealloc];
}

- (void)main {
	gps_poll(gpsData);
	struct gps_fix_t fixInfo = gpsData->fix;
	
	NSMutableDictionary* locationInfo = [NSMutableDictionary dictionary];
	
	if (!isnan(fixInfo.time)) {
		[locationInfo setObject:[NSNumber numberWithDouble:(fixInfo.time)]
						 forKey:@"timestamp"];
	}
	
	if (fixInfo.mode > MODE_NO_FIX) {
		[locationInfo setObject:[NSNumber numberWithDouble:(fixInfo.latitude)]
						 forKey:@"latitude"];
		[locationInfo setObject:[NSNumber numberWithDouble:(fixInfo.longitude)]
						 forKey:@"longitude"];
		[locationInfo setObject:[NSNumber numberWithDouble:(fixInfo.eph)]
						 forKey:@"horizontalAccuracy"];
	}
	
	if (fixInfo.mode > MODE_NO_FIX) {
		[locationInfo setObject:[NSNumber numberWithDouble:(fixInfo.track)]
						 forKey:@"course"];
		[locationInfo setObject:[NSNumber numberWithDouble:(fixInfo.speed)]
						 forKey:@"speed"];
	}
	
	if (fixInfo.mode == MODE_3D) {
		[locationInfo setObject:[NSNumber numberWithDouble:(fixInfo.altitude)]
						 forKey:@"altitude"];
		[locationInfo setObject:[NSNumber numberWithDouble:(fixInfo.epv)]
						 forKey:@"verticalAccuracy"];
		
	}
	
	// NOTE: GPSD often sends duplicate information (both RMC and GGA)
	// TODO: where to filter this duplicate info out?
	if ([locationInfo count])
	{
		NSLog(@"%@", locationInfo);
		[(self.sender) performSelectorOnMainThread:@selector(sendLocationInfo:)
										withObject:locationInfo
									 waitUntilDone:NO];
	}
	
	if (self.queue && ![self.queue isSuspended]) {
		PollGPSDOperation* clone = [[PollGPSDOperation new] autorelease];
		clone.sender = self.sender;
		clone.queue = self.queue;
		clone.previousLocationInfo = locationInfo;
		[(self.queue) addOperation:clone];
	}
}

@end
