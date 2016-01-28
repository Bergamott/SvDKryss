//
//  InAppPurchaseManager.h
//  SvD Kryss
//
//  Created by Karl on 2013-02-06.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#define kInAppPurchaseManagerProductsFetchedNotification @"kInAppPurchaseManagerProductsFetchedNotification"
#define kInAppPurchaseManagerStoreGeneralProblem @"kInAppPurchaseManagerStoreGeneralProblem"
#define kInAppPurchaseManagerTransactionFailedNotification @"kInAppPurchaseManagerTransactionFailedNotification"
#define kInAppPurchaseManagerTransactionSucceededNotification @"kInAppPurchaseManagerTransactionSucceededNotification"

#define kInAppPurchaseManagerFreePurchaseNotification @"kInAppPurchaseManagerFreePurchaseNotification"

#define kInAppPurchaseManagerDownloadComplete @"kInAppPurchaseManagerDownloadComplete"

@interface InAppPurchaseManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    SKProductsRequest *productsRequest;
    NSMutableDictionary *verifiedProducts;
}

+(InAppPurchaseManager*)sharedInAppPurchaseManager;
-(void)loadStore;
-(BOOL)canMakePurchases;
-(void)requestPackagesProductData:(NSArray*)pIds;
-(void)mockRequestPackagesProductData:(NSArray*)pIds;
-(void)purchasePackage:(NSDictionary*)pk;

-(NSString*)localizedPriceFor:(SKProduct*)skp;

-(void)restoreAllPurchases;

-(void)cancelRequestWhenLeavingStore;

@property(nonatomic,retain) NSMutableDictionary *verifiedProducts;

@end
