//
//  OFRequestManager.m
//  OFRequestManager
//
//  Created by Oliver Franke on 05.07.16.
//  Copyright © 2016 Oliver Franke. All rights reserved.
//

#import "OFRequestManager.h"

@interface OFRequestManager ()

@end

@implementation OFRequestManager

static OFRequestManager *sharedInstance = nil;

//--------------------------------------------------------------------------------
+ (instancetype)sharedManager
//--------------------------------------------------------------------------------
{
    if ( sharedInstance == nil ) {
        sharedInstance = [self new];
    }
    return sharedInstance;
}

//--------------------------------------------------------------------------------
- (instancetype)initWithBaseURL:(NSURL *)url
//--------------------------------------------------------------------------------
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

#pragma mark - Custom Getter

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


#pragma mark - HTTP API

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


@end
