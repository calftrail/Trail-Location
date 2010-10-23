//
//  AppDelegate.m
//  Mainframe Sends Location
//
//  Created by Nathan Vander Wilt on 8/6/09.
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

#import "TLLocationSender.h"


static const double maxLatitude = 80.0; // 85.05;
static const double maxLongitude = 175.0; // 180.0;


@interface AppDelegate (RandomLocations)
- (void)random_keepSending;
@end

@implementation AppDelegate

- (void)awakeFromNib {
	locationSender = [TLLocationSender new];
	if ([self respondsToSelector:@selector(gpsd_keepSending)]) {
		[self performSelector:@selector(gpsd_keepSending)
				   withObject:nil
				   afterDelay:0.5];
	}
	else {
		[self random_keepSending];
	}
}

- (void)dealloc {
	[locationSender release];
	if ([self respondsToSelector:@selector(gpsd_cleanup)]) {
		[self gpsd_cleanup];
	}
	[super dealloc];
}

@end


@implementation AppDelegate (RandomLocations)

- (void)random_sendLocation {
	double randomLatitude = -maxLatitude + (2.0 * maxLatitude) * (random() / (double)LONG_MAX);
	double randomLongitude = -maxLongitude + (2.0 * maxLongitude) * (random() / (double)LONG_MAX);
	if (fabs(randomLatitude - 46.36369) < 0.5 &&
		fabs(randomLongitude - -120.07905) < 0.5)
	{
		// avoid crushing Calf Trail HQ
		return;
	}
	
	NSDictionary* locationInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithDouble:randomLatitude], @"latitude",
								  [NSNumber numberWithDouble:randomLongitude], @"longitude", nil];
	[locationSender sendLocationInfo:locationInfo];
}

- (void)random_keepSending {
	static bool randomInitialized = false;
	if (!randomInitialized) {
		srandomdev();
		randomInitialized = true;
	}
	[self random_sendLocation];
	[self performSelector:_cmd withObject:nil afterDelay:1.42];
}

@end
