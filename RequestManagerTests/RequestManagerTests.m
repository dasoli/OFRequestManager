//
//  RequestManagerTests.m
//  RequestManagerTests
//
//  Created by Oliver Franke on 07.07.16.
//  Copyright © 2016 Oliver Franke. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OFRequestManager.h"

@interface RequestManagerTests : XCTestCase

@end

@implementation RequestManagerTests

- (void)setUp {
    [super setUp];
}

- (NSString*)downloadURL {
    return @"http://widewallpaper.info/wp-content/uploads/2016/01/Nature-autumn-4k-uhd-wallpaper.jpeg";
}

- (NSString*)downloadFilename {
    return @"Image1.jpeg";
}

- (void)tearDown {
    [super tearDown];
}

/**
 *  Tests that a progress object was correctly revealed
 */
- (void)testCreationOfTaskAndProgressForTask {
    NSURLSessionDownloadTask *task = [[OFRequestManager sharedManager] downloadFileFromURL:[self downloadURL]
                                                                                  withName:[self downloadFilename]
                                                                          inDirectoryNamed:nil
                                                                             progressBlock:nil
                                                                             remainingTime:nil
                                                                           completionBlock:nil
                                                                                   failure:nil
                                                                      enableBackgroundMode:nil];
    
    XCTAssertNotNil(task);
    if (task) {
        XCTAssertNotNil([[OFRequestManager sharedManager] progressForTask:task]);
    }
    [task cancel];
}

/**
 *  Tests that a creation of upload task was successful by correct params
 */
- (void)testCreationOfUploadTask{
    
}

/**
 *  Tests that a creation of download task was successful by correct params
 */
- (void)testCreationOfDownloadTask{
    NSURLSessionDownloadTask *task = [[OFRequestManager sharedManager] downloadFileFromURL:[self downloadURL]
                                                                                  withName:[self downloadFilename]
                                                                          inDirectoryNamed:nil
                                                                             progressBlock:nil
                                                                             remainingTime:nil
                                                                           completionBlock:nil
                                                                                   failure:nil
                                                                      enableBackgroundMode:nil];
    
    XCTAssertNotNil(task);
    [task cancel];
}

/**
 *  Tests that a creation of background download task was successful by correct params
 */
- (void)testCreationOfBackgroundDownloadTask{
    NSURLSessionDownloadTask *task = [[OFRequestManager sharedManager] downloadFileFromURL:[self downloadURL]
                                                                                  withName:[self downloadFilename]
                                                                          inDirectoryNamed:nil
                                                                             progressBlock:nil
                                                                             remainingTime:nil
                                                                           completionBlock:nil
                                                                                   failure:nil
                                                                      enableBackgroundMode:^(NSURLSession *session) {
                                                                      }];
    
    XCTAssertNotNil(task);
    [task cancel];
}

@end
