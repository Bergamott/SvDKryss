//
//  DownloadManager.m
//  SvD Kryss
//
//  Created by Karl on 2013-02-07.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "DownloadManager.h"
#import "StoreDataHolder.h"
#import "DataHolder.h"
#import "InAppPurchaseManager.h"
#import "SvDKryssAppDelegate.h"
#import "CustomAlertView.h"

#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"

#import "OpenUDID.h"

#import "Metadata.h"

//#define ROOT_URL @"https://dev.thewebpoker.net/api/v1/"
#define ROOT_URL @"https://api.korsord.proactivegaming.com/v1/"

#define URL_CROSSWORDS ROOT_URL@"crossword/crosswords.json"
#define URL_PACKAGES ROOT_URL@"crossword/packages.json"
#define URL_CATEGORIES ROOT_URL@"crossword/categories.json"
#define URL_OFFERS ROOT_URL@"crossword/storefront.json"

#define URL_UUID_LOGIN ROOT_URL@"auth/session?method=uuidLogin"
#define URL_LOGIN ROOT_URL@"auth/session?method=login"
#define URL_LOGOUT ROOT_URL@"auth/session?method=logout"
//#define URL_USER_SETTINGS ROOT_URL@"account/users/%d/settings/crossword"
#define URL_USER_SETTINGS ROOT_URL@"account/users/%d"

#define URL_UPLOAD ROOT_URL@"crossword/user/%d/solutions/%d"
#define URL_GET_SOLUTION ROOT_URL@"crossword/user/%d/solutions/%d.json"
#define URL_GET_ALL_SOLUTIONS ROOT_URL@"crossword/user/%d/solutions"
#define URL_GET_UPDATES ROOT_URL@"crossword/user/%d/solutions?updatedafter=%@"
#define URL_GET_PURCHASED_PACKAGES ROOT_URL@"crossword/user/%d/packages?idonly"
#define URL_REGISTER_PURCHASE ROOT_URL@"crossword/user/%d/purchases"
#define URL_COMPETITION ROOT_URL@"crossword/user/%d/solutions/%d?method=storeCompetiton"

#define URL_REGISTER_ADDRESS ROOT_URL@"account/users/%d?method=updateContactInfo"

#define URL_REGISTER_PUSH_NOTIFICATIONS ROOT_URL@"device/user/%d/pushUrls"

#define URL_MERGE_DATA ROOT_URL@"crossword/user/%d?method=mergeAccount"

#define URL_VERIFY_SESSION ROOT_URL@"auth/session" // Change later

//#define AUTH_USERNAME @"svdkryss" //#define AUTH_USERNAME @"svddev"
#define AUTH_USERNAME @"svdkryss"
//#define AUTH_PASSWORD @"svdkryss" //#define AUTH_PASSWORD @"svddev"
#define AUTH_PASSWORD @"Chajev9uxTFg"
#define LOGIN_AUTH_USERNAME @"svdprenumerant"
#define LOGIN_AUTH_PASSWORD @"foo"

#define LOGIN_TAG 1
#define UPLOAD_TAG 2
#define GET_SOLUTION_TAG 3
#define NEW_SOLUTIONS_TAG 4
#define PURCHASED_PACKAGES_TAG 5
#define REGISTER_PURCHASE_TAG 6
#define LOGIN_CROSSWORDS_TAG 7
#define COMPLETE_PICTURE_TAG 8
#define COMPLETE_METADATA_TAG 9
#define COMPETITION_TAG 10
#define REGISTER_ADDRESS_TAG 11
#define REGISTER_PUSH_NOTIFICATIONS_TAG 12
#define LOGOUT_TAG 13
#define MERGE_TAG 14
#define USER_SETTINGS_TAG 15
#define SEPARATE_FETCH_PACKAGES_TAG 16
#define VERIFY_BEFORE_STORE 20

@implementation DownloadManager

@synthesize authenticationQueue;

@synthesize email;
@synthesize password;
@synthesize registeredEmail;

+(DownloadManager*)sharedDownloadManager
{
	static DownloadManager *sharedDownloadManager;
	
	@synchronized(self)
	{
		if (!sharedDownloadManager)
			sharedDownloadManager = [[DownloadManager alloc] init];
        
		return sharedDownloadManager;
	}
}

-(void)setup
{
    authenticationQueue = [[NSMutableArray alloc] initWithCapacity:10];
    // Get IDs and stuff
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    userID = (int)[defaults integerForKey:@"userID"];
    loginId = (int)[defaults integerForKey:@"accountID"];
    defaultId = (int)[defaults integerForKey:@"voidID"];
    self.email = [defaults stringForKey:@"email"];
    self.password = [defaults stringForKey:@"password"];
    self.registeredEmail = [defaults stringForKey:@"registeredEmail"];
    isSubscriber = [defaults boolForKey:@"subscriber"];
    
    NSLog(@"userID: %d, loginId: %d, defaultId: %d",userID,loginId,defaultId);
}

#pragma mark -
#pragma mark Login data fetching methods

-(void)queueLoginDataDownloads
{
	if (!loginDataNetworkQueue) {
		loginDataNetworkQueue = [[ASINetworkQueue alloc] init];
	}
	[loginDataNetworkQueue reset];
	[loginDataNetworkQueue setRequestDidFinishSelector:@selector(loginDataFetchComplete:)];
	[loginDataNetworkQueue setRequestDidFailSelector:@selector(loginDataFetchFailed:)];
	[loginDataNetworkQueue setQueueDidFinishSelector:@selector(loginDataAllLoaded:)];
	[loginDataNetworkQueue setDelegate:self];
	
	ASIHTTPRequest *request;
    
    if (userID == loginId && defaultId != 0 && defaultId != userID && manualLogin) // Logging in to SvD, possibly request merge
    {
        // Skip this check. Always merge for manual login
/*        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *tmpS = [defaults objectForKey:@"mergeEmail"];
        if (tmpS == NULL) // Has not merged this account before
        {
            mergeID = defaultId;
            [defaults setObject:email forKey:@"mergeEmail"];
            [defaults synchronize];
        }*/
        mergeID = defaultId;
    }
    if (mergeID != 0) // Should migrate data from a deprecated account or to SvD account the first time
    {
        NSLog(@"Attempting to merge data");
        request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:URL_MERGE_DATA,userID]]];
        request.tag = MERGE_TAG;
        [request setRequestMethod:@"POST"];
        NSError *writeError = nil;
        NSDictionary *tmpDic = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:mergeID],@"sourceUserId", nil];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tmpDic options:NSJSONWritingPrettyPrinted error:&writeError];
        [request setPostBody:[NSMutableData dataWithData:jsonData]];
        [tmpDic release];
        
        [request addBasicAuthenticationHeaderWithUsername:[self getAuthUsername] andPassword:[self getAuthPassword]];
        [loginDataNetworkQueue addOperation:request];
        mergeID = 0;
    }
        
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URL_CROSSWORDS]];
    request.tag = LOGIN_CROSSWORDS_TAG;
    [request addBasicAuthenticationHeaderWithUsername:[self getAuthUsername] andPassword:[self getAuthPassword]];
	[loginDataNetworkQueue addOperation:request];
    
    request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:URL_GET_PURCHASED_PACKAGES,userID]]];
    request.tag = PURCHASED_PACKAGES_TAG;
    [request addBasicAuthenticationHeaderWithUsername:[self getAuthUsername] andPassword:[self getAuthPassword]];
	[loginDataNetworkQueue addOperation:request];
    NSLog(@"Requesting packages for userID %d, auth %@",userID,[self getAuthUsername]);
    
    // Ask for new solution update information
    NSString *timestamp = [self getLatestUpdateTime];
    NSString *tmpUrl;
    if (timestamp != NULL)
    {
        tmpUrl = [NSString stringWithFormat: URL_GET_UPDATES,userID,timestamp];
    }
    else
    {
        tmpUrl = [NSString stringWithFormat: URL_GET_ALL_SOLUTIONS,userID];
    }
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:tmpUrl]];
    request.tag = NEW_SOLUTIONS_TAG;
    [request addBasicAuthenticationHeaderWithUsername:[self getAuthUsername] andPassword:[self getAuthPassword]];
	[loginDataNetworkQueue addOperation:request];
	
    // User settings
    if (loginId != 0 && userID == loginId)
    {
        NSLog(@"Making settings request");
        request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:URL_USER_SETTINGS,userID]]];
        request.tag = USER_SETTINGS_TAG;
        [request addBasicAuthenticationHeaderWithUsername:[self getAuthUsername] andPassword:[self getAuthPassword]];
        [loginDataNetworkQueue addOperation:request];
    }
    
    [loginDataNetworkQueue setMaxConcurrentOperationCount:1];
	[loginDataNetworkQueue go];
}

-(void)loginDataFetchComplete:(ASIHTTPRequest*)request
{
    NSError *err;
    NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[request responseData] options:kNilOptions error:&err];
    
    switch(request.tag)
    {
        case LOGIN_CROSSWORDS_TAG:
        {
            NSLog(@"Login crossword list received");
            [[StoreDataHolder sharedStoreDataHolder] receiveJSONCrosswords:jsonDict];
//            NSLog(@"%@",jsonDict);
            if (jsonDict == NULL)
            {
                NSLog(@"Response length: %lu",(unsigned long)[[request responseData] length]);
                NSLog(@"Response data: %@",[request responseData]);
            }            break;
        }
        case PURCHASED_PACKAGES_TAG:
        {
            [[StoreDataHolder sharedStoreDataHolder] clearPurchases];
            NSLog(@"Login purchased packages list received");
//            NSLog(@"%@",jsonDict);
            NSArray *idList = [jsonDict objectForKey:@"ids"];
            for (NSNumber *tmpN in idList)
                [[StoreDataHolder sharedStoreDataHolder] setAsPurchased:tmpN];
            
            NSArray *packageList = [jsonDict objectForKey:@"packages"];
            for (NSDictionary *tmpPK in packageList)
            {
                NSNumber *tmpID = [tmpPK objectForKey:@"paId"];
                if (![[DataHolder sharedDataHolder] alreadyRegisteredPackage:tmpID])
                    [[DataHolder sharedDataHolder] addPackageAsBought:tmpPK];
                else // Handle updates to the crossword list
                {
                    [[DataHolder sharedDataHolder] updatePackage:tmpID withListOfCrosswords:[tmpPK objectForKey:@"crosswords"]];
                }
            }
            NSLog(@"Trying to save packages");
            [[DataHolder sharedDataHolder] saveMyPackages];
            break;
        }
        case NEW_SOLUTIONS_TAG:
        {
            NSLog(@"List of new solutions received");
            // First save timestamp
            [self setLatestUpdateTime:[jsonDict objectForKey:@"lastUpdate"]];
            
            // Then process the data
            NSArray *tmpA = [jsonDict objectForKey:@"solutions"];
            for (NSDictionary *tmpD in tmpA)
            {
/*                NSNumber *tmpN = [tmpD objectForKey:@"cwId"];
                NSMutableDictionary *cw = [[DataHolder sharedDataHolder] getCrosswordFromID:tmpN];
                if (cw != nil) // Try to store percentage stats if we own this crossword
                {
                    NSData *statsDat = [self base64DataFromString:[tmpD objectForKey:@"statistics"]];
                    NSError *e;
                    NSDictionary *jsonStats = [NSJSONSerialization JSONObjectWithData:statsDat options:nil error:&e];
                    if (jsonStats != nil)
                    {
                        int p = [(NSNumber*)[jsonStats objectForKey:@"percentageComplete"] intValue];
                        NSLog(@"Percentage: %d",p);
                        [[DataHolder sharedDataHolder] setPercentageSolved:p ForCrosswordId:tmpN];
                    }
                    NSNumber *milliseconds = [tmpD objectForKey:@"updated"];
                    [cw setObject:[NSDate dateWithTimeIntervalSince1970:[milliseconds doubleValue]*0.001] forKey:LAST_MODIFIED_TAG];
                }
                NSLog(@"Saving solution data");
                NSString *fileName = [NSString stringWithFormat:@"cwdata%d",[tmpN intValue]];
                NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                NSString *storePath = [applicationDocumentsDir stringByAppendingPathComponent:fileName];
                NSError* error = nil;
                NSData *tmpDat = [self base64DataFromString:[tmpD objectForKey:@"data"]];
                [tmpDat writeToFile:storePath atomically:TRUE];
                if (error != nil)
                    NSLog(@"File save error %@",error);*/

                NSString *serverTime = [tmpD objectForKey:@"updated"];
                NSNumber *cwId = [tmpD objectForKey:@"cwId"];
                NSLog(@"Update for ID %@",cwId);
                NSString *deviceTime = [[DataHolder sharedDataHolder] getLastUploadedForCrosswordId:cwId];
                if (![serverTime isEqualToString:deviceTime])
                {
                    [[DataHolder sharedDataHolder] appendUpdatedSolution:tmpD];
                    NSLog(@"Storing solution");
                }
            }
            [[DataHolder sharedDataHolder] saveUpdatedSolutions];
            [[DataHolder sharedDataHolder] saveMyCrosswords];
            break;
        }
        case USER_SETTINGS_TAG:
        {
//            NSDictionary *tmpD = [jsonDict objectForKey:@"settings"];
            NSLog(@"User settings: %@",jsonDict);
//            NSNumber *tmpN = [tmpD objectForKey:@"is_subscriber"];
//            isSubscriber = ([tmpN intValue] == 1);
            isSubscriber = [[jsonDict objectForKey:@"group"] isEqualToString:@"subscriber"];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:isSubscriber forKey:@"subscriber"];
            [defaults synchronize];
            break;
        }
    }
}

-(void)loginDataFetchFailed:(ASIHTTPRequest*)request
{
    NSLog(@"Failed to load login data for tag %ld",(long)request.tag);
    [loginDataNetworkQueue reset];
    loginDataNetworkQueue = nil;
}

-(void)loginDataAllLoaded:(ASINetworkQueue*)queue
{
    [self queueMetadataUpdateDownloads];
}

#pragma mark -
#pragma mark Metadata update fetching methods

-(void)queueMetadataUpdateDownloads
{
    // Perform check for updated metadata (typically ended competitions)
    NSLog(@"Checking for metadata to update");
    StoreDataHolder *sdh = [StoreDataHolder sharedStoreDataHolder];
    DataHolder *dh = [DataHolder sharedDataHolder];
    NSMutableArray *updatedMetafiles = [[NSMutableArray alloc] init];
    for (NSDictionary *tmpSCW in sdh.storeCrosswords)
    {
        NSNumber *tmpID = [tmpSCW objectForKey:@"cwId"];
        NSMutableDictionary *tmpCW = [dh getCrosswordFromID:tmpID];
        if ([tmpCW objectForKey:@"downloaded"] != nil)
        {
            NSNumber *storeUpdate = [tmpSCW objectForKey:@"updated"];
//            if (storeUpdate != NULL)
//                NSLog(@"Store update for crossword %@: %@",tmpID,storeUpdate);
            NSNumber *ownedUpdate = [tmpCW objectForKey:@"updated"];
//            if (ownedUpdate != NULL)
//                NSLog(@"Owned update: %@",ownedUpdate);
            if ([storeUpdate doubleValue] > [ownedUpdate doubleValue])
            {
                [self copyFieldsFromCrossword:tmpSCW toCrossword:tmpCW];
                // Store ID number of crossword to update
                [updatedMetafiles addObject:tmpID];
                NSLog(@"Crossword %@ needs updating",tmpID);
            }
        }
    }
    [dh saveMyCrosswords];
    if (updatedMetafiles.count > 0)
    {
        ASINetworkQueue *networkQueue = [[ASINetworkQueue alloc] init];
        [networkQueue reset];
        [networkQueue setRequestDidFinishSelector:@selector(metadataUpdateComplete:)];
        [networkQueue setRequestDidFailSelector:@selector(metadataUpdateFailed:)];
        [networkQueue setQueueDidFinishSelector:@selector(metadataUpdateAllLoaded:)];
        [networkQueue setDelegate:self];
        ASIHTTPRequest *request;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *downloadFilePath;
        
        for (NSNumber *tmpID in updatedMetafiles)
        {
            NSDictionary *tmpCW = [[StoreDataHolder sharedStoreDataHolder] getCrosswordFromId:tmpID];
            NSString *tmpMetadataURL = [tmpCW objectForKey:@"metaUrl"];
            request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[tmpMetadataURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            [request setUserInfo:[NSDictionary dictionaryWithObject:tmpID forKey:@"cwId"]];
            downloadFilePath = [documentsDirectory stringByAppendingPathComponent:[self extractFilename: tmpMetadataURL]];
            [request setDownloadDestinationPath:downloadFilePath];
            [networkQueue addOperation:request];
        }
        [networkQueue setMaxConcurrentOperationCount:1];
        [networkQueue go];
    }
    else
        [self metadataUpdateAllLoaded:NULL];
    [updatedMetafiles release];
}

-(void)metadataUpdateComplete:(ASIHTTPRequest*)request
{
    // Set new update timestamp
    NSNumber *cwId = [request.userInfo objectForKey:@"cwId"];
    NSMutableDictionary *tmpCW = [[DataHolder sharedDataHolder] getCrosswordFromID:cwId];
    NSDictionary *tmpSCW = [[StoreDataHolder sharedStoreDataHolder] getCrosswordFromId:cwId];
    [tmpCW setObject:[tmpSCW objectForKey:@"updated"] forKey:@"updated"];
    NSLog(@"Crossword %@ received update",cwId);
}
-(void)metadataUpdateFailed:(ASIHTTPRequest*)request
{
    NSLog(@"Crossword update failed");
}
-(void)metadataUpdateAllLoaded:(ASINetworkQueue*)queue
{
    [[DataHolder sharedDataHolder] saveMyCrosswords];
    
    // All the startup initialization is complete
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate checkNewPackageNotification];
}


#pragma mark -
#pragma mark Store data fetching methods

/**
 Set up a queue with requests to get JSON data from server
 **/
-(void)queueStoreDataDownloads
{
	if (!storeDataNetworkQueue) {
		storeDataNetworkQueue = [[ASINetworkQueue alloc] init];
	}
	[storeDataNetworkQueue reset];
	[storeDataNetworkQueue setRequestDidFinishSelector:@selector(storeDataFetchComplete:)];
	[storeDataNetworkQueue setRequestDidFailSelector:@selector(storeDataFetchFailed:)];
	[storeDataNetworkQueue setQueueDidFinishSelector:@selector(storeDataAllLoaded:)];
	[storeDataNetworkQueue setDelegate:self];
	
	ASIHTTPRequest *request;
	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URL_CROSSWORDS]];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"crosswords" forKey:@"name"]];
    [request addBasicAuthenticationHeaderWithUsername:AUTH_USERNAME andPassword:AUTH_PASSWORD];
	[storeDataNetworkQueue addOperation:request];

	request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URL_PACKAGES]];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"packages" forKey:@"name"]];
    [request addBasicAuthenticationHeaderWithUsername:AUTH_USERNAME andPassword:AUTH_PASSWORD];
	[storeDataNetworkQueue addOperation:request];

    request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URL_CATEGORIES]];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"categories" forKey:@"name"]];
    [request addBasicAuthenticationHeaderWithUsername:AUTH_USERNAME andPassword:AUTH_PASSWORD];
	[storeDataNetworkQueue addOperation:request];
    
    request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URL_OFFERS]];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"offers" forKey:@"name"]];
    [request addBasicAuthenticationHeaderWithUsername:AUTH_USERNAME andPassword:AUTH_PASSWORD];
	[storeDataNetworkQueue addOperation:request];
	
    [storeDataNetworkQueue setMaxConcurrentOperationCount:1];
	[storeDataNetworkQueue go];
}

/**
 Queue request results arrived safely
 **/
-(void)storeDataFetchComplete:(ASIHTTPRequest*)request
{
    NSString *tmpName = [request.userInfo objectForKey:@"name"];
    if ([tmpName isEqualToString:@"crosswords"])
    {
        NSLog(@"Store crossword list received");
        NSError *err;
        NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[request responseData] options:kNilOptions error:&err];
        [[StoreDataHolder sharedStoreDataHolder] receiveJSONCrosswords:jsonDict];
//        NSLog(@"%@",jsonDict);
        if (jsonDict == NULL)
        {
            NSLog(@"Response length: %lu",(unsigned long)[[request responseData] length]);
            NSLog(@"Response data: %@",[request responseData]);
        }
    }
    else if ([tmpName isEqualToString:@"packages"])
    {
        NSLog(@"Store packages list received");
        NSError *err;
        NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[request responseData] options:kNilOptions error:&err];
        [[StoreDataHolder sharedStoreDataHolder] receiveJSONPackages:jsonDict];
//        NSLog(@"%@",jsonDict);
        if (jsonDict == NULL)
        {
            NSLog(@"Response length: %lu",(unsigned long)[[request responseData] length]);
            NSLog(@"Response data: %@",[request responseData]);
        }
    }
    else if ([tmpName isEqualToString:@"categories"])
    {
        NSLog(@"Store categories list received");
       NSError *err;
        NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[request responseData] options:kNilOptions error:&err];
        [[StoreDataHolder sharedStoreDataHolder] receiveJSONCategories:jsonDict];
//        NSLog(@"%@",jsonDict);
        if (jsonDict == NULL)
        {
            NSLog(@"Response length: %lu",(unsigned long)[[request responseData] length]);
            NSLog(@"Response data: %@",[request responseData]);
        }
    }
    else if ([tmpName isEqualToString:@"offers"])
    {
        NSLog(@"Store front list received");
        NSError *err;
        NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[request responseData] options:kNilOptions error:&err];
        [[StoreDataHolder sharedStoreDataHolder] receiveJSONOffers:jsonDict];
//        NSLog(@"%@",jsonDict);
        if (jsonDict == NULL)
        {
            NSLog(@"Response length: %lu",(unsigned long)[[request responseData] length]);
            NSLog(@"Response data: %@",[request responseData]);
        }
    }
}

-(void)storeDataFetchFailed:(ASIHTTPRequest*)request
{
    NSLog(@"Failed to load store data, %@",[request.userInfo objectForKey:@"name"]);
    [self cancelStoreDataFetch];
    [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerStoreGeneralProblem object:self userInfo:nil];
}

-(void)cancelStoreDataFetch
{
    NSLog(@"Cancelling store data fetch");
    if (storeDataNetworkQueue != nil)
    {
        [storeDataNetworkQueue reset];
        storeDataNetworkQueue = nil;
    }
}

/**
 Queue requests all finished
 **/
-(void)storeDataAllLoaded:(ASINetworkQueue*)queue
{
    [[StoreDataHolder sharedStoreDataHolder] removeAlreadyOwnedPackages];
    [[InAppPurchaseManager sharedInAppPurchaseManager] requestPackagesProductData:[[StoreDataHolder sharedStoreDataHolder] getListOfStorePackageIds]];
    
    [self queueMetadataUpdateDownloads]; // Extra check for updated crossword metadata
}

#pragma mark -
#pragma mark Package content download methods

/**
 Set up a queue to download metadata and pictures for all the crosswords in a package
 **/
-(void)downloadPackage:(NSDictionary*)pk
{
    NSLog(@"Trying to download package");
    if (pk == NULL)
        NSLog(@"**** Null package, ignore");
    else
    {
        ASINetworkQueue *networkQueue = [[ASINetworkQueue alloc] init];
        [networkQueue reset];
        [networkQueue setRequestDidFinishSelector:@selector(crosswordFetchComplete:)];
        [networkQueue setRequestDidFailSelector:@selector(crosswordFetchFailed:)];
        [networkQueue setQueueDidFinishSelector:@selector(crosswordsAllLoaded:)];
        [networkQueue setDelegate:self];
        [networkQueue setUserInfo:pk];
        ASIHTTPRequest *request;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *downloadFilePath;
        
        NSArray *tmpCA = [pk objectForKey:@"crosswords"];
        for (NSNumber *tmpID in tmpCA)
        {
            NSUInteger pos = [[StoreDataHolder sharedStoreDataHolder].storeCrosswordIds indexOfObject:tmpID];
            if (pos != NSNotFound)
            {
                NSDictionary *tmpCW = [[StoreDataHolder sharedStoreDataHolder].storeCrosswords objectAtIndex:pos];
                NSString *tmpPictureURL = [tmpCW objectForKey:@"pdfUrl"];
                if (tmpPictureURL == NULL || tmpPictureURL.length == 0)
                    tmpPictureURL = [[tmpCW objectForKey:@"pictureUrl"] stringByReplacingOccurrencesOfString:@".jpg" withString:@".pdf"];
                NSString *tmpMetadataURL = [tmpCW objectForKey:@"metaUrl"];
                
                request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[tmpPictureURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                [request setUserInfo:[NSDictionary dictionaryWithObject:@"picture" forKey:@"name"]];
                downloadFilePath = [documentsDirectory stringByAppendingPathComponent:[self extractFilename: tmpPictureURL]];
                [request setDownloadDestinationPath:downloadFilePath];
                [networkQueue addOperation:request];
                
                request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[tmpMetadataURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                [request setUserInfo:[NSDictionary dictionaryWithObject:@"metadata" forKey:@"name"]];
                downloadFilePath = [documentsDirectory stringByAppendingPathComponent:[self extractFilename: tmpMetadataURL]];
                [request setDownloadDestinationPath:downloadFilePath];
                [networkQueue addOperation:request];
            }
        }
        packageDownloadErrorFlag = FALSE;
        [networkQueue setMaxConcurrentOperationCount:1];
        [networkQueue go];
    }
}

-(void)crosswordFetchComplete:(ASIHTTPRequest*)request
{
    NSString *tmpS = [request.userInfo objectForKey:@"name"];
    if ([tmpS isEqualToString:@"picture"])
        NSLog(@"Downloaded crossword picture");
    else
        NSLog(@"Downloaded crossword metadata");
}

-(void)crosswordFetchFailed:(ASIHTTPRequest*)request
{
    NSLog(@"Failed to load crossword");
    packageDownloadErrorFlag = TRUE;
}

/**
 All crosswords have been successfully downloaded
 **/
-(void)crosswordsAllLoaded:(ASINetworkQueue*)queue
{
    if (packageDownloadErrorFlag)
    {
        // Show some kind of error alert here
        UIAlertView *message = [[CustomAlertView alloc] initWithTitle:nil message:@"Nedladdningen misslyckades. Kan bero på nätverksproblem." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [message show];
    }
    else
    {
        // Everything worked fine
        NSLog(@"Downloaded entire package\n%@",queue.userInfo);
        NSLog(@"Storing data ...");
        [[DataHolder sharedDataHolder] addPackageFromStore:queue.userInfo];
        NSNumber *tmpID = [queue.userInfo objectForKey:@"paId"];
        [[StoreDataHolder sharedStoreDataHolder] doneDownloading:tmpID];
        NSLog(@"Done.");
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerDownloadComplete object:self userInfo:queue.userInfo];
    }
    [queue release];
}


#pragma mark -
#pragma mark Package content completion methods

-(void)completePackage:(NSDictionary*)pk
{
    NSLog(@"Completing package");
	ASINetworkQueue *networkQueue = [[ASINetworkQueue alloc] init];
	[networkQueue reset];
	[networkQueue setRequestDidFinishSelector:@selector(crosswordCompletionComplete:)];
	[networkQueue setRequestDidFailSelector:@selector(crosswordCompletionFailed:)];
	[networkQueue setQueueDidFinishSelector:@selector(crosswordsAllCompleted:)];
	[networkQueue setDelegate:self];
    [networkQueue setUserInfo:pk];
	ASIHTTPRequest *request;
    
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *downloadFilePath;
    
    NSArray *tmpCA = [pk objectForKey:@"crosswords"];
    for (NSNumber *tmpID in tmpCA)
    {
        NSMutableDictionary *tmpCW = [[DataHolder sharedDataHolder] getCrosswordFromID:tmpID];
        if (tmpCW != nil && ![[DataHolder sharedDataHolder] hasThisCrosswordBeenDownloaded:tmpCW])
        {
            NSString *tmpPictureURL = [tmpCW objectForKey:@"pdfUrl"];
            if (tmpPictureURL == NULL || tmpPictureURL.length == 0)
                tmpPictureURL = [[tmpCW objectForKey:@"pictureUrl"] stringByReplacingOccurrencesOfString:@".jpg" withString:@".pdf"];
            NSString *tmpMetadataURL = [tmpCW objectForKey:@"metaUrl"];
        
            request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[tmpPictureURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            request.tag = COMPLETE_PICTURE_TAG;
            downloadFilePath = [documentsDirectory stringByAppendingPathComponent:[self extractFilename: tmpPictureURL]];
            [request setDownloadDestinationPath:downloadFilePath];
            [networkQueue addOperation:request];
            [tmpCW setObject:[self extractFilename: tmpPictureURL] forKey:@"pdf"];
        
            request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[tmpMetadataURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            request.tag = COMPLETE_METADATA_TAG;
            [request setUserInfo:[NSDictionary dictionaryWithObject:tmpCW forKey:@"crossword"]];
            downloadFilePath = [documentsDirectory stringByAppendingPathComponent:[self extractFilename: tmpMetadataURL]];
            [request setDownloadDestinationPath:downloadFilePath];
            [networkQueue addOperation:request];
            [tmpCW setObject:[self extractFilename: tmpMetadataURL] forKey:@"metadata"];
        }
    }
    completionErrorFlag = FALSE;
    [networkQueue setMaxConcurrentOperationCount:1];
	[networkQueue go];
}

-(void)crosswordCompletionComplete:(ASIHTTPRequest*)request
{
    if (request.tag == COMPLETE_METADATA_TAG) // Mark as completely downloaded
    {
        NSMutableDictionary *tmpD = [request.userInfo objectForKey:@"crossword"];
        [tmpD setObject:@"true" forKey:@"downloaded"];
        [[DataHolder sharedDataHolder] setCrosswordAsDownloaded:tmpD];
        [[DataHolder sharedDataHolder] integrateStoredSolution:tmpD];
        SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
        [delegate completionDownloadProgress:FALSE];
    }
}
-(void)crosswordCompletionFailed:(ASIHTTPRequest*)request
{
    NSLog(@"crosswordCompletionFailed");
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate completionDownloadProgress:TRUE];
    completionErrorFlag = TRUE;
}
-(void)crosswordsAllCompleted:(ASINetworkQueue*)queue
{
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate completionDownloadProgress:TRUE];
    if (completionErrorFlag)
    {
        UIAlertView *message = [[CustomAlertView alloc] initWithTitle:nil message:@"Nedladdning ej möjlig just nu – ingen kontakt med servern." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [message show];
    }
    else
    {
        NSLog(@"Package completed. Saving updated crossword data.");
        [[DataHolder sharedDataHolder] saveMyCrosswords];
    }
}


#pragma mark -
#pragma mark Login and update methods

-(void)queueAuthenticationMessage:(NSString*)urlS withTag:(int)tag andData:(NSDictionary*)dic
{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlS]];
    if (dic != NULL)
    {
        [request setRequestMethod:@"POST"];
        NSError *writeError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&writeError];
        [request setPostBody:[NSMutableData dataWithData:jsonData]];
    }
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request addBasicAuthenticationHeaderWithUsername:[self getAuthUsername] andPassword:[self getAuthPassword]];
    [request setDelegate:self];
    request.tag = tag;
    [authenticationQueue addObject:request];
}

-(void)handleQueue
{
    NSLog(@"Handling queue");
    if ([authenticationQueue count] > 0)
    {
        ASIHTTPRequest *request = [authenticationQueue objectAtIndex:0];
        
        NSLog(@"Calling %@",request.url);
        [request startAsynchronous];
        [authenticationQueue removeObject:request];
    }
}

-(void)reinsertAuthenticationMessage:(ASIHTTPRequest*)req
{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:req.url];
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request addBasicAuthenticationHeaderWithUsername:[self getAuthUsername] andPassword:[self getAuthPassword]];
    [request setDelegate:self];
    request.tag = req.tag;
    if ([req.requestMethod isEqualToString:@"POST"])
    {
        [request setRequestMethod:@"POST"];
        [request setPostBody:[req postBody]];
    }
    [authenticationQueue insertObject:request atIndex:0];
//    userID = 0;
//    [self fetchUserID];
}

-(void)fetchUserID
{
	if (userID == 0)
    {
        NSDictionary *tmpD = [[NSDictionary alloc] initWithObjectsAndKeys:[OpenUDID value], @"uuid", nil];
        NSError *writeError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tmpD options:NSJSONWritingPrettyPrinted error:&writeError];

        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URL_LOGIN]];
        [request setRequestMethod:@"POST"];
        [request addRequestHeader:@"Accept" value:@"application/json"];
        [request addBasicAuthenticationHeaderWithUsername:AUTH_USERNAME andPassword:AUTH_PASSWORD];
        [request setPostBody:[NSMutableData dataWithData:jsonData]];
        [request setDelegate:self];
        request.tag = LOGIN_TAG;
        NSLog(@"Calling fetchUserID, %@",request.url);
        [request startAsynchronous];
        [tmpD release];
    }
}

/*- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSError *err;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[request responseData] options:kNilOptions error:&err];
    NSString *tmpE = [jsonDict objectForKey:@"error"];
    if ([tmpE isEqualToString:@"NOT_LOGGED_IN"])
    {
        NSLog(@"Not logged in. Re-sending.");
        [self reinsertAuthenticationMessage:request];
    }
    else
    {
        switch(request.tag)
        {
            case LOGIN_TAG:
            {
                NSLog(@"Successfully logged in");
                NSDictionary *userContext = [jsonDict objectForKey:@"userContext"];
                userID = [(NSNumber*)[userContext objectForKey:@"userId"] intValue];
                
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                [prefs setInteger:userID forKey:@"userID"];
                NSString *token = [prefs objectForKey:@"apstoken"];
                if (token != NULL && ![prefs boolForKey:@"apstokensent"])
                {
                    [self registerDevice:[OpenUDID value] ForPushNotifications:token];
                }
                [prefs synchronize];

                [self queueLoginDataDownloads];
                
                break;
            }
            case UPLOAD_TAG:
                NSLog(@"Successfully uploaded");
                // Store timestamp
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                [prefs setObject:[jsonDict objectForKey:@"updated"] forKey:LATEST_UPLOAD_PREFS];
                [prefs synchronize];
                break;
            case GET_SOLUTION_TAG:
            {
                NSLog(@"Got solution response");
                break;
            }
            case NEW_SOLUTIONS_TAG:
            {
                NSLog(@"List of new solutions since last upload");
                // First save timestamp
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                [prefs setObject:[jsonDict objectForKey:@"lastUpdate"] forKey:LATEST_UPLOAD_PREFS];
                [prefs synchronize];
                
                // Then process the data
                NSArray *tmpA = [jsonDict objectForKey:@"solutions"];
                for (NSDictionary *tmpD in tmpA)
                {
                    NSNumber *tmpN = [tmpD objectForKey:@"cwId"];
                    NSMutableDictionary *cw = [[DataHolder sharedDataHolder] getCrosswordFromID:tmpN];
                    if (cw != nil) // Make sure we actually have this crossword stored or downloaded
                    {
                        NSLog(@"Received data %@",[tmpD objectForKey:@"data"]);
                        NSData *tmpDat = [self base64DataFromString:[tmpD objectForKey:@"data"]];
                        Metadata *tmpM = [[Metadata alloc] init];
                        
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *documentsDirectory = [paths objectAtIndex:0];
                        NSData *crosswordData = NULL;
                        NSString *localMetadata = [cw objectForKey:@"local-metadata"];
                        if (localMetadata != nil)
                        {
                            NSString *filePath = [[NSBundle mainBundle] pathForResource:localMetadata ofType:@"xwd"];
                            crosswordData = [NSData dataWithContentsOfFile:filePath];
                        }
                        else
                        {
                            NSString *fileS = [cw objectForKey:@"metadata"];
                            NSString *localFilePath = [documentsDirectory stringByAppendingPathComponent:fileS];
                            crosswordData = [NSData dataWithContentsOfFile:localFilePath];
                        }
                       
                        [tmpM setupWithData:crosswordData];
                        [tmpM setUserDataFromData:tmpDat];
                        [tmpM saveFilledInCharactersAs:[NSString stringWithFormat:@"cwdata%d",[tmpN intValue]]];
                       int p = [tmpM getFilledInPercent];
                        if (p > 0)
                            [cw setObject:[NSString stringWithFormat:@"%d",p] forKey:PERCENTAGE_SOLVED_TAG];
                        else
                            [cw removeObjectForKey:PERCENTAGE_SOLVED_TAG];
                        
                        [tmpM release];
                    }
                    else // Save directly and perhaps use later
                    {
                        NSLog(@"Saving solution data for non-existent crossword");
                        NSString *fileName = [NSString stringWithFormat:@"cwdata%d",[tmpN intValue]];
                        NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                        NSString *storePath = [applicationDocumentsDir stringByAppendingPathComponent:fileName];
                        NSError* error = nil;
                        NSData *tmpDat = [self base64DataFromString:[tmpD objectForKey:@"data"]];
                        [tmpDat writeToFile:storePath atomically:TRUE];
                        if (error != nil)
                            NSLog(@"File save error %@",error);
                    }
                }
                [[DataHolder sharedDataHolder] saveMyCrosswords];
                break;
            }
            case PURCHASED_PACKAGES_TAG:
            {
                NSArray *idList = [jsonDict objectForKey:@"ids"];
                for (NSNumber *tmpN in idList)
                    [[StoreDataHolder sharedStoreDataHolder] setAsPurchased:tmpN];
//                [[InAppPurchaseManager sharedInAppPurchaseManager] requestPackagesProductData:[[StoreDataHolder sharedStoreDataHolder] getListOfStorePackageIds]];

                break;
            }
            case REGISTER_PURCHASE_TAG:
            {
                NSNumber *pkID = [jsonDict objectForKey:@"kindId"];
                NSLog(@"Trying to download package %d",[pkID intValue]);
                [self downloadPackage:[[StoreDataHolder sharedStoreDataHolder] getPackageFromId:pkID]];
                break;
            }
            case COMPETITION_TAG:
            {
                // Confirm response here
                
                break;
            }
            case REGISTER_ADDRESS_TAG:
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadManagerRegisteredAddressNotification object:self userInfo:nil];
                break;
            }
            case REGISTER_PUSH_NOTIFICATIONS_TAG:
                if (request.responseStatusCode == 200) // All OK, mark as sent and received
                {
                    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                    [prefs setBool:TRUE forKey:@"apstokensent"];
                    [prefs synchronize];
                }
                break;
            default:
                break;
        }
        NSLog(@"%@",jsonDict);
        [self handleQueue];
    }
}*/

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    NSError *err;
    NSDictionary *jsonDict = NULL;
    if ([request responseData] != NULL)
        jsonDict = [NSJSONSerialization JSONObjectWithData:[request responseData] options:kNilOptions error:&err];
    NSLog(@"Error: %@",error);
    [authenticationQueue removeAllObjects];
    switch (request.tag) {
        case PURCHASED_PACKAGES_TAG: // Fail during store connect
            [loginDataNetworkQueue reset];
            loginDataNetworkQueue = nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerStoreGeneralProblem object:self userInfo:nil];
            break;
        case REGISTER_PURCHASE_TAG: // Probably not connected when trying to buy free package
            NSLog(@"Purchase failed");
            [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionFailedNotification object:self userInfo:nil];
            break;
        case COMPETITION_TAG:
        {
            CustomAlertView *alert = [[CustomAlertView alloc] initWithTitle:@"Problem att skicka in"
                                                                    message:@"Det gick inte att skicka in tävlingsbidraget. Kontrollera att uppkopplingen till Internet fungerar."
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
            [alert show];
            [alert release];
            break;
        }
        case LOGIN_TAG:
        {
 /*           if ([error code] == ASIRequestTimedOutErrorType || ([error code] == ASIConnectionFailureErrorType && self.password != NULL))
            {
                CustomAlertView *alert = [[CustomAlertView alloc] initWithTitle:@"Uppkopplingen misslyckades"
                                                                        message:@"Det gick ej att ansluta mot servern. Vänligen försök igen."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                [alert show];
                [alert release];
            }
            SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
            [delegate hideLoginIndicator];*/
            
            
            NSString *tmpE = [jsonDict objectForKey:@"error"];
            SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
            if ([tmpE isEqualToString:@"TIMEOUT"] || ([error code] ==ASIConnectionFailureErrorType && self.password != NULL)) // Login timeout or connection failure
            {
                CustomAlertView *alert = [[CustomAlertView alloc] initWithTitle:@"Uppkopplingen misslyckades"
                                                                        message:@"Det gick ej att ansluta mot servern. Vänligen försök igen."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                [alert show];
                [alert release];
                [delegate hideLoginIndicator];
            }
            else // Normal login fail
            {
                [delegate successfullyLoggedOut];
                // Clear password data
                self.password = NULL;
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                [prefs removeObjectForKey:@"password"];
                [prefs synchronize];
                if (loginId != 0) // Has been logged in before
                {
                    // Show message with option to migrate back
                    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
                    [delegate automaticLoginFailed];
                    
                    // Return to default account
                    loginId = 0;
                    [[DataHolder sharedDataHolder] loadEverything];
                }
                else // if (manualLogin)
                {
                    CustomAlertView *alert = [[CustomAlertView alloc] initWithTitle:@"Inloggning misslyckades"
                                                                            message:@"Felaktig e-postadress eller lösenord. Vänligen försök igen, tryck på \"Glömt lösenord\" eller besök svd.se/kundservice för hjälp."
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"OK"
                                                                  otherButtonTitles:nil];
                    [alert show];
                    [alert release];
                }
            }
            manualLogin = FALSE;
            
            break;
        }
        default:
            break;
    }
}

-(void)sendCharacterData:(NSString*)base64Data withPercent:(int)pc forID:(int)cwId
{
    if (userID != 0)
    {
        NSLog(@"Sending %d percent solved for crossword ID %d and user %d and auth %@",pc,cwId,userID,[self getAuthUsername]);
/*        NSString *jsonString = [NSString stringWithFormat:@"{\"percentageComplete\" : %d}",pc];
        NSData *pData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSString *p64 = [self base64forData:pData];
        
        NSDictionary *tmpD = [[NSDictionary alloc] initWithObjectsAndKeys:base64Data, @"data", p64, @"statistics", nil];*/
        
        NSDictionary *tmpD = [[NSDictionary alloc] initWithObjectsAndKeys:base64Data, @"data", [[UIDevice currentDevice] name], @"deviceName", [NSNumber numberWithInt:pc], @"percentageSolved", nil];
        
        NSString *tmpUrl = [NSString stringWithFormat: URL_UPLOAD,userID,cwId];
        [self queueAuthenticationMessage:tmpUrl withTag:UPLOAD_TAG andData:tmpD];
        [self handleQueue];
        [tmpD release];
    }
    else
        [self fetchUserID];
}

-(void)sendCompetitionData:(NSString*)dat forID:(int)cwId
{
    if (userID != 0)
    {
        NSLog(@"Sending competition entry");
        
        NSDictionary *tmpD = [[NSDictionary alloc] initWithObjectsAndKeys:dat, @"data", nil];
        NSString *tmpUrl = [NSString stringWithFormat: URL_COMPETITION,userID,cwId];
        [self queueAuthenticationMessage:tmpUrl withTag:COMPETITION_TAG andData:tmpD];
        [self handleQueue];
        [tmpD release];
    }
    else
        [self fetchUserID];
}

-(void)requestCharacterDataForID:(int)cwId
{
    if (userID != 0)
    {
        NSString *tmpUrl = [NSString stringWithFormat: URL_UPLOAD,userID,cwId];
        [self queueAuthenticationMessage:tmpUrl withTag:GET_SOLUTION_TAG andData:NULL];
        [self handleQueue];
    }
    else
        [self fetchUserID];
}

-(void)requestNewStoredSolutions
{
    if (userID != 0)
    {
        NSString *timestamp = [self getLatestUpdateTime];
        NSString *tmpUrl;
        if (timestamp != NULL)
        {
            tmpUrl = [NSString stringWithFormat: URL_GET_UPDATES,userID,timestamp];
        }
        else
        {
            tmpUrl = [NSString stringWithFormat: URL_GET_ALL_SOLUTIONS,userID];
        }
        [self queueAuthenticationMessage:tmpUrl withTag:NEW_SOLUTIONS_TAG andData:NULL];
        [self handleQueue];
    }
    else
        [self fetchUserID];
}

-(void)requestPurchasedPackages
{
    NSLog(@"Requesting purchased packages");
    if (userID != 0)
    {
        NSString *tmpUrl = [NSString stringWithFormat: URL_GET_PURCHASED_PACKAGES,userID];
        [self queueAuthenticationMessage:tmpUrl withTag:PURCHASED_PACKAGES_TAG andData:NULL];
        [self handleQueue];
    }
    else
        [self fetchUserID];
}

-(void)registerPurhcaseID:(NSNumber*)pId withWallet:(NSString*)wal withTransactionId:(NSString*)tid andReceipt:(NSString*)rec
{
    if (userID != 0)
    {
        NSString *tmpUrl = [NSString stringWithFormat: URL_REGISTER_PURCHASE,userID];
        NSDictionary *tmpD = [NSDictionary dictionaryWithObjectsAndKeys:tid, @"txid",
                              wal, @"wallet", @"crossword_package", @"kind", pId, @"kindid",
                              rec, @"receipt", nil];
        [self queueAuthenticationMessage:tmpUrl withTag:REGISTER_PURCHASE_TAG andData:tmpD];
        [self handleQueue];
    }
    else
        [self fetchUserID];
}


-(void)registerEmailAddress:(NSString*)eaddr
{
    if (userID != 0)
    {
        NSString *tmpUrl = [NSString stringWithFormat: URL_REGISTER_ADDRESS,userID];
        NSDictionary *tmpD = [NSDictionary dictionaryWithObjectsAndKeys:eaddr, @"email", nil];
        [self queueAuthenticationMessage:tmpUrl withTag:REGISTER_ADDRESS_TAG andData:tmpD];
        [self handleQueue];
    }
    else
        [self fetchUserID];
}

-(void)registerDevice:(NSString*)udid ForPushNotifications:(NSString*)token
{
    if (userID != 0)
    {
        NSString *tmpUrl = [NSString stringWithFormat: URL_REGISTER_PUSH_NOTIFICATIONS,userID];
        NSDictionary *tmpD = [NSDictionary dictionaryWithObjectsAndKeys:@"ios", @"platformid",
                              udid, @"deviceuuid", @"se.svd.korsord", @"appidentifier",
                              token, @"url", nil];
        [self queueAuthenticationMessage:tmpUrl withTag:REGISTER_PUSH_NOTIFICATIONS_TAG andData:tmpD];
        [self handleQueue];
    }
    else
        [self fetchUserID];
}

-(void)copyFieldsFromCrossword:(NSDictionary*)scw toCrossword:(NSMutableDictionary*)cw
{
    // Update metadata link and other stuff
    NSString *metaURL = [scw objectForKey:@"metaUrl"];
    [cw setObject:metaURL forKey:@"metaUrl"];
    [cw setObject:[self extractFilename:metaURL] forKey:@"metadata"];
    [cw setObject:[scw objectForKey:@"updated"] forKey:@"updated"];
}

#pragma mark -
#pragma Multiple accounts methods

-(void)setLoginId:(int)lid
{
    loginId = lid;
}

-(NSString*)getFullPathNameForFile:(NSString*)fName
{
    NSString *pName = NULL;
    NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    if (loginId != 0 && userID == loginId)
//        pName = [applicationDocumentsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%d/%@",loginId,fName]];
        pName = [applicationDocumentsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%d%@",loginId,fName]];
    else
        pName = [applicationDocumentsDir stringByAppendingPathComponent:fName];
    NSLog(@"Pathname %@",pName);
    return pName;
}

-(NSData*)getUserDataForCrossword:(NSString*)cwS
{
/*    NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *storePath = NULL;
    NSData *userData = NULL;
    if (loginId != 0)
        storePath = [applicationDocumentsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%d/%@",loginId,cwS]];
    else
        storePath = [applicationDocumentsDir stringByAppendingPathComponent:cwS];*/
    NSData *userData = [NSData dataWithContentsOfFile:[self getFullPathNameForFile:cwS]];
/*    if (userData == NULL && loginId != 0)
    {
        // Try again, without account id
        storePath = [applicationDocumentsDir stringByAppendingPathComponent:cwS];
        userData = [NSData dataWithContentsOfFile:storePath];
    }*/
    return userData;
}

-(void)saveUserData:(NSData*)dat forCrossword:(NSString*)cwS
{
/*    NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *storePath;
    if (loginId != 0)
        storePath = [applicationDocumentsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%d/%@",loginId,cwS]];
    else
        storePath = [applicationDocumentsDir stringByAppendingPathComponent:cwS];*/
    NSError* error = nil;
    [dat writeToFile:[self getFullPathNameForFile:cwS] atomically:TRUE];
    if (error != nil)
        NSLog(@"File save error %@",error);
}

-(NSString*)getLatestUpdateTime
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if (loginId != 0)
        return [prefs stringForKey:[NSString stringWithFormat:@"%d%@",loginId,LATEST_UPDATE_PREFS]];
    else
        return [prefs stringForKey:LATEST_UPDATE_PREFS];
}

-(void)setLatestUpdateTime:(NSObject*)upt
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if (loginId != 0)
        [prefs setObject:upt forKey:[NSString stringWithFormat:@"%d%@",loginId,LATEST_UPDATE_PREFS]];
    else
        [prefs setObject:upt forKey:LATEST_UPDATE_PREFS];
    [prefs synchronize];
}

#pragma mark -
#pragma Helper methods

-(NSString*)extractFilename:(NSString*)url
{
    int i = (int)[url length];
    while ([url characterAtIndex:i-1] != '/')
        i--;
    return [url substringFromIndex:i];
}

-(void)convertToJSON:(NSDictionary*)dic
{
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&err];
    NSString *tmpS = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"%@",tmpS);
    [tmpS release];
}

-(NSString*)base64forData:(NSData*)theData {
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
}

-(NSData*)base64DataFromString:(NSString*)string
{
    unsigned long ixtext, lentext;
    unsigned char ch, inbuf[4] = {}, outbuf[3];
    short i, ixinbuf;
    Boolean flignore, flendtext = false;
    const unsigned char *tempcstring;
    NSMutableData *theData;
    
    if (string == nil)
    {
        return [NSData data];
    }
    
    ixtext = 0;
    
    tempcstring = (const unsigned char *)[string UTF8String];
    
    lentext = [string length];
    
    theData = [NSMutableData dataWithCapacity: lentext];
    
    ixinbuf = 0;
    
    while (true)
    {
        if (ixtext >= lentext)
        {
            break;
        }
        
        ch = tempcstring [ixtext++];
        
        flignore = false;
        
        if ((ch >= 'A') && (ch <= 'Z'))
        {
            ch = ch - 'A';
        }
        else if ((ch >= 'a') && (ch <= 'z'))
        {
            ch = ch - 'a' + 26;
        }
        else if ((ch >= '0') && (ch <= '9'))
        {
            ch = ch - '0' + 52;
        }
        else if (ch == '+')
        {
            ch = 62;
        }
        else if (ch == '=')
        {
            flendtext = true;
        }
        else if (ch == '/')
        {
            ch = 63;
        }
        else
        {
            flignore = true;
        }
        
        if (!flignore)
        {
            short ctcharsinbuf = 3;
            Boolean flbreak = false;
            
            if (flendtext)
            {
                if (ixinbuf == 0)
                {
                    break;
                }
                
                if ((ixinbuf == 1) || (ixinbuf == 2))
                {
                    ctcharsinbuf = 1;
                }
                else
                {
                    ctcharsinbuf = 2;
                }
                
                ixinbuf = 3;
                
                flbreak = true;
            }
            
            inbuf [ixinbuf++] = ch;
            
            if (ixinbuf == 4)
            {
                ixinbuf = 0;
                
                outbuf[0] = (inbuf[0] << 2) | ((inbuf[1] & 0x30) >> 4);
                outbuf[1] = ((inbuf[1] & 0x0F) << 4) | ((inbuf[2] & 0x3C) >> 2);
                outbuf[2] = ((inbuf[2] & 0x03) << 6) | (inbuf[3] & 0x3F);
                
                for (i = 0; i < ctcharsinbuf; i++)
                {
                    [theData appendBytes: &outbuf[i] length: 1];
                }
            }
            
            if (flbreak)
            {
                break;
            }
        }
    }
    
    return theData;
}

// Called when the application becomes active
-(BOOL)authenticate:(BOOL)forced
{
    BOOL mustAuthenticate = forced;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (!forced)
    {
/*        NSDate *lastAuthentication = (NSDate*)[defaults objectForKey:@"last_authentication"];
        if (lastAuthentication == NULL)
            mustAuthenticate = TRUE;
        else if ([lastAuthentication timeIntervalSinceNow] < -180.0)*/
/*        else if (![[NSDateFormatter localizedStringFromDate:lastAuthentication dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterNoStyle] isEqualToString:[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterNoStyle]])*/
        
        NSDate *lastActive = (NSDate*)[defaults objectForKey:@"lastActive"];
        if (lastActive == NULL || [lastActive timeIntervalSinceNow] < -180.0)
            mustAuthenticate = TRUE;
    }
    if (mustAuthenticate)
    {
        if (password != NULL)
        {
            [self makeLoginAuthentication];
        }
        else
        {
            [self makeDefaultAuthentication];
        }
    }
    return mustAuthenticate; // Let caller know that we are logging in
}

-(void)forceAuthenticate
{
    [self authenticate:TRUE];
}

-(void)makeDefaultAuthentication
{
    NSDictionary *tmpD = [[NSDictionary alloc] initWithObjectsAndKeys:[OpenUDID value], @"uuid", nil];
    NSError *writeError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tmpD options:NSJSONWritingPrettyPrinted error:&writeError];
    NSLog(@"Making default authentication with %@",tmpD);
    [tmpD release];
    
    [ASIHTTPRequest setSessionCookies:nil];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URL_UUID_LOGIN]];
    [request setRequestMethod:@"POST"];
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request addBasicAuthenticationHeaderWithUsername:AUTH_USERNAME andPassword:AUTH_PASSWORD];
    [request setPostBody:[NSMutableData dataWithData:jsonData]];
    [request setDelegate:self];
    request.tag = LOGIN_TAG;
    [request startAsynchronous];
    
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate showLoginIndicator];
}

-(void)loginWithEmail:(NSString*)eml andPassword:(NSString*)pwd
{
    manualLogin = TRUE;
    self.email = eml;
    self.password = pwd;
    [self makeLoginAuthentication];
}

-(void)makeLoginAuthentication
{
    NSDictionary *tmpD = [[NSDictionary alloc] initWithObjectsAndKeys:email, @"username", password, @"password", nil];
    NSError *writeError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tmpD options:NSJSONWritingPrettyPrinted error:&writeError];
    NSLog(@"Making login authentication with %@",tmpD);
    [tmpD release];
    
    [ASIHTTPRequest setSessionCookies:nil];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URL_LOGIN]];
    [request setRequestMethod:@"POST"];
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request addBasicAuthenticationHeaderWithUsername:LOGIN_AUTH_USERNAME andPassword:LOGIN_AUTH_PASSWORD];
    [request setPostBody:[NSMutableData dataWithData:jsonData]];
    [request setDelegate:self];
    [request setTimeOutSeconds:30];
    request.tag = LOGIN_TAG;
    [request startAsynchronous];
    
    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
    [delegate showLoginIndicator];
}

-(void)makeLogout
{
    NSLog(@"Making logout (client side only)");
/*    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URL_LOGOUT]];
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request addBasicAuthenticationHeaderWithUsername:LOGIN_AUTH_USERNAME andPassword:LOGIN_AUTH_PASSWORD];
//    [request addBasicAuthenticationHeaderWithUsername:[self getAuthUsername] andPassword:[self getAuthPassword]];
    [request setDelegate:self];
    request.tag = LOGOUT_TAG;
    [request startAsynchronous];*/
    self.password = NULL;
    loginId = 0;
    [self makeDefaultAuthentication];
}

-(void)requestMerge
{
    self.password = NULL;
    mergeID = loginId;
    loginId = 0;
    [self setLatestUpdateTime:[NSNumber numberWithInt:0]]; // Treat all solutions as new
    [self makeDefaultAuthentication];
}

-(void)requestFinished:(ASIHTTPRequest *)request
{
    NSError *err;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[request responseData] options:kNilOptions error:&err];
    NSString *tmpE = [jsonDict objectForKey:@"error"];
    if (tmpE != NULL)
    {
        NSLog(@"Problem with request: %@",tmpE);
        if (request.tag == LOGIN_TAG) // Login itself failed
        {
            SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
            if ([tmpE isEqualToString:@"TIMEOUT"]) // Login timeout
            {
                CustomAlertView *alert = [[CustomAlertView alloc] initWithTitle:@"Uppkopplingen misslyckades"
                                                                        message:@"Det gick ej att ansluta mot servern. Vänligen försök igen."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                [alert show];
                [alert release];
                [delegate hideLoginIndicator];
            }
            else // Normal login fail
            {
                [delegate successfullyLoggedOut];
                // Clear password data
                self.password = NULL;
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                [prefs removeObjectForKey:@"password"];
                [prefs synchronize];
                if (loginId != 0) // Has been logged in before
                {
                    // Show message with option to migrate back
                    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
                    [delegate automaticLoginFailed];
                    
                    // Return to default account
                    loginId = 0;
                    [[DataHolder sharedDataHolder] loadEverything];
                }
                else // if (manualLogin)
                {
                    CustomAlertView *alert = [[CustomAlertView alloc] initWithTitle:@"Inloggning misslyckades"
                                                                            message:@"Felaktig e-postadress eller lösenord. Vänligen försök igen, tryck på \"Glömt lösenord\" eller besök svd.se/kundservice för hjälp."
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"OK"
                                                                  otherButtonTitles:nil];
                    [alert show];
                    [alert release];
                }
            }
            manualLogin = FALSE;
        }
        else
        {
            // Not logged in. We need to authenticate again
            [self forceAuthenticate];
            [self reinsertAuthenticationMessage:request];
        }
    }
    else
    {
        switch(request.tag)
        {
            case LOGIN_TAG:
            {
                NSLog(@"Successfully");
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                NSDictionary *userContext = [jsonDict objectForKey:@"userContext"];
                userID = [(NSNumber*)[userContext objectForKey:@"userId"] intValue];
                if (email != NULL && password != NULL) // We must have logged in to an existing account
                {
                    loginId = userID;
                    NSLog(@"Logged in to account");
                    // Save username and password to preferences
                    [prefs setObject:email forKey:@"email"];
                    [prefs setObject:password forKey:@"password"];
                    [prefs setInteger:loginId forKey:@"accountID"];
                    // Switch menu screen button to "Logout"
                    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
                    [delegate successfullyLoggedIn:manualLogin];
                    
/*                    if (manualLogin)
                    // Show confirmation dialog
                    {
                        CustomAlertView *alert = [[CustomAlertView alloc] initWithTitle:@"Du är nu inloggad"
                                                                        message:@"Dina korsord och lösningar blir nu tillgängliga på samtliga enheter som använder ditt SvD-konto."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                        [alert release];
                    }*/
                    
                }
                else
                {
                    defaultId = userID;
                    NSLog(@"Default authentication");
                    // Clear password and logged in ID in preferences
                    [prefs removeObjectForKey:@"password"];
                    [prefs removeObjectForKey:@"accountID"];
                    [prefs setInteger:userID forKey:@"voidID"];
                    loginId = 0;
                    // Switch menu screen button to "Login"
                    SvDKryssAppDelegate *delegate = (SvDKryssAppDelegate*)[[UIApplication sharedApplication] delegate];
                    [delegate successfullyLoggedOut];
                }
                [[DataHolder sharedDataHolder] loadEverything]; // Refresh packages and crosswords list
                
                [prefs setInteger:userID forKey:@"userID"];
                NSString *token = [prefs objectForKey:@"apstoken"];
                if (token != NULL && ![prefs boolForKey:@"apstokensent"])
                {
                    [self registerDevice:[OpenUDID value] ForPushNotifications:token];
                }
//                [prefs setObject:[NSDate date] forKey:@"last_authentication"];
                [prefs synchronize];

                [self queueLoginDataDownloads];
                manualLogin = FALSE;
                break;
            }
            case UPLOAD_TAG:
                NSLog(@"Successfully uploaded");
                NSNumber *cwId = [jsonDict objectForKey:@"cwId"];
                NSString *updateTime = [jsonDict objectForKey:@"updated"];
                [[DataHolder sharedDataHolder] setLastUploaded:updateTime forCrosswordId:cwId];
                break;
            case GET_SOLUTION_TAG:
            {
                NSLog(@"Got solution response");
                break;
            }
            case REGISTER_PURCHASE_TAG:
            {
                NSNumber *pkID = [jsonDict objectForKey:@"kindId"];
                // Make sure the package is not already on the device
                if (![[DataHolder sharedDataHolder] alreadyRegisteredPackage:pkID])
                {
                    NSLog(@"Trying to download package %d",[pkID intValue]);
                    [self downloadPackage:[[StoreDataHolder sharedStoreDataHolder] getPackageFromId:pkID]];
                }
                break;
            }
            case COMPETITION_TAG:
            {
                // Confirm response here
                CustomAlertView *alert = [[CustomAlertView alloc] initWithTitle:@"Tävlingsbidraget inskickat"
                                                                        message:@"Vi har tagit emot tävlingsbidraget och önskar lycka till i tävlingen."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                [alert show];
                [alert release];
                break;
            }
            case REGISTER_PUSH_NOTIFICATIONS_TAG:
                if (request.responseStatusCode == 200) // All OK, mark as sent and received
                {
                    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                    [prefs setBool:TRUE forKey:@"apstokensent"];
                    [prefs synchronize];
                }
                break;
            case REGISTER_ADDRESS_TAG:
            {
                
                break;
            }
            case MERGE_TAG:
            {
                CustomAlertView *alert = [[CustomAlertView alloc] initWithTitle:@"Data flyttat till denna enhet"
                                                                        message:@"All korsordsdata som tillhörde ditt tidigare SvD-konto finns nu tillgängligt i denna enhet."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                [alert show];
                [alert release];
                break;
            }
            case SEPARATE_FETCH_PACKAGES_TAG:
            {
                NSLog(@"Store packages list received separately");
                NSError *err;
                NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[request responseData] options:kNilOptions error:&err];
                [[StoreDataHolder sharedStoreDataHolder] receiveJSONPackages:jsonDict];
                // Now we can restore the purchases
                [[InAppPurchaseManager sharedInAppPurchaseManager] restoreAllPurchases];
                break;
            }
            case VERIFY_BEFORE_STORE:
                
                break;
            default:
                break;
        }
        NSLog(@"%@",jsonDict);
        [self handleQueue];
    }
}

-(NSString*)getPriceLabelForPackage:(NSDictionary*)pk
{
    NSNumber *cost = [pk objectForKey:@"cost"];
    NSNumber *subscriberCost = [pk objectForKey:SUBSCRIBER_COST];
    if ([cost intValue] == 0 || ([self isSubscriber] && subscriberCost != NULL && [subscriberCost intValue] == 0))
        return @"Ladda ned";
    else
        return [NSString stringWithFormat:@"%d,%02d kr",([cost intValue]/100),([cost intValue]%100)];
}

-(BOOL)isPackageFree:(NSDictionary*)pk
{
    NSNumber *subscriberCost = [pk objectForKey:SUBSCRIBER_COST];
    if ([[pk objectForKey:@"cost"] intValue] == 0)
        return TRUE;
    else
        return ([self isSubscriber] && subscriberCost != NULL && [subscriberCost intValue] == 0);
}

-(BOOL)isSubscriber
{
    return isSubscriber && [self isLoggedInWithRealAccount];
}

-(BOOL)isLoggedInWithRealAccount
{
    return (loginId != 0 && userID == loginId);
}

-(void)updateRegisteredEmail:(NSString*)eadr
{
    self.registeredEmail = eadr;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:eadr forKey:@"registeredEmail"];
    [defaults synchronize];
}

// Called when restoring purchases and the list of store packages has not yet been received
-(void)getStorePackages
{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URL_PACKAGES]];
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request addBasicAuthenticationHeaderWithUsername:AUTH_USERNAME andPassword:AUTH_PASSWORD];
    [request setDelegate:self];
    request.tag = SEPARATE_FETCH_PACKAGES_TAG;
    [request startAsynchronous];
}

// Called before sending any large queue, to make sure the session is intact
-(void)verifySessionWithTag:(int)t
{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:URL_VERIFY_SESSION]];
    [request addRequestHeader:@"Accept" value:@"application/json"];
    [request addBasicAuthenticationHeaderWithUsername:[self getAuthUsername] andPassword:[self getAuthPassword]];
    [request setDelegate:self];
    request.tag = t;
    [request startAsynchronous];
}

-(void)removeDownloadedCrossword:(NSDictionary*)cDic
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath;
    NSString *tmpPictureURL = [cDic objectForKey:@"pdfUrl"];
    if (tmpPictureURL == NULL || tmpPictureURL.length == 0)
        tmpPictureURL = [[cDic objectForKey:@"pictureUrl"] stringByReplacingOccurrencesOfString:@".jpg" withString:@".pdf"];
    NSString *tmpMetadataURL = [cDic objectForKey:@"metaUrl"];
    
    filePath = [documentsDirectory stringByAppendingPathComponent:[self extractFilename: tmpPictureURL]];
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    if (!success)
        NSLog(@"Failed to remove picture file");
    filePath = [documentsDirectory stringByAppendingPathComponent:[self extractFilename: tmpMetadataURL]];
    success = [fileManager removeItemAtPath:filePath error:&error];
    if (!success)
        NSLog(@"Failed to remove metadata file");
}

#pragma mark -
#pragma mark Special solution for separating basic auth between udid and svd accounts
-(NSString*)getAuthUsername
{
    if (userID == loginId && email != NULL && password != NULL)
        return LOGIN_AUTH_USERNAME;
    else
        return AUTH_USERNAME;
}

-(NSString*)getAuthPassword
{
    if (userID == loginId && email != NULL && password != NULL)
        return LOGIN_AUTH_PASSWORD;
    else
        return AUTH_PASSWORD;
}

@end
