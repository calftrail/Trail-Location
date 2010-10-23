//
//  TLLocationMaster.m
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

#include <CoreLocation/CoreLocation.h>
#import "TLLocationMaster.h"
#import "TLLocationMaster+TLLocationManagerUseOnly.h"
#import "TLLocationMaster+TLLocationSourceUseOnly.h"
#import "TLLocationManager.h"
#import "TLLocationManager+TLLocationMasterUseOnly.h"
#import "TLLocationSource.h"

#import "TLNetworkLocationSource.h"


#include <libkern/OSAtomic.h>

static TLLocationMaster* volatile gDefaultMaster = nil;
static NSString* TLLocationMasterObservationContext = @"TLLocationMaster_ObservationContext";

@interface TLLocationMaster ()
@property (nonatomic, readonly) NSSet* activeManagers;
// TODO: make some of these public as appropriate
@property (nonatomic, readwrite, assign) BOOL requestsLocationUpdates;
@property (nonatomic, readwrite, assign) CLLocationAccuracy desiredAccuracy;
@property (nonatomic, readwrite, assign) CLLocationDistance distanceFilter;
@property (nonatomic, readwrite, assign) BOOL requestsHeadingUpdates;
@property (nonatomic, readwrite, assign) CLLocationDegrees headingFilter;
- (void)updateCoreLocationManager;
@end


@implementation TLLocationMaster

+ (id)defaultMaster {
	if (!gDefaultMaster) {
		// See http://alanquatermain.net/post/114613488/lockless-lazily-initialized-static-global-variables
		TLLocationMaster* newDefaultMaster = [TLLocationMaster new];
		
		TLNetworkLocationSource* netSource = [TLNetworkLocationSource new];
		// TODO: how/where should listening be stopped? better to keep listening internal to source?
		[netSource startListening];
		[newDefaultMaster addLocationSource:netSource];
		[netSource release];
		
		bool set = OSAtomicCompareAndSwapPtrBarrier(nil,
													newDefaultMaster,
													(void**)&gDefaultMaster);
		if (!set) {
			[newDefaultMaster release];
		}
	}
	return [[gDefaultMaster retain] autorelease];
}

+ (void)setDefaultMaster:(id)newDefaultMaster {
	[newDefaultMaster retain];
	bool swapped = false;
	TLLocationMaster* oldDefaultMaster = nil;
	do {
		// See http://www.mikeash.com/?page=pyblog/late-night-cocoa.html
		oldDefaultMaster = gDefaultMaster;
		swapped = OSAtomicCompareAndSwapPtrBarrier(oldDefaultMaster,
												   newDefaultMaster,
												   (void**)&gDefaultMaster);
	} while (!swapped);
	[oldDefaultMaster release];
}


@synthesize locationSources;
@synthesize activeManagers;
@synthesize requestsLocationUpdates;
@synthesize desiredAccuracy;
@synthesize distanceFilter;
@synthesize requestsHeadingUpdates;
@synthesize headingFilter;

- (id)init {
	self = [super init];
	if (self) {
		locationSources = [[NSCountedSet set] retain];
		activeManagers = [[NSMutableSet set] retain];
		// TODO: activeManagers sub-properties need observing!
		[self addObserver:self
			   forKeyPath:@"activeManagers"
				  options:NSKeyValueObservingOptionNew
				  context:&TLLocationMasterObservationContext];
		[self addObserver:self
			   forKeyPath:@"locationSources"
				  options:NSKeyValueObservingOptionNew
				  context:&TLLocationMasterObservationContext];
	}
	return self;
}

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"activeManagers"];
	[self removeObserver:self forKeyPath:@"locationSources"];
	[locationSources release];
	[activeManagers release];
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
    if (context == &TLLocationMasterObservationContext) {
		//NSLog(@"Observed %@ - %@", keyPath, change);
		if ([keyPath isEqualToString:@"activeManagers"] ||
			[keyPath isEqualToString:@"locationSources"]) {
			[self updateCoreLocationManager];
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)addActiveManagersObject:(TLLocationManager*)newManager { [activeManagers addObject:newManager]; }
- (void)removeActiveManagersObject:(TLLocationManager*)newManager { [activeManagers removeObject:newManager]; }
- (void)addLocationSourcesObject:(id)newSource { [locationSources addObject:newSource]; }
- (void)addLocationSource:(id <TLLocationSource>)newSource { [self addLocationSourcesObject:newSource]; }
- (void)removeLocationSourcesObject:(id)oldSource { [locationSources removeObject:oldSource]; }
- (void)removeLocationSource:(id <TLLocationSource>)oldSource { [self removeLocationSourcesObject:oldSource]; }

- (void)updateCoreLocationManager {
	BOOL needsLocation = NO;
	BOOL needsHeading = NO;
	for (TLLocationManager* manager in [self activeManagers]) {
		if ([manager wantsLocations]) {
			needsLocation = YES;
		}
		if ([manager wantsHeadings]) {
			needsHeading = YES;
		}
		if (needsLocation && needsHeading) break;
	}
	[self setRequestsLocationUpdates:needsLocation];
	[self setRequestsHeadingUpdates:needsHeading];
	
	if (needsLocation) {
		CLLocationAccuracy minDesiredAccuracy = [[[self activeManagers] valueForKeyPath:@"@min.desiredAccuracy"]
												 doubleValue];
		[self setDesiredAccuracy:minDesiredAccuracy];
		CLLocationDistance minDistanceFilter = [[[self activeManagers] valueForKeyPath:@"@min.distanceFilter"]
												doubleValue];
		[self setDistanceFilter:minDistanceFilter];
	}
	
	if (needsHeading) {
		CLLocationDegrees minHeadingFilter = [[[self activeManagers] valueForKeyPath:@"@min.headingFilter"]
											  doubleValue];
		[self setHeadingFilter:minHeadingFilter];
	}
	
	for (id <TLLocationSource> source in [self locationSources]) {
		if ([source respondsToSelector:@selector(locationMasterRequestsUpdates:toLocation:toHeading:)]) {
			[source locationMasterRequestsUpdates:self
									   toLocation:needsLocation
										toHeading:needsHeading];
		}
	}
}

@end


@implementation TLLocationMaster (TLLocationManagerUseOnly)

- (void)registerManager:(TLLocationManager*)aManager {
	NSAssert(![[self activeManagers] containsObject:aManager],
			 @"Location manager should only be registered/unregistered once.");
	[self addActiveManagersObject:aManager];
}

- (void)unregisterManager:(TLLocationManager*)aManager {
	[self removeActiveManagersObject:aManager];
}

- (void)dismissHeadingCalibrationDisplay {
	for (id <TLLocationSource> source in [self locationSources]) {
		if ([source respondsToSelector:@selector(locationMasterNeedsHeadingCalibrationDisplayDismissed:)]) {
			[source locationMasterNeedsHeadingCalibrationDisplayDismissed:self];
		}
	}
}

@end

@implementation TLLocationMaster (TLLocationSourceUseOnly)

- (void)locationSource:(id <TLLocationSource>)aSource
		   hasLocation:(CLLocation*)aLocation
{
	(void)aSource;
	for (TLLocationManager* manager in [self activeManagers]) {
		[manager masterProvidesLocation:aLocation];
	}
}

- (void)locationSource:(id <TLLocationSource>)aSource
			hasHeading:(CLHeading*)aHeading
{
	(void)aSource;
	for (TLLocationManager* manager in [self activeManagers]) {
		[manager masterProvidesHeading:aHeading];
	}
}

- (void)locationSource:(id <TLLocationSource>)aSource
			  hasError:(NSError*)anError
{
	(void)aSource;
	for (TLLocationManager* manager in [self activeManagers]) {
		[manager masterProvidesError:anError];
	}
}

- (BOOL)locationSourceShouldDisplayHeadingCalibration:(id <TLLocationSource>)aSource {
	(void)aSource;
	BOOL shouldDisplay = NO;
	for (TLLocationManager* manager in [self activeManagers]) {
		shouldDisplay |= [manager masterWantsHeadingCalibrationPermission];
		if (shouldDisplay) break;
	}
	return shouldDisplay;
}

@end

