//
//  DataHolder.m
//  XMLTest
//
//  Created by Karl Hörnell on 2012-12-08.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "DataHolder.h"
#import "StoreDataHolder.h"
#import "Metadata.h"
#import "DownloadManager.h"

#define CONTENT_XML_URL @"http://www.javaonthebrain.com/eweguo/korsord/purchase.xml"

#define LAST_UPLOADED @"lastUploaded"

#define PROMO_HEADLINE @"promo-headline"

@implementation DataHolder

@synthesize myPackages;
@synthesize myPackageIds;

@synthesize myCrosswords;
@synthesize myCrosswordIds;
@synthesize myCrosswordStats;

@synthesize crosswordSubsetList;

@synthesize currentCrossword;

@synthesize updatedSolutions;

@synthesize downloadedCrosswords;

@synthesize defaultPackageIDs;

+(DataHolder*)sharedDataHolder
{
	static DataHolder *sharedDataHolder;
	
	@synchronized(self)
	{
		if (!sharedDataHolder)
			sharedDataHolder = [[DataHolder alloc] init];
		return sharedDataHolder;
	}
}

-(void)loadEverything
{
    if (downloadedCrosswords == NULL)
        downloadedCrosswords = [[NSMutableSet alloc] initWithCapacity:200];
    
    [self loadMyPackages];
    [self loadMyCrosswords];
    
    [self loadMyCrosswordStats];
    
    [self loadUpdatedSolutions];
}

-(void)loadMyPackages
{
/*	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *ownedFilePath = [documentsDirectory stringByAppendingPathComponent:@"mypackages.data"];*/
    
    NSString *ownedFilePath = [[DownloadManager sharedDownloadManager] getFullPathNameForFile:@"mypackages.data"];
    NSArray *tempPackages = [[NSArray alloc] initWithContentsOfFile:ownedFilePath];

    // Sort packages in reverse publishing order
    if (tempPackages == nil)
        myPackages = [[NSMutableArray alloc] init];
    else
    {
        myPackages = [[tempPackages sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSNumber *firstYear = [(NSDictionary*)a objectForKey:@"year"];
            NSNumber *firstWeek = [(NSDictionary*)a objectForKey:@"week"];
            NSNumber *secondYear = [(NSDictionary*)b objectForKey:@"year"];
            NSNumber *secondWeek = [(NSDictionary*)b objectForKey:@"week"];
            int res = [firstYear intValue]*100+[firstWeek intValue] - [secondYear intValue]*100 - [secondWeek intValue];
            if (res < 0)
                return NSOrderedDescending;
            else
                return  NSOrderedAscending;
        }] mutableCopy];
        
/*        myPackages = [[tempPackages sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            NSString *first = [(NSDictionary*)a objectForKey:@"published"];
            NSString *second = [(NSDictionary*)b objectForKey:@"published"];
            return  [second compare:first];
        }] mutableCopy];*/
    }
    myPackageIds = [[NSMutableArray alloc] initWithCapacity:[myPackages count]];
    for (NSDictionary *tmpD in myPackages)
    {
        [myPackageIds addObject:[tmpD objectForKey:@"paId"]];
    }

    BOOL addedPackage = FALSE;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"default_packages" ofType:@"json"];
    NSData *ownedData = [[NSData alloc] initWithContentsOfFile:filePath];
    NSError *err;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:ownedData options:kNilOptions error:&err];
    [ownedData release];
    NSMutableArray *tmpPackages = [jsonDict objectForKey:@"packages"];
    defaultPackageIDs = [[NSMutableSet alloc] initWithCapacity:[tmpPackages count]];
    for (NSDictionary *tmpD in tmpPackages)
    {
        NSNumber *tmpID = [tmpD objectForKey:@"paId"];
        [defaultPackageIDs addObject:tmpID];
        if ([myPackageIds indexOfObject:tmpID] == NSNotFound)
        {
            addedPackage = TRUE;
            [myPackageIds addObject:tmpID];
            [myPackages addObject:[[tmpD mutableCopy] autorelease]];
        }
    }
    if (addedPackage)
    {
        [myPackages writeToFile:ownedFilePath atomically:TRUE];
    }
}

-(NSDictionary*)getMyPackageNumbered:(int)num
{
    return [myPackages objectAtIndex:num];
}

-(int)getNumberOfCrosswordsInPackage:(NSDictionary*)pk
{
    NSArray *tmpA = [pk objectForKey:ITEM_CROSSWORDS];
    return tmpA.count;
}

-(int)getNumberOfStartedCrosswordsInPackage:(NSDictionary*)pk
{
    int count = 0;
    NSArray *tmpA = [pk objectForKey:ITEM_CROSSWORDS];
    for (NSNumber *tmpN in tmpA)
    {
        if ([self getPercentageSolvedForCrosswordId:tmpN] != NULL)
            count++;
    }
    return count;
}

-(NSString*)getHeadlineFromPackage:(NSDictionary*)pk
{
    NSString *headline = [pk objectForKey:@"category"];
    NSString *packageInfo = [pk objectForKey:@"packageInfo"];
    NSNumber *week = [pk objectForKey:@"week"];
    NSNumber *year = [pk objectForKey:@"year"];
    
    NSDate *currDate = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [calendar setFirstWeekday:2];
    NSDateComponents *components = [calendar components:NSWeekOfYearCalendarUnit|NSYearCalendarUnit fromDate:currDate];
    int thisWeek = components.weekOfYear;
    int thisYear = components.year;
    [calendar release];
    
    // Special case
    if ([week intValue]==thisWeek && [year intValue]==thisYear)
        return @"Denna veckas paket";
    else
    {
        if (packageInfo != NULL && [packageInfo length] > 0)
            headline = [NSString stringWithFormat:@"%@ %@",headline,packageInfo];
        if (week != NULL && [week intValue] != 0)
            headline = [NSString stringWithFormat:@"%@ v %@",headline,week];
        if (year != NULL && [year intValue] != 0)
            headline = [NSString stringWithFormat:@"%@, %@",headline,year];
        return headline;
    }
}

-(NSString*)getContentDescriptionFromPackage:(NSDictionary*)pk;
{
/*    NSNumber *week = [pk objectForKey:@"week"];
    NSNumber *year = [pk objectForKey:@"year"];
    
    NSDate *currDate = [NSDate date];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:NSWeekOfYearCalendarUnit|NSYearCalendarUnit fromDate:currDate];
    int thisWeek = components.weekOfYear;
    int thisYear = components.year;
    
    // Special case
    if ([week intValue]==thisWeek && [year intValue]==thisYear)
        return @"Nya korsord varje dag";*/
    
    NSArray *tmpA = [pk objectForKey:@"crosswords"];
    
    NSDictionary *tmpD = NULL;
    for (NSNumber *tmpN in tmpA)
    {
        tmpD = [self getCrosswordFromID:tmpN];
        if (tmpD != NULL)
            break;
    }
    
    NSString *typeInfo = [tmpD objectForKey:@"type"];
    NSString *subtype = [tmpD objectForKey:@"subtype"];
    int numStarted = 0;
    BOOL mixed = FALSE;
    BOOL mixedSubtype = FALSE;
    for (NSNumber *tmpN in tmpA)
    {
        tmpD = [self getCrosswordFromID:tmpN];
/*        if ([tmpD objectForKey:PERCENTAGE_SOLVED_TAG] != nil)
            numStarted++;*/
        if ([self getPercentageSolvedForCrosswordId:tmpN] != NULL)
            numStarted++;
        if (tmpD != NULL && ![typeInfo isEqualToString: [tmpD objectForKey:@"type"]])
        {
            mixed = TRUE;
        }
        if (subtype == NULL || ![subtype isEqualToString:[tmpD objectForKey:@"subtype"]])
            mixedSubtype = TRUE;
    }
    if (!mixedSubtype)
        typeInfo = subtype;
    else if (mixed)
         typeInfo = @"blandade";
    
    NSString *startedInfo = NULL;
    if (numStarted == 1)
        startedInfo = @"1 påbörjat";
    else if (numStarted > 1)
        startedInfo = [NSString stringWithFormat:@"%d påbörjade",numStarted];

    if (numStarted == 0)
        return [NSString stringWithFormat:@"%d %@",[tmpA count], [typeInfo lowercaseString]];
    else
        return [NSString stringWithFormat:@"%d %@ varav %@",[tmpA count],[typeInfo lowercaseString],startedInfo];
}

-(NSString*)getContentDescriptionFromStorePackage:(NSDictionary*)pk purchased:(BOOL)pu
{
    if (pu) // Already purchased
    {
        if ([myCrosswordIds containsObject:[pk objectForKey:@"paId"]])
            return @"Redan köpt och nedladdat";
        else
            return @"Köpt men inte nedladdat";
    }
    
    NSArray *tmpA = [pk objectForKey:ITEM_CROSSWORDS];    
    NSDictionary *tmpD = [myCrosswords objectAtIndex:[myCrosswordIds indexOfObject:[tmpA objectAtIndex:0]]];
    NSString *typeInfo = [tmpD objectForKey:@"type"];
    NSString *subtype = [tmpD objectForKey:@"subtype"];
    int numPurchased = 0;
    BOOL mixed = FALSE;
    BOOL mixedSubtype = FALSE;
    for (NSNumber *tmpN in tmpA)
    {
        tmpD = [myCrosswords objectAtIndex:[myCrosswordIds indexOfObject:tmpN]];
        if ([myCrosswordIds containsObject:[tmpD objectForKey:@"cwId"]])
            numPurchased++;
        if (![typeInfo isEqualToString: [tmpD objectForKey:@"type"]])
            mixed = TRUE;
        if (subtype == NULL || ![subtype isEqualToString:[tmpD objectForKey:@"subtype"]])
            mixedSubtype = TRUE;
    }
    if (!mixedSubtype)
        typeInfo = subtype;
    else if (mixed)
        typeInfo = @"blandade";
    NSString *purchasedInfo = NULL;
    if (numPurchased == 1)
        purchasedInfo = @"köpt";
    else if (numPurchased > 1)
        purchasedInfo = @"köpta";

    if (numPurchased == 0)
    {
        return [NSString stringWithFormat:@"%d %@",[tmpA count], [typeInfo lowercaseString]];
    }
    else
        return [NSString stringWithFormat:@"%d %@ varav %d redan %@ i annat paket",[tmpA count],[typeInfo lowercaseString],numPurchased,purchasedInfo];
}

-(NSString*)getHeadlineFromCrossword:(NSDictionary*)cw
{
    NSString *headline = [cw objectForKey:@"name"];
    NSNumber *week = [cw objectForKey:@"week"];
    NSNumber *year = [cw objectForKey:@"year"];
    if (week != NULL && [week intValue] != 0)
        headline = [NSString stringWithFormat:@"%@ v %@",headline,week];
    if (year != NULL && [year intValue] != 0)
        headline = [NSString stringWithFormat:@"%@, %@",headline,year];
    return headline;
}

-(NSString*)getDescriptionFromCrossword:(NSDictionary*)cw
{
    NSString *setter = [cw objectForKey:@"setter"];
    if (setter == NULL)
        return @"";
    else
        return [NSString stringWithFormat:@"Av %@",setter];
}

-(void)loadMyCrosswords
{
/*	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *ownedFilePath = [documentsDirectory stringByAppendingPathComponent:@"mycrosswords.data"];*/
    NSString *ownedFilePath = [[DownloadManager sharedDownloadManager] getFullPathNameForFile:@"mycrosswords.data"];
    
    myCrosswords = [[NSMutableArray alloc] initWithContentsOfFile:ownedFilePath];
 	if (myCrosswords == nil)
        myCrosswords = [[NSMutableArray alloc] init];
    myCrosswordIds = [[NSMutableArray alloc] initWithCapacity:[myCrosswords count]];
    for (NSMutableDictionary *tmpD in myCrosswords)
    {
        NSNumber *tmpN = [tmpD objectForKey:@"cwId"];
        [myCrosswordIds addObject:tmpN];
        if ([tmpD valueForKey:@"downloaded"] != NULL)
            [downloadedCrosswords addObject:tmpN];
        if ([downloadedCrosswords containsObject:tmpN])
            [tmpD setValue:@"true" forKey:@"downloaded"];
        
        // Special sanity check, fix corrupt metadata filenames
        NSString *metaURL = [tmpD objectForKey:@"metaUrl"];
        NSString *metaFilename = [tmpD objectForKey:@"metadata"];
        if (metaFilename != NULL && metaURL != NULL)
        {
            [tmpD setObject:[self extractFilename:metaURL] forKey:@"metadata"];
        }
    }
    BOOL addedCrossword = FALSE;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"default_crosswords" ofType:@"json"];
    NSData *ownedData = [[NSData alloc] initWithContentsOfFile:filePath];
    NSError *err;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:ownedData options:kNilOptions error:&err];
    NSMutableArray *tmpCrosswords = [jsonDict objectForKey:@"crosswords"];
    [ownedData release];
    for (NSDictionary *tmpD in tmpCrosswords)
    {
        NSNumber *tmpID = [tmpD objectForKey:@"cwId"];
        if ([myCrosswordIds indexOfObject:tmpID] == NSNotFound)
        {
            addedCrossword = TRUE;
            [myCrosswordIds addObject:tmpID];
            [myCrosswords addObject:[[tmpD mutableCopy] autorelease]];
        }
    }
    if (addedCrossword)
        [myCrosswords writeToFile:ownedFilePath atomically:TRUE];
}

-(void)saveMyCrosswords
{
    NSLog(@"Saving crosswords");

/*	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *ownedFilePath = [documentsDirectory stringByAppendingPathComponent:@"mycrosswords.data"];
    [myCrosswords writeToFile:ownedFilePath atomically:TRUE];*/
    [myCrosswords writeToFile:[[DownloadManager sharedDownloadManager] getFullPathNameForFile:@"mycrosswords.data"] atomically:TRUE];
}

-(void)saveMyPackages
{
/*	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *ownedFilePath = [documentsDirectory stringByAppendingPathComponent:@"mypackages.data"];*/
    NSLog(@"Saving packages");
    [myPackages writeToFile:[[DownloadManager sharedDownloadManager] getFullPathNameForFile:@"mypackages.data"] atomically:TRUE];
}

-(void)getSubsetFromPackage:(NSDictionary*)pk
{
    NSArray *tmpA = [pk objectForKey:ITEM_CROSSWORDS];
    crosswordSubsetList = [[NSMutableArray alloc] initWithCapacity:10];
    for (NSNumber *tmpN in tmpA)
    {
        NSUInteger pos = [myCrosswordIds indexOfObject:tmpN];
        if (pos != NSNotFound)
            [crosswordSubsetList addObject:[myCrosswords objectAtIndex:pos]];
    }
}

-(void)getListOfStartedCrosswords
{
/*    crosswordSubsetList = [[NSMutableArray alloc] initWithCapacity:100];
    for (NSDictionary *tmpD in myCrosswords)
    {
        if ([tmpD objectForKey:PERCENTAGE_SOLVED_TAG] != nil)
            [crosswordSubsetList addObject:tmpD];
    }*/
    [self getListOfStartedCrosswordsSince:[NSDate dateWithTimeIntervalSince1970:0]];
}

-(void)getListOfStartedCrosswordsSince:(NSDate*)dt
{
    crosswordSubsetList = [[NSMutableArray alloc] initWithCapacity:100];
/*    for (NSDictionary *tmpD in myCrosswords)
    {
        if ([tmpD objectForKey:PERCENTAGE_SOLVED_TAG] != nil)
        {
            NSDate *tmpDt = [tmpD objectForKey:LAST_MODIFIED_TAG];
            if (tmpDt != nil && [tmpDt compare:dt] == NSOrderedDescending)
                [crosswordSubsetList addObject:tmpD];
        }
    }*/
    for (NSNumber *tmpN in myCrosswordIds)
    {
        NSDate *tmpDt = [self getLastModifiedForCrosswordId:tmpN];
        if (tmpDt != nil && [tmpDt compare:dt] == NSOrderedDescending)
            [crosswordSubsetList addObject:[self getCrosswordFromID:tmpN]];
    }
    
    // Order with last modified first
    [crosswordSubsetList sortUsingComparator:
     ^(id obj1, id obj2)
     {
         NSDate* key1 = [self getLastModifiedForCrosswordId:[obj1 objectForKey:@"cwId"]];
         NSDate* key2 = [self getLastModifiedForCrosswordId:[obj2 objectForKey:@"cwId"]];
         return [key2 compare: key1];
     }];
}

-(NSMutableDictionary*)getMyCrosswordNumbered:(int)num
{
    return [crosswordSubsetList objectAtIndex:num];
}

-(NSMutableDictionary*)getCrosswordFromID:(NSNumber*)num
{
    NSUInteger ix = [myCrosswordIds indexOfObject:num];
    if (ix == NSNotFound)
        return nil;
    else
        return [myCrosswords objectAtIndex:ix];
}

-(NSMutableDictionary*)getPackageThatContainsCrossword:(NSNumber*)cwId
{
    NSMutableDictionary *pk = NULL;
    for (NSMutableDictionary *tmpD in myPackages)
    {
        NSArray *tmpA = [tmpD objectForKey:@"crosswords"];
        if ([tmpA containsObject:cwId])
        {
            pk = tmpD;
            break;
        }
    }
    return pk;
}

-(NSMutableDictionary*)getPackageFromId:(NSNumber*)pid
{
    NSUInteger ix = [myPackageIds indexOfObject:pid];
    if (ix == NSNotFound)
        return nil;
    else
        return [myPackages objectAtIndex:ix];
}

-(BOOL)isPackageFullyDownloaded:(NSNumber*)pkId
{
    if (![myPackageIds containsObject:pkId])
        return FALSE;
    NSMutableDictionary *tmpP = [myPackages objectAtIndex:[myPackageIds indexOfObject:pkId]];
    return [self haveAllCrosswordsBeenDownloaded:tmpP];
}

-(void)setForCurrentCrosswordProperty:(NSString*)prp value:(NSString*)val
{
    if (val != nil)
    {
        [currentCrossword setObject:val forKey:prp];
    }
    else
    {
        [currentCrossword removeObjectForKey:prp];
    }
    [currentCrossword setObject:[NSDate date] forKey:LAST_MODIFIED_TAG];
}

-(NSString*)getCurrentCrosswordProperty:(NSString*)prp
{
    return [currentCrossword objectForKey:prp];
}

-(NSString*)getCurrentDataFilename
{
    return [NSString stringWithFormat:@"cwdata%d",[(NSNumber*)[currentCrossword objectForKey:@"cwId"] intValue]];
}

// Check input list against already owned package ids
-(int)numberOfPackagesAlreadyOwned:(NSArray*)idList
{
    int count = 0;
    for (NSNumber *tmpS in idList)
    {
        if ([myPackageIds containsObject:tmpS])
            count++;
    }
    return count;
}

-(int)numberOfCrosswordsAlreadyOwned:(NSArray*)idList
{
    int count = 0;
    for (NSNumber *tmpS in idList)
    {
        if ([myCrosswordIds containsObject:tmpS])
            count++;
    }
    return count;
}

-(BOOL)alreadyRegisteredPackage:(NSNumber*)pId
{
    return [myPackageIds containsObject:pId];
}

-(void)updatePackage:(NSNumber*)pkID withListOfCrosswords:(NSArray*)cws
{
    NSUInteger pos = [myPackageIds indexOfObject:pkID];
    BOOL changeFlag = FALSE;
    if (pos != NSNotFound)
    {
        NSMutableDictionary *tmpP = [[myPackages objectAtIndex:pos] mutableCopy];
        for (NSNumber *newCWID in cws)
            if ([myCrosswordIds indexOfObject:newCWID] == NSNotFound && [[StoreDataHolder sharedStoreDataHolder] getCrosswordFromId:newCWID] != nil)
            {
                // Need to add crossword
                [myCrosswordIds addObject:newCWID];
                NSMutableDictionary *storeCrossword = [[[StoreDataHolder sharedStoreDataHolder] getCrosswordFromId:newCWID] mutableCopy];
                [myCrosswords addObject:storeCrossword];
               
                changeFlag = TRUE;
            }
        if (changeFlag)
        {
            [tmpP setObject:cws forKey:@"crosswords"];
            [myPackages setObject:tmpP atIndexedSubscript:pos];
            [self saveMyCrosswords];
        }
        [tmpP release];
    }
}

-(BOOL)alreadyOwnsCrossword:(NSNumber*)cId;
{
    return [myCrosswordIds containsObject:cId];
}

-(void)addPackageFromStore:(NSDictionary*)pk
{
    NSNumber *tmpID = [pk objectForKey:@"paId"];
    [myPackageIds addObject:tmpID];
//    [myPackageIds sortUsingSelector:@selector(compare:)];
//    int newPos = [myPackageIds indexOfObject:tmpID];
    int newPos = [self findInsertionPointForPackage:pk];
    [myPackages insertObject:pk atIndex:newPos];
    NSLog(@"Adding package %@",tmpID);
//	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//	NSString *documentsDirectory = [paths objectAtIndex:0];
//	NSString *ownedFilePath = [documentsDirectory stringByAppendingPathComponent:@"mypackages.data"];
//    NSLog(@"Saving packages dictionary");
//    [myPackages writeToFile:ownedFilePath atomically:TRUE];
    [self saveMyPackages];
    
    NSArray *tmpA = [pk objectForKey:@"crosswords"];
    for (NSNumber *tmpN in tmpA)
    {
        if ([[StoreDataHolder sharedStoreDataHolder] getCrosswordFromId:tmpN] != nil)
        {
            NSMutableDictionary *tmpCW = NULL;
            BOOL alreadyOwned = ([myCrosswordIds indexOfObject:tmpN] != NSNotFound);
            if (alreadyOwned)
            {
                tmpCW = [[DataHolder sharedDataHolder] getCrosswordFromID:tmpN];
            }
            else
            {
                tmpCW = [[[StoreDataHolder sharedStoreDataHolder].storeCrosswords objectAtIndex:[[StoreDataHolder sharedStoreDataHolder].storeCrosswordIds indexOfObject:tmpN]] mutableCopy];
            }
            
            [tmpCW setObject:@"TRUE" forKey:@"downloaded"];
            [self setCrosswordAsDownloaded:tmpCW];
            
            if (!alreadyOwned)
            {
                NSString *tmpMetaUrl = [tmpCW objectForKey:@"metaUrl"];
                [tmpCW setObject:[self extractFilename:tmpMetaUrl] forKey:@"metadata"];
                
                NSString *tmpPdfUrl = [tmpCW objectForKey:@"pdfUrl"];
                if (tmpPdfUrl == NULL || tmpPdfUrl.length == 0)
                {
                    tmpPdfUrl = [[tmpCW objectForKey:@"pictureUrl"] stringByReplacingOccurrencesOfString:@".jpg" withString:@".pdf"];
                }
                [tmpCW setObject:[self extractFilename:tmpPdfUrl] forKey:@"pdf"];
                
                [myCrosswordIds addObject:tmpN];
                [myCrosswords addObject:tmpCW];
                
                [self integrateStoredSolution:tmpCW];
            }
        }
    }
// 	ownedFilePath = [documentsDirectory stringByAppendingPathComponent:@"mycrosswords.data"];
//    NSLog(@"Saving crosswords dictionary");
//    [myCrosswords writeToFile:ownedFilePath atomically:TRUE];
    [self saveMyCrosswords];
}

-(void)addPackageAsBought:(NSDictionary*)pk
{
    NSNumber *tmpID = [pk objectForKey:@"paId"];
    [myPackageIds addObject:tmpID];
    int newPos = [self findInsertionPointForPackage:pk];
    [myPackages insertObject:pk atIndex:newPos];
    NSLog(@"Adding package %@",tmpID);
//	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//	NSString *documentsDirectory = [paths objectAtIndex:0];
//	NSString *ownedFilePath = [documentsDirectory stringByAppendingPathComponent:@"mypackages.data"];
//    NSLog(@"Saving packages dictionary");
//    [myPackages writeToFile:ownedFilePath atomically:TRUE];
    [self saveMyPackages];
    
    NSArray *tmpA = [pk objectForKey:@"crosswords"];
    for (NSNumber *tmpN in tmpA)
    {
        if ([[StoreDataHolder sharedStoreDataHolder] getCrosswordFromId:tmpN] != nil)
        {
            NSMutableDictionary *tmpCW = NULL;
            BOOL alreadyOwned = ([myCrosswordIds indexOfObject:tmpN] != NSNotFound);
            if (alreadyOwned)
            {
                tmpCW = [[DataHolder sharedDataHolder] getCrosswordFromID:tmpN];
                NSLog(@"Already owns %@",tmpN);
            }
            else
            {
                NSUInteger pos = [[StoreDataHolder sharedStoreDataHolder].storeCrosswordIds indexOfObject:tmpN];
                if (pos != NSNotFound)
                {
                    tmpCW = [[[StoreDataHolder sharedStoreDataHolder].storeCrosswords objectAtIndex:pos] mutableCopy];
                    NSLog(@"Getting %@ from store crosswords list",tmpN);
                }
            }
            
            if (tmpCW != NULL && [tmpCW objectForKey:@"local-metadata"] == NULL)
            {
                NSString *tmpMetaUrl = [tmpCW objectForKey:@"metaUrl"];
                [tmpCW setObject:[self extractFilename:tmpMetaUrl] forKey:@"metadata"];
                
                NSString *tmpPdfUrl = [tmpCW objectForKey:@"pdfUrl"];
                if (tmpPdfUrl == NULL || tmpPdfUrl.length == 0)
                {
                    tmpPdfUrl = [[tmpCW objectForKey:@"pictureUrl"] stringByReplacingOccurrencesOfString:@".jpg" withString:@".pdf"];
                }
                
                [tmpCW setObject:[self extractFilename:tmpPdfUrl] forKey:@"pdf"];
            }
            
            if (tmpCW != NULL && [downloadedCrosswords containsObject:tmpN])
                [tmpCW setObject:@"true" forKey:@"downloaded"];
            
            if (tmpCW != NULL && !alreadyOwned)
            {
                [myCrosswordIds addObject:tmpN];
                [myCrosswords addObject:tmpCW];
            }
        }
    }
    [self saveMyCrosswords];
}

#pragma mark -
#pragma Helper methods

-(NSString*)extractFilename:(NSString*)url
{
    int i = [url length];
    while (i>0 && [url characterAtIndex:i-1] != '/')
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

/*-(NSObject*)packageSortingValue:(NSDictionary*)pk
{
    // Temporary
    return [pk objectForKey:@"published"];
}*/

-(int)findInsertionPointForPackage:(NSDictionary*)pk
{
    // Sort in order of newest (highest time value) first
    int pos = 0;
    int timeIndex = [(NSNumber*)[pk objectForKey:@"year"] intValue]*100 + [(NSNumber*)[pk objectForKey:@"week"] intValue];
    for (NSDictionary *tmpD in myPackages)
    {
        int cmpIndex = [(NSNumber*)[tmpD objectForKey:@"year"] intValue]*100 + [(NSNumber*)[tmpD objectForKey:@"week"] intValue];
        if (timeIndex < cmpIndex)
            pos++;
        else
            break;
    }
    return pos;
}

-(BOOL)haveAllCrosswordsBeenDownloaded:(NSDictionary*)pk
{
    BOOL complete = TRUE;
    NSArray *tmpA = [pk objectForKey:@"crosswords"];
    for (NSNumber *tmpN in tmpA)
    {
        NSDictionary *tmpD = [self getCrosswordFromID:tmpN];
        if (tmpD != NULL && [tmpD objectForKey:@"downloaded"] == NULL)
            complete = FALSE;
    }
    
    return complete;
}

-(BOOL)hasThisCrosswordBeenDownloaded:(NSDictionary*)cw
{
    return ([cw objectForKey:@"downloaded"] != NULL);
}

// Call this if user solution data has been fetched and stored before the actual crossword
-(void)integrateStoredSolution:(NSMutableDictionary*)cw
{
    NSNumber *tmpID = [cw objectForKey:@"cwId"];
    NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *storePath = [applicationDocumentsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"cwdata%d",[tmpID intValue]]];
    NSData *userData = [NSData dataWithContentsOfFile:storePath];
    if (userData != NULL)
    {
        NSLog(@"Loading locally stored metadata");
        NSString *fileS = [cw objectForKey:@"metadata"];
        NSString *localFilePath = [applicationDocumentsDir stringByAppendingPathComponent:fileS];
        NSData *crosswordData = [NSData dataWithContentsOfFile:localFilePath];
        Metadata *md = [[Metadata alloc] init];
        [md setupWithData:crosswordData];
        [md setUserDataFromData:userData];
        [md saveFilledInCharactersAs:[NSString stringWithFormat:@"cwdata%d",[tmpID intValue]]];
        
        int p = [md getFilledInPercent];
/*        if (p > 0)
            [cw setObject:[NSString stringWithFormat:@"%d",p] forKey:PERCENTAGE_SOLVED_TAG];
        else
            [cw removeObjectForKey:PERCENTAGE_SOLVED_TAG];*/
        [self setPercentageSolved:p ForCrosswordId:tmpID];
        
        [self saveMyCrosswords];
        [md release];
    }
}

// Received during login
/*-(void)receiveJSONCrosswords:(NSMutableDictionary*)cw
{
    NSMutableArray *tmpCWs = [cw objectForKey:@"crosswords"];
    for (NSDictionary *tmpD in tmpCWs)
    {
        NSNumber *tmpID = [tmpD objectForKey:@"cwId"];
        if (![myCrosswordIds containsObject:tmpID])
        {
            [myCrosswordIds addObject:tmpID];
            NSMutableDictionary *tmpMD = [tmpD mutableCopy];
            [myCrosswords addObject:tmpMD];
            [tmpMD release];
        }
    }
}*/

-(void)setPercentageSolvedForCurrentCrossword:(int)p
{
    [self setPercentageSolved:p ForCrosswordId:[currentCrossword objectForKey:@"cwId"]];
}

-(void)setPercentageSolved:(int)p ForCrosswordId:(NSNumber*)cwId
{
    NSMutableDictionary *tmpD = [myCrosswordStats objectForKey:[cwId stringValue]];
    if (tmpD == NULL)
    {
        if (p > 0)
        {
            tmpD = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:@"%d",p], PERCENTAGE_SOLVED_TAG, [NSDate date], LAST_MODIFIED_TAG, nil];
            [myCrosswordStats setObject:tmpD forKey:[cwId stringValue]];
            [tmpD release];
        }
    }
    else
    {
        if (p > 0)
        {
            [tmpD setObject:[NSString stringWithFormat:@"%d",p] forKey:PERCENTAGE_SOLVED_TAG];
            [tmpD setObject:[NSDate date] forKey:LAST_MODIFIED_TAG];
        }
        else
        {
            if ([tmpD objectForKey:PERCENTAGE_SOLVED_TAG] != NULL)
            {
                [tmpD removeObjectForKey:PERCENTAGE_SOLVED_TAG];
                [tmpD removeObjectForKey:LAST_MODIFIED_TAG];
            }
        }
    }

    [self saveMyCrosswordStats];
}

-(NSString*)getPercentageSolvedForCrosswordId:(NSNumber*)cwId
{
    NSMutableDictionary *tmpD = [myCrosswordStats objectForKey:[cwId stringValue]];
    NSDictionary *tmpCD = [updatedSolutions objectForKey:[cwId stringValue]];

    if (tmpD != NULL && tmpCD != NULL)
    {
        NSString *tmpP = [tmpD objectForKey:PERCENTAGE_SOLVED_TAG];
        NSString *tmpCP = [tmpCD objectForKey:@"percentageSolved"];
        if ([tmpP intValue] >= [tmpCP intValue])
            return tmpP;
        else
            return tmpCP;
    }
    else if (tmpD != NULL)
        return [tmpD objectForKey:PERCENTAGE_SOLVED_TAG];
    else if (tmpCD != NULL)
        return [tmpCD objectForKey:@"percentageSolved"];
    else
        return NULL;
}

-(NSDate*)getLastModifiedForCrosswordId:(NSNumber*)cwId
{
    NSMutableDictionary *tmpD = [myCrosswordStats objectForKey:[cwId stringValue]];
    NSDictionary *tmpCD = [updatedSolutions objectForKey:[cwId stringValue]];

    if (tmpD != NULL && tmpCD != NULL)
    {
        NSString *tmpP = [tmpD objectForKey:PERCENTAGE_SOLVED_TAG];
        NSString *tmpCP = [tmpCD objectForKey:@"percentageSolved"];
        if ([tmpP intValue] >= [tmpCP intValue])
            return [tmpD objectForKey:LAST_MODIFIED_TAG];
        else
        {
            NSNumber *milliseconds = [tmpCD objectForKey:@"updated"];
            NSTimeInterval timeInterval = [milliseconds doubleValue]/1000.0;
            return [NSDate dateWithTimeIntervalSince1970:timeInterval];
        }
    }
    else if (tmpD != NULL)
        return [tmpD objectForKey:LAST_MODIFIED_TAG];
    else if (tmpCD != NULL)
    {
        NSNumber *milliseconds = [tmpCD objectForKey:@"updated"];
        NSTimeInterval timeInterval = [milliseconds doubleValue]/1000.0;
        return [NSDate dateWithTimeIntervalSince1970:timeInterval];
    }
    else
        return NULL;
}

-(void)setLastUploaded:(NSString*)timestamp forCrosswordId:(NSNumber*)cwId
{
    NSMutableDictionary *tmpD = [myCrosswordStats objectForKey:[cwId stringValue]];
    if (tmpD != NULL)
    {
        [tmpD setObject:timestamp forKey:LAST_UPLOADED];
        [self saveMyCrosswordStats];
    }
}
-(NSString*)getLastUploadedForCrosswordId:(NSNumber*)cwId
{
    NSMutableDictionary *tmpD = [myCrosswordStats objectForKey:[cwId stringValue]];
    if (tmpD == NULL)
        return NULL;
    return [tmpD objectForKey:LAST_UPLOADED];
}

-(void)saveMyCrosswordStats
{
    BOOL success = [myCrosswordStats writeToFile:[[DownloadManager sharedDownloadManager] getFullPathNameForFile:@"crosswordstats.data"] atomically:TRUE];
    if (!success)
    {
        NSLog(@"**** Failed to write statistics %@",myCrosswordStats);
    }
}

-(void)loadMyCrosswordStats
{
    myCrosswordStats = [[NSMutableDictionary alloc] initWithContentsOfFile:[[DownloadManager sharedDownloadManager] getFullPathNameForFile:@"crosswordstats.data"]];
    if (myCrosswordStats == nil) // First time? Copy possible legacy data
    {
        myCrosswordStats = [[NSMutableDictionary alloc] init];
        for (NSMutableDictionary *tmpC in myCrosswords)
        {
            NSString *tmpS = [tmpC objectForKey:PERCENTAGE_SOLVED_TAG];
            if (tmpS != NULL)
            {
                NSMutableDictionary *tmpD = [[NSMutableDictionary alloc] initWithObjectsAndKeys:tmpS, PERCENTAGE_SOLVED_TAG, [tmpC objectForKey:LAST_MODIFIED_TAG], LAST_MODIFIED_TAG, nil];
                [myCrosswordStats setObject:tmpD forKey:[[tmpC objectForKey:@"cwId"] stringValue]];
                [tmpD release];
            }
        }
    }
}

-(void)loadUpdatedSolutions
{
    updatedSolutions = [[NSMutableDictionary alloc] initWithContentsOfFile:[[DownloadManager sharedDownloadManager] getFullPathNameForFile:@"updatedsolutions.data"]];
    if (updatedSolutions == nil) // First time?
    {
        updatedSolutions = [[NSMutableDictionary alloc] init];
    }
}

-(void)saveUpdatedSolutions
{
    [updatedSolutions writeToFile:[[DownloadManager sharedDownloadManager] getFullPathNameForFile:@"updatedsolutions.data"] atomically:TRUE];
}

-(void)appendUpdatedSolution:(NSDictionary*)sol
{
    NSString *cwId = [[sol objectForKey:@"cwId"] stringValue];
    NSNumber *solved = [sol objectForKey:@"percentageSolved"];
    if ([solved intValue] == 0) // Don't store empty data
        [updatedSolutions removeObjectForKey:cwId];
    else
        [updatedSolutions setObject:sol forKey:cwId];
}

-(void)removeUpdatedSolutionForCurrent;
{
    [updatedSolutions removeObjectForKey:[[currentCrossword objectForKey:@"cwId"] stringValue]];
    [self saveUpdatedSolutions];
}

-(NSData*)getUpdatedSolutionDataForCurrent
{
    NSNumber *cwId = [currentCrossword objectForKey:@"cwId"];
    NSDictionary *tmpUS = [updatedSolutions objectForKey:[cwId stringValue]];
    return [[DownloadManager sharedDownloadManager] base64DataFromString:[tmpUS objectForKey:@"data"]];
}

-(NSData*)getUpdatedSolutionIfSameAsThisDevice
{
    NSNumber *cwId = [currentCrossword objectForKey:@"cwId"];
    NSDictionary *tmpUS = [updatedSolutions objectForKey:[cwId stringValue]];
    if (tmpUS == NULL)
        return NULL;
    NSString *remoteDeviceName = [tmpUS objectForKey:@"deviceName"];
    if ([remoteDeviceName isEqualToString:[[UIDevice currentDevice] name]])
    {
        return [[DownloadManager sharedDownloadManager] base64DataFromString:[tmpUS objectForKey:@"data"]];
    }
    else
        return  NULL;
}

-(NSString*)updatedSolutionResponseForPercent:(int)p
{
    NSNumber *cwId = [currentCrossword objectForKey:@"cwId"];
    NSDictionary *tmpUS = [updatedSolutions objectForKey:[cwId stringValue]];
    if (tmpUS == NULL) // No stored updated solution
    {
        NSLog(@"No stored updated solution");
        return NULL;
    }
    NSError *err;
    NSFileManager *myManager = [NSFileManager defaultManager];
    NSString *myPath = [[DownloadManager sharedDownloadManager] getFullPathNameForFile:[self getCurrentDataFilename]];
    NSDictionary *myDict = [myManager attributesOfItemAtPath:myPath error:&err];
    NSDate *latestSave = NULL;
    if (myDict != NULL)
        latestSave = [myDict objectForKey:@"NSFileModificationDate"];
    
    NSNumber *milliseconds = [tmpUS objectForKey:@"updated"];
    NSTimeInterval timeInterval = [milliseconds doubleValue]/1000.0;
    NSDate *lastUpdate = [NSDate dateWithTimeIntervalSince1970:timeInterval];

    NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormat setDateFormat:@"d/M 'kl' HH.mm"];
    
    if (latestSave == NULL || p == 0)
        return [NSString stringWithFormat:@"Detta korsord fylldes i till %@%% på %@ %@. Använd den lösningen?",[tmpUS objectForKey:@"percentageSolved"],[tmpUS objectForKey:@"deviceName"],[dateFormat stringFromDate:lastUpdate]];
    else
        return [NSString stringWithFormat:@"Detta korsord fylldes i till %@%% på %@ %@. Använd den lösningen i stället för den som fylldes i till %d%% på denna enhet %@?",[tmpUS objectForKey:@"percentageSolved"],[tmpUS objectForKey:@"deviceName"],[dateFormat stringFromDate:lastUpdate],p,[dateFormat stringFromDate:latestSave]];
}

-(void)setCrosswordAsDownloaded:(NSDictionary*)cw
{
    [downloadedCrosswords addObject:[cw objectForKey:@"cwId"]];
}

-(BOOL)isPackagePartOfDefault:(NSNumber*)pId
{
    return [defaultPackageIDs containsObject:pId];
}

-(void)clearCrosswordsInPackageNumber:(int)n
{
    NSDictionary *clearDic = [self getMyPackageNumbered:n];
    NSNumber *clearId = [clearDic objectForKey:@"paId"];
    NSArray *clearCrosswords = [clearDic objectForKey:@"crosswords"];
    for (NSNumber *cwId in clearCrosswords)
    {
        // First see if it is part of any other package
        NSLog(@"Ckecking crossword ID %@",cwId);
        BOOL deleteFlag = TRUE;
        for (NSDictionary *tmpD in myPackages)
        {
            NSNumber *paId = [tmpD objectForKey:@"paId"];
            if (([self isPackagePartOfDefault:paId] || [self haveAllCrosswordsBeenDownloaded:tmpD]) &&
                ![clearId isEqualToNumber:paId])
            {
                NSArray *tmpA = [tmpD objectForKey:@"crosswords"];
                if ([tmpA containsObject:cwId])
                    deleteFlag = FALSE;
            }
        }
        if (deleteFlag)
        {
            NSLog(@"Trying to delete");
            // Now remove the crossword
            NSMutableDictionary *tmpCD = [self getCrosswordFromID:cwId];
            [[DownloadManager sharedDownloadManager] removeDownloadedCrossword:tmpCD];
            [tmpCD removeObjectForKey:@"downloaded"];
            [downloadedCrosswords removeObject:cwId];
        }
        else
            NSLog(@"Do not delete");
    }
    [self saveMyCrosswords];
}

@end
