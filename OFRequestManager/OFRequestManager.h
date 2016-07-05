//
//  OFRequestManager.h
//  OFRequestManager
//
//  Created by Oliver Franke on 05.07.16.
//  Copyright © 2016 Oliver Franke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "AFNetworkActivityIndicatorManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface OFRequestManager : NSObject

// P
//--------------------------------------------------------------------------------
@property (nonatomic, strong) AFHTTPSessionManager *httpSessionManager;
@property (nonatomic, strong) AFURLSessionManager  *urlSessionManager;
@property (nonatomic, strong) AFURLSessionManager  *backgroundSessionManager;
/**
 The URL used to construct requests from relative paths in methods like `requestWithMethod:URLString:parameters:`, and the `GET` / `POST` / et al. convenience methods.
 */
@property (nonatomic, copy, nullable) NSURL *baseURL;
/**
 Use this property if you want to provide more than standard contenttypes acceptance.
 */
@property (nonatomic, copy, nullable) NSSet *acceptedContentTypes;
/**
 Use this property to provide extra HTTP Headers, they will be added as provided.
 */
@property (nonatomic, copy, nullable) NSDictionary *extraHTTPHeaderFields;
/**
 Override this for custom values, default value is 60 seconds
 */
@property (nonatomic, assign) NSTimeInterval timeout;
/**
 Set enable if you want to show statusbar activity indicator automatically
 */
@property (nonatomic, assign) BOOL showNetworkIndicator;
/**
 Parameters which will be used in every request as a kind of base parameters.
 */
@property (nonatomic, copy, nullable) NSDictionary *additionalParamsToAddContiniously;
//--------------------------------------------------------------------------------

// M
//--------------------------------------------------------------------------------
+ (instancetype)sharedManager;

/**
 Initializes an `AFHTTPSessionManager` object with the specified base URL.
 
 @param url The base URL for the HTTP client.
 
 @return The newly-initialized HTTP client
 */
- (instancetype)initWithBaseURL:(nullable NSURL *)url;

/**
 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param downloadProgress A block object to be executed when the download progress is updated. Note this block is called on the session queue, not the main queue.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the data task, and the response object created by the client response serializer.
 @param failure A block object to be executed when the task finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a two arguments: the data task and the error describing the network or parsing error that occurred.
 */
- (nullable NSURLSessionDataTask *)GET:(NSString *)URLString
                            parameters:(nullable id)parameters
                              progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
                               success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                               failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `POST` request.
 
 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param uploadProgress A block object to be executed when the upload progress is updated. Note this block is called on the session queue, not the main queue.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the data task, and the response object created by the client response serializer.
 @param failure A block object to be executed when the task finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a two arguments: the data task and the error describing the network or parsing error that occurred.
 */
- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable id)parameters
                               progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                                success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
