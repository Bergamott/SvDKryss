//
//  InAppPurchaseManager.m
//  SvD Kryss
//
//  Created by Karl on 2013-02-06.
//  Copyright (c) 2013 KEP Games. All rights reserved.
//

#import "InAppPurchaseManager.h"
#import "DataHolder.h"
#import "DownloadManager.h"
#import "StoreDataHolder.h"
#import "CustomAlertView.h"

#define APP_PREFIX_STRING @"se.svd.svdkorsord"

@implementation InAppPurchaseManager

@synthesize verifiedProducts;

+(InAppPurchaseManager*)sharedInAppPurchaseManager
{
	static InAppPurchaseManager *sharedInAppPurchaseManager;
	
	@synchronized(self)
	{
		if (!sharedInAppPurchaseManager)
			sharedInAppPurchaseManager = [[InAppPurchaseManager alloc] init];
		return sharedInAppPurchaseManager;
	}
}

-(void)loadStore
{
    // restarts any purchases if they were interrupted last time the app was open
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

// call this before making a purchase
//
-(BOOL)canMakePurchases
{
    return [SKPaymentQueue canMakePayments];
}

-(void)requestPackagesProductData:(NSArray*)pIds;
{
    NSMutableSet *productIds = [[NSMutableSet alloc] initWithCapacity:[pIds count]];
    for (NSString *tmpS in pIds)
    {
        [productIds addObject:tmpS];
    }
    productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIds];
    productsRequest.delegate = self;
    [productsRequest start];
    NSLog(@"Requesting products list from In-App Store");
    [productIds release];
    
    // we will release the request object in the delegate callback
}

// For testing purposes
-(void)mockRequestPackagesProductData:(NSArray*)pIds
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerProductsFetchedNotification object:self userInfo:nil];
}

#pragma mark -
#pragma mark SKProductsRequestDelegate methods

-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    verifiedProducts = [[NSMutableDictionary alloc] initWithCapacity:[response.products count]];
//    NSLog(@"Valid products:");
    for (SKProduct *tmpSP in response.products)
    {
        [verifiedProducts setObject:tmpSP forKey:tmpSP.productIdentifier];
        
//        NSLog(@"Identifier: %@",tmpSP.productIdentifier);
//        NSLog(@"Description: %@",tmpSP.localizedDescription);
//        NSLog(@"Price: %@",[self localizedPriceFor:tmpSP]);
    }
    NSLog(@"");
    NSLog(@"Invalid products: %@",response.invalidProductIdentifiers);
    
    // finally release the reqest we alloc/init’ed in requestProUpgradeProductData
    [productsRequest release];
    productsRequest = NULL;
        
    [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerProductsFetchedNotification object:self userInfo:nil];
}

-(void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Problem contacting In-App Store");
    NSLog(@"%@",error);
    CustomAlertView *alert = [[CustomAlertView alloc] initWithTitle:@"Uppkopplingen misslyckades"
                                                            message:@"Det gick ej att ansluta mot iTunes. Vänligen försök igen senare."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
    [alert show];
    [alert release];
    [productsRequest release];
    productsRequest = NULL;
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction wasSuccessful:(BOOL)wasSuccessful
{
    // remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:transaction, @"transaction" , nil];
    if (wasSuccessful)
    {
        // send out a notification that we’ve finished the transaction
        NSLog(@"Transaction successful");
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionSucceededNotification object:self userInfo:userInfo];
    }
    else
    {
        // send out a notification for the failed transaction
        NSLog(@"Transaction failed");
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionFailedNotification object:self userInfo:userInfo];
    }
}

//
// called when the transaction was successful
//
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
//    [self recordTransaction:transaction];
//    [self provideContent:transaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
}

//
// called when a transaction has been restored and and successfully completed
//
- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
//    [self recordTransaction:transaction.originalTransaction];
//    [self provideContent:transaction.originalTransaction.payment.productIdentifier];
    [self finishTransaction:transaction wasSuccessful:YES];
}

//
// called when a transaction has failed
//
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        // error!
        [self finishTransaction:transaction wasSuccessful:NO];
    }
    else
    {
        // this is fine, the user just cancelled, so don’t notify. Send message to restore Disclosure View
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        NSLog(@"Transaction cancelled");
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerDownloadComplete object:self userInfo:nil];
    }
}

//
// called when the transaction status is updated
//
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

//
// Start a transaction
//
-(void)purchasePackage:(NSDictionary*)pk
{
//    NSNumber *cost = [pk objectForKey:@"cost"];
//    NSNumber *subscriberCost = [pk objectForKey:SUBSCRIBER_COST];
//    if ([cost intValue] == 0 || (subscriberCost != NULL && [subscriberCost intValue] == 0))
    if ([[DownloadManager sharedDownloadManager] isPackageFree:pk])
    {
        NSLog(@"Free package ...");
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerFreePurchaseNotification object:self userInfo:pk];
    }
    else
    {
        NSLog(@"Package that costs money ...");
        NSNumber *packageID = [pk objectForKey:@"paId"];
        SKPayment *payment = [SKPayment paymentWithProduct:[verifiedProducts objectForKey:[packageID stringValue]]];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

-(void)restoreAllPurchases
{
    if ([StoreDataHolder sharedStoreDataHolder].storePackages != NULL)
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    else // We need the store package list first
        [[DownloadManager sharedDownloadManager] getStorePackages];
}

-(NSString*)localizedPriceFor:(SKProduct*)skp
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:skp.priceLocale];
    NSString *formattedString = [numberFormatter stringFromNumber:skp.price];
    [numberFormatter release];
    return formattedString;
}

-(void)cancelRequestWhenLeavingStore
{
    if (productsRequest != NULL)
    {
        [productsRequest cancel];
        [productsRequest release];
        productsRequest = NULL;
    }
}

@end
