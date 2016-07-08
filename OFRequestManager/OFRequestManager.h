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

enum kRequestManagerSessionStatus
{
    kRequestManagerSessionStatusIdle                        = 0,
    kRequestManagerSessionStatusStarted                     = 1,
    kRequestManagerSessionStatusAborted                     = 2,
    kRequestManagerSessionStatusErrored                     = 3,
    kRequestManagerSessionStatusAlreadyDownloaded           = 4,
    kRequestManagerSessionStatusCurrentlyDownloading        = 5,
    kRequestManagerSessionStatusFileExists                  = 6,
    kRequestManagerSessionStatusFileCompletedWithCopyError  = 7,
    kRequestManagerSessionStatusFileCompleted               = 8
} typedef kRequestManagerSessionStatus;

NS_ASSUME_NONNULL_BEGIN

@interface OFRequestManager : NSObject

extern NSString * const DOWNLOAD_STORE_USERDEFAULTS_NAME;

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
/**
 Parameters which will be used in every request as a kind of base parameters.
 */
@property (nonatomic, readonly, nullable) NSArray <NSURLSessionUploadTask *> *uploadTasks;
/**
 Parameters which will be used in every request as a kind of base parameters.
 */
@property (nonatomic, readonly, nullable) NSArray <NSURLSessionDownloadTask *> *downloadTasks;
/**
 Parameters which will be used in every request as a kind of base parameters.
 */
@property (nonatomic, readonly, nullable) NSArray <NSURLSessionDataTask *> *dataTasks;
///**
// If you want to get informed after a long term background download is done.
// */
//@property (nonatomic, strong, nullable) void(^backgroundDownloadTransferCompletionHandler)();
/**
 All finished tasks & objects
 */
@property (nonatomic, readonly) NSMutableDictionary *downloadStore;

//--------------------------------------------------------------------------------

// M
//--------------------------------------------------------------------------------
+ (instancetype)sharedManager;

/**
 *  Invalidate & stops all currently running tasks by all active managers
 *
 *  @param stopPending true if you want to stop, currently enqueued tasks
 */
- (void)invalidateAllRunningTasksShouldCancelPending:(BOOL)stopPending;

/**
 Initializes an `AFHTTPSessionManager` object with the specified base URL.
 
 @param url The base URL for the HTTP client.
 
 @return The newly-initialized HTTP client
 */
- (instancetype)initWithBaseURL:(nullable NSURL *)url;


/**
 *  Searches and returns a NSProgress object for a given task.
 *
 *  @param task Any kind of Tasks are handled.
 *
 *  @return if found, NSProgress object of the task.
 */
- (nullable NSProgress *)progressForTask:(NSURLSessionTask *)task;


#pragma mark - Data Tasks
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
 Creates and runs an `NSURLSessionDataTask` with a `HEAD` request.
 
 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes a single arguments: the data task.
 @param failure A block object to be executed when the task finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a two arguments: the data task and the error describing the network or parsing error that occurred.
 
 */
- (nullable NSURLSessionDataTask *)HEAD:(NSString *)URLString
                             parameters:(nullable id)parameters
                                success:(nullable void (^)(NSURLSessionDataTask *task))success
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

/**
 Creates and runs an `NSURLSessionDataTask` with a multipart `POST` request.
 
 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param block A block that takes a single argument and appends data to the HTTP body. The block argument is an object adopting the `AFMultipartFormData` protocol.
 @param uploadProgress A block object to be executed when the upload progress is updated. Note this block is called on the session queue, not the main queue.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the data task, and the response object created by the client response serializer.
 @param failure A block object to be executed when the task finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a two arguments: the data task and the error describing the network or parsing error that occurred.
 
 */
- (nullable NSURLSessionDataTask *)POST:(NSString *)URLString
                             parameters:(nullable id)parameters
              constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                               progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
                                success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;


/**
 Creates and runs an `NSURLSessionDataTask` with a `PUT` request.
 
 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the data task, and the response object created by the client response serializer.
 @param failure A block object to be executed when the task finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a two arguments: the data task and the error describing the network or parsing error that occurred.
 */
- (nullable NSURLSessionDataTask *)PUT:(NSString *)URLString
                            parameters:(nullable id)parameters
                               success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                               failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `PATCH` request.
 
 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the data task, and the response object created by the client response serializer.
 @param failure A block object to be executed when the task finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a two arguments: the data task and the error describing the network or parsing error that occurred.
 
 */
- (nullable NSURLSessionDataTask *)PATCH:(NSString *)URLString
                              parameters:(nullable id)parameters
                                 success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                 failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `DELETE` request.
 
 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the data task, and the response object created by the client response serializer.
 @param failure A block object to be executed when the task finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a two arguments: the data task and the error describing the network or parsing error that occurred.
 
 */
- (nullable NSURLSessionDataTask *)DELETE:(NSString *)URLString
                               parameters:(nullable id)parameters
                                  success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                                  failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

#pragma mark - Download Task
/**
 *  Creates a download task and a download item for later use
 *
 *  @param URLString The URL string used to create the request URL.
 *  @param fileName provide a filename, if nothing is provided, the session generates an identifier
 *  @param directory provide a directory, if nothing is provided, the standard downloadmanager folder will be choosen
 *  @param progressBlock provide a progress block if you want to stay informed about the process
 *  @param statusBlock provide a progress block if you want to stay informed about the remaining time of the download and some other small benefits
 *  @param completionBlock A block object to be executed when the task finishes. This block has no return value and takes three arguments: the status, the path to the response object and the filename, created by that serializer.
 *  @param failureBlock A block object to be executed when the task finishes with failure. This block has no return value and takes five arguments: the original response,an error if possible, status, the path to the response object and the filename if one was created, the objectname which should be downloaded, created by that serializer.
 *  @param enableBackgroundModeBlock if set, the downloadmanager creates a task which will be able to be keept alive also when the app is full in background, it will wakeup the app after finish the task.
 *
 *  @return a `NSURLSessionDownloadTask` object, to grant you the ability the proof things by yourself and cancel a running request.
*/
- (nullable NSURLSessionDownloadTask *)downloadFileFromURL:(NSString *)URLString
                                                  withName:(nullable NSString *)fileName
                                          inDirectoryNamed:(nullable NSURL *)directory
                                             progressBlock:(nullable void (^)(NSProgress *progress))progressBlock
                                               statusBlock:(nullable void (^)(NSTimeInterval seconds,
                                                                              CGFloat percentDone,
                                                                              CGFloat byteRemaining,
                                                                              CGFloat bytesWritten)) statusBlock
                                           completionBlock:(nullable void (^)(kRequestManagerSessionStatus status,
                                                                              NSURL *directory,
                                                                              NSString *fileName,
                                                                              NSURLResponse * _Nonnull response))completionBlock
                                              failureBlock:(nullable void (^)(NSURLResponse * _Nonnull response,
                                                                              NSError *error,
                                                                              kRequestManagerSessionStatus status,
                                                                              NSURL *directory,
                                                                              NSString *fileName)) failure
                                 enableBackgroundModeBlock:(nullable void (^)(NSURLSession *session))backgroundBlock;



#pragma mark - Upload Tasks

/**
 *  Creates an `NSURLSessionUploadTask` with the specified request for a local file.
 *
 *  @param fileURL         Url to a file.
 *  @param URLString       The URL string used to create the request URL.
 *  @param progressBlock   progressBlock provide a progress block if you want to stay informed about the process
 *  @param statusBlock     statusBlock provide a progress block if you want to stay informed about the remaining time of the download and some other small benefits
 *  @param completionBlock A block object to be executed when the task finishes. This block has no return value and takes four arguments: the status, the path to the response object and the filename, created by that serializer.
 *  @param failureBlock    A block object to be executed when the task finishes with failure. This block has no return value and takes five arguments: the original response,an error if possible, status, the path to the response object and the filename if one was created, the objectname which should be downloaded, created by that serializer.
 *  @param backgroundBlock if set, the downloadmanager creates a task which will be able to be keept alive also when the app is full in background, it will wakeup the app after finish the task.
 *
 *  @return a `NSURLSessionUploadTask` object, to grant you the ability the proof things by yourself and cancel a running request.
 */
- (nullable NSURLSessionUploadTask *)uploadFile:(NSURL *)fileURL
                                          toUrl:(NSString *)URLString
                                  progressBlock:(nullable void(^)(NSProgress *progress)) progressBlock
                                    statusBlock:(nullable void (^)(NSTimeInterval seconds,
                                                                   CGFloat percentDone,
                                                                   CGFloat byteRemaining,
                                                                   CGFloat bytesWritten)) statusBlock
                                completionBlock:(nullable void(^)(kRequestManagerSessionStatus status,
                                                                  id response)) completionBlock
                                        failure:(nullable void (^)(id response,
                                                                   NSError *error,
                                                                   kRequestManagerSessionStatus status)) failureBlock
                           enableBackgroundMode:(nullable void (^)(NSURLSession *session))backgroundBlock;

/**
 *  Creates an `NSURLSessionUploadTask` with the specified request for a local file.
 *
 *  @param uploadData      a raw NSData object which should be transferred
 *  @param URLString       The URL string used to create the request URL.
 *  @param progressBlock   progressBlock provide a progress block if you want to stay informed about the process
 *  @param statusBlock     statusBlock provide a progress block if you want to stay informed about the remaining time of the download and some other small benefits
 *  @param completionBlock A block object to be executed when the task finishes. This block has no return value and takes four arguments: the status, the path to the response object and the filename, created by that serializer.
 *  @param failureBlock    A block object to be executed when the task finishes with failure. This block has no return value and takes five arguments: the original response,an error if possible, status, the path to the response object and the filename if one was created, the objectname which should be downloaded, created by that serializer.
 *  @param backgroundBlock if set, the downloadmanager creates a task which will be able to be keept alive also when the app is full in background, it will wakeup the app after finish the task.
 *
 *  @return a `NSURLSessionUploadTask` object, to grant you the ability the proof things by yourself and cancel a running request.
 */
- (nullable NSURLSessionUploadTask *)uploadData:(NSData *)rawData
                                          toUrl:(NSString *)URLString
                                  progressBlock:(nullable void(^)(NSProgress *progress)) progressBlock
                                    statusBlock:(nullable void (^)(NSTimeInterval seconds,
                                                                   CGFloat percentDone,
                                                                   CGFloat byteRemaining,
                                                                   CGFloat bytesWritten)) statusBlock
                                completionBlock:(nullable void(^)(kRequestManagerSessionStatus status,
                                                                  id response)) completionBlock
                                        failure:(nullable void (^)(id response,
                                                                   NSError *error,
                                                                   kRequestManagerSessionStatus status)) failureBlock
                           enableBackgroundMode:(nullable void (^)(NSURLSession *session)) backgroundBlock;


@end

NS_ASSUME_NONNULL_END
