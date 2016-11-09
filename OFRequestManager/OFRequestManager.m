//
//  OFRequestManager.m
//  OFRequestManager
//
//  Created by Oliver Franke on 05.07.16.
//  Copyright © 2016 Oliver Franke. All rights reserved.
//

#import "OFRequestManager.h"

@interface OFRequestManager () <NSURLSessionDelegate>
@property (nonatomic, strong) NSMutableDictionary *downloadStore;
@property (nonatomic, strong) NSMutableDictionary *calculationTimesStore;
@property (nonatomic, getter=uploadTasks) NSArray <NSURLSessionUploadTask *> *uploadTasks;
@property (nonatomic, getter=downloadTasks) NSArray <NSURLSessionDownloadTask *> *downloadTasks;
@property (nonatomic, getter=dataTasks) NSArray <NSURLSessionDataTask *> *dataTasks;
@end

@implementation OFRequestManager
//Const
NSString * const DOWNLOAD_STORE_USERDEFAULTS_NAME = @"OFRequestManagerDownloadStore";
NSString * const httpPattern  = @"http://";
NSString * const httpsPattern = @"https://";

static OFRequestManager *sharedInstance = nil;

@synthesize timeout = _timeout;
@synthesize extraHTTPHeaderFields = _extraHTTPHeaderFields;

//----------------------------------------------------------------------------------------------
+ (instancetype)sharedManager
//----------------------------------------------------------------------------------------------
{
    if ( sharedInstance == nil ) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}


//----------------------------------------------------------------------------------------------
- (void)setup
//----------------------------------------------------------------------------------------------
{
    self.calculationTimesStore = [NSMutableDictionary new];
}

//----------------------------------------------------------------------------------------------
- (instancetype)init
//----------------------------------------------------------------------------------------------
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

//----------------------------------------------------------------------------------------------
- (instancetype)initWithBaseURL:(NSURL *)url
//----------------------------------------------------------------------------------------------
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    if ([[url path] length] > 0 && ![[url absoluteString] hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    self.baseURL = url;
    
    return self;
}

#pragma mark - Custom Setter

//----------------------------------------------------------------------------------------------
- (void)setBaseURL:(NSURL *)baseURL
//----------------------------------------------------------------------------------------------
{
    if ([[baseURL path] length] > 0 && ![[baseURL absoluteString] hasSuffix:@"/"]) {
        baseURL = [baseURL URLByAppendingPathComponent:@""];
    }
    _baseURL = baseURL;
}


//----------------------------------------------------------------------------------------------
- (NSMutableDictionary*)downloadStore
//----------------------------------------------------------------------------------------------
{
    if (!_downloadStore) {
        _downloadStore = [[NSUserDefaults standardUserDefaults] objectForKey:DOWNLOAD_STORE_USERDEFAULTS_NAME];
        if (!_downloadStore) {
            _downloadStore = [NSMutableDictionary new];
        }
        
        [self removeDeadFilesInStore];
    }
    return _downloadStore;
}
#pragma mark - Custom Setter
//----------------------------------------------------------------------------------------------
- (void)setTimeout:(NSTimeInterval)timeout
//----------------------------------------------------------------------------------------------
{
    _timeout = timeout;
    if (_httpSessionManager) {
        [_httpSessionManager.requestSerializer setTimeoutInterval:timeout];
    }
}

//----------------------------------------------------------------------------------------------
- (void)setExtraHTTPHeaderFields:(NSMutableDictionary *)extraHTTPHeaderFields
//----------------------------------------------------------------------------------------------
{
    _extraHTTPHeaderFields = extraHTTPHeaderFields;
    [self updateHeaders];
}

//----------------------------------------------------------------------------------------------
- (void)updateHeaders
//----------------------------------------------------------------------------------------------
{
    if (self.extraHTTPHeaderFields) {
        if (_httpSessionManager) {
            for (NSString *key in self.extraHTTPHeaderFields) {
                [_httpSessionManager.requestSerializer setValue:[self.extraHTTPHeaderFields objectForKey:key] forHTTPHeaderField:key];
            }
        }
    }
}

#pragma mark - Custom Getter

//----------------------------------------------------------------------------------------------
- (NSMutableDictionary*)extraHTTPHeaderFields
//----------------------------------------------------------------------------------------------
{
    if (!_extraHTTPHeaderFields) {
        _extraHTTPHeaderFields = [NSMutableDictionary new];
    }
    return _extraHTTPHeaderFields;
}

//----------------------------------------------------------------------------------------------
- (NSArray*)uploadTasks
//----------------------------------------------------------------------------------------------
{
    if ((_backgroundSessionManager && _backgroundSessionManager.uploadTasks.count)
        && (_urlSessionManager && _urlSessionManager.uploadTasks.count)) {
        NSMutableArray *uploadTasks = [_backgroundSessionManager.uploadTasks mutableCopy];
        [uploadTasks addObjectsFromArray:_urlSessionManager.uploadTasks];
        return [uploadTasks copy];
    } else if (_urlSessionManager && _urlSessionManager.uploadTasks.count) {
        return _urlSessionManager.uploadTasks;
    } else if (_urlSessionManager && _urlSessionManager.uploadTasks.count) {
        return _urlSessionManager.uploadTasks;
    }
    return nil;
}

//----------------------------------------------------------------------------------------------
- (NSArray*)downloadTasks
//----------------------------------------------------------------------------------------------
{
    if ((_backgroundSessionManager && _backgroundSessionManager.downloadTasks.count)
        && (_urlSessionManager && _urlSessionManager.downloadTasks.count)) {
        NSMutableArray *downloadTasks = [_backgroundSessionManager.downloadTasks mutableCopy];
        [downloadTasks addObjectsFromArray:_urlSessionManager.downloadTasks];
        return [downloadTasks copy];
    } else if (_urlSessionManager && _urlSessionManager.downloadTasks.count) {
        return _urlSessionManager.downloadTasks;
    } else if (_urlSessionManager && _urlSessionManager.downloadTasks.count) {
        return _urlSessionManager.downloadTasks;
    }
    return nil;
}

//----------------------------------------------------------------------------------------------
- (NSArray*)dataTasks
//----------------------------------------------------------------------------------------------
{
    if (_httpSessionManager && _httpSessionManager.dataTasks.count) {
        return _httpSessionManager.dataTasks;
    }
    return nil;
}

//----------------------------------------------------------------------------------------------
- (NSTimeInterval)timeout
//----------------------------------------------------------------------------------------------
{
    if (!_timeout) {
        return 60;
    }
    return _timeout;
}

//----------------------------------------------------------------------------------------------
- (BOOL)showNetworkIndicator
//----------------------------------------------------------------------------------------------
{
    if (!_showNetworkIndicator) {
        return NO;
    }
    return _showNetworkIndicator;
}

//----------------------------------------------------------------------------------------------
- (nullable NSProgress *)progressForTask:(NSURLSessionTask *)task
//----------------------------------------------------------------------------------------------
{
    NSProgress *progress = nil;
    
    if ([task isKindOfClass:[NSURLSessionDownloadTask class]] && (_urlSessionManager || _backgroundSessionManager)) {
        if (_urlSessionManager && !_backgroundSessionManager) {
            progress = [_urlSessionManager downloadProgressForTask:task];
        } else if (!_urlSessionManager && _backgroundSessionManager) {
            progress = [_backgroundSessionManager downloadProgressForTask:task];
        }
        else if (_urlSessionManager && _backgroundSessionManager) {
            progress = [_urlSessionManager downloadProgressForTask:task];
            if (!progress) {
                progress = [_backgroundSessionManager downloadProgressForTask:task];
            }
        }
    } else if ([task isKindOfClass:[NSURLSessionUploadTask class]] && (_urlSessionManager || _backgroundSessionManager)) {
        if (_urlSessionManager && !_backgroundSessionManager) {
            progress = [_urlSessionManager uploadProgressForTask:task];
        } else if (!_urlSessionManager && _backgroundSessionManager) {
            progress = [_backgroundSessionManager uploadProgressForTask:task];
        }
        else if (_urlSessionManager && _backgroundSessionManager) {
            progress = [_urlSessionManager uploadProgressForTask:task];
            if (!progress) {
                progress = [_backgroundSessionManager uploadProgressForTask:task];
            }
        }
    }
    return progress;
}

//--------------------------------------------------------------------------------
- (AFHTTPSessionManager *)httpSessionManager
//--------------------------------------------------------------------------------
{
    if (_httpSessionManager == nil ) {
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:self.showNetworkIndicator];
        _httpSessionManager = [[AFHTTPSessionManager alloc] init];
        _httpSessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        if (self.acceptedContentTypes) {
            _httpSessionManager.responseSerializer.acceptableContentTypes = self.acceptedContentTypes;
        }
        
        [self updateHeaders];
        
        [_httpSessionManager.requestSerializer setTimeoutInterval:self.timeout];
    }
    return _httpSessionManager;
}

//--------------------------------------------------------------------------------
- (AFURLSessionManager *)urlSessionManager
//--------------------------------------------------------------------------------
{
    if (_urlSessionManager == nil ) {
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:self.showNetworkIndicator];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _urlSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    }
    return _urlSessionManager;
}

//--------------------------------------------------------------------------------
- (AFURLSessionManager *)backgroundSessionManager
//--------------------------------------------------------------------------------
{
    if (_backgroundSessionManager == nil ) {
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:self.showNetworkIndicator];
        
        NSURLSessionConfiguration *backgroundConfiguration;
        if (floor(NSFoundationVersionNumber) >= NSFoundationVersionNumber_iOS_8_0) {
            backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.elegantDownloader.downloadmanager"];
        } else {
            backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.elegantDownloader.downloadmanager"];
        }
        
        _backgroundSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:backgroundConfiguration];
    }
    return _urlSessionManager;
}

#pragma mark - Interruptions

//----------------------------------------------------------------------------------------------
- (void)invalidateAllRunningTasksShouldCancelPending:(BOOL)stopPending
//----------------------------------------------------------------------------------------------
{
    if (_backgroundSessionManager) {
        [_backgroundSessionManager invalidateSessionCancelingTasks:stopPending];
    }
    if (_urlSessionManager) {
        [_urlSessionManager invalidateSessionCancelingTasks:stopPending];
    }
    if (_httpSessionManager) {
        [_httpSessionManager invalidateSessionCancelingTasks:stopPending];
    }
}

//----------------------------------------------------------------------------------------------
- (NSString*)checkUrlForBasePath:(NSString*)url
//----------------------------------------------------------------------------------------------
{
    if (!self.baseURL || [url containsString:httpPattern] || [url containsString:httpsPattern]) {
        return url;
    } else if (self.baseURL) {
        return [[self.baseURL URLByAppendingPathComponent:url] absoluteString];
    }
    return nil;
}

#pragma mark - HTTP API
#pragma mark - Get
//----------------------------------------------------------------------------------------------
- (nullable NSURLSessionDataTask*)GET:(NSString *)URLString
                           parameters:(NSDictionary*)parameters
                             progress:(void (^)(NSProgress *))downloadProgress
                              success:(void (^)(NSURLSessionDataTask *, id _Nullable))success
                              failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError *))failure
//----------------------------------------------------------------------------------------------
{
    return [self.httpSessionManager GET:[self checkUrlForBasePath:URLString]
                             parameters:parameters
                               progress:downloadProgress
                                success:success
                                failure:failure];
}

#pragma mark - Post
//----------------------------------------------------------------------------------------------
- (nullable NSURLSessionDataTask*)POST:(NSString *)URLString
                            parameters:(id)parameters
                              progress:(void (^)(NSProgress * _Nonnull))uploadProgress
                               success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                               failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
//----------------------------------------------------------------------------------------------
{
    NSMutableDictionary *params;
    if (parameters) {
        params = [parameters mutableCopy];
    } else {
        params = [NSMutableDictionary new];
    }
    
    if (self.additionalParamsToAddContiniously) {
        [params addEntriesFromDictionary:self.additionalParamsToAddContiniously];
    }
    return [self.httpSessionManager POST:[self checkUrlForBasePath:URLString]
                              parameters:params
                                progress:uploadProgress
                                 success:success
                                 failure:failure];
}

//----------------------------------------------------------------------------------------------
- (nullable NSURLSessionDataTask*)POST:(NSString *)URLString
                            parameters:(id)parameters
             constructingBodyWithBlock:(void (^)(id<AFMultipartFormData> _Nonnull))block
                              progress:(void (^)(NSProgress * _Nonnull))uploadProgress
                               success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                               failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
//----------------------------------------------------------------------------------------------
{
    NSMutableDictionary *params;
    if (parameters) {
        params = [parameters mutableCopy];
    } else {
        params = [NSMutableDictionary new];
    }
    
    if (self.additionalParamsToAddContiniously) {
        [params addEntriesFromDictionary:self.additionalParamsToAddContiniously];
    }
    return [self.httpSessionManager POST:[self checkUrlForBasePath:URLString]
                              parameters:params
               constructingBodyWithBlock:block
                                progress:uploadProgress
                                 success:success
                                 failure:failure];
}

#pragma mark - Put
//----------------------------------------------------------------------------------------------
- (nullable NSURLSessionDataTask *)PUT:(NSString *)URLString
                            parameters:(nullable id)parameters
                               success:(nullable void (^)(NSURLSessionDataTask *task, id _Nullable responseObject))success
                               failure:(nullable void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure
//----------------------------------------------------------------------------------------------
{
    NSMutableDictionary *params;
    if (parameters) {
        params = [parameters mutableCopy];
    } else {
        params = [NSMutableDictionary new];
    }
    
    if (self.additionalParamsToAddContiniously) {
        [params addEntriesFromDictionary:self.additionalParamsToAddContiniously];
    }
    
    return [self.httpSessionManager PUT:[self checkUrlForBasePath:URLString]
                             parameters:params
                                success:success
                                failure:failure];
}

#pragma mark - Patch
//----------------------------------------------------------------------------------------------
- (nullable NSURLSessionDataTask *)PATCH:(NSString *)URLString
                              parameters:(id)parameters
                                 success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                                 failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
//----------------------------------------------------------------------------------------------
{
    NSMutableDictionary *params;
    if (parameters) {
        params = [parameters mutableCopy];
    } else {
        params = [NSMutableDictionary new];
    }
    
    if (self.additionalParamsToAddContiniously) {
        [params addEntriesFromDictionary:self.additionalParamsToAddContiniously];
    }
    
    return [self.httpSessionManager PATCH:[self checkUrlForBasePath:URLString]
                               parameters:params
                                  success:success
                                  failure:failure];
}

#pragma mark - Delete
//----------------------------------------------------------------------------------------------
- (nullable NSURLSessionDataTask *)DELETE:(NSString *)URLString
                               parameters:(id)parameters
                                  success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                                  failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
//----------------------------------------------------------------------------------------------
{
    NSMutableDictionary *params;
    if (parameters) {
        params = [parameters mutableCopy];
    } else {
        params = [NSMutableDictionary new];
    }
    
    if (self.additionalParamsToAddContiniously) {
        [params addEntriesFromDictionary:self.additionalParamsToAddContiniously];
    }
    
    return [self.httpSessionManager DELETE:[self checkUrlForBasePath:URLString]
                                parameters:params
                                   success:success
                                   failure:failure];
}

#pragma mark - Head
//----------------------------------------------------------------------------------------------
- (nullable NSURLSessionDataTask*)HEAD:(NSString *)URLString
                            parameters:(id)parameters
                               success:(void (^)(NSURLSessionDataTask * _Nonnull))success
                               failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
//----------------------------------------------------------------------------------------------
{
    return [self.httpSessionManager HEAD:[self checkUrlForBasePath:URLString]
                              parameters:parameters
                                 success:success
                                 failure:failure];
}

#pragma mark -
//TODO: Check if a Task with the current url is running, so not other is created.
#pragma mark - Download

//----------------------------------------------------------------------------------------------
- (nullable NSURLSessionDownloadTask *)downloadFileFromURL:(NSString *)URLString
                                                  withName:(nullable NSString *)fileName
                                          inDirectoryNamed:(nullable NSURL *)directory
                                             progressBlock:(nullable void (^)(NSProgress *progress)) progressBlock
                                               statusBlock:(nullable void (^)(NSTimeInterval seconds,
                                                                              CGFloat percentDone,
                                                                              CGFloat byteRemaining,
                                                                              CGFloat bytesWritten)) statusBlock
                                           completionBlock:(nullable void (^)(kRequestManagerSessionStatus status,
                                                                              NSURL *directory,
                                                                              NSString *fileName,
                                                                              NSURLResponse * _Nonnull response)) completionBlock
                                              failureBlock:(nullable void (^)(NSURLResponse * _Nonnull response,
                                                                              NSError *error,
                                                                              kRequestManagerSessionStatus status,
                                                                              NSURL *directory,
                                                                              NSString *fileName)) failure
                                 enableBackgroundModeBlock:(nullable void (^)(NSURLSession *session)) backgroundBlock
//----------------------------------------------------------------------------------------------
{
    NSURL *url = [NSURL URLWithString:[self checkUrlForBasePath:URLString]];
    if (!fileName) {
        fileName = [URLString lastPathComponent];
    }
    if (!directory) {
        directory = [self cachesDirectoryUrlPath];
    }
    
    NSURL *finalPathToWrite = [directory URLByAppendingPathComponent:fileName];
    NSURLSessionDownloadTask *localDownloadTask;
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFURLSessionManager *manager;
    
    if (backgroundBlock) {
        manager = self.backgroundSessionManager;
        [self.backgroundSessionManager setDidFinishEventsForBackgroundURLSessionBlock:backgroundBlock];
    } else {
        manager = self.urlSessionManager;
    }
    
    localDownloadTask = [manager downloadTaskWithRequest:request
                                                progress:progressBlock
                                             destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                 return finalPathToWrite;
                                             }
                                       completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                           if (failure && error) {
                                               kRequestManagerSessionStatus status = kRequestManagerSessionStatusErrored;
                                               failure(response, error, status, directory, fileName);
                                           } else if(completionBlock && !error) {
                                               
                                               kRequestManagerSessionStatus status;
                                               status = kRequestManagerSessionStatusFileCompleted;
                                               [self.downloadStore setObject:filePath forKey:fileName];
                                               [self.calculationTimesStore removeObjectForKey:@(localDownloadTask.taskIdentifier)];
                                               completionBlock(status, filePath, fileName, response);
                                           }
                                       }];
    
    if (statusBlock) {
        [self setStatusBlockForDownloadManagar:manager
                                      withTask:localDownloadTask
                                   statusBlock:statusBlock];
    }
    
    [localDownloadTask resume];
    [self.calculationTimesStore setObject:[NSDate date] forKey:@(localDownloadTask.taskIdentifier)];
    
    return localDownloadTask;
}

#pragma mark - Upload

//----------------------------------------------------------------------------------------------
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
                           enableBackgroundMode:(nullable void (^)(NSURLSession *session)) backgroundBlock
//----------------------------------------------------------------------------------------------
{
    if (!fileURL) {
        return nil;
    }
    NSURL *url = [NSURL URLWithString:[self checkUrlForBasePath:URLString]];
    NSURLSessionUploadTask *localUploadTask;
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFURLSessionManager *manager;
    if (backgroundBlock) {
        manager = self.backgroundSessionManager;
        [self.backgroundSessionManager setDidFinishEventsForBackgroundURLSessionBlock:backgroundBlock];
    } else {
        manager = self.urlSessionManager;
    }
    
    localUploadTask = [manager uploadTaskWithRequest:request
                                            fromFile:fileURL
                                            progress:progressBlock
                                   completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                       if (failureBlock && error) {
                                           kRequestManagerSessionStatus status = kRequestManagerSessionStatusErrored;
                                           failureBlock(responseObject, error, status);
                                       }
                                       if (completionBlock && !error) {
                                           kRequestManagerSessionStatus status = kRequestManagerSessionStatusFileCompleted;
                                           completionBlock(status, responseObject);
                                       }
                                   }];
    
    if (statusBlock) {
        [self setStatusBlockForUploadManagar:manager
                                    withTask:localUploadTask
                                 statusBlock:statusBlock];
    }
    
    [localUploadTask resume];
    [self.calculationTimesStore setObject:[NSDate date] forKey:@(localUploadTask.taskIdentifier)];
    
    return localUploadTask;
}


//----------------------------------------------------------------------------------------------
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
                           enableBackgroundMode:(nullable void (^)(NSURLSession *session)) backgroundBlock
//----------------------------------------------------------------------------------------------
{
    if (!rawData) {
        return nil;
    }
    NSURL *url = [NSURL URLWithString:[self checkUrlForBasePath:URLString]];
    NSURLSessionUploadTask *localUploadTask;
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFURLSessionManager *manager;
    if (backgroundBlock) {
        manager = self.backgroundSessionManager;
        [self.backgroundSessionManager setDidFinishEventsForBackgroundURLSessionBlock:backgroundBlock];
    } else {
        manager = self.urlSessionManager;
    }
    
    localUploadTask = [manager uploadTaskWithRequest:request
                                            fromData:rawData
                                            progress:progressBlock
                                   completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                                       if (failureBlock && error) {
                                           kRequestManagerSessionStatus status = kRequestManagerSessionStatusErrored;
                                           failureBlock(responseObject, error, status);
                                       }
                                       if (completionBlock && !error) {
                                           kRequestManagerSessionStatus status = kRequestManagerSessionStatusFileCompleted;
                                           completionBlock(status, responseObject);
                                       }
                                   }];
    
    if (statusBlock) {
        [self setStatusBlockForUploadManagar:manager
                                    withTask:localUploadTask
                                 statusBlock:statusBlock];
    }
    
    [localUploadTask resume];
    [self.calculationTimesStore setObject:[NSDate date] forKey:@(localUploadTask.taskIdentifier)];
    
    return localUploadTask;
}
#pragma mark - Helper Functions

//----------------------------------------------------------------------------------------------
- (void)setStatusBlockForDownloadManagar:(AFURLSessionManager*)manager
                                withTask:(NSURLSessionDownloadTask*)task
                             statusBlock:(nullable void (^)(NSTimeInterval seconds,
                                                            CGFloat percentDone,
                                                            CGFloat byteRemaining,
                                                            CGFloat bytesWritten))statusBlock
//----------------------------------------------------------------------------------------------
{
    [manager setDownloadTaskDidWriteDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        
        if (task.taskIdentifier == downloadTask.taskIdentifier) {
            //inline to avoid weakselfs etc. function is not to big and this is so simpel math, we dont need seperate test here..
            NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:[self.calculationTimesStore objectForKey:@(downloadTask.taskIdentifier)]];
            NSTimeInterval speed = (totalBytesWritten / timeInterval);
            double remainingBytes = totalBytesExpectedToWrite - totalBytesWritten;
            NSTimeInterval remainingSeconds = (remainingBytes / speed);
            
            CGFloat percentDone = (100 * totalBytesWritten) / totalBytesExpectedToWrite;
            CGFloat bytesRemaining = totalBytesExpectedToWrite - totalBytesWritten;
            statusBlock(remainingSeconds, percentDone, bytesRemaining, totalBytesWritten);
        }
    }];
}

//----------------------------------------------------------------------------------------------
- (void)setStatusBlockForUploadManagar:(AFURLSessionManager*)manager
                              withTask:(NSURLSessionUploadTask*)upTask
                           statusBlock:(nullable void (^)(NSTimeInterval seconds,
                                                          CGFloat percentDone,
                                                          CGFloat byteRemaining,
                                                          CGFloat bytesWritten))statusBlock
//----------------------------------------------------------------------------------------------
{
    [manager setTaskDidSendBodyDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        if (task.taskIdentifier == upTask.taskIdentifier) {
            //inline to avoid weakselfs etc. function is not to big and this is so simpel math, we dont need seperate test here..
            NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:[self.calculationTimesStore objectForKey:@(upTask.taskIdentifier)]];
            NSTimeInterval speed = (bytesSent / timeInterval) * 1024;
            double remainingBytes = totalBytesExpectedToSend - totalBytesSent;
            NSTimeInterval remainingSeconds = (remainingBytes / speed);
            
            CGFloat percentDone = (100 * totalBytesSent) / totalBytesExpectedToSend;
            CGFloat bytesRemaining = totalBytesExpectedToSend - totalBytesSent;
            statusBlock(remainingSeconds, percentDone, bytesRemaining, totalBytesSent);
        }
    }];
}

//----------------------------------------------------------------------------------------------
- (BOOL)fileDownloadCompletedForItem:(NSString *)fileIdentifier
//----------------------------------------------------------------------------------------------
{
    NSString *filePath = [self.downloadStore objectForKey:fileIdentifier];
    return filePath ? YES : NO;
}

//----------------------------------------------------------------------------------------------
+ (id)responseForTask:(NSURLSessionTask *)task
            withError:(NSError*)error
//----------------------------------------------------------------------------------------------
{
    NSError *parserError;
    AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    
    NSDictionary *response = [serializer responseObjectForResponse:task.response
                                                              data:error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]
                                                             error:&parserError];
    return response;
}

//----------------------------------------------------------------------------------------------
+ (NSInteger)statusCodeFromResponse:(NSURLResponse*)response
//----------------------------------------------------------------------------------------------
{
    if (response) {
        return ((NSHTTPURLResponse*)response).statusCode;
    }
    
    return 0;
}

//----------------------------------------------------------------------------------------------
+ (id)requestBodyForTask:(NSURLSessionTask *)task
//----------------------------------------------------------------------------------------------
{
    return [[NSString alloc] initWithData:task.originalRequest.HTTPBody encoding:NSUTF8StringEncoding];
}

#pragma mark - File related Helper Functions
//----------------------------------------------------------------------------------------------
- (void)removeDeadFilesInStore
//----------------------------------------------------------------------------------------------
{
    NSMutableArray *entriesToRemove = [NSMutableArray new];
    for(id key in self.downloadStore)
    {
        if (![[NSFileManager defaultManager] fileExistsAtPath:[self.downloadStore objectForKey:key]]) {
            [entriesToRemove addObject:key];
        }
    }
    
    for (NSString *key in entriesToRemove) {
        [self.downloadStore removeObjectForKey:key];
    }
}

//----------------------------------------------------------------------------------------------
- (BOOL)fileExistsInDefaultDirWithName:(NSString *)fileName
//----------------------------------------------------------------------------------------------
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[[[self cachesDirectoryUrlPath] absoluteString] stringByAppendingPathComponent:fileName]];
}

//----------------------------------------------------------------------------------------------
- (BOOL)fileExistsWithName:(NSString *)fileName
               inDirectory:(NSString *)directoryName
//----------------------------------------------------------------------------------------------
{
    return [[NSFileManager defaultManager] fileExistsAtPath:[[directoryName stringByAppendingPathComponent:directoryName]
                                                             stringByAppendingPathComponent:fileName]];
}

//----------------------------------------------------------------------------------------------
- (NSURL *)cachesDirectoryUrlPath
//----------------------------------------------------------------------------------------------
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths objectAtIndex:0];
    return [NSURL fileURLWithPath:cachesDirectory];
}


@end
