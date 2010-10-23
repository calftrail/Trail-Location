//
//  TLCoreLocationSource.m
//  TrailLocation
//
//  Created by Nathan Vander Wilt on 7/10/09.
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

#import "TLCoreLocationSource.h"
#include <CoreLocation/CoreLocation.h>
#import "TLLocationMaster.h"
#import "TLLocationMaster+TLLocationSourceUseOnly.h"

#ifndef __IPHONE_3_0
@class CLHeading;
#endif


@interface TLCoreLocationSource () <CLLocationManagerDelegate>
@property (nonatomic, readonly) CLLocationManager* manager;
@end

@implementation TLCoreLocationSource

@synthesize manager;

- (id)init {
	self = [super init];
	if (self) {
		manager = [CLLocationManager new];
		[manager setDelegate:self];
	}
	return self;
}

- (void)dealloc {
	[manager release];
	[super dealloc];
}

- (void)locationMasterRequestsUpdates:(TLLocationMaster*)aMaster
						   toLocation:(BOOL)doesRequestLocationUpdates
							toHeading:(BOOL)doesRequestHeadingUpdates
{
	if (doesRequestLocationUpdates) {
		[[self manager] startUpdatingLocation];
		[[self manager] setDesiredAccuracy:[aMaster desiredAccuracy]];
		[[self manager] setDistanceFilter:[aMaster distanceFilter]];
	}
	else {
		[[self manager] stopUpdatingLocation];
	}

#ifdef __IPHONE_3_0
	if (doesRequestHeadingUpdates) {
		[[self manager] startUpdatingHeading];
		[[self manager] setHeadingFilter:[aMaster headingFilter]];
	}
	else {
		[[self manager] stopUpdatingHeading];
	}
#else
	(void)doesRequestHeadingUpdates;
#endif
}

- (void)locationManager:(CLLocationManager*)aManager
	didUpdateToLocation:(CLLocation*)newLocation
		   fromLocation:(CLLocation*)oldLocation
{
	(void)aManager;
	(void)oldLocation;
	[self updateLocation:newLocation];
}


- (void)locationManager:(CLLocationManager*)aManager
	   didFailWithError:(NSError*)anError
{
	(void)aManager;
	[self giveError:anError];
}

- (void)locationManager:(CLLocationManager*)aManager
	   didUpdateHeading:(CLHeading*)newHeading
{
	(void)aManager;
	[self updateHeading:newHeading];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager*)aManager {
	(void)aManager;
	return [self queryHeadingCalibrationDisplay];
}

- (void)locationMasterNeedsHeadingCalibrationDisplayDismissed:(TLLocationMaster*)aMaster {
	(void)aMaster;
#ifdef __IPHONE_3_0
	[[self manager] dismissHeadingCalibrationDisplay];	
#endif
}

@end
