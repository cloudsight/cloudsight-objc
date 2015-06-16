//
//  CloudSightResponseTest.m
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

#import <XCTest/XCTest.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <CloudSight/CloudSight.h>


@interface CloudSightImageResponseTest : XCTestCase <CloudSightQueryDelegate>
{
    dispatch_semaphore_t sema;
    CloudSightQuery *query;
    
    NSString *delegatedMessage;
    NSArray *delegatedMessageObjects;
}
@end

@implementation CloudSightImageResponseTest

- (void)setUp
{
    [super setUp];
    
    [CloudSightConnection sharedInstance].consumerKey = @"test-key";
    [CloudSightConnection sharedInstance].consumerSecret = @"test-secret";
    
    sema = dispatch_semaphore_create(0);
    query = [[CloudSightQuery alloc] initWithImage:nil atLocation:CGPointZero withDelegate:nil atPlacemark:nil withDeviceId:nil];
}

- (void)tearDown
{
    [super tearDown];

    [OHHTTPStubs removeAllStubs];
}

- (void)testShouldHandleCompletedTag
{
    [self performRequestForFixture:@"response_completed.json" withDelegate:self];
    
    XCTAssertEqualObjects(delegatedMessage,
                          @"cloudSightQueryDidFinishIdentifying:",
                          @"Should call expected delegate method");
    XCTAssertEqualObjects([delegatedMessageObjects firstObject], query, @"Should call with current query");
    XCTAssertEqualObjects(query.title, @"red rose", @"Should update query object with new tag");
    XCTAssertNil(query.skipReason, @"Should not set skip reason");
}

- (void)testShouldHandleSkipReason
{
    [self performRequestForFixture:@"response_skipped.json" withDelegate:self];
    
    XCTAssertEqualObjects(delegatedMessage,
                          @"cloudSightQueryDidFinishIdentifying:",
                          @"Should call expected delegate method");
    XCTAssertEqualObjects([delegatedMessageObjects firstObject], query, @"Should call with current query");
    XCTAssertEqualObjects(query.skipReason, @"bogus", @"Should update query object with skip reason");
    XCTAssertNil(query.title, @"Should not set title");
}

- (void)testShouldHandleTimeout
{
    [self performRequestForFixture:@"response_timeout.json" withDelegate:self];
    
    XCTAssertEqualObjects(delegatedMessage, @"cloudSightQueryDidFail:withError:", @"Should call expected delegate method");
    XCTAssertEqualObjects([delegatedMessageObjects firstObject], query, @"Should call with current query");
    XCTAssertNotNil([delegatedMessageObjects objectAtIndex:1], @"Should set error");
    XCTAssertNil(query.title, @"Should not set title");
    XCTAssertNil(query.skipReason, @"Should not set skip reason");
}

#pragma mark Helpers

- (void)performRequestForFixture:(NSString *)name withDelegate:(id)delegate
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"api.cloudsightapi.com"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFile(name, self.class)
                                                statusCode:200 headers:@{ @"Content-Type" : @"text/json" }];
    }];
    
    CloudSightImageResponse *response = [[CloudSightImageResponse alloc] initWithToken:@"token" withDelegate:delegate forQuery:query];
    [response pollForResponse];

    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

#pragma mark CloudSightQueryDelegate

- (void)cloudSightQueryDidFinishIdentifying:(CloudSightQuery *)tpq
{
    delegatedMessage = NSStringFromSelector(_cmd);
    delegatedMessageObjects = @[tpq];
    
    dispatch_semaphore_signal(sema);
}

- (void)cloudSightQueryDidFail:(CloudSightQuery *)tpq withError:(NSError *)error
{
    delegatedMessage = NSStringFromSelector(_cmd);
    delegatedMessageObjects = @[tpq, error];
    
    dispatch_semaphore_signal(sema);
}

- (void)cloudSightQueryDidFinishUploading:(CloudSightQuery *)tpq
{
    delegatedMessage = NSStringFromSelector(_cmd);
    delegatedMessageObjects = @[tpq];
    
    dispatch_semaphore_signal(sema);
}

- (void)cloudSightQueryDidUpdateTag:(CloudSightQuery *)tpq
{
    delegatedMessage = NSStringFromSelector(_cmd);
    delegatedMessageObjects = @[tpq];
    
    dispatch_semaphore_signal(sema);
}

@end
