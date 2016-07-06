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
@property (nonatomic, strong) NSMutableDictionary *downloadTimesStores;
@property (nonatomic, getter=uploadTasks) NSArray <NSURLSessionUploadTask *> *uploadTasks;
@property (nonatomic, getter=downloadTasks) NSArray <NSURLSessionDownloadTask *> *downloadTasks;
@property (nonatomic, getter=dataTasks) NSArray <NSURLSessionDataTask *> *dataTasks;
@end

@implementation OFRequestManager
//Const
NSString * const DOWNLOAD_STORE_USERDEFAULTS_NAME = @"OFRequestManagerDownloadStore";

static OFRequestManager *sharedInstance = nil;

@synthesize timeout = _timeout;

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
    self.downloadTimesStores = [NSMutableDictionary new];
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

#pragma mark - Custom Getter

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

//--------------------------------------------------------------------------------
- (AFHTTPSessionManager *)httpSessionManager
//--------------------------------------------------------------------------------
{
    if (_httpSessionManager == nil ) {
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:self.showNetworkIndicator];
        _httpSessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:self.baseURL];
        _httpSessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        if (self.acceptedContentTypes) {
            _httpSessionManager.responseSerializer.acceptableContentTypes = self.acceptedContentTypes;
        }
        
        if (self.extraHTTPHeaderFields) {
            for (NSString *key in self.extraHTTPHeaderFields) {
                [_httpSessionManager.requestSerializer setValue:[self.extraHTTPHeaderFields objectForKey:key] forHTTPHeaderField:key];
            }
        }
        
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
    return [self.httpSessionManager GET:URLString
                             parameters:parameters
                               progress:downloadProgress
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
    return [self.httpSessionManager HEAD:URLString
                              parameters:parameters
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
    NSMutableDictionary *params = [parameters mutableCopy];
    
    if (self.additionalParamsToAddContiniously) {
        [params addEntriesFromDictionary:self.additionalParamsToAddContiniously];
    }
    return [self.httpSessionManager POST:URLString
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
    NSMutableDictionary *params = [parameters mutableCopy];
    
    if (self.additionalParamsToAddContiniously) {
        [params addEntriesFromDictionary:self.additionalParamsToAddContiniously];
    }
    return [self.httpSessionManager POST:URLString
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
    NSMutableDictionary *params = [parameters mutableCopy];
    
    if (self.additionalParamsToAddContiniously) {
        [params addEntriesFromDictionary:self.additionalParamsToAddContiniously];
    }
    
    return [self.httpSessionManager PUT:URLString
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
    NSMutableDictionary *params = [parameters mutableCopy];
    
    if (self.additionalParamsToAddContiniously) {
        [params addEntriesFromDictionary:self.additionalParamsToAddContiniously];
    }
    
    return [self.httpSessionManager PATCH:URLString
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
    NSMutableDictionary *params = [parameters mutableCopy];
    
    if (self.additionalParamsToAddContiniously) {
        [params addEntriesFromDictionary:self.additionalParamsToAddContiniously];
    }
    
    return [self.httpSessionManager DELETE:URLString
                                parameters:params
                                   success:success
                                   failure:failure];
}

#pragma mark - Download

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
- (kRequestManagerSessionStatus)downloadFileFromURL:(NSString *)URLString
                                           withName:(nullable NSString *)fileName
                                   inDirectoryNamed:(nullable NSURL *)directory
                                      progressBlock:(nullable void(^)(NSProgress *progress))progressBlock
                                      remainingTime:(nullable void(^)(NSTimeInterval seconds))remainingTimeBlock
                                    completionBlock:(nullable void(^)(kRequestManagerSessionStatus status, NSURL *directory, NSString *fileName))completionBlock
                                            failure:(nullable void (^)(NSURLResponse * _Nonnull response, NSError *error, kRequestManagerSessionStatus status, NSURL *directory, NSString *fileName))failure
                               enableBackgroundMode:(nullable void (^)(NSURLSession *session))backgroundBlock
//----------------------------------------------------------------------------------------------
{
    NSURL *url = [NSURL URLWithString:URLString];
    if (!fileName) {
        fileName = [URLString lastPathComponent];
    }
    if (!directory) {
        directory = [self cachesDirectoryUrlPath];
    }
    
    NSURL *finalPathToWrite = [directory URLByAppendingPathComponent:fileName];
    
    //missing currently downloading? currently no ideas how to solve it in best way
    if (![[NSFileManager defaultManager] fileExistsAtPath:[finalPathToWrite absoluteString]]) {
        
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLSessionDownloadTask *localDownloadTask;
        
        if (backgroundBlock) {
            [self.backgroundSessionManager setDidFinishEventsForBackgroundURLSessionBlock:backgroundBlock];
            
            localDownloadTask = [self.backgroundSessionManager downloadTaskWithRequest:request
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
                                                                             [self.downloadTimesStores removeObjectForKey:@(localDownloadTask.taskIdentifier)];
                                                                             completionBlock(status, filePath, fileName);
                                                                         }
                                                                     }];
            if (remainingTimeBlock) {
                __weak typeof(self) weakSelf = self;
                [self.urlSessionManager setDownloadTaskDidWriteDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
                    
                    if (localDownloadTask.taskIdentifier == downloadTask.taskIdentifier) {
                        if (remainingTimeBlock) {
                            remainingTimeBlock([weakSelf calculateRemainingTimeForTask:downloadTask
                                                                      withBytesWritten:bytesWritten
                                                                     totalBytesWritten:totalBytesWritten
                                                             totalBytesExpectedToWrite:totalBytesExpectedToWrite]);
                        }
                    }
                }];
            }

            
        } else {
            localDownloadTask = [self.urlSessionManager downloadTaskWithRequest:request
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
                                                                      [self.downloadTimesStores removeObjectForKey:@(localDownloadTask.taskIdentifier)];
                                                                      completionBlock(status, filePath, fileName);
                                                                  }
                                                              }];
            
            if (remainingTimeBlock) {
                __weak typeof(self) weakSelf = self;
                [self.urlSessionManager setDownloadTaskDidWriteDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
                    
                    if (localDownloadTask.taskIdentifier == downloadTask.taskIdentifier) {
                        if (remainingTimeBlock) {
                            remainingTimeBlock([weakSelf calculateRemainingTimeForTask:downloadTask
                                                                      withBytesWritten:bytesWritten
                                                                     totalBytesWritten:totalBytesWritten
                                                             totalBytesExpectedToWrite:totalBytesExpectedToWrite]);
                        }
                    }
                }];
            }
        }
        
        if (!localDownloadTask) {
            return kRequestManagerSessionStatusErrored;
        }
        [localDownloadTask resume];
        [self.downloadTimesStores setObject:[NSDate date] forKey:@(localDownloadTask.taskIdentifier)];
        return kRequestManagerSessionStatusStarted;
    } else {
        return kRequestManagerSessionStatusAlreadyDownloaded;
    }
}

#pragma mark - Download Helper Functions

//----------------------------------------------------------------------------------------------
- (NSTimeInterval)calculateRemainingTimeForTask:(NSURLSessionDownloadTask*)downloadTask
                               withBytesWritten:(int64_t)bytesWritten
                              totalBytesWritten:(int64_t)totalBytesWritten
                      totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
//----------------------------------------------------------------------------------------------
{
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:[self.downloadTimesStores objectForKey:@(downloadTask.taskIdentifier)]];
    NSTimeInterval speed = (bytesWritten / timeInterval) * 1024;
    double remainingBytes = totalBytesExpectedToWrite - bytesWritten;
    return (remainingBytes / speed);
}


//----------------------------------------------------------------------------------------------
- (BOOL)fileDownloadCompletedForItem:(NSString *)fileIdentifier
//----------------------------------------------------------------------------------------------
{
    NSString *filePath = [self.downloadStore objectForKey:fileIdentifier];
    return filePath ? YES : NO;
}

#pragma mark - File related Helper Functions

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
