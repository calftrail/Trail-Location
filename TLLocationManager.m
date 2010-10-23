//
//  TLLocationManager.m
//  TrailLocation
//
//  Created by Nathan Vander Wilt on 7/9/09.
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

#import <CoreLocation/CoreLocation.h>
#ifndef __IPHONE_3_0
@class CLHeading;
#endif
#import "TLLocationManager.h"
#import "TLLocationManager+TLLocationMasterUseOnly.h"
#import "TLLocationMaster.h"
#import "TLLocationMaster+TLLocationManagerUseOnly.h"

@interface TLLocationManager ()
@property (nonatomic, retain, readwrite) CLLocation* location;
@property (nonatomic, readonly) TLLocationMaster* master;
@property (nonatomic, assign, getter=isRegistered) BOOL registered;
@property (nonatomic, readwrite, assign) BOOL wantsLocations;
@property (nonatomic, readwrite, assign) BOOL wantsHeadings;
@end


@implementation TLLocationManager

@synthesize location;
@synthesize master;
@synthesize registered;
@synthesize wantsLocations;
@synthesize wantsHeadings;

- (id)initWithMaster:(TLLocationMaster*)theMaster {
	self = [super init];
	if (self) {
		master = [theMaster retain];
	}
	return self;
}

- (void)dealloc {
	[master release];
	[super dealloc];
}

- (id)init {
	return [self initWithMaster:[TLLocationMaster defaultMaster]];
}

- (void)startUpdatingLocation {
	[self setWantsLocations:YES];
	if (![self isRegistered]) {
		[[self master] registerManager:self];
		[self setRegistered:YES];
	}
}

- (void)stopUpdatingLocation {
	[self setWantsLocations:NO];
	if (![self wantsHeadings]) {
		[[self master] unregisterManager:self];
		[self setRegistered:NO];
	}
}

- (void)startUpdatingHeading {
	[self setWantsHeadings:YES];
	if (![self isRegistered]) {
		[[self master] registerManager:self];
	}
}

- (void)stopUpdatingHeading {
	[self setWantsHeadings:NO];
	if (![self wantsLocations]) {
		[[self master] unregisterManager:self];
		[self setRegistered:NO];
	}
}

#ifndef __IPHONE_3_0
- (CLLocationDegrees)headingFilter {
	return -1.0;
}
#endif

- (void)masterProvidesLocation:(CLLocation*)aLocation {
	// TODO: filter for distance
	CLLocation* oldLocation = [self location];
	if ([[self delegate] respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)]) {
		[[self delegate] locationManager:self didUpdateToLocation:aLocation fromLocation:oldLocation];
	}
	[self setLocation:aLocation];
}

- (void)masterProvidesHeading:(CLHeading*)aHeading {
	// TODO: filter for degree
#ifdef __IPHONE_3_0
	if ([[self delegate] respondsToSelector:@selector(locationManager:didUpdateHeading:)]) {
		[[self delegate] locationManager:self didUpdateHeading:aHeading];
	}
#else
	(void)aHeading;
#endif
}

- (void)masterProvidesError:(NSError*)anError {
	if ([[self delegate] respondsToSelector:@selector(locationManager:didFailWithError:)]) {
		[[self delegate] locationManager:self didFailWithError:anError];
	}
}

- (BOOL)masterWantsHeadingCalibrationPermission {
	BOOL permissionGranted = NO;
#ifdef __IPHONE_3_0
	if ([[self delegate] respondsToSelector:@selector(locationManagerShouldDisplayHeadingCalibration:)]) {
		permissionGranted = [[self delegate] locationManagerShouldDisplayHeadingCalibration:self];
	}
#endif
	return permissionGranted;
}

@end