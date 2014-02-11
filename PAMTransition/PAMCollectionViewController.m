//
//  PAMCollectionViewController.m
//  PAMTransition
//
//  Created by tak on 2014/02/11.
//  Copyright (c) 2014年 taktamur. All rights reserved.
//

#import "PAMCollectionViewController.h"

@interface PAMCollectionViewController ()
@property(nonatomic, readonly)UICollectionViewTransitionLayout *transitionLayout;
@property(nonatomic)NSUInteger horaizontalCellCount;
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
    
    self.collectionView.dataSource=self;
    self.horaizontalCellCount=3;
    self.collectionView.collectionViewLayout = [self layoutWithHorizontalCount:self.horaizontalCellCount];
    
    UIPinchGestureRecognizer *gesture = [UIPinchGestureRecognizer new];
    [gesture addTarget:self action:@selector(pinchAction:)];
    [self.collectionView addGestureRecognizer:gesture];
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
            break;
        case UIGestureRecognizerStateChanged:
            if( self.transitionLayout == nil ){
                if (gesture.scale > 1.0) {
                    // 拡大
                    if( self.horaizontalCellCount == 1 ){
                        // これ以上拡大は出来ない
                    }else{
                        NSUInteger nextCount = self.horaizontalCellCount-1;
                        UICollectionViewLayout *nextLayout = [self layoutWithHorizontalCount:nextCount];
                        [self.collectionView startInteractiveTransitionToCollectionViewLayout:nextLayout
                                                                                   completion:nil];
                    }
                }else{
                    // 縮小
                    NSUInteger nextCount = self.horaizontalCellCount+1;
                    UICollectionViewLayout *nextLayout = [self layoutWithHorizontalCount:nextCount];
                    [self.collectionView startInteractiveTransitionToCollectionViewLayout:nextLayout
                                                                               completion:nil];
                }
            }
            if( gesture.scale > 1.0 ){
                // 拡大中 scaleの1.0〜2.0をprogressの0.0〜1.0にマッピング
                CGFloat progress = gesture.scale > 2.0 ? 2.0:gesture.scale;
                self.transitionLayout.transitionProgress = progress - 1.0;
            }else{
                // 縮小中 scaleの1.0〜0.5をprogressの0.0〜1.0にマッピング
                CGFloat progress = (1.0-gesture.scale)*2.0;
                if( progress > 1.0 ){
                    progress = 1.0;
                }
                self.transitionLayout.transitionProgress=progress;
            }
            NSLog( @"transitionProgress=%f",self.transitionLayout.transitionProgress);
            break;
        case UIGestureRecognizerStateEnded:
            if( self.transitionLayout != nil ){
                if ((gesture.scale > 2.0) || (gesture.scale < 0.5)) {
                    [self.collectionView finishInteractiveTransition];
                    if( gesture.scale > 2.0 ){
                        self.horaizontalCellCount = self.horaizontalCellCount-1;
                    }else{
                        self.horaizontalCellCount = self.horaizontalCellCount+1;
                    }
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
-(UICollectionViewTransitionLayout *)transitionLayout
{
    id layout = self.collectionView.collectionViewLayout;
    if( [layout isKindOfClass:[UICollectionViewTransitionLayout class]]){
        return layout;
    }else{
        return nil;
    }
}

-(NSUInteger)horaizontalCountFromLayout:(UICollectionViewFlowLayout *)flowLayout
{
    return 310/flowLayout.itemSize.width;
}
-(UICollectionViewLayout *)layoutWithHorizontalCount:(NSUInteger) count
{
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
