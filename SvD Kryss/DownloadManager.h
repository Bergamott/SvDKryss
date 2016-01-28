//
//  DownloadManager.h
//  SvD Kryss
//
//  Created by Karl on 2013-02-07.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    stateNotLoading,
    stateLoadingStoreData,
    stateLoadingPackage
} loadingState;

@class ASINetworkQueue;
@class ASIHTTPRequest;

#define LATEST_UPDATE_PREFS @"latestUpdate"

@interface DownloadManager : NSObject {
    
    ASINetworkQueue *loginDataNetworkQueue;
    ASINetworkQueue *storeDataNetworkQueue;
    
    NSMutableArray *authenticationQueue;
    
    int userID;
    
    BOOL packageDownloadErrorFlag;
    BOOL completionErrorFlag;
    
    // Multiple accounts stuff
    int loginId;
    int defaultId;
    NSString *email;
    NSString *password;
    NSString *registeredEmail;
    BOOL isSubscriber;
    BOOL manualLogin;
    
    int mergeID;
}

+(DownloadManager*)sharedDownloadManager;
-(void)setup;

-(void)queueLoginDataDownloads;
-(void)loginDataFetchComplete:(ASIHTTPRequest*)request;
-(void)loginDataFetchFailed:(ASIHTTPRequest*)request;
-(void)loginDataAllLoaded:(ASINetworkQueue*)queue;

-(void)queueMetadataUpdateDownloads;
-(void)metadataUpdateComplete:(ASIHTTPRequest*)request;
-(void)metadataUpdateFailed:(ASIHTTPRequest*)request;
-(void)metadataUpdateAllLoaded:(ASINetworkQueue*)queue;

-(void)queueStoreDataDownloads;
-(void)storeDataFetchComplete:(ASIHTTPRequest*)request;
-(void)storeDataFetchFailed:(ASIHTTPRequest*)request;
-(void)storeDataAllLoaded:(ASINetworkQueue*)queue;
-(void)cancelStoreDataFetch;

-(void)downloadPackage:(NSDictionary*)pk;
-(void)crosswordFetchComplete:(ASIHTTPRequest*)request;
-(void)crosswordFetchFailed:(ASIHTTPRequest*)request;
-(void)crosswordsAllLoaded:(ASINetworkQueue*)queue;

-(void)completePackage:(NSDictionary*)pk;
-(void)crosswordCompletionComplete:(ASIHTTPRequest*)request;
-(void)crosswordCompletionFailed:(ASIHTTPRequest*)request;
-(void)crosswordsAllCompleted:(ASINetworkQueue*)queue;


-(NSString*)extractFilename:(NSString*)url;
-(void)convertToJSON:(NSDictionary*)dic;
-(NSString*)base64forData:(NSData*)theData;
-(NSData*)base64DataFromString:(NSString*)string;

// Login and update methods
-(void)queueAuthenticationMessage:(NSString*)urlS withTag:(int)tag andData:(NSDictionary*)dic;
-(void)reinsertAuthenticationMessage:(ASIHTTPRequest*)req;
-(void)handleQueue;
-(void)fetchUserID;
-(void)sendCharacterData:(NSString*)base64Data withPercent:(int)pc forID:(int)cwId;
-(void)requestCharacterDataForID:(int)cwId;
-(void)requestNewStoredSolutions;
-(void)requestPurchasedPackages;
-(void)registerPurhcaseID:(NSNumber*)pId withWallet:(NSString*)wal withTransactionId:(NSString*)tid andReceipt:(NSString*)rec;
-(void)copyFieldsFromCrossword:(NSDictionary*)scw toCrossword:(NSMutableDictionary*)cw;

-(void)sendCompetitionData:(NSString*)dat forID:(int)cwId;

-(void)registerEmailAddress:(NSString*)email;

-(void)registerDevice:(NSString*)udid ForPushNotifications:(NSString*)token;

// Help methods for managing multiple accounts
-(void)setLoginId:(int)lid;
-(NSString*)getFullPathNameForFile:(NSString*)fName;
-(NSData*)getUserDataForCrossword:(NSString*)cwS;
-(void)saveUserData:(NSData*)dat forCrossword:(NSString*)cwS;
-(NSString*)getLatestUpdateTime;
-(void)setLatestUpdateTime:(NSObject*)upt;

-(BOOL)authenticate:(BOOL)forced;
-(void)forceAuthenticate;
-(void)makeLogout;
-(void)makeDefaultAuthentication;
-(void)loginWithEmail:(NSString*)eml andPassword:(NSString*)pwd;
-(void)makeLoginAuthentication;
-(void)requestMerge;

-(NSString*)getPriceLabelForPackage:(NSDictionary*)pk;
-(BOOL)isPackageFree:(NSDictionary*)pk;
-(BOOL)isSubscriber;
-(BOOL)isLoggedInWithRealAccount;
-(void)updateRegisteredEmail:(NSString*)eadr;
-(void)getStorePackages;

-(void)verifySessionWithTag:(int)t;

-(void)removeDownloadedCrossword:(NSDictionary*)cDic;

// Special solution for separating basic auth between udid and svd accounts
-(NSString*)getAuthUsername;
-(NSString*)getAuthPassword;

@property(nonatomic,retain) NSMutableArray *authenticationQueue;

@property(nonatomic,retain) NSString *email;
@property(nonatomic,retain) NSString *password;
@property(nonatomic,retain) NSString *registeredEmail;

@end
