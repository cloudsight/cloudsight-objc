//
//  CloudSightQuery.m
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

#import "CloudSightQuery.h"
#import "CloudSightImageRequest.h"
#import "CloudSightImageResponse.h"
#import "CloudSightDelete.h"

@implementation CloudSightQuery

- (id)initWithImage:(NSData *)image atLocation:(CGPoint)location withDelegate:(id)delegate atPlacemark:(CLLocation *)placemark withDeviceId:(NSString *)deviceId
{
    self = [super init];
    if (self) {
        self.request = [[CloudSightImageRequest alloc] initWithImage:image
                                                          atLocation:location
                                                        withDelegate:self
                                                         atPlacemark:placemark
                                                        withDeviceId:deviceId];
        
        self.queryDelegate = delegate;
    }
    
    return self;
}

- (void)start
{
    [self.request startRequest];
}

- (void)cloudSightRequest:(CloudSightImageRequest *)sender didReceiveToken:(NSString *)token withRemoteURL:(NSString *)url
{
    self.response = [[CloudSightImageResponse alloc] initWithToken:token withDelegate:self.queryDelegate forQuery:self];
    [self.response pollForResponse];
    
    self.token = token;
    self.remoteUrl = url;
    
    if ([self.queryDelegate respondsToSelector:@selector(cloudSightQueryDidFinishUploading:)]) {
        [self.queryDelegate cloudSightQueryDidFinishUploading:self];
    }
}

- (void)cloudSightRequest:(CloudSightImageRequest *)sender didFailWithError:(NSError *)error
{
    [self.queryDelegate cloudSightQueryDidFail:self withError:error];
}

- (void)cancelAndDestroy
{
    [self.request cancel];
    [self.response cancel];
    
    self.destroy = [[CloudSightDelete alloc] initWithToken:self.token];
    [self.destroy startRequest];
}

- (void)stop
{
    [self cancelAndDestroy];
    
    NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:self.class] bundleIdentifier]
                                         code:kTPQueryCancelledError
                                     userInfo:@{NSLocalizedDescriptionKey : @"User cancelled request"}];

    if ([self.queryDelegate respondsToSelector:@selector(cloudSightQueryDidFail:withError:)]) {
        [self.queryDelegate cloudSightQueryDidFail:self withError:error];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"token: '%@', remoteUrl: '%@', title:'%@', skipReason:'%@'", self.token, self.remoteUrl, self.title, self.skipReason];
}

- (NSString *)name
{
    if (self.title == NULL || [self.title length] == 0)
        return self.skipReason;
    
    return self.title;
}

- (void)dealloc
{
    [self.request setDelegate:nil];
}

@end
