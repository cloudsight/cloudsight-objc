//
//  CloudSightDelete.m
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

#import <RequestUtils/RequestUtils.h>
#import <BFOAuth/BFOAuth.h>
#import "CloudSightConnection.h"
#import "CloudSightDelete.h"

NSString *const kTPImageDeleteURL = @"https://api.cloudsightapi.com/image_requests/%@";

@implementation CloudSightDelete

- (id)initWithToken:(NSString *)token
{
    self = [super init];
    if(self) {
        self.token = token;
    }
    
    return self;
}

- (void)startRequest
{
    // Start next request to poll for image
    NSString *deleteUrl = [NSString stringWithFormat:kTPImageDeleteURL, self.token];
    NSString *authHeader = [[CloudSightConnection sharedInstance] authorizationHeaderWithUrl:deleteUrl withParameters:nil withMethod:kBFOAuthDELETERequestMethod];
    
    // Setup connection session
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [sessionConfiguration setTimeoutIntervalForRequest:30];
    [sessionConfiguration setHTTPAdditionalHeaders:@{ @"Accept" : @"application/json",
                                                      @"Authorization" : authHeader }];
    
    session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:nil delegateQueue:nil];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:deleteUrl]];
    [request setHTTPMethod:kBFOAuthDELETERequestMethod];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // Ignore
    }];

    [task resume];
    [session finishTasksAndInvalidate];
}

- (void)cancel
{
    [session invalidateAndCancel];
}

- (void)dealloc
{
    [self cancel];
}

@end
