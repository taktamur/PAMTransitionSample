//
//  PAMCollectionViewController.m
//  PAMTransition
//
//

#import "PAMCollectionViewController.h"


#pragma mark - UIPinchGestureRecognizer+PAMUtil
// PinchGestureをカテゴリ拡張
// このジェスチャーが拡大してるのか縮小しているのか
typedef enum PAMPinchGestureZoomStatus:NSUInteger{
    PAMPinchGestureZoomStatusZoomIn,  // 拡大
    PAMPinchGestureZoomStatusZoomOut, // 縮小
}PAMPinchGestureZoomStatus;


@interface UIPinchGestureRecognizer(PAMUtil)
// 拡大中か縮小中か
@property(readonly)PAMPinchGestureZoomStatus pam_zoomStatus;
// transitionLayout.transitionProgress に値をそのまま突っ込めるように、
// 拡大中縮小中にあわせて、scale(0.5〜2.0)をprogress(0.0〜1.0)に変換する
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
    // はみ出してるところを丸める
    progress = progress > 1.0 ? 1.0 : progress;
    progress = progress < 0.0 ? 0.0 : progress;
    return progress;
}
@end

#pragma mark - UICollectionViewFlowLayout+PAMUtil
@interface UICollectionViewFlowLayout(PAMUtil)
+(UICollectionViewFlowLayout *)layoutWithHorizontalItemCount:(NSUInteger)count;
@end;
@implementation UICollectionViewFlowLayout(PAMUtil)
+(UICollectionViewFlowLayout *)layoutWithHorizontalItemCount:(NSUInteger)count
{
    NSAssert(count!=0, @"zero count");
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.itemSize=CGSizeMake(310/count,310/count);
    layout.minimumInteritemSpacing=1.0;
    layout.minimumLineSpacing=1.0;
    return layout;

}
@end

#pragma mark - PAMCollectionViewController
@interface PAMCollectionViewController ()
@property(nonatomic,readonly)UICollectionViewTransitionLayout *transitionLayout;
@property(nonatomic)NSUInteger currentHoraizontalItemCount; // 今現在の横方向のItem数
@property(nonatomic)PAMPinchGestureZoomStatus zoomingStatus; // 今現在ズームしている方向
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
    self.collectionView.collectionViewLayout = [UICollectionViewFlowLayout layoutWithHorizontalItemCount:self.currentHoraizontalItemCount];
    [self enableGesture];
}

#define kPAMProgressThreshold 0.5
-(void)pinchAction:(UIPinchGestureRecognizer *)gesture
{
    switch(gesture.state){
        case UIGestureRecognizerStateBegan:
        {
            NSLog(@"begin scale=%f",gesture.scale);
            // 拡大なのか縮小なのかを記録しておく。
            // これをしておかないと、拡大で開始して途中で縮小したりするとおかしな事になる。
            self.zoomingStatus = gesture.pam_zoomStatus;

            // Transitionする先のLayoutを用意
            NSUInteger nextItemCount = [self nextHoraizontalItemCount];
            UICollectionViewLayout *nextLayout=[UICollectionViewFlowLayout layoutWithHorizontalItemCount:nextItemCount];

            // Transitionの開始
            [self.collectionView startInteractiveTransitionToCollectionViewLayout:nextLayout
                                                                       completion:^(BOOL completed, BOOL finish) {
                                                                           NSLog( @"completion");
                                                                           // Transitionの完了時にジェスチャーを止めるので、ここで再開
                                                                           [self enableGesture];
                                                                       }];
        }
            break;
        case UIGestureRecognizerStateChanged:
            // Transitionの進捗(progress)を0.0〜1.0で更新
            self.transitionLayout.transitionProgress = [gesture pam_transitionProgressWithZoomStatus:self.zoomingStatus];
            NSLog( @"transitionProgress=%f",self.transitionLayout.transitionProgress);
            break;
        case UIGestureRecognizerStateEnded:
            // Transitionを完了
            if( self.transitionLayout.transitionProgress > kPAMProgressThreshold ){
                [self.collectionView finishInteractiveTransition];
                self.currentHoraizontalItemCount = [self nextHoraizontalItemCount];
            }else{
                [self.collectionView cancelInteractiveTransition];
            }
            // 最後のアニメーションが終わるまでジェスチャーを停止
            [self disableGesture];
            break;
        default:
            break;
    }
}
#pragma mark - Gesture controll.
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


#pragma mark - util.
-(NSUInteger)nextHoraizontalItemCount
{
    NSUInteger nextCount;
    switch (self.zoomingStatus) {
        case PAMPinchGestureZoomStatusZoomIn:
            nextCount = self.currentHoraizontalItemCount-1;
            nextCount = nextCount==0 ? 1 : nextCount;
            break;
        case PAMPinchGestureZoomStatusZoomOut:
            nextCount = self.currentHoraizontalItemCount+1;
            break;
    }
    return nextCount;
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

#pragma mark - UICollectionViewDatasource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 100;
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell =  [collectionView dequeueReusableCellWithReuseIdentifier:@"cell"
                                                                            forIndexPath:indexPath];
    NSUInteger color = indexPath.row % 3;
    switch (color) {
        case 0:
            cell.backgroundColor=[UIColor redColor];
            break;
        case 1:
            cell.backgroundColor=[UIColor greenColor];
            break;
        default:
            cell.backgroundColor=[UIColor blueColor];
            break;
    }
    return cell;
}
@end
