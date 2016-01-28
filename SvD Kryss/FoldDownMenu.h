//
//  FoldDownMenu.h
//  XMLTest
//
//  Created by Karl on 2012-12-20.
//
//

#import <UIKit/UIKit.h>

@class PullTab;
@class Checkbox;

@interface FoldDownMenu : UIView {
    IBOutlet UIView *helpView;
    IBOutlet UIView *settingsView;
    IBOutlet UIView *competitionView;
    
    NSArray *myViews;
    
    IBOutlet UISegmentedControl *mySegment;
    IBOutlet PullTab *pullDown;
    IBOutlet UIImageView *bottomEdge;
    
    IBOutlet Checkbox *markerButton;
    IBOutlet Checkbox *pencilButton;
}

-(void)initiate;
-(void)showViewNumber:(int)num animated:(BOOL)anm;
-(void)hideMenuAnimated:(BOOL)anm;
-(void)showMenuAnimated:(BOOL)anm;
-(IBAction)didChangeSegmentControl:(id)sender;
-(void)downFlapPressed;
-(void)upFlapPressed;
-(IBAction)toggleCheckbox:(id)sender;

-(void)enableHelp:(BOOL)active;

-(void)activateMarker:(BOOL)act;
-(void)activatePencil:(BOOL)act;

@property(nonatomic,retain) IBOutlet UIView *helpView;
@property(nonatomic,retain) IBOutlet UIView *settingsView;
@property(nonatomic,retain) IBOutlet UIView *competitionView;

@property(nonatomic,retain) NSArray *myViews;
@property(nonatomic,retain) IBOutlet UISegmentedControl *mySegment;
@property(nonatomic,retain) IBOutlet PullTab *pullDown;
@property(nonatomic,retain) IBOutlet UIImageView *bottomEdge;


@end
