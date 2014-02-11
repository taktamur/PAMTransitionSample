//
//  PAMCollectionViewController.m
//  PAMTransition
//
//  Created by tak on 2014/02/11.
//  Copyright (c) 2014年 taktamur. All rights reserved.
//

#import "PAMCollectionViewController.h"

typedef enum PAMPinchGestureZoomStatus:NSUInteger{
    PAMPinchGestureZoomStatusZoomIn,  // 拡大
    PAMPinchGestureZoomStatusZoomOut, // 縮小
}PAMPinchGestureZoomStatus;


@interface UIPinchGestureRecognizer(PAMUtil)
@property(readonly)PAMPinchGestureZoomStatus pam_zoomStatus;
-(CGFloat)pam_transitionProgressWithZoomStatus:(PAMPinchGestureZoomStatus)zoomStatus;
@end

@implementation UIPinchGestureRecognizer(PAMUtil)
-(PAMPinchGestureZoomStatus)pam_zoomStatus
{
    return self.scale > 1.0 ? PAMPinchGestureZoomStatusZoomIn : PAMPinchGestureZoomStatusZoomOut;
}
-(CGFloat)pam_transitionProgressWithZoomStatus:(PAMPinchGestureZoomStatus)zoomStatus
{
    CGFloat progress = 0.0;
    switch (zoomStatus) {
        case PAMPinchGestureZoomStatusZoomIn:
            // 拡大中 scaleの1.0〜2.0をprogressの0.0〜1.0にマッピング
            progress = self.scale - 1.0;
            break;
        case PAMPinchGestureZoomStatusZoomOut:
            // 縮小中 scaleの1.0〜0.5をprogressの0.0〜1.0にマッピング
            progress = 2.0 - 2.0*self.scale;
            break;
    }
    progress = progress > 1.0 ? 1.0 : progress;
    progress = progress < 0.0 ? 0.0 : progress;
    return progress;
}
@end

@interface PAMCollectionViewController ()
@property(nonatomic,readonly)UICollectionViewTransitionLayout *transitionLayout;
@property(nonatomic)NSUInteger currentHoraizontalItemCount;
@property(nonatomic)PAMPinchGestureZoomStatus zoomingStatus;
@property(nonatomic)UIPinchGestureRecognizer *pinchGesture;
@end

@implementation PAMCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.currentHoraizontalItemCount=3;
    self.collectionView.dataSource=self;
    self.collectionView.collectionViewLayout = [self layoutWithHorizontalCount:self.currentHoraizontalItemCount];
    [self enableGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)pinchAction:(UIPinchGestureRecognizer *)gesture
{
    switch(gesture.state){
        case UIGestureRecognizerStateBegan:
            NSLog(@"begin scale=%f",gesture.scale);
            break;
            
        case UIGestureRecognizerStateChanged:
            if( self.transitionLayout == nil ){
//            if ([self isInteractiveTransitioning]){
                // まだTransitionが開始されていない
                self.zoomingStatus = gesture.pam_zoomStatus;
                NSUInteger nextCellCount = [self nextHoraizontalItemCountWithZoomStatus:self.zoomingStatus];
                UICollectionViewLayout *nextLayout=[self layoutWithHorizontalCount:nextCellCount];
                
                [self.collectionView startInteractiveTransitionToCollectionViewLayout:nextLayout
                                                                           completion:^(BOOL completed, BOOL finish) {
                                                                               NSLog( @"completion");
                                                                               [self enableGesture];
                                                                           }];
            }
            self.transitionLayout.transitionProgress = [gesture pam_transitionProgressWithZoomStatus:self.zoomingStatus];
            NSLog( @"transitionProgress=%f",self.transitionLayout.transitionProgress);
            break;
        case UIGestureRecognizerStateEnded:
            if( self.transitionLayout != nil ){
//            if ([self isInteractiveTransitioning]){
                [self disableGesture];
                if( self.transitionLayout.transitionProgress > 0.5 ){
                    [self.collectionView finishInteractiveTransition];
                    self.currentHoraizontalItemCount = [self nextHoraizontalItemCountWithZoomStatus:self.zoomingStatus];
                }else{
                    [self.collectionView cancelInteractiveTransition];
                }
            }
            break;
        default:
            break;
    }
}

#pragma mark - util.
-(NSUInteger)nextHoraizontalItemCountWithZoomStatus:(PAMPinchGestureZoomStatus)zoomStatus
{
    NSUInteger nextHoraizontalItemCount;
    switch (self.zoomingStatus) {
        case PAMPinchGestureZoomStatusZoomIn:
            nextHoraizontalItemCount = self.currentHoraizontalItemCount-1;
            break;
        case PAMPinchGestureZoomStatusZoomOut:
            nextHoraizontalItemCount = self.currentHoraizontalItemCount+1;
            break;
    }
    return nextHoraizontalItemCount;
}

-(void)enableGesture
{
    if( self.pinchGesture == nil ){
        self.pinchGesture = [UIPinchGestureRecognizer new];
        [self.pinchGesture addTarget:self action:@selector(pinchAction:)];
    }
    [self.collectionView addGestureRecognizer:self.pinchGesture];
}
-(void)disableGesture
{
    [self.collectionView removeGestureRecognizer:self.pinchGesture];
}
-(BOOL)isInteractiveTransitioning
{
    return (self.transitionLayout!=nil);
}
-(UICollectionViewTransitionLayout *)transitionLayout
{
    id layout = self.collectionView.collectionViewLayout;
    if( [layout isKindOfClass:[UICollectionViewTransitionLayout class]]){
        return layout;
    }else{
        return nil;
    }
}
-(UICollectionViewLayout *)layoutWithHorizontalCount:(NSUInteger) count
{
    if( count == 0 ){
        count=1;
    }
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.itemSize=CGSizeMake(310/count,310/count);
    layout.minimumInteritemSpacing=1.0;
    layout.minimumLineSpacing=1.0;
    return layout;
}

#pragma mark - UICollectionViewDatasource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 10;
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [collectionView dequeueReusableCellWithReuseIdentifier:@"cell"
                                                     forIndexPath:indexPath];
}
@end
