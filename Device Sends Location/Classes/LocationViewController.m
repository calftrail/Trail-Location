//
//  LocationViewController.m
//  Device Sends Location
//
//  Created by Nathan Vander Wilt on 8/3/09.
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

#import "LocationViewController.h"

#import <CoreLocation/CoreLocation.h>
#import "AppDelegate.h"
#import "TLLocationSender.h"


static NSString* LVCObservingContext = @"LocationViewController observation context";


@interface LocationViewController ()
@property (nonatomic, readonly) MKMapView* mapView;
@end


@implementation LocationViewController

- (MKMapView*)mapView {
	return (MKMapView*)[self view];
}

- (void)viewWillAppear:(BOOL)animated {
	[self addObserver:self
		   forKeyPath:@"view.userLocation.location"
			  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial)
			  context:&LVCObservingContext];
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self removeObserver:self forKeyPath:@"view.userLocation.location"];
	[super viewWillDisappear:animated];
}

- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
    if (context == &LVCObservingContext) {
		//NSLog(@"Observed %@ - %@", keyPath, change);
		if ([keyPath isEqualToString:@"view.userLocation.location"]) {
			CLLocation* newLocation = [change objectForKey:NSKeyValueChangeNewKey];
			if ((id)newLocation != [NSNull null]) {
				id appDelegate = [[UIApplication sharedApplication] delegate];
				[[appDelegate locationSender] sendLocation:newLocation];
				[(MKMapView*)[self view] setCenterCoordinate:newLocation.coordinate animated:YES];
			}
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)mapView:(MKMapView*)aMapView regionDidChangeAnimated:(BOOL)animated {
	(void)aMapView;
	//NSLog(@"Map view changed %s animation", (animated ? "WITH" : "without"));
	if (!animated) {
		CLLocation* currentLocation = [[[self mapView] userLocation] location];
		[[self mapView] setCenterCoordinate:currentLocation.coordinate animated:YES];
	}
}

@end
