//
//  AppDelegate.m
//  iPhone sample
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

#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#import "TrailLocation.h"

@interface AppDelegate () <CLLocationManagerDelegate>
@property (nonatomic, retain) CLLocationManager* locator;
@end


@implementation AppDelegate

@synthesize window;
@synthesize locator;
@synthesize map;

- (void)dealloc {
    [window release];
	[locator stopUpdatingLocation];
	locator.delegate = nil;
	[locator release];
	[map release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(UIApplication*)application {
    [window makeKeyAndVisible];
	
	//[map setShowsUserLocation:YES];
	
	CLLocationManager* aLocator = [[TLLocationManager new] autorelease];
	aLocator.delegate = self;
	[aLocator startUpdatingLocation];
	[self setLocator:aLocator];
}

- (void)locationManager:(CLLocationManager*)aManager
	didUpdateToLocation:(CLLocation*)newLocation
		   fromLocation:(CLLocation*)oldLocation
{
	(void)aManager;
	//NSLog(@"%@ moved from %@ to %@", [aManager class], oldLocation, newLocation);
	printf("Moved to: %s\n", [[newLocation description] UTF8String]);
	
	[self.map removeAnnotations:[self.map annotations]];
	MKPlacemark* placemark = [[MKPlacemark alloc] initWithCoordinate:newLocation.coordinate
												   addressDictionary:nil];
	[self.map addAnnotation:placemark];
	[placemark release];
	[self.map setCenterCoordinate:newLocation.coordinate];
}

@end
