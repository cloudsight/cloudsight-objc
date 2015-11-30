//
//  CloudSightImageResponse.m
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
#import "CloudSightImageResponse.h"
#import "CloudSightQuery.h"
#import "CloudSightConnection.h"

NSString *const kTPImageResponseURL = @"https://api.cloudsightapi.com/image_responses/%@";

@implementation CloudSightImageResponse

- (id)initWithToken:(NSString *)token withDelegate:(id <CloudSightQueryDelegate>)delegate forQuery:(CloudSightQuery *)_query
{
    self = [super init];
    if(self) {
        self.token = token;
        self.delegate = delegate;
        cancelled = NO;
        query = _query;
    }
    
    return self;
}

- (void)handleErrorForCode:(NSInteger)code withMessage:(NSString *)message
{
    NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:self.class] bundleIdentifier]
                                         code:code
                                     userInfo:@{NSLocalizedDescriptionKey : message}];
    
    if ([[self delegate] respondsToSelector:@selector(cloudSightQueryDidFail:withError:)]) {
        [[self delegate] cloudSightQueryDidFail:query withError:error];
    }
}

- (void)pollForResponse
{
    if (cancelled)
        return;

    // Start next request to poll for image
    NSString *responseUrl = [NSString stringWithFormat:kTPImageResponseURL, self.token];
    NSDictionary *params = @{ };

    NSString *authHeader = [[CloudSightConnection sharedInstance] authorizationHeaderWithUrl:responseUrl
                                                                              withParameters:params];

    // Setup connection session
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [sessionConfiguration setTimeoutIntervalForRequest:30];
    [sessionConfiguration setHTTPAdditionalHeaders:@{ @"Accept" : @"application/json",
                                                      @"Authorization" : authHeader }];
    
    session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:nil delegateQueue:nil];
    
    NSURL *responseUrlWithParameters = [NSURL URLWithString:responseUrl];
    responseUrlWithParameters = [responseUrlWithParameters URLWithQuery:[NSString URLQueryWithParameters:params]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:responseUrlWithParameters];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (cancelled)
            return;

        if (error || data == nil) {
            [self handleErrorForCode:kTPImageResponseTroubleError withMessage:error.localizedDescription];
            return;
        }
        
        // Sanity check - sometimes server fails in the response (500 error, etc)
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if ([(NSHTTPURLResponse *)response statusCode] != 200 || dict == nil) {
            [self handleErrorForCode:kTPImageResponseTroubleError withMessage:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
            return;
        }
        
        // Handle the CloudSight image response
        NSString *taggedImageStatus = [dict objectForKey:@"status"];
        if ([taggedImageStatus isEqualToString:@"not completed"]) {
            [self restart];
        } else if ([taggedImageStatus isEqualToString:@"skipped"]) {
            NSString *taggedImageString = [dict objectForKey:@"reason"];
            if ([taggedImageString isKindOfClass:[NSNull class]])
                taggedImageString = @"";
            
            [query setSkipReason:taggedImageString];

            if ([[self delegate] respondsToSelector:@selector(cloudSightQueryDidFinishIdentifying:)]) {
                [[self delegate] cloudSightQueryDidFinishIdentifying:query];
            }
        } else if ([taggedImageStatus isEqualToString:@"in progress"] || [taggedImageStatus isEqualToString:@"completed"]) {
            NSString *taggedImageString = [dict objectForKey:@"name"];
            if ([taggedImageString isKindOfClass:[NSNull class]])
                taggedImageString = @"";
            
            [query setTitle:taggedImageString];
            
            if ([taggedImageStatus isEqualToString:@"in progress"]) {
                [self restart];
                if ([self.delegate respondsToSelector:@selector(cloudSightQueryDidUpdateTag:)]) {
                    [[self delegate] cloudSightQueryDidUpdateTag:query];
                }
            } else {
                if ([[self delegate] respondsToSelector:@selector(cloudSightQueryDidFinishIdentifying:)]) {
                    [[self delegate] cloudSightQueryDidFinishIdentifying:query];
                }
            }
        } else if ([taggedImageStatus isEqualToString:@"timeout"]) {
            [self handleErrorForCode:kTPImageResponseTimeoutError withMessage:@"Timeout, please try again"];
        }
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}

- (void)cancel
{
    cancelled = YES;

    [currentTimer invalidate];
    currentTimer = nil;
    
    [session invalidateAndCancel];
}

- (void)restart
{
    if (cancelled)
        return;

    // Callback happens from another queue during response
    dispatch_async(dispatch_get_main_queue(), ^{
        // Restart the request loop after a 1s delay
        currentTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                        target:self
                                                      selector:@selector(pollForResponse)
                                                      userInfo:nil
                                                       repeats:NO];
    });
}

- (void)dealloc
{
    [self cancel];
}

@end
