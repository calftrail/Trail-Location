//
//  AppDelegate+GPSD.h
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



/*
 --- HOW TO USE WITH GPSD ---
 
 Initial setup
 1. Download gpsd from http://gpsd.berlios.de/ and compile gpsd
 2. Replace the missing header in this project with the one from gpsd
 3. Rename the libgps.a static library to something that won't trigger Xcode's .dylib fetish,
 and replace this project's missing static library.
 4. Check the box so that this header's corresponding implementation file is built as part of the target
 
 Then
 1. GPSD must be running on its default port before you start this app
 Example: 'gpsd -b -N /dev/cu.BT-GPS018EEB-SerialPort' (will allow Ctrl-C to kill daemon)
 2. Start this app. It will send info from GPSD to any Trail Location listeners.
 */


#import <Cocoa/Cocoa.h>

@interface AppDelegate (UseGPSD)
- (void)gpsd_keepSending;
- (void)gpsd_cleanup;
@end
