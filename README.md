# OFRequestManager
A friendly to use toplevel implemtation of AFNetwork 3.x with some specials.

This manager will help you to interact as fast as possible with several types of Http sources.

* simple get requests
* get requests with parameters
* post requests also with base url functionality
* put
* delete

* upload files
* upload files in background
* download files
* download files in background

Later you could easily upload & download files, with one function and a complete store system. (ongoing)

## Compatibility

The library is suitable for applications running on iOS 7 and above.


## Installation

```ruby
pod 'OFRequestManager', '<version>'
```

For more information about CocoaPods and the `Podfile`, please refer to the [official documentation](http://guides.cocoapods.org/).

## Demo project

To test what the library is capable of - a demoproject is included and strings could be replaced for testing and easy copy.

## Usage
Simple get with automatically adding of params to url:
```objc
[[OFRequestManager sharedManager] Get:@"Url"
                           parameters:@{ param1 : value }
                             progress:nil
                              success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
                              {
                              }
                              failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
                              {
                              }];
```


If you want to do use post or other base url related operations:

```objc
[OFRequestManager sharedManager].baseURL = self.postBaseUrl;
```

If you have params that will return with every request, the mananger will add these values with every Rest request:

```objc
  [OFRequestManager sharedManager].additionalParamsToAddContiniously = @{ param1 : value}
```

Example Post:
```objc
[[OFRequestManager sharedManager] POST:@"Hook1"
                           parameters:@{ param1 : value }
                             progress:nil
                              success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
                              {
                              }
                              failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
                              {
                              }];
```

Example Post:
```objc
[[OFRequestManager sharedManager] downloadFileFromURL:@"an url"
                                             withName:@"a name for a file"
                                     inDirectoryNamed:nil
                                        progressBlock:nil
                                          statusBlock:^(NSTimeInterval seconds,
                                                        CGFloat percentDone,
                                                        CGFloat byteRemaining,
                                                        CGFloat bytesWritten) {
                                              dispatch_async(dispatch_get_main_queue(), ^()
                                                             {
                                                                 //update ui?
                                                             });
                                          }
                                      completionBlock:^(kRequestManagerSessionStatus status,
                                                        NSURL * _Nonnull directory,
                                                        NSString * _Nonnull fileName,
                                                        NSURLResponse * _Nonnull response) {

                                          if (status == kRequestManagerSessionStatusFileCompleted) {

                                          } else if (status == kRequestManagerSessionStatusAlreadyDownloaded) {

                                          }
                                      }
                                         failureBlock:^(NSURLResponse * _Nonnull response,
                                                        NSError * _Nonnull error,
                                                        kRequestManagerSessionStatus status,
                                                        NSURL * _Nonnull directory,
                                                        NSString * _Nonnull fileName) {
                                             if (error) {
                                                 //handle
                                             }
                                         }
                            enableBackgroundModeBlock:nil];
```
If you want to enable Background downloading, put in a backgroundBlock. (actually this is bugging state)

## License

See the [LICENSE](LICENSE) file for more information.
