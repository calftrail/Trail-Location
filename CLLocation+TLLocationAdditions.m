//
//  CLLocation+TLLocationAdditions.m
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

#import "CLLocation+TLLocationAdditions.h"


@implementation CLLocation (TLLocationAdditions)

- (NSDictionary*)tl_dictionaryRepresentation {
	NSMutableDictionary* dictRep = [NSMutableDictionary dictionary];
	[dictRep setObject:[NSNumber numberWithDouble:self.coordinate.latitude]
				forKey:@"latitude"];
	[dictRep setObject:[NSNumber numberWithDouble:self.coordinate.longitude]
				forKey:@"longitude"];
	[dictRep setObject:[NSNumber numberWithDouble:[self.timestamp timeIntervalSince1970]]
				forKey:@"timestamp"];
	NSDictionary* otherKeys = [self dictionaryWithValuesForKeys:
							   [NSArray arrayWithObjects:@"altitude", @"course", @"speed",
								@"horizontalAccuracy", @"verticalAccuracy", nil]];
	[dictRep addEntriesFromDictionary:otherKeys];
	return dictRep;
}

- (id)tl_initWithDictionaryRepresentation:(NSDictionary*)dictRep {
	CLLocationCoordinate2D coordinate = {};
	CLLocationAccuracy hAccuracy = -1.0;
	if ([dictRep objectForKey:@"latitude"] && [dictRep objectForKey:@"longitude"]) {
		hAccuracy = 0.0;
		CLLocationDegrees lat = [[dictRep objectForKey:@"latitude"] doubleValue];
		CLLocationDegrees lon = [[dictRep objectForKey:@"longitude"] doubleValue];
		coordinate = (CLLocationCoordinate2D){ .latitude = lat, .longitude = lon };
		if ([dictRep objectForKey:@"horizontalAccuracy"]) {
			hAccuracy = [[dictRep objectForKey:@"horizontalAccuracy"] doubleValue];
		}
	}
	
	CLLocationDistance altitude = 0.0;
	CLLocationAccuracy vAccuracy = -1.0;
	if ([dictRep objectForKey:@"altitude"]) {
		altitude = [[dictRep objectForKey:@"altitude"] doubleValue];
		if ([dictRep objectForKey:@"verticalAccuracy"]) {
			vAccuracy = [[dictRep objectForKey:@"verticalAccuracy"] doubleValue];
		}
	}
	
	NSDate* timestamp = nil;
	if ([dictRep objectForKey:@"timestamp"]) {
		NSTimeInterval epochTimestamp = [[dictRep objectForKey:@"timestamp"] doubleValue];
		timestamp = [NSDate dateWithTimeIntervalSince1970:epochTimestamp];
	}
	else {
		timestamp = [NSDate date];
	}
	
	// TODO: what to do about course and speed?
	
	return [self initWithCoordinate:coordinate
						   altitude:altitude
				 horizontalAccuracy:hAccuracy
				   verticalAccuracy:vAccuracy
						  timestamp:timestamp];
}

@end
