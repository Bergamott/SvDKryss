//
//  StoreDataHolder.h
//  SvD Kryss
//
//  Created by Karl on 2013-01-31.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PACKAGE_TAG @"bundle"
#define CROSSWORD_TAG @"crossword"
#define CATEGORY_TAG @"category"
#define OFFER_TAG @"offer"

@interface StoreDataHolder : NSObject {
    
    NSMutableArray *storeOffers;
    NSMutableArray *storeCategories;
    NSMutableArray *storePackages;
    NSMutableArray *storeCrosswords;
    
    NSMutableArray *storeCrosswordIds;
    NSMutableArray *storePackageIds;
    NSMutableArray *storeOfferIds;
    NSMutableArray *storeCategoryIds;
    NSMutableSet *packagesBeingDownloaded;
    NSMutableSet *packagesPurchased;
    
    NSString *storeIntroText;
}

+(StoreDataHolder*)sharedStoreDataHolder;

-(void)receiveJSONCrosswords:(NSMutableDictionary*)cw;
-(void)receiveJSONPackages:(NSMutableDictionary*)pk;
-(void)receiveJSONCategories:(NSMutableDictionary*)ct;
-(void)receiveJSONOffers:(NSMutableDictionary*)of;
-(void)removeAlreadyOwnedPackages;
-(NSMutableArray*)cleanUpCollections:(NSArray*)col;

-(int)numberOfOfferSections;
-(int)numberOfPackagesInOfferSection:(int)s;
-(NSDictionary*)packageInOfferSection:(int)s andRow:(int)r;
-(NSString*)titleForOfferSection:(int)s;

-(NSDictionary*)categoryAtRow:(int)r;
-(NSNumber*)categoryIDAtRow:(int)r;
-(NSDictionary*)categoryFromID:(NSNumber*)cid;
-(int)numberOfCategories;
-(NSDictionary*)getPackageFromId:(NSNumber*)pid;
-(NSUInteger)getPackageNumberFromId:(NSNumber*)pid;
-(NSDictionary*)getPackageFromNumber:(int)num;
-(NSArray*)filterOutUnpublishedCrosswords:(NSArray*)ids;

-(void)clearPurchases;
-(BOOL)hasPurchasedPackage:(NSNumber*)pid;
-(BOOL)isBeingDownloaded:(NSNumber*)pid;
-(void)setAsPurchased:(NSNumber*)pid;
-(void)setAsBeingDownloaded:(NSNumber*)pid;
-(void)cancelDownload:(NSNumber*)pid;
-(void)doneDownloading:(NSNumber*)pid;

-(NSArray*)getListOfStorePackageIds;

-(NSString*)getContentDescriptionFromPackage:(NSDictionary*)pk;

-(NSDictionary*)getCrosswordFromId:(NSNumber*)cwId;

@property(nonatomic,retain) NSMutableArray *storeOffers;
@property(nonatomic,retain) NSMutableArray *storeCategories;
@property(nonatomic,retain) NSMutableArray *storePackages;
@property(nonatomic,retain) NSMutableArray *storeCrosswords;

@property(nonatomic,retain) NSMutableArray *storeCrosswordIds;
@property(nonatomic,retain) NSMutableArray *storePackageIds;
@property(nonatomic,retain) NSMutableArray *storeOfferIds;
@property(nonatomic,retain) NSMutableArray *storeCategoryIds;

@property(nonatomic,retain) NSMutableSet *packagesBeingDownloaded;
@property(nonatomic,retain) NSMutableSet *packagesPurchased;

@property(nonatomic,retain) NSString *storeIntroText;


@end
