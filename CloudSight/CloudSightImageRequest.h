//
//  CloudSightImageRequest.h
//  CloudSight API
//  Copyright (c) 2012-2015 CamFind Inc. (http://cloudsightapi.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "CloudSightImageRequestDelegate.h"
#import "CloudSightUploadProgressDelegate.h"

static const int kTPImageRequestInvalidError = 9010;
static const int kTPImageRequestTroubleError = 9011;

@interface CloudSightImageRequest : NSObject <NSURLSessionDataDelegate>
{
    NSURLSession *session;
    BOOL cancelled;
}

@property (nonatomic, weak) id <CloudSightImageRequestDelegate> delegate;
@property (nonatomic, weak) id <CloudSightUploadProgressDelegate> uploadProgressDelegate;
@property (nonatomic, retain) NSString *token;
@property (nonatomic, retain) NSString *remoteUrl;
@property (nonatomic, retain) NSData *image;
@property (nonatomic, assign) CGPoint location;

@property (nonatomic, retain) CLLocation *placemark;
@property (nonatomic, retain) NSString *deviceId;

- (id)initWithImage:(NSData *)image atLocation:(CGPoint)location withDelegate:(id)delegate atPlacemark:(CLLocation *)placemark withDeviceId:(NSString *)deviceId;
- (void)startRequest;
- (void)cancel;

@end
