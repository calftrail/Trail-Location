//
//  TLLocationSourceBase.m
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

#import "TLLocationSourceBase.h"

#import <CoreLocation/CoreLocation.h>
#import "TLLocationMaster.h"
#import "TLLocationMaster+TLLocationSourceUseOnly.h"


@interface TLLocationSourceBase ()
@property (nonatomic, assign) TLLocationMaster* target;
@end

@implementation TLLocationSourceBase

@synthesize target;

- (void)locationMasterRequestsUpdates:(TLLocationMaster*)aMaster
						   toLocation:(BOOL)doesRequestLocationUpdates
							toHeading:(BOOL)doesRequestHeadingUpdates
{
	if (doesRequestLocationUpdates || doesRequestHeadingUpdates) {
		NSAssert(![self target] || [self target] == aMaster,
				 @"Location source base currently supports only one master.");
		[self setTarget:aMaster];
	}
	else {
		[self setTarget:nil];
	}
}

- (void)updateLocation:(CLLocation*)newLocation {
	[[self target] locationSource:self hasLocation:newLocation];
}

- (void)updateHeading:(CLHeading*)newHeading {
	[[self target] locationSource:self hasHeading:newHeading];
}

- (void)giveError:(NSError*)anError {
	[[self target] locationSource:self hasError:anError];
}

- (BOOL)queryHeadingCalibrationDisplay {
	return [[self target] locationSourceShouldDisplayHeadingCalibration:self];
}

@end
