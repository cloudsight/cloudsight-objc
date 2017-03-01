//
//  ViewController.m
//  CloudSightExample
//
//  Created by Bradford Folkens on 3/2/17.
//  Copyright © 2017 CloudSight Inc. All rights reserved.
//

#import <CloudSight/CloudSight.h>
#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, retain) CloudSightQuery *query;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [CloudSightConnection sharedInstance].consumerKey = @"your-key";
    [CloudSightConnection sharedInstance].consumerSecret = @"your-secret";
}

- (void)viewDidAppear:(BOOL)animated {
    [self searchWithImage:[UIImage imageNamed:@"CS-Full-Color"]];
}

- (void)searchWithImage:(UIImage *)image {
    NSString *deviceIdentifier = nil;  // This can be any unique identifier per device, and is optional - we like to use UUIDs
    CLLocation *location = nil; // you can use the CLLocationManager to determine the user's location
    
    // We recommend sending a JPG image no larger than 1024x1024 and with a 0.7-0.8 compression quality,
    // you can reduce this on a Cellular network to 800x800 at quality = 0.4
    NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
    
    // Create the actual query object
    self.query = [[CloudSightQuery alloc] initWithImage:imageData
                                             atLocation:CGPointZero
                                           withDelegate:self
                                            atPlacemark:location
                                           withDeviceId:deviceIdentifier];
    
    // Start the query process
    [self.query start];
}

#pragma mark CloudSightQueryDelegate

- (void)cloudSightQueryDidFinishIdentifying:(CloudSightQuery *)query {
    if (query.skipReason != nil) {
        NSLog(@"Skipped: %@", query.skipReason);
    } else {
        NSLog(@"Identified: %@", query.title);
    }
}

- (void)cloudSightQueryDidFail:(CloudSightQuery *)query withError:(NSError *)error {
    NSLog(@"Error: %@", error);
}

@end
