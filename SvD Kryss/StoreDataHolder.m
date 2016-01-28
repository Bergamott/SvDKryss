//
//  StoreDataHolder.m
//  SvD Kryss
//
//  Created by Karl on 2013-01-31.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "StoreDataHolder.h"
#import "DataHolder.h"

@implementation StoreDataHolder

@synthesize storeOffers;
@synthesize storeCategories;
@synthesize storePackages;
@synthesize storeCrosswords;

@synthesize storeCrosswordIds;
@synthesize storePackageIds;
@synthesize storeOfferIds;
@synthesize storeCategoryIds;
@synthesize packagesBeingDownloaded;
@synthesize packagesPurchased;

@synthesize storeIntroText;

+(StoreDataHolder*)sharedStoreDataHolder
{
	static StoreDataHolder *sharedStoreDataHolder;
	
	@synchronized(self)
	{
		if (!sharedStoreDataHolder)
			sharedStoreDataHolder = [[StoreDataHolder alloc] init];
		return sharedStoreDataHolder;
	}
}

-(void)receiveJSONCrosswords:(NSMutableDictionary*)cw
{
    self.storeCrosswords = [cw objectForKey:@"crosswords"];
    storeCrosswordIds = [[NSMutableArray alloc] initWithCapacity:[storeCrosswords count]];
    for (NSDictionary *tmpD in storeCrosswords)
        [storeCrosswordIds addObject:[tmpD objectForKey:@"cwId"]];
}


-(void)receiveJSONPackages:(NSMutableDictionary*)pk
{
    storePackages = [[pk objectForKey:@"packages"] mutableCopy];
    storePackageIds = [[NSMutableArray alloc] initWithCapacity:[storePackages count]];
    for (NSDictionary *tmpD in storePackages)
    {
        [storePackageIds addObject:[tmpD objectForKey:@"paId"]];
    }
}

-(void)receiveJSONCategories:(NSMutableDictionary*)ct
{
    storeCategories = [[ct objectForKey:@"categories"] mutableCopy];
    storeCategoryIds = [[NSMutableArray alloc] initWithCapacity:[storeCategories count]];
    for (NSDictionary *tmpD in storeCategories)
        [storeCategoryIds addObject:[tmpD objectForKey:@"catId"]];
}

-(void)receiveJSONOffers:(NSMutableDictionary*)of
{
    self.storeIntroText = [of objectForKey:@"description"];
    storeOffers = [[of objectForKey:@"sections"] mutableCopy];
    storeOfferIds = [[NSMutableArray alloc] initWithCapacity:[storeOffers count]];
    for (NSDictionary *tmpD in storeOffers)
        [storeOfferIds addObject:[tmpD objectForKey:@"secId"]];
}

-(void)removeAlreadyOwnedPackages
{
    DataHolder *myData = [DataHolder sharedDataHolder];
    // First the packages
    BOOL updatedPackages = FALSE;
    NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
    for (int i=0;i<storePackageIds.count;i++)
    {
        NSNumber *tmpId = [storePackageIds objectAtIndex:i];
//        if ([myData isPackageFullyDownloaded:tmpId])
        if ([myData alreadyRegisteredPackage:tmpId])
        {
            [indexes addIndex:i];
            // Update list of crosswords
            NSMutableDictionary *storeP = [storePackages objectAtIndex:i];
            NSMutableDictionary *ownedP = [myData getPackageFromId:tmpId];
            NSNumber *storeId = [storeP objectForKey:@"paId"];
            NSNumber *ownedId = [ownedP objectForKey:@"paId"];
            // Sanity check
            if ([storeId isEqualToNumber:ownedId] && [storeId isEqualToNumber:tmpId])
            {
                [ownedP setObject:[storeP objectForKey:@"crosswords"] forKey:@"crosswords"];
                updatedPackages = TRUE;
            }
        }
    }
    [storePackageIds removeObjectsAtIndexes:indexes];
    [storePackages removeObjectsAtIndexes:indexes];
    [indexes release];
    
    self.storeOffers = [self cleanUpCollections:storeOffers];
    storeOfferIds = [[NSMutableArray alloc] initWithCapacity:[storeOffers count]];
    for (NSDictionary *tmpD in storeOffers)
        [storeOfferIds addObject:[tmpD objectForKey:@"secId"]];
  
    self.storeCategories = [self cleanUpCollections:storeCategories];
//    self.storeCategories = [[NSMutableArray alloc] init];
    storeCategoryIds = [[NSMutableArray alloc] initWithCapacity:[storeCategories count]];
    for (NSDictionary *tmpD in storeCategories)
        [storeCategoryIds addObject:[tmpD objectForKey:@"catId"]];
    if (updatedPackages)
        [myData saveMyPackages];
}

-(NSMutableArray*)cleanUpCollections:(NSArray*)col
{
    NSMutableArray *tmpCollections = [[[NSMutableArray alloc] init] autorelease];
    for (NSDictionary *tmpD in col)
    {
        NSMutableArray *tmpPackages = [[NSMutableArray alloc] init];
        NSMutableArray *tmpA = [tmpD objectForKey:@"packages"];
        for (NSNumber *tmpN in tmpA)
        {
            if ([storePackageIds containsObject:tmpN])
                [tmpPackages addObject:tmpN];
        }
        if ([tmpPackages count] > 0)
        {
            NSMutableDictionary *tmpOffer = [tmpD mutableCopy];
            [tmpOffer setObject:tmpPackages forKey:@"packages"];
            [tmpCollections addObject:tmpOffer];
            [tmpOffer release];
        }
        [tmpPackages release];
    }
    return tmpCollections;
}

#pragma mark -

-(int)numberOfOfferSections
{
    return [storeOfferIds count];
}

-(int)numberOfPackagesInOfferSection:(int)s
{
    NSDictionary *tmpD = [storeOffers objectAtIndex:s];
    NSArray *tmpA = [tmpD objectForKey:@"packages"];
    return [tmpA count];
}

-(NSDictionary*)packageInOfferSection:(int)s andRow:(int)r
{
    NSDictionary *tmpD = [storeOffers objectAtIndex:s];
    NSArray *tmpA = [tmpD objectForKey:@"packages"];
    return [storePackages objectAtIndex:[storePackageIds indexOfObject:[tmpA objectAtIndex:r]]];
}

-(NSString*)titleForOfferSection:(int)s
{
    NSDictionary *tmpD = [storeOffers objectAtIndex:s];
    return [tmpD objectForKey:@"name"];
}

-(NSDictionary*)categoryAtRow:(int)r
{
    return [storeCategories objectAtIndex:r];
}

-(NSNumber*)categoryIDAtRow:(int)r
{
    return [storeCategoryIds objectAtIndex:r];
}

-(NSDictionary*)categoryFromID:(NSNumber*)cid
{
    return [storeCategories objectAtIndex:[storeCategoryIds indexOfObject:cid]];
}

-(int)numberOfCategories
{
    return storeCategoryIds.count;
}

-(NSDictionary*)getPackageFromId:(NSNumber*)pid
{
    int ix = -1;
    for (int i=0;i<storePackageIds.count;i++)
    {
        NSNumber *tmpN = [storePackageIds objectAtIndex:i];
        if ([tmpN intValue] == [pid intValue])
        {
            ix = i;
        }
    }
    if (ix >= 0)
        return [storePackages objectAtIndex:ix];
    else
        return NULL;
}

-(NSUInteger)getPackageNumberFromId:(NSNumber*)pid
{
    return [storePackageIds indexOfObject:pid];
}

-(NSDictionary*)getPackageFromNumber:(int)num
{
    return [storePackages objectAtIndex:num];
}

-(NSArray*)filterOutUnpublishedCrosswords:(NSArray*)ids
{
    NSMutableArray *holder = [[[NSMutableArray alloc] initWithCapacity:[ids count]] autorelease];
    for (NSNumber *num in ids)
        if ([storeCrosswordIds indexOfObject:num] != NSNotFound)
            [holder addObject:num];
    return holder;
}

-(void)clearPurchases
{
    packagesPurchased = [[NSMutableSet alloc] initWithCapacity:50];
}

-(BOOL)hasPurchasedPackage:(NSNumber*)pid
{
//    NSLog(@"Packages purchased: %@",packagesPurchased);
    return [packagesPurchased containsObject:pid];
}

-(BOOL)isBeingDownloaded:(NSNumber*)pid
{
    return [packagesBeingDownloaded containsObject:pid];
}

-(void)setAsBeingDownloaded:(NSNumber*)pid
{
    if (packagesBeingDownloaded == nil)
        packagesBeingDownloaded = [[NSMutableSet alloc] initWithCapacity:10];

    [packagesBeingDownloaded addObject:pid];
}

-(void)cancelDownload:(NSNumber*)pid
{
    [packagesBeingDownloaded removeObject:pid];
}

-(void)doneDownloading:(NSNumber*)pid
{
    [packagesBeingDownloaded removeObject:pid];
    [self setAsPurchased:pid];
    [self removeAlreadyOwnedPackages];
}

-(void)setAsPurchased:(NSNumber*)pid
{
    if (packagesPurchased == nil)
        [self clearPurchases];
    
    [packagesPurchased addObject:pid];
}

-(NSArray*)getListOfStorePackageIds
{
    NSMutableArray *tmpA = [[[NSMutableArray alloc] initWithCapacity:[storePackageIds count]] autorelease];
    for (NSNumber *tmpN in storePackageIds)
        [tmpA addObject:[tmpN stringValue]];
    return tmpA;
}

-(NSString*)getContentDescriptionFromPackage:(NSDictionary*)pk;
{
    NSArray *tmpA = [pk objectForKey:@"crosswords"];
    
    NSString *typeInfo = NULL;
    
    int numOwned = 0;
    BOOL mixed = FALSE;
    for (NSNumber *tmpN in tmpA)
    {
        NSUInteger pos = [storeCrosswordIds indexOfObject:tmpN];
        if (pos != NSNotFound)
        {
            NSDictionary *tmpD = [storeCrosswords objectAtIndex:pos];
            if ([[DataHolder sharedDataHolder].myCrosswordIds containsObject:tmpN])
                numOwned++;
            if (typeInfo == NULL)
                typeInfo = [tmpD objectForKey:@"type"];
            else if (![typeInfo isEqualToString: [tmpD objectForKey:@"type"]])
                mixed = TRUE;
        }
    }
    if (mixed)
        typeInfo = @"blandade";
    NSString *ownedInfo = @"";
    if (numOwned == 1)
        ownedInfo = @", varav 1 redan ägt";
    else if (numOwned > 1)
        ownedInfo = [NSString stringWithFormat:@", varav %d redan ägda",numOwned];

    return [NSString stringWithFormat:@"%d %@%@",[tmpA count],[typeInfo lowercaseString],ownedInfo];
}

-(NSDictionary*)getCrosswordFromId:(NSNumber*)cwId
{
    NSUInteger ix = [storeCrosswordIds indexOfObject:cwId];
    if (ix == NSNotFound)
        return NULL;
    else
        return [storeCrosswords objectAtIndex:ix];
}

@end
