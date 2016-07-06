//
//  ViewController.m
//  OFRequestManagerDemo
//
//  Created by Oliver Franke on 05.07.16.
//  Copyright © 2016 Oliver Franke. All rights reserved.
//

#import "ViewController.h"
#import "OFRequestManager.h"


@interface ViewController ()
@property (strong, nonatomic) UIButton *testGetRequestBt;
@property (strong, nonatomic) UIButton *testPostRequestBt;
@property (strong, nonatomic) UIButton *testDownloadRequestBt;
@property (strong, nonatomic) UILabel *remainingTimeLabel;
@property (strong, nonatomic) UITextView *resultTV;

@property (copy, nonatomic) NSString *getUrl;
@property (copy, nonatomic) NSURL *postBaseUrl;
@property (copy, nonatomic) NSString *postHook1;
@property (copy, nonatomic) NSDictionary *getParams;
@property (copy, nonatomic) NSDictionary *postParams;
@property (copy, nonatomic) NSDictionary *postGeneralParams;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupPost];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)setupPost {
    [OFRequestManager sharedManager].baseURL = self.postBaseUrl;
    [OFRequestManager sharedManager].additionalParamsToAddContiniously = self.postGeneralParams;
}

- (void)setupUI {
    self.view.frame = [[UIScreen mainScreen] bounds];
    self.view.backgroundColor = [UIColor whiteColor];
    self.testGetRequestBt = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.testGetRequestBt setTitle:@"Test Get" forState:UIControlStateNormal];
    [self.testGetRequestBt addTarget:self action:@selector(testGetButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.testGetRequestBt setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [self.testGetRequestBt sizeToFit];
    self.testGetRequestBt.frame = CGRectMake(0, 30, self.testGetRequestBt.frame.size.width, self.testGetRequestBt.frame.size.height);
    [self.view addSubview:self.testGetRequestBt];
    
    self.testPostRequestBt = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.testPostRequestBt setTitle:@"Test Post" forState:UIControlStateNormal];
    [self.testPostRequestBt addTarget:self action:@selector(testPostButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.testPostRequestBt setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.testPostRequestBt sizeToFit];
    self.testPostRequestBt.frame = CGRectMake(75, 30, self.testPostRequestBt.frame.size.width, self.testPostRequestBt.frame.size.height);
    [self.view addSubview:self.testPostRequestBt];
    
    self.testDownloadRequestBt = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.testDownloadRequestBt setTitle:@"Test Downloadfile" forState:UIControlStateNormal];
    [self.testDownloadRequestBt addTarget:self action:@selector(testDownloadFileButtonDidPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.testDownloadRequestBt setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.testDownloadRequestBt sizeToFit];
    self.testDownloadRequestBt.frame = CGRectMake(175, 30, self.testDownloadRequestBt.frame.size.width, self.testDownloadRequestBt.frame.size.height);
    [self.view addSubview:self.testDownloadRequestBt];
    
    self.remainingTimeLabel = [UILabel new];
    self.remainingTimeLabel.text = @"Here you will see the remaining time";
    [self.remainingTimeLabel sizeToFit];
    self.remainingTimeLabel.frame = CGRectMake(0, 80, self.remainingTimeLabel.frame.size.width, self.remainingTimeLabel.frame.size.height);
    [self.view addSubview:self.remainingTimeLabel];
    
    self.resultTV = [[UITextView alloc] initWithFrame:CGRectMake(0, 150, self.view.frame.size.width, self.view.frame.size.height - 150)];
    [self.view addSubview:self.resultTV];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - URLS

- (NSString*)getUrl {
    return @"http://www.srfcdn.ch/mobile/srf-newsappconf/meteo/apps.json";
}

- (NSDictionary*)getParams {
    return @{
             @"TestParam1" : @"Value1",
             @"TestParam2" : @"Value2"
             };
}

- (NSURL*)postBaseUrl {
    return [NSURL URLWithString:@"http://dev.crowdradio.de:3000/"];
}

- (NSString*)postHook1 {
    return @"/app/init/";
}

- (NSDictionary*)postParams {
    return @{
             @"api_key" : @"43a0ec24-da00-4988-b05d-d7dc80099a63",
             @"brandKey" : @"c255cc77-51c2-450e-9973-1cd35ee7bec5"
             };
}

- (NSDictionary*)postGeneralParams {
    return @{
             @"device" : @"Unknown device in the iPhone/iPod family",
             @"locale" : @"en_US",
             @"screen" : @{
                     @"height" : @1136,
                     @"width" : @640
                     },
             @"system_os" : @"iOS_9.3",
             @"app_version" : @"3.3.0.2",
             };
}

- (NSString*)downloadURL {
//    return @"https://gilly.berlin/wp-content/uploads/2008/11/cat-content-4.jpg";
    return @"http://widewallpaper.info/wp-content/uploads/2016/01/Nature-autumn-4k-uhd-wallpaper.jpeg";
    return @"http://dashousetear.de/images/eigene/othermedia/DasHouseTear_-_Microbeat.mp3";
}

- (NSString*)downloadFilename {
    return @"Image1.jpeg";
}

#pragma mark - Buttons

- (void)testGetButtonDidPress:(id)sender {
    [[OFRequestManager sharedManager] GET:self.getUrl
                               parameters:self.getParams
                                 progress:nil
                                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                      self.resultTV.text = [NSString stringWithFormat:@"%@",responseObject];
                                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                      self.resultTV.text = [NSString stringWithFormat:@"%@\n\non: %@",error.localizedDescription,
                                                            task.originalRequest.URL];
                                  }];
}

- (void)testPostButtonDidPress:(id)sender {
    [[OFRequestManager sharedManager] POST:self.postHook1
                               parameters:self.postParams
                                 progress:nil
                                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                      self.resultTV.text = [NSString stringWithFormat:@"%@",responseObject];
                                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                      self.resultTV.text = [NSString stringWithFormat:@"%@\n\non: %@",error.localizedDescription,
                                                            task.originalRequest.URL];
                                  }];
}

- (void)testDownloadFileButtonDidPress:(id)sender {
    kRequestManagerSessionStatus status = [[OFRequestManager sharedManager] downloadFileFromURL:[self downloadURL]
                                                                                       withName:[self downloadFilename]
                                                                               inDirectoryNamed:nil
                                                                                  progressBlock:^(NSProgress * _Nonnull progress) {
//                                                                                      NSLog(@"progress %@",progress);
                                                                                  }
                                                                                  remainingTime:nil
                                                                                completionBlock:^(kRequestManagerSessionStatus status, NSURL * _Nonnull directory, NSString * _Nonnull fileName) {
                                                                                      if (status == kRequestManagerSessionStatusFileCompleted) {
                                                                                          self.resultTV.text = [NSString stringWithFormat:@"Downloaded file with name:%@\nTo path:%@\n",fileName,directory];
                                                                                      } else if (status == kRequestManagerSessionStatusAlreadyDownloaded) {
                                                                                          self.resultTV.text = [NSString stringWithFormat:@"Downloaded file exchanged with name:%@\nTo path:%@\n",fileName,directory];
                                                                                      }
                                                                                  }
                                           
                                           
                                                                                        failure:^(NSURLResponse * _Nonnull response, NSError * _Nonnull error, kRequestManagerSessionStatus status, NSURL * _Nonnull directory, NSString * _Nonnull fileName) {
                                                                                      if (error) {
                                                                                          self.resultTV.text = [NSString stringWithFormat:@"Failed to download with result %@",response];
                                                                                      }
                                                                                  }
                                           
                                           
                                                                           enableBackgroundMode:^(NSURLSession *session){
                                                                               NSLog(@"task finished in background");
                                                                           }];
    
    NSLog(@"session state was %u",status);
}
@end
