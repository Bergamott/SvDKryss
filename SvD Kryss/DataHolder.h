//
//  DataHolder.h
//  XMLTest
//
//  Created by Karl Hörnell on 2012-12-08.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PACKAGE_TAG @"bundle"
#define CROSSWORD_TAG @"crossword"
#define LOCAL_PICTURE_TAG @"local-picture"
#define LOCAL_METADATA_TAG @"local-metadata"
#define PERCENTAGE_SOLVED_TAG @"percentage-solved"
#define LAST_MODIFIED_TAG @"last-modified"
#define SUBSCRIBER_COST @"subscriberCost"

#define ITEM_NONE @"dummyitems"
#define ITEM_CROSSWORDS @"crosswords"
#define ITEM_PACKAGES @"packages"

@interface DataHolder : NSObject {
    
    NSMutableArray *myPackages;
    NSMutableArray *myPackageIds;
    
    NSMutableArray *myCrosswords;
    NSMutableArray *myCrosswordIds;
    NSMutableDictionary *myCrosswordStats;
    
    NSMutableArray *crosswordSubsetList;

    NSMutableDictionary *currentCrossword;
    
    NSMutableDictionary *updatedSolutions;
    
    NSMutableSet *downloadedCrosswords;
    
    NSMutableSet *defaultPackageIDs;
}

+(DataHolder*)sharedDataHolder;

-(void)loadEverything;

-(void)loadMyPackages;
-(NSDictionary*)getMyPackageNumbered:(int)num;
-(int)getNumberOfCrosswordsInPackage:(NSDictionary*)pk;
-(int)getNumberOfStartedCrosswordsInPackage:(NSDictionary*)pk;

-(void)loadMyCrosswords;
-(void)saveMyCrosswords;
-(void)saveMyPackages;

-(void)getSubsetFromPackage:(NSDictionary*)pk;
-(void)getListOfStartedCrosswords;
-(void)getListOfStartedCrosswordsSince:(NSDate*)dt;

-(void)setForCurrentCrosswordProperty:(NSString*)prp value:(NSString*)val;
-(NSString*)getCurrentCrosswordProperty:(NSString*)prp;

-(NSMutableDictionary*)getMyCrosswordNumbered:(int)num;
-(NSMutableDictionary*)getCrosswordFromID:(NSNumber*)num;
-(NSMutableDictionary*)getPackageThatContainsCrossword:(NSNumber*)cwId;
-(NSMutableDictionary*)getPackageFromId:(NSNumber*)pid;
-(BOOL)isPackageFullyDownloaded:(NSNumber*)pkId;

-(int)numberOfPackagesAlreadyOwned:(NSArray*)idList;
-(BOOL)alreadyRegisteredPackage:(NSNumber*)pId;
-(void)updatePackage:(NSNumber*)pkID withListOfCrosswords:(NSArray*)cws;
-(BOOL)alreadyOwnsCrossword:(NSNumber*)cId;

-(void)addPackageFromStore:(NSDictionary*)pk;
-(void)addPackageAsBought:(NSDictionary*)pk;

-(int)numberOfCrosswordsAlreadyOwned:(NSArray*)idList;

-(NSString*)getCurrentDataFilename;
-(NSString*)getHeadlineFromPackage:(NSDictionary*)pk;
-(NSString*)getContentDescriptionFromPackage:(NSDictionary*)pk;
-(NSString*)getContentDescriptionFromStorePackage:(NSDictionary*)pk purchased:(BOOL)pu;

-(NSString*)getHeadlineFromCrossword:(NSDictionary*)cw;
-(NSString*)getDescriptionFromCrossword:(NSDictionary*)cw;

-(NSString*)extractFilename:(NSString*)url;
-(void)convertToJSON:(NSDictionary*)dic;

//-(NSObject*)packageSortingValue:(NSDictionary*)pk;
-(int)findInsertionPointForPackage:(NSDictionary*)pk;

-(BOOL)haveAllCrosswordsBeenDownloaded:(NSDictionary*)pk;
-(BOOL)hasThisCrosswordBeenDownloaded:(NSDictionary*)cw;

-(void)integrateStoredSolution:(NSMutableDictionary*)cw;
//-(void)receiveJSONCrosswords:(NSMutableDictionary*)cw;

-(void)setPercentageSolvedForCurrentCrossword:(int)p;
-(void)setPercentageSolved:(int)p ForCrosswordId:(NSNumber*)cwId;
-(NSString*)getPercentageSolvedForCrosswordId:(NSNumber*)cwId;
-(NSDate*)getLastModifiedForCrosswordId:(NSNumber*)cwId;
-(void)setLastUploaded:(NSString*)timestamp forCrosswordId:(NSNumber*)cwId;
-(NSString*)getLastUploadedForCrosswordId:(NSNumber*)cwId;
-(void)saveMyCrosswordStats;
-(void)loadMyCrosswordStats;
-(void)loadUpdatedSolutions;
-(void)saveUpdatedSolutions;
-(void)appendUpdatedSolution:(NSDictionary*)sol;
-(void)removeUpdatedSolutionForCurrent;
-(NSString*)updatedSolutionResponseForPercent:(int)p;
-(NSData*)getUpdatedSolutionDataForCurrent;
-(NSData*)getUpdatedSolutionIfSameAsThisDevice;

-(void)setCrosswordAsDownloaded:(NSDictionary*)cw;

-(BOOL)isPackagePartOfDefault:(NSNumber*)pId;
-(void)clearCrosswordsInPackageNumber:(int)n;

@property (nonatomic,retain) NSMutableArray *myPackages;
@property (nonatomic,retain) NSMutableArray *myPackageIds;

@property (nonatomic,retain) NSMutableArray *myCrosswords;
@property (nonatomic,retain) NSMutableArray *myCrosswordIds;
@property (nonatomic,retain) NSMutableDictionary *myCrosswordStats;

@property (nonatomic,retain) NSMutableArray *crosswordSubsetList;

@property (nonatomic,retain) NSMutableDictionary *currentCrossword;

@property (nonatomic,retain) NSMutableDictionary *updatedSolutions;

@property (nonatomic,retain) NSMutableSet *downloadedCrosswords;

@property (nonatomic,retain) NSMutableSet *defaultPackageIDs;


@end
