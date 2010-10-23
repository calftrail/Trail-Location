//
//  TLLocationSender.m
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

#import "TLLocationSender.h"

#import "TLLocationTarget.h"

#if TL_HAS_CORE_LOCATION
#import "CLLocation+TLLocationAdditions.h"
#endif

@interface TLLocationSender ()
@property (nonatomic, retain) NSMutableSet* mutableFoundTargets;
@end


@implementation TLLocationSender

//@synthesize foundTargets;
- (NSSet*)foundTargets {
	return foundTargets;
}

@synthesize mutableFoundTargets = foundTargets;

- (id)init {
	self = [super init];
	if (self) {
		foundTargets = [NSMutableSet new];
		
		serviceBrowser = [NSNetServiceBrowser new];
		[serviceBrowser setDelegate:self];
		[serviceBrowser searchForServicesOfType:@"_geoloc-client._udp." inDomain:@""];
	}
	return self;
}

- (void)dealloc {
	[foundTargets release];
	[super dealloc];
}


- (void)netServiceBrowser:(NSNetServiceBrowser*)aNetServiceBrowser
		   didFindService:(NSNetService*)netService
			   moreComing:(BOOL)moreServicesComing
{
	(void)aNetServiceBrowser;
	(void)moreServicesComing;
	//NSLog(@"Found service: %@", netService);
	
	TLLocationTarget* target = [[TLLocationTarget alloc] initWithRecord:netService];
	[[self mutableFoundTargets] addObject:target];
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)aNetServiceBrowser
		 didRemoveService:(NSNetService*)netService
			   moreComing:(BOOL)moreServicesComing
{
	(void)aNetServiceBrowser;
	(void)moreServicesComing;
	
	//NSLog(@"Lost service: %@", netService);
	
	TLLocationTarget* removedTarget = nil;
	for (TLLocationTarget* target in [self foundTargets]) {
		if ([[target serviceRecord] isEqual:netService]) {
			removedTarget = target;
			break;
		}
	}
	NSAssert(removedTarget, @"Could not find target for removed service.");
	[removedTarget invalidateService];
	[[self mutableFoundTargets] removeObject:removedTarget];
}

- (void)sendLocationInfo:(NSDictionary*)locationInfo {
	/*
	NSUInteger numTargets = [[self foundTargets] count];
	if (numTargets) NSLog(@"Sending location info to %lu targets - %@", numTargets, locationInfo);
	 */
	for (TLLocationTarget* target in [self foundTargets]) {
		[target sendLocationInfo:locationInfo];
	}
}

#if TL_HAS_CORE_LOCATION
- (void)sendLocation:(CLLocation*)location {
	NSDictionary* locationInfo = [location tl_dictionaryRepresentation];
	[self sendLocationInfo:locationInfo];
}
#endif

@end


