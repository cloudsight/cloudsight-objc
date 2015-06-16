//
//  CloudSightConnection.m
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

#import <BFOAuth/BFOAuth.h>
#import "CloudSightConnection.h"

@implementation CloudSightConnection

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedInstance];
}

+ (instancetype)sharedInstance
{
    static CloudSightConnection *sharedInstance = nil;
    if (!sharedInstance) {
        sharedInstance = [[super allocWithZone:nil] init];
    }
    
    return sharedInstance;
}

- (NSString *)authorizationHeaderWithUrl:(NSString *)url
{
    return [self authorizationHeaderWithUrl:url withParameters:nil];
}

- (NSString *)authorizationHeaderWithUrl:(NSString *)url withParameters:(NSDictionary *)parameters
{
    return [self authorizationHeaderWithUrl:url withParameters:parameters withMethod:kBFOAuthGETRequestMethod];
}

- (NSString *)authorizationHeaderWithUrl:(NSString *)url withParameters:(NSDictionary *)parameters withMethod:(NSString *)method
{
    NSAssert(self.consumerKey != nil, @"consumerKey property is set to nil, be sure to set credentials");
    NSAssert(self.consumerSecret != nil, @"consumerSecret property is set to nil, be sure to set credentials");
    
    BFOAuth *oauth = [[BFOAuth alloc] initWithConsumerKey:self.consumerKey
                                           consumerSecret:self.consumerSecret
                                              accessToken:nil
                                              tokenSecret:nil];

    [oauth setRequestURL:[NSURL URLWithString:url]];
    [oauth setRequestMethod:method];
    [oauth setRequestParameters:parameters];

    return [oauth authorizationHeader];
}

@end
