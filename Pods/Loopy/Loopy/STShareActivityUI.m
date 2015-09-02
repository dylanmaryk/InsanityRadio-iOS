//
//  STShare.m
//  Loopy
//
//  Created by David Jedeikin on 10/23/13.
//  Copyright (c) 2013 ShareThis. All rights reserved.
//

#import "STShareActivityUI.h"
#import "STActivity.h"
#import "STFacebookActivity.h"
#import "STTwitterActivity.h"
#import "STConstants.h"
#import "STShare.h"

@implementation STShareActivityUI

@synthesize parentController;
@synthesize apiClient;

- (id)initWithParent:(UIViewController *)parent apiClient:(STAPIClient *)client {
    self = [super init];
    if(self) {
        self.parentController = parent;
        self.apiClient = client;
        //listen for share events (both intent to share -- beginning -- and end -- share complete)
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleShareDidBegin:)
                                                     name:LoopyShareDidBegin
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleShareDidComplete:)
                                                     name:LoopyShareDidComplete
                                                   object:nil];
    }
    
    return self;
}

//Returns the default set of Activities using the specified activity items
//These are newly-created each time as activities will vary
- (NSArray *)getDefaultActivities:(NSArray *)activityItems {
    STFacebookActivity *fbActivity = [[STFacebookActivity alloc] init];
    STTwitterActivity *twitterActivity = [[STTwitterActivity alloc] init];
    
    return @[fbActivity, twitterActivity];
}

//Returns UIActivityViewController for specified items and activities
//This is the ViewController to SELECT Activity (i.e. social network) to share
- (UIActivityViewController *)newActivityViewController:(NSArray *)shareItems withActivities:(NSArray *)activities {
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:shareItems
                                                                                         applicationActivities:activities];
    //by default, e-mail and MMS are included, but they will not be tracked as shares
    activityViewController.excludedActivityTypes = @[UIActivityTypePostToFacebook,
                                                     UIActivityTypePostToTwitter,
                                                     UIActivityTypePostToWeibo,
                                                     UIActivityTypeCopyToPasteboard];
    activityViewController.completionHandler = ^(NSString *activityType, BOOL completed) {
        if(completed) {
            [[NSNotificationCenter defaultCenter] postNotificationName:LoopyActivityDidComplete object:activityType];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:LoopyActivityDidCancel object:activityType];
        }
    };
    return activityViewController;
}

//Returns SLComposeViewController with specified activity items for specified service type
//The is the view controller to share the activity items to a specified social network
//TODO for now simply assumes first activity item is a NSString shortlink
- (SLComposeViewController *)newActivityShareController:(id)activityObj {
    NSString *slServiceType = nil;
    NSArray *activityItems = nil;
    SLComposeViewController *controller = nil;
    
    if([[activityObj class] conformsToProtocol:@protocol(STActivity)]) {
        id<STActivity> activity = (id<STActivity>)activityObj;
        activityItems = [activity shareItems];
        slServiceType = [activity activityType];
    }
    
    controller = [SLComposeViewController composeViewControllerForServiceType:slServiceType];
    
    //if any item is a URL, use it as a URL
    //any other items wil be stringified, concatenated, and used as initial text
    NSMutableString *initialText = [NSMutableString stringWithFormat:@""];
    if([activityItems count] > 0) {
        for (id item in activityItems) {
            if([item isKindOfClass:[NSString class]]) {
                NSString *itemStr = (NSString *)item;
                
                //try to make it a URL if one doesn't already exist
                NSURL *url = [NSURL URLWithString:itemStr];
                if(!url) {
                    [initialText appendString:itemStr];
                }
                else {
                    [controller addURL:url];
                }
            }
            else if([item isKindOfClass:[NSURL class]]) {
                [controller addURL:(NSURL *)item];
            }
        }
        
        [controller setInitialText:initialText];
    }
    
    return controller;
}

#pragma mark - UI operations

//Shows main share selector dialog
- (void)showActivityViewDialog:(UIActivityViewController *)activityController completion:(void (^)(void))completion {
    [self.parentController presentViewController:activityController animated:YES completion:completion];
}

//Shows specific share dialog for selected service
- (void)handleShareDidBegin:(NSNotification *)notification {
    __block id<STActivity> activity = (id<STActivity>)[notification object];
    
    //dismiss share selector and bring up activity-specific share dialog
    [self.parentController dismissViewControllerAnimated:YES completion:^ {
        SLComposeViewController *controller = [self newActivityShareController:activity];
        controller.completionHandler = ^(SLComposeViewControllerResult result) {
            switch(result) {
                case SLComposeViewControllerResultCancelled:
                    [[NSNotificationCenter defaultCenter] postNotificationName:LoopyShareDidCancel object:activity];
                    break;
                case SLComposeViewControllerResultDone:
                    [[NSNotificationCenter defaultCenter] postNotificationName:LoopyShareDidComplete object:activity];
                    break;
            }
        };
        [self.parentController presentViewController:controller animated:YES completion:nil];
    }];
}

//calls out to API to report share
- (void)handleShareDidComplete:(NSNotification *)notification {
    id<STActivity> activity = (id<STActivity>)[notification object];
    NSArray *shareItems = activity.shareItems;
    NSString *shareItem = (NSString *)[shareItems lastObject]; //by default last item is the shortlink or other share item
    STShare *shareObj = [self.apiClient reportShareWithShortlink:shareItem
                                                         channel:activity.activityType];
    [self.apiClient reportShare:shareObj
                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:LoopyRecordShareDidSucceed object:responseObject];
                        }
                        failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:LoopyRecordShareDidFail object:error];
                        }];
    
}

@end
