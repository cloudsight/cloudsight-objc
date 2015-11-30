//
//  CloudSightImageRequest.m
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
#import "CloudSightImageRequest.h"

NSString *const kTPImageRequestURL = @"https://api.cloudsightapi.com/image_requests";

@implementation CloudSightImageRequest

- (id)initWithImage:(NSData *)image atLocation:(CGPoint)location withDelegate:(id)delegate atPlacemark:(CLLocation *)placemark withDeviceId:(NSString *)deviceId
{
    self = [super init];
    if (self) {
        cancelled = NO;
        self.image = image;
        self.location = location;
        
        self.placemark = placemark;
        self.deviceId = deviceId;
        
        self.delegate = delegate;
    }
    
    return self;
}

- (NSDictionary *)buildRequestParameters
{
    NSString *localeIdentifier = [[NSLocale currentLocale] localeIdentifier];
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"@.*"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:nil];
    NSString *localeIdentifierWithoutCalendar = [regex stringByReplacingMatchesInString:localeIdentifier
                                                                                options:0
                                                                                  range:NSMakeRange(0, [localeIdentifier length])
                                                                           withTemplate:@""];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
        @"image_request[locale]" : localeIdentifierWithoutCalendar,
        @"image_request[language]" : [[NSLocale preferredLanguages] objectAtIndex:0],
        @"image_request[device_id]" : self.deviceId,
        @"image_request[latitude]" : [NSNumber numberWithDouble:self.placemark.coordinate.latitude],
        @"image_request[longitude]" : [NSNumber numberWithDouble:self.placemark.coordinate.longitude],
        @"image_request[altitude]" : [NSNumber numberWithDouble:self.placemark.altitude]
    }];
    
    if (self.location.x != 0.000000 || self.location.y != 0.000000) {
        NSString *focusX = [[NSString alloc]initWithFormat:@"%f", self.location.x];
        [params setValue:focusX forKey:@"focus[x]"];
        
        NSString *focusY = [[NSString alloc]initWithFormat:@"%f", self.location.y];
        [params setValue:focusY forKey:@"focus[y]"];
    }
    
    return params;
}

- (void)handleErrorForCode:(NSInteger)code withMessage:(NSString *)message
{
    NSError *error = [NSError errorWithDomain:[[NSBundle bundleForClass:self.class] bundleIdentifier]
                                         code:code
                                     userInfo:@{NSLocalizedDescriptionKey : message}];
    
    [[self delegate] cloudSightRequest:self didFailWithError:error];
}

- (void)startRequest
{
    NSURL *requestUrl = [NSURL URLWithString:kTPImageRequestURL];
    NSDictionary *params = [self buildRequestParameters];
 
    // Setup OAuth1 headers
    NSString *authHeader = [[CloudSightConnection sharedInstance] authorizationHeaderWithUrl:kTPImageRequestURL withParameters:params withMethod:kBFOAuthPOSTRequestMethod];
    
    // Build Request
    static NSString *imageRequestKey = @"image_request[image]";
    static NSString *filename = @"image.jpg";
    static NSString *boundary = @"tpRequestFormBoundary";
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
    [request setHTTPMethod:kBFOAuthPOSTRequestMethod];
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", obj] dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    // Image attachament part
    if (self.image) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", imageRequestKey, filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:self.image];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:[NSString stringWithFormat:@"%u", (unsigned int)[body length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:body];
    
    // Setup connection session
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    [sessionConfiguration setTimeoutIntervalForRequest:30];
    [sessionConfiguration setHTTPAdditionalHeaders:@{ @"Accept" : @"application/json",
                                                      @"Authorization" : authHeader }];
    
    session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (cancelled)
            return;
        
        if (error || data == nil) {
            [self handleErrorForCode:kTPImageRequestInvalidError withMessage:@"Trouble sending image"];
            return;
        }
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if ([(NSHTTPURLResponse *)response statusCode] != 200 || dict == nil) {
            [self handleErrorForCode:kTPImageRequestInvalidError withMessage:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
            return;
        } else if (dict != nil && [dict objectForKey:@"error"] != nil) {
            [self handleErrorForCode:kTPImageRequestTroubleError withMessage:[dict objectForKey:@"error"]];
            return;
        }
        
        self.token = [dict objectForKey:@"token"];
        self.remoteUrl = [dict objectForKey:@"url"];
        
        [[self delegate] cloudSightRequest:self didReceiveToken:self.token withRemoteURL:self.remoteUrl];
    }];
    [task resume];
    [session finishTasksAndInvalidate];
}

- (void)cancel
{
    cancelled = YES;
    [session invalidateAndCancel];
}

- (void)dealloc
{
    [self cancel];
}

#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    float progress = (float)totalBytesSent / (float)totalBytesExpectedToSend;
    [[self uploadProgressDelegate] cloudSightRequest:self setProgress:progress];
}

@end
