CloudSight API library for Objective-C.  Extracted from CamFind-iOS.

## Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like CloudSight in your projects.

### Podfile

```ruby
pod "CloudSight", "~> 1.0"
```

## Usage

### Configure the instance

The CloudSight library uses the OAuth1 authentication method to the API.  Make sure your key and secret are set.

```objective-c
[CloudSightConnection sharedInstance].consumerKey = @"your-key";
[CloudSightConnection sharedInstance].consumerSecret = @"your-secret";
```

### Using the query object

The easiest way to use the API is to use a Query object to handle the request/response workflow work for you.

```objective-c
- (void)searchWithImage:(UIImage *)image {
    NSString *deviceIdentifier = nil;  // This can be any unique identifier per device, and is optional - we like to use UUIDs
    CLLocation *location = nil; // you can use the CLLocationManager to determine the user's location

    // We recommend sending a JPG image no larger than 1024x1024 and with a 0.7-0.8 compression quality,
    // you can reduce this on a Cellular network to 800x800 at quality = 0.4
    UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                                                        bounds:CGSizeMake(1024, 1024)
                                          interpolationQuality:kCGInterpolationDefault];
    NSData *imageData = [resizedImage imageAsJPEGWithQuality:0.7];

    // Create the actual query object
    CloudSightQuery *query = [[CloudSightQuery alloc] initWithImage:imageData
                                                         atLocation:focalPoint
                                                       withDelegate:self
                                                        atPlacemark:location
                                                       withDeviceId:deviceIdentifier];

    // Start the query process
    [query start];
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
```

## License

CloudSight is released under the MIT license.
