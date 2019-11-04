//
//  PortraitEditingView.m
//  PortraitEditing
//
//  Created by ATH on 2019/10/28.
//  Copyright © 2019 ath. All rights reserved.
//

#import "PortraitEditingView.h"
#import "UIImage+ImageUtils.h"
//手势移动头像框位置
typedef NS_ENUM(NSInteger,PortraitFramePosition){
    PortraitFramePositionNone = 1,
    PortraitFramePositionLeftTop,
    PortraitFramePositionTop,
    PortraitFramePositionRightTop,
    PortraitFramePositionRight,
    PortraitFramePositionRightBottom,
    PortraitFramePositionBottom,
    PortraitFramePositionLeftBottom,
    PortraitFramePositionLeft
};
@interface PortraitEditingView()
@property(nonatomic,strong)UIImage *portraitImage;
//手势
@property(nonatomic,strong)UIPinchGestureRecognizer *pinchGesture;
@property(nonatomic,strong)UIPanGestureRecognizer *panGesture;

@property(nonatomic,assign)CGFloat lastMoveX;//在一次移动过程中上次移动X方向的大小
@property(nonatomic,assign)CGFloat lastMoveY;//在一次移动过程中上一次移动Y方向的大小
@property(nonatomic,assign)PortraitFramePosition portraitFramePosition;//移动手势所触发的初始点在头像框上的哪部分位置：左上角顶点附近，上边界附近，右上角顶点附近等等。

@end
@implementation PortraitEditingView
+(id)portraitEditingViewWithImage:(UIImage *)portraitImage type:(PortraitEditingType)portraitEditiingType{
    PortraitEditingView *portraitEditingView = [[self alloc]initWithFrame:[UIScreen mainScreen].bounds portratitImage:portraitImage portraitEditingType:portraitEditiingType];
    return portraitEditingView;
}
-(id)initWithFrame:(CGRect)frame portratitImage:(UIImage *)portraitImage portraitEditingType:(PortraitEditingType)portraitEditingType;{
    if(self = [super initWithFrame:[UIScreen mainScreen].bounds]){
        self.portraitImage = portraitImage;
        self.portraitEditingType = portraitEditingType;
        [self initData];
        [self initView];
    }
    return self;
}
-(void)initData{
    self.maxTransformScale = 5;
    self.minTransformScale = 0.5;
    self.lastMoveX = 0;
    self.lastMoveY = 0;
    self.maxFrameIVW = [self defaultCuttingW];
    self.minFrameIVW = [self defaultCuttingW]/3;
}

/**
 初始化控件
 */
-(void)initView{
    UIColor *bgColor =[UIColor whiteColor];
    [self setBackgroundColor:bgColor];
   
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    self.portraitIV = [[UIImageView alloc]initWithFrame:screenBounds];
    [self.portraitIV setImage:self.portraitImage];
    [self.portraitIV setContentMode:UIViewContentModeScaleAspectFit];
    [self addSubview:self.portraitIV];

    self.maskView = [[UIView alloc]initWithFrame:screenBounds];
    self.maskView.backgroundColor = [UIColor blackColor];
    self.maskView.alpha = 0.8;
    [self.maskView setBackgroundColor:[UIColor blackColor]];
    [self addSubview:self.maskView];
    
    self.frameIV = [[UIImageView alloc]initWithFrame:screenBounds];
    [self.frameIV setContentMode:UIViewContentModeScaleAspectFit];
    self.frameIV.frame = [self defaultCuttingRect];
    [self addSubview:self.frameIV];
    
    self.dividerView = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetHeight(screenBounds)-75, CGRectGetWidth(screenBounds), 0.5)];
    [self.dividerView setBackgroundColor:[UIColor colorWithRed:150 green:150 blue:150 alpha:1]];
    self.dividerView.alpha = 0.1;
    [self addSubview:self.dividerView];
    
    self.cancelBtn = [[UIButton alloc]initWithFrame:CGRectMake(10,CGRectGetHeight(screenBounds)-50, 50, 30)];
    [self.cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [self.cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.cancelBtn.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [self.cancelBtn addTarget:self action:@selector(cancelBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.cancelBtn];
    
    self.resetBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetWidth(screenBounds)/2-25,CGRectGetHeight(screenBounds)-50, 50, 30)];
    [self.resetBtn setTitle:@"重置" forState:UIControlStateNormal];
    [self.resetBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [self.resetBtn.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [self.resetBtn addTarget:self action:@selector(resetBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.resetBtn setEnabled:NO];
    [self addSubview:self.resetBtn];
    
    self.completeBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetWidth(screenBounds)-60,CGRectGetHeight(screenBounds)-50, 50, 30)];
    [self.completeBtn setTitle:@"完成" forState:UIControlStateNormal];
    [self.completeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.completeBtn.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [self.completeBtn addTarget:self action:@selector(completeBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.completeBtn];
    
    if(self.portraitEditingType == PortraitEditingTypeCircle){
        [self.frameIV setImage:[UIImage imageNamed:@"circle_frame"]];
          self.maskView.layer.mask = [self cuttingShapeLayer:[self defaultCuttingRect] cornerRadius:[self defaultCuttingCorner]];
    }else{
        [self.frameIV setImage:[UIImage imageNamed:@"square_frame.png"]];
        self.maskView.layer.mask = [self cuttingShapeLayer:[self defaultCuttingRect] cornerRadius:0];
    }
    self.panGesture = [[UIPanGestureRecognizer alloc]init];
    [self.panGesture addTarget:self action:@selector(panGestureTouch:)];
    self.panGesture.minimumNumberOfTouches=1;
//    self.panGesture.delegate = self;
    [self addGestureRecognizer:self.panGesture];
    
    self.pinchGesture = [[UIPinchGestureRecognizer alloc]init];
    [self.pinchGesture addTarget:self action:@selector(pinchGestureTouch:)];
//    self.pinchGesture.delegate = self;
    [self addGestureRecognizer:self.pinchGesture];
    [self changeToProperTransformIfNeeded];
}
//生成遮罩层
- (CAShapeLayer *)cuttingShapeLayer:(CGRect)cuttingRect cornerRadius:(CGFloat)radius{
     UIBezierPath *cuttingPath =  [UIBezierPath bezierPathWithRoundedRect:cuttingRect cornerRadius:radius];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:[UIScreen mainScreen].bounds];
    [path appendPath:cuttingPath];
    path.usesEvenOddFillRule = YES;
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = path.CGPath;
    shapeLayer.fillColor= [UIColor blackColor].CGColor;
    shapeLayer.fillRule=kCAFillRuleEvenOdd;
    return shapeLayer;
}
-(CGFloat)currentPortraitIVScale{
    return CGRectGetWidth(self.portraitIV.frame)/CGRectGetWidth([self defaultPotraitIVFrame]);
}
/**
 对图片进行缩放或者对截剪框进行缩放以让截剪框内占满图片内容，截剪框内不能有空白。
 */
-(void)changeToProperTransformIfNeeded{
    CGRect imageFrameInPortrait = [self getImageFrameFromUIImageView:self.portraitIV.frame image:self.portraitIV.image];
    CGRect imageFrameInSelf = [self.portraitIV convertRect:imageFrameInPortrait toView:self];
    //截剪框(头像框)未被缩放
    if([self isRectEqual:self.frameIV.frame withRect:[self defaultCuttingRect]]){
        [self showMask];
        CGFloat scallX = 1;
        CGFloat scallY = 1;;
        CGFloat addLeftX = 0;
        CGFloat addTopY = 0;
        CGFloat addRightX = 0;
        CGFloat addBottomY = 0;
        CGFloat addX = 0;
        CGFloat addY = 0;
        if(CGRectGetWidth(imageFrameInSelf)<CGRectGetWidth(self.frameIV.frame)){
        //图片宽度小于截剪框宽度，需要放大宽度
            scallX = CGRectGetWidth(self.frameIV.frame)/CGRectGetWidth(imageFrameInSelf);
        }
        //图片高度小于截剪框高度，需要放大高度
        if(CGRectGetHeight(imageFrameInSelf)<CGRectGetHeight(self.frameIV.frame)){
            scallY  = CGRectGetHeight(self.frameIV.frame)/CGRectGetHeight(imageFrameInSelf);
        }
        CGFloat scale = scallY > scallX?scallY:scallX;
        
        CGFloat anchorPointX = 0.5;
        CGFloat anchorPointY = 0.5;
        // 1.只要在内框,只需放大，不用移动，需要修改anchorPoint
        // 2.半边内框，必然要移动和放大，可以修改anchorPoint
        //   3.全部外框，必然移动，放大看情况
        if(CGRectGetMinX(imageFrameInSelf)>CGRectGetMinX(self.frameIV.frame)){
            //图片最左边进入截剪框，需要往左移动
            addLeftX = CGRectGetMinX(self.frameIV.frame) - CGRectGetMinX(imageFrameInSelf);
            anchorPointX = 1;
        }
        if(CGRectGetMaxX(imageFrameInSelf)<CGRectGetMaxX(self.frameIV.frame)){
            //图片最右边进入截剪框，需要往右移动
            addRightX = CGRectGetMaxX(self.frameIV.frame) - CGRectGetMaxX(imageFrameInSelf);
            anchorPointX = 0;
        }
        if(addLeftX!=0&&addRightX!=0){//全部在内框
            if(addLeftX+addRightX!=0){
                anchorPointX = [self caculateAnchorPoint:addLeftX padding2:addRightX imageSizeLen:CGRectGetWidth(imageFrameInSelf) imageIVSizeLen:CGRectGetWidth(self.portraitIV.frame)];
            }else{
                anchorPointX = 0.5;
            }
            addX = 0;
        }else{
            if(addLeftX!=0){//左边在内框
                anchorPointX = CGRectGetMinX(imageFrameInPortrait)/CGRectGetWidth(self.portraitIV.frame);
                 addX =CGRectGetMinX(self.frameIV.frame)-CGRectGetMinX(imageFrameInSelf);
               
            }else if(addRightX!=0){//右边在内框
                anchorPointX = CGRectGetMaxX(imageFrameInPortrait)/CGRectGetWidth(self.portraitIV.frame);
                addX = CGRectGetMaxX(self.frameIV.frame)-CGRectGetMaxX(imageFrameInSelf);
            }else{//都不在内框
                addX = 0;
                anchorPointX = self.portraitIV.layer.anchorPoint.x;
            }
        }
        if(CGRectGetMinY(imageFrameInSelf)>CGRectGetMinY(self.frameIV.frame)){
            //图片最上边进入截剪框，需要往上移动
            addTopY = CGRectGetMinY(self.frameIV.frame) - CGRectGetMinY(imageFrameInSelf);
            anchorPointY = 1;
        }
        if(CGRectGetMaxY(imageFrameInSelf)<CGRectGetMaxY(self.frameIV.frame)){
            //图片最下边进入截剪框，需要往下移动
            addBottomY = CGRectGetMaxY(self.frameIV.frame) - CGRectGetMaxY(imageFrameInSelf);
            anchorPointY = 0;
        }
        if(addTopY!=0&&addBottomY!=0){
            if(addTopY+addBottomY!=0){
//                anchorPointY = fabs(addTopY/(fabs(addTopY)+fabs(addBottomY)));
                  anchorPointY = [self caculateAnchorPoint:addTopY padding2:addBottomY  imageSizeLen:CGRectGetHeight(imageFrameInSelf) imageIVSizeLen:CGRectGetHeight(self.portraitIV.frame)];
            }else{
                anchorPointY = 0.5;
            }
            addY = 0;
        }else{
            if(addTopY!=0){//上边在内框
                anchorPointY = CGRectGetMinY(imageFrameInPortrait)/CGRectGetHeight(self.portraitIV.frame);
                 addY = CGRectGetMinY(self.frameIV.frame)-CGRectGetMinY(imageFrameInSelf);
            }else if(addBottomY!=0){//下边在内框
                anchorPointY = CGRectGetMaxY(imageFrameInPortrait)/CGRectGetHeight(self.portraitIV.frame);
                addY =  CGRectGetMaxY(self.frameIV.frame)-CGRectGetMaxY(imageFrameInSelf);
            }else{//都不在内框
                addY = 0;
                anchorPointY = self.portraitIV.layer.anchorPoint.y;
            }
        }
        [self transformImageWithScale:scale anchor:CGPointMake(anchorPointX, anchorPointY) addX:addX addY:addY animatied:YES duration:0.3];
        
    }else{
        CGFloat scale = CGRectGetWidth([self defaultCuttingRect])/CGRectGetWidth(self.frameIV.frame);
        CGPoint anchorPoint = [self getAnchorPointWithCurrentFrameIVFrame:self.frameIV.frame position:self.portraitFramePosition];
        [self transformImageWithScale:scale anchor:anchorPoint  animatied:YES duration:0.5];
        [self resetFrameIV:self.portraitFramePosition];
        
    }
    
}

/**
 设置重置按钮的状态,如果portraitIV的尺寸不是最小的，则可重置其尺寸
 */
-(void)checkResetBtnState{
    if([self isRectEqual:self.portraitIV.frame withRect:[self getMinPortraitIVFrame]]){
        [self.resetBtn setEnabled:NO];
        [self.resetBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    }else{
        [self.resetBtn setEnabled:YES];
        [self.resetBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}
/**
 根据手势缩小头像框的位置计算出portraitIV的anchorPoint

 @param frame 头像框的frame
 @param portraitFramePosition 手势触摸位置
 @return anchorPoint
 */
-(CGPoint)getAnchorPointWithCurrentFrameIVFrame:(CGRect)frame position:(PortraitFramePosition)portraitFramePosition{
    CGFloat positionX,positionY;
    switch (portraitFramePosition) {
        case PortraitFramePositionTop:
            positionX = CGRectGetMidX(frame);
            positionY = CGRectGetMaxY(frame);
            break;
        case PortraitFramePositionRightTop:
            positionX = CGRectGetMinX(frame);
            positionY = CGRectGetMaxY(frame);
            break;
        case PortraitFramePositionRight:
            positionX = CGRectGetMinX(frame);
            positionY = CGRectGetMidY(frame);
            break;
        case PortraitFramePositionRightBottom:
            positionX = CGRectGetMinX(frame);
            positionY = CGRectGetMinY(frame);
            break;
        case PortraitFramePositionBottom:
            positionX = CGRectGetMidX(frame);
            positionY = CGRectGetMinY(frame);
            break;
        case PortraitFramePositionLeftBottom:
            positionX = CGRectGetMaxX(frame);
            positionY = CGRectGetMinY(frame);
            break;
        case PortraitFramePositionLeft:
            positionX = CGRectGetMaxX(frame);
            positionY = CGRectGetMidY(frame);
            break;
        case PortraitFramePositionLeftTop:
            positionX = CGRectGetMaxX(frame);
            positionY = CGRectGetMaxY(frame);
            break;
        default:
            return CGPointMake(0.5, 0.5);
            break;
    }
    CGPoint positionInPortraitIV = [self convertPoint:CGPointMake(positionX, positionY) toView:self.portraitIV];
    CGPoint anchorPoint = CGPointMake(positionInPortraitIV.x/CGRectGetWidth(self.portraitIV.frame), positionInPortraitIV.y/CGRectGetHeight(self.portraitIV.frame));
    return anchorPoint;
}

/**
 当图片两边界（图片上边和下边或者左边和右边）都在头像框内时，计算portraitIV的anchorPoint，
 使其放大后两边正好在头像框线上。

 @param padding1 图片左边界或者上边界离头像框的边界的大小
 @param padding2 图片右边界或者下边界离头像框的边的大小
 @param imageSizeLen 图片在屏幕上显示的大小：宽度或高度
 @param imageIVSizeLen 图片所在的控件的大小：宽度或高度
 @return AnchorPoint 的x或者y，传入图片的左边和右边时为x，传入图片的上边和下边距为y
 */
-(CGFloat)caculateAnchorPoint:(CGFloat)padding1 padding2:(CGFloat)padding2 imageSizeLen:(CGFloat)imageSizeLen imageIVSizeLen:(CGFloat)imageIVSizeLen{
    if(padding1<0){
        padding1 = -padding1;
    }
    if(padding2<0){
        padding2 = -padding2;
    }
    //图片上边界（或左边界）距离anchorPoint的y（或x）所在的点的距离。
    CGFloat x = imageSizeLen/(padding2/padding1+1);
    //图片下边界（或右边界）距离anchorPoint的y（或x）所在的点的距离。
//    CGFloat y = imageSizeLen-x;
    //图片上边界（或左边界）距图片所在控件的上边界（或左边界）的大小
    CGFloat m = (imageIVSizeLen-imageSizeLen)/2;
    return (x+m)/imageIVSizeLen;
}
/**
 计算对portraitIV进行缩放值为scale后portraitIV的frame
 @param scale 缩放的scale
 @return portraitIV的缩放值为scale的frame
 */
-(CGRect)getPortraitIVFrameWithScale:(CGFloat)scale{
    //计算缩放后portraitIV的frame
    CGPoint position = self.portraitIV.layer.position;
    //宽度
    CGFloat portraitW = CGRectGetWidth(self.portraitIV.frame)*scale;
    //高度
    CGFloat portraitH = CGRectGetHeight(self.portraitIV.frame)*scale;
    //x坐标
    CGFloat minXToPositionXLen =fabs(position.x-CGRectGetMinX(self.portraitIV.frame));//
    CGFloat newMinXToAPositionXLen = fabs(minXToPositionXLen/CGRectGetWidth(self.portraitIV.frame)*portraitW);
    CGFloat newX = minXToPositionXLen-newMinXToAPositionXLen + CGRectGetMinX(self.portraitIV.frame);
    //y坐标
    CGFloat minYToPositionPointYLen = fabs(position.y-CGRectGetMinY(self.portraitIV.frame));//
    CGFloat newMinYToPositionYLen = fabs(minYToPositionPointYLen/CGRectGetHeight(self.portraitIV.frame)*portraitH);
    CGFloat newY = minYToPositionPointYLen-newMinYToPositionYLen + CGRectGetMinY(self.portraitIV.frame);
    return CGRectMake(newX, newY,portraitW, portraitH);
}

/**
 显示遮罩层
 */
-(void)showMask{
    [UIView animateWithDuration:0.3 animations:^{
        self.maskView.alpha = 0.8;
    }];
}


/**
 隐藏遮罩层
 */
-(void)hideMask{
    [UIView animateWithDuration:0.3 animations:^{
        self.maskView.alpha = 0;
    }];
}

/**
 将头像框以动画的形式恢复到默认的frame大小

 @param portraitFramePosition 缩小头像框时手势按压的位置
 */
-(void)resetFrameIV:(PortraitFramePosition)portraitFramePosition{
    CGRect frame = self.frameIV.frame;
    CGFloat frameW = [self defaultCuttingW];
    CGFloat frameH = [self defaultCuttingH];
    switch (portraitFramePosition) {
        case PortraitFramePositionTop:
            frame.origin.x = CGRectGetMidX(frame)-frameW/2;
            frame.origin.y = CGRectGetMaxY(frame)-frameH;
            break;
        case PortraitFramePositionRightTop:
             frame.origin.y = CGRectGetMaxY(frame)-frameH;
            break;
        case PortraitFramePositionRight:
             frame.origin.y = CGRectGetMidY(frame)-frameH/2;
            break;
        case PortraitFramePositionRightBottom:
            break;
        case PortraitFramePositionBottom:
            frame.origin.x = CGRectGetMidX(frame)-frameW/2;
            break;
        case PortraitFramePositionLeftBottom:
            frame.origin.x = CGRectGetMaxX(frame)-frameW;
            break;
        case PortraitFramePositionLeft:
            frame.origin.x = CGRectGetMaxX(frame)-frameW;
            frame.origin.y = CGRectGetMidY(frame)-frameH/2;
            break;
        case PortraitFramePositionLeftTop:
             frame.origin.x = CGRectGetMaxX(frame)-frameW;
             frame.origin.y = CGRectGetMaxY(frame)-frameH;
            break;
        default:
            return;
            break;
    }
    frame.size.width = frameW;
    frame.size.height = [self defaultCuttingH];
    [UIView animateWithDuration:0.5 animations:^{
        self.frameIV.frame = frame;
    } completion:^(BOOL finish){
         [self showMask];
    }];
}

/**
 默认PotraitIV的frame

 @return 默认PotraitIV的frame
 */
-(CGRect)defaultPotraitIVFrame{
    return self.frame;
}
/**
 默认截剪Rect

 @return 截剪Rect
 */
-(CGRect)defaultCuttingRect{
    CGFloat padding = [self defaultCuttingPadding];
    CGFloat w = [self defaultCuttingW];
    CGFloat h = [self defaultCuttingH];
    CGRect rect = CGRectMake(padding,CGRectGetHeight(self.bounds)/2-h/2, w, h);
    return rect;
}

/**
  默认截剪的圆角

 @return 截剪的圆角
 */
-(CGFloat)defaultCuttingCorner{
    return  [self defaultCuttingW]/2;
}

/**
 默认截剪宽度

 @return 截剪宽度
 */
-(CGFloat)defaultCuttingW{
    return CGRectGetWidth(self.bounds)-2*[self defaultCuttingPadding];
}
/**
 默认截剪高度
 
 @return 截剪高度
 */
-(CGFloat)defaultCuttingH{
    return [self defaultCuttingW];
}
-(CGFloat)defaultCuttingPadding{
    return 20;
}
#pragma mark getsture

//移动手势调用此方法
-(void)panGestureTouch:(UIGestureRecognizer*)gesture{
    CGPoint movePoint = [self.panGesture translationInView:self];
    
    CGFloat addX =movePoint.x-self.lastMoveX;
    CGFloat addY = movePoint.y-self.lastMoveY;
    if(gesture.state == UIGestureRecognizerStateBegan){
        self.lastMoveX = movePoint.x;
        self.lastMoveY = movePoint.y;
        self.portraitFramePosition = [self getPortraitFramePosition:[self.panGesture locationInView:self]];
        [self hideMask];
        [self checkResetBtnState];
        return;
    }
    if(self.panGesture.state ==UIGestureRecognizerStateEnded){
        self.lastMoveX = 0;
        self.lastMoveY = 0;
        [self changeToProperTransformIfNeeded];
         [self checkResetBtnState];
        return;
    }
    if(self.portraitFramePosition == PortraitFramePositionNone){
         [self moveImageviewWithXDirection:addX YDirection:addY animatied:NO duration:0];
    }else{
        [self changePortraitFrameRect:self.portraitFramePosition addX:addX addY:addY];
    }
    self.lastMoveX = movePoint.x;
    self.lastMoveY = movePoint.y;
}

/**
 捏合手势的回调

 @param gesture UIPinchGestureRecognizer
 */
-(void)pinchGestureTouch:(UIGestureRecognizer *)gesture{
    NSInteger numberOfTouch = [self.pinchGesture numberOfTouches];
    if(gesture.state == UIGestureRecognizerStateBegan){
        [self hideMask];
        [self checkResetBtnState];
        return;
    }else if(gesture.state == UIGestureRecognizerStateEnded){
        [self changeToProperTransformIfNeeded];
        [self checkResetBtnState];
        return;
    }
    if(numberOfTouch == 2){
        CGPoint p1 = [self.pinchGesture locationOfTouch:0 inView:self];
        CGPoint p2 = [self.pinchGesture locationOfTouch:1 inView:self];
        CGPoint centerP1P2 =CGPointMake((p1.x+p2.x)/2,(p1.y+p2.y)/2);
        CGPoint pointInPortrait = [self convertPoint:centerP1P2 toView:self.portraitIV];
        CGPoint anchorCenter = CGPointMake(pointInPortrait.x/CGRectGetWidth(self.portraitIV.bounds),pointInPortrait.y/CGRectGetHeight(self.portraitIV.bounds));
        //self.pinchGesture.scale变化有些快，需要适当减慢
        CGFloat scale =1+(self.pinchGesture.scale-1)/10;
        [self transformImageWithScale:scale anchor:anchorCenter animatied:NO duration:0];
    }
}
/**
 对图片进行缩放

 @param scale 缩放比例
 */
-(void)transformImageWithScale:(double)scale animatied:(BOOL)animated duration:(NSTimeInterval)duration{
    [self transformImageWithScale:scale anchor:self.portraitIV.layer.anchorPoint  animatied:animated duration:duration];
}
/**
 修改头像框的位置大小
 @param portraitFramePosition 修改触发点
 @param addX x方向修改大小(跟 addY一起作用，主要看portraitFramePosition来具体确定用哪一个)
 @param addY y方向修改大小(跟 addX一起作用，主要看portraitFramePosition来具体确定用哪一个)
 */
-(void)changePortraitFrameRect:(PortraitFramePosition )portraitFramePosition addX:(CGFloat)addX addY:(CGFloat)addY{
    CGRect frame = self.frameIV.frame;
    CGFloat frameW =0 ;
    CGFloat frameH = 0;
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat addMax = addX>addY?addX:addY;
    switch (portraitFramePosition) {
        case PortraitFramePositionTop:
            frameH = CGRectGetHeight(frame)-addY;
            y = frame.origin.y+addY;
            frameW = frameH;
            x = frame.origin.x+addY/2;
            break;
        case PortraitFramePositionRightTop:
            if(self.portraitEditingType == PortraitEditingTypeSquare){
                frameH = CGRectGetHeight(frame)-addMax;
                frameW = frameH;
                y = frame.origin.y+addMax;
                x = frame.origin.x;
            }else{
                return;
            }
            break;
        case PortraitFramePositionRight:
            frameW = CGRectGetWidth(frame)+addX;
            x = frame.origin.x;
            frameH=frameW;
            y = frame.origin.y-addX/2;
            break;
        case PortraitFramePositionRightBottom:
            if(self.portraitEditingType == PortraitEditingTypeSquare){
                frameH = CGRectGetHeight(frame)+addMax;
                frameW = frameH;
                x = frame.origin.x;
                y = frame.origin.y;
            }else{
                return;
            }
            break;
        case PortraitFramePositionBottom:
            frameH = CGRectGetHeight(frame)+addY;
            y = frame.origin.y;
            frameW = frameH;
            x = frame.origin.x-addY/2;
            break;
        case PortraitFramePositionLeftBottom:
            if(self.portraitEditingType == PortraitEditingTypeSquare){
                frameH = CGRectGetHeight(frame)-addMax;
                frameW = frameH;
                y = frame.origin.y;
                x = frame.origin.x+addMax;
            }else{
                return;
            }
            break;
        case PortraitFramePositionLeft:
            frameW = CGRectGetWidth(frame)-addX;
            x = frame.origin.x+addX;
            frameH =frameW;
            y = frame.origin.y+addX/2;
            break;
      
        case PortraitFramePositionLeftTop:
            if(self.portraitEditingType == PortraitEditingTypeSquare){
                frameH = CGRectGetHeight(frame)-addMax;
                frameW = frameH;
                x = frame.origin.x+addMax;
                y = frame.origin.y+addMax;
            }else{
                return;
            }
            break;
        default:
            x = frame.origin.x;
            y = frame.origin.y;
            frameW = frame.size.width;
            frameH = frame.size.height;
            break;
    }
    if(frameW>self.maxFrameIVW||frameW<self.minFrameIVW){
        return;
    }
    frame.origin.x = x;
    frame.origin.y = y;
    frame.size.width = frameW;
    frame.size.height = frameH;
    self.frameIV.frame = frame;
   
}
-(void)printRect:(CGRect)rect name:(NSString *)name{
    NSLog(@"%@:x=%f,y=%f,w=%f,h=%f",name,rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
}

/**
 给layer设置新的anchorPoint时，计算layer层新的position，以保证frame不变

 @param anchorPoint 新的anchorPoint
 @param view 要设置anchorPoint的view
 @return 新的position
 */
-(CGPoint)getCorrectPositionWithNewAnchorPoint:(CGPoint)anchorPoint view:(UIView *)view{
    CGPoint currentPosition = view.layer.position;
    CGPoint currentAnchorPoint = view.layer.anchorPoint;
    CGFloat positionMoveDistenceX = (anchorPoint.x-currentAnchorPoint.x)*CGRectGetWidth(view.frame);
    CGFloat positionMoveDistenceY =(anchorPoint.y-currentAnchorPoint.y)*CGRectGetHeight(view.frame);
    return CGPointMake(currentPosition.x+positionMoveDistenceX, currentPosition.y+positionMoveDistenceY);
}
/**
 判断移动手势首次所触发的点是否在在头像框上
 @param p 移动手势首次所触发的点
 @return 手势首次所触发的点在头像框的哪一个位置，没有则返回PortraitFramePositionNone
 */
-(PortraitFramePosition)getPortraitFramePosition:(CGPoint)p{
    CGFloat triggeredRange = 40;//触发范围，在该范围内会修改头像框的位置大小而不是移动头像
    CGRect frame = self.frameIV.frame;
    //顶部
    if(p.y>CGRectGetMinY(frame)-triggeredRange/2
       &&p.y<CGRectGetMinY(frame)+triggeredRange/2){
        if(p.x>CGRectGetMinX(frame)-triggeredRange
           &&p.x<CGRectGetMinX(frame)+triggeredRange){ //左上角
            return PortraitFramePositionLeftTop;
        }else if(p.x>CGRectGetMaxX(frame)-triggeredRange
                 &&p.x<CGRectGetMaxX(frame)+triggeredRange){ //右上角
            return PortraitFramePositionRightTop;
        }
        return PortraitFramePositionTop;//上边
    }
    //底部
    if(p.y>CGRectGetMaxY(frame)-triggeredRange/2
       &&p.y<CGRectGetMaxY(frame)+triggeredRange/2){
        
        if(p.x>CGRectGetMinX(frame)-triggeredRange
           &&p.x<CGRectGetMinX(frame)+triggeredRange){ //左下角
            return PortraitFramePositionLeftBottom;
        }else if(p.x>CGRectGetMaxX(frame)-triggeredRange
                 &&p.x<CGRectGetMaxX(frame)+triggeredRange){ //右下角
            return PortraitFramePositionRightBottom;
        }
        return PortraitFramePositionBottom;//下边
    }
    
    if(p.x>CGRectGetMinX(frame)-triggeredRange/2
       &&p.x<CGRectGetMinX(frame)+triggeredRange/2){
        if(p.y>CGRectGetMinY(frame)-triggeredRange
           &&p.y<CGRectGetMinY(frame)+triggeredRange){
             return PortraitFramePositionLeftTop;
        }else if(p.y>CGRectGetMaxY(frame)-triggeredRange
           &&p.y<CGRectGetMaxY(frame)+triggeredRange){
             return PortraitFramePositionLeftBottom;
        }
        return PortraitFramePositionLeft;//左边
    }else if(p.x>CGRectGetMaxX(frame)-triggeredRange/2
             &&p.x<CGRectGetMaxX(frame)+triggeredRange/2){ //右边
        if(p.y>CGRectGetMinY(frame)-triggeredRange
           &&p.y<CGRectGetMinY(frame)+triggeredRange){
            return PortraitFramePositionRightTop;
        }else if(p.y>CGRectGetMaxY(frame)-triggeredRange
                 &&p.y<CGRectGetMaxY(frame)+triggeredRange){
            return PortraitFramePositionRightBottom;
        }
        return PortraitFramePositionRight;
    }
    return PortraitFramePositionNone;
}


/**
 缩放
 @param scale 缩放比例
 @param anchor 缩放的anchor，两根手指跟屏幕的接触点连线中心
 */
-(void)transformImageWithScale:(double)scale anchor:(CGPoint)anchor animatied:(BOOL)animated duration:(NSTimeInterval)duration{
    
    [self transformImageWithScale:scale anchor:anchor addX:0 addY:0 animatied:animated duration:duration];
}

/**
 缩放及移动
 
 @param scale 缩放比例
 @param anchor 缩放位置
 @param addX 水平移动大小
 @param addY 竖直移动大小
 @param animated 是否动画
 */
-(void)transformImageWithScale:(double)scale anchor:(CGPoint)anchor addX:(CGFloat)addX addY:(CGFloat)addY animatied:(BOOL)animated duration:(NSTimeInterval)duration{
    CGFloat newScale =CGRectGetWidth(self.portraitIV.frame)*scale/CGRectGetWidth([self defaultPotraitIVFrame]);
    if(newScale > self.maxTransformScale){
        if([self currentPortraitIVScale]<self.maxTransformScale){
               scale = self.maxTransformScale*CGRectGetWidth([self defaultPotraitIVFrame])/CGRectGetWidth(self.portraitIV.frame);
        }else{
            scale = 1;
        }
    }
    if(newScale < self.minTransformScale){
        if([self currentPortraitIVScale]>self.minTransformScale){
             scale = self.minTransformScale*CGRectGetWidth([self defaultPotraitIVFrame])/CGRectGetWidth(self.portraitIV.frame);
        }else{
            scale = 1;
        }
    }
    CGPoint newPosition = [self getCorrectPositionWithNewAnchorPoint:anchor view:self.portraitIV];
    
    [self.portraitIV.layer setAnchorPoint:anchor];
    [self.portraitIV.layer setPosition:newPosition];
    [self moveAndSetScale:scale addX:addX addY:addY animated:animated duration:duration];
}
//移动图
-(void)moveImageviewWithXDirection:(CGFloat)addX YDirection:(CGFloat)addY animatied:(BOOL)animated duration:(NSTimeInterval)duration{
    if(addX==0&&addY==0){
        return;
    }
    CGRect imageFrame = [self getImageFrameFromUIImageView:self.portraitIV.frame image:self.portraitIV.image];
    imageFrame = [self.portraitIV convertRect:imageFrame toView:self];
    CGFloat divide = 3;//图片超出头像框边界后适当减慢图片的移动速度
    if(CGRectGetMinX(imageFrame)+addX>[self defaultCuttingPadding]){
        addX /= divide;
    }
    if(CGRectGetMaxX(imageFrame)+addX<self.frame.size.width-[self defaultCuttingPadding]){
        addX /= divide;
    }
    if(CGRectGetMinY(imageFrame)+addY>CGRectGetMinY(self.frameIV.frame)){
        addY /= divide;
    }
    if(CGRectGetMaxY(imageFrame)+addY<CGRectGetMaxY(self.frameIV.frame)){
        addY /= divide;
    }
    [self moveAndSetScale:1 addX:addX addY:addY animated:animated duration:duration];
}

/**
 同时缩放和移动
 
 @param scale 缩放比率
 @param addX x方向移动大小
 @param addY y方向移动大小
 @param animated 是否开启动画
 */
-(void)moveAndSetScale:(CGFloat)scale addX:(CGFloat)addX addY:(CGFloat)addY animated:(BOOL)animated duration:(NSTimeInterval)duration{
    CGRect originalFrame = self.portraitIV.frame;
    CGPoint anchorPoint = self.portraitIV.layer.anchorPoint;
    CGFloat newW = CGRectGetWidth(originalFrame)*scale;
    CGFloat newH = CGRectGetHeight(originalFrame)*scale;
    CGFloat scaleAddX =- (newW*anchorPoint.x -CGRectGetWidth(originalFrame)*anchorPoint.x);
    CGFloat scaleAddY = -(newH*anchorPoint.y -CGRectGetHeight(originalFrame)*anchorPoint.y);
    CGFloat newX = CGRectGetMinX(originalFrame)+addX+scaleAddX;
    CGFloat newY = CGRectGetMinY(originalFrame)+addY+scaleAddY;
    CGRect newFrame = CGRectMake(newX, newY, newW, newH);
    if(animated){
        [UIView animateWithDuration:duration animations:^{
            self.portraitIV.frame = newFrame;
        }];
    }else{
        self.portraitIV.frame = newFrame;
    }
//    //图片的缩放跟移动的距离有关系，如果移动的大小为addX，图片已经放大scale倍，则用CGAffineTransformTranslate方法图片实际移动的大小为addX*scale。
//    addX = addX/self.portraitIV.transform.a;
//    addY = addY/self.portraitIV.transform.d;
//    CGAffineTransform transform = self.portraitIV.transform;
//    transform = CGAffineTransformTranslate(self.portraitIV.transform,addX,addY);
//    transform = CGAffineTransformScale(transform, scale, scale);
//    if(animated){
//        [UIView animateWithDuration:0.5 animations:^{
//            self.portraitIV.transform = transform;
//        }];
//    }else{
//        self.portraitIV.transform = transform;
//    }
}
/**
 恢复到默认大小
 */
-(void)resetPortraiIVScale{
    self.portraitIV.frame = [self getMinPortraitIVFrame];
    [self checkResetBtnState];
}

/**
 获取portraitIV的最小frame，该frame要保证头像框内占满要剪辑的图片
 @return frame
 */
-(CGRect)getMinPortraitIVFrame{
    CGFloat aspectRatio = [self getImageAspectRatio:self.portraitIV.image];
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat w = 0;
    CGFloat h = 0;
    if(aspectRatio>1){
        CGFloat imageH = CGRectGetHeight(self.frameIV.frame);
        CGFloat imageW = imageH*aspectRatio;
        w = imageW;
        h = CGRectGetHeight(self.frame)/CGRectGetWidth(self.frame)*w;
    }else{
        
        CGFloat imageW = CGRectGetWidth(self.frameIV.frame);
        CGFloat imageH = imageW/aspectRatio;
        h = imageH;
        w = CGRectGetWidth(self.frame)/CGRectGetHeight(self.frame)*imageH;
        
    }
    x = CGRectGetWidth(self.frame)/2-w/2;
    y = CGRectGetHeight(self.frame)/2-h/2;
    return CGRectMake(x, y, w, h);
    
}

/**
 获取UIImageView中显示图片的坐标,填充模式为:UIViewContentModeScaleAspectFit

 @param imageViewFrame UIImageView 的frame
 @param image UIImageView的图片
 @return 返回图片的frame
 */
-(CGRect)getImageFrameFromUIImageView:(CGRect)imageViewFrame image:(UIImage *)image{
    CGFloat aspectRatio = [self getImageAspectRatio:image];
    if(aspectRatio==0){
        return CGRectZero;
    }
    CGFloat pointX ;
    CGFloat pointY ;
    CGFloat imageWidth ;
    CGFloat imageHeight ;
    
    if(aspectRatio>=1){//宽大于高
        pointX= 0;
        imageWidth = CGRectGetWidth(imageViewFrame);
        imageHeight =imageWidth/aspectRatio;
        pointY = CGRectGetHeight(imageViewFrame)/2-imageHeight/2;
    }else{//宽小于高
        pointY= 0;
        imageHeight = CGRectGetHeight(imageViewFrame);
        imageWidth =imageHeight*aspectRatio;
        pointX = CGRectGetWidth(imageViewFrame)/2-imageWidth/2;
    }
    return CGRectMake(pointX, pointY, imageWidth, imageHeight);
}
//获取图片宽高比
-(CGFloat)getImageAspectRatio:(UIImage*)image{
    if(!image){
        return 0;
    }
    return image.size.width/image.size.height;
}

/**
 判断rect和withRect所在区域是否相同

 @param rect rect
 @param withRect withRect
 @return 相同则返回true
 */
-(BOOL)isRectEqual:(CGRect)rect withRect:(CGRect)withRect{
    if(CGRectGetMidY(rect)!=CGRectGetMidY(withRect)){
        return false;
    }
    if(CGRectGetMidX(rect)!=CGRectGetMidX(withRect)){
        return false;
    }
    if(CGRectGetWidth(rect)!=CGRectGetWidth(withRect)){
        return false;
    }
    if(CGRectGetHeight(rect)!=CGRectGetHeight(withRect)){
        return false;
    }
    return true;
}
/**
 获取真实的剪切头像尺寸
 @return 真实的剪切头像尺寸
 */
-(CGRect)getCutttingImageRealRect{
    CGRect rect = self.frameIV.frame;
    CGRect imageFrame = [self getImageFrameFromUIImageView:self.portraitIV.frame image:self.portraitIV.image];
    imageFrame = [self convertRect:imageFrame fromView:self.portraitIV];
    CGFloat imageW = self.portraitIV.image.size.width;
    CGFloat imageH = self.portraitIV.image.size.height;
    CGFloat cuttingImageX = (rect.origin.x-imageFrame.origin.x)*(imageW/CGRectGetWidth(imageFrame));
    CGFloat cuttingImageY = (rect.origin.y-imageFrame.origin.y)*(imageH/CGRectGetHeight(imageFrame));
    CGFloat cuttingImageW = CGRectGetWidth(rect)*(imageW/CGRectGetWidth(imageFrame));
    CGFloat cuttingImageH = CGRectGetHeight(rect)*(imageH/CGRectGetHeight(imageFrame));
    return CGRectMake(cuttingImageX, cuttingImageY, cuttingImageW, cuttingImageH);
}


/**
 根据当前头像框的位置剪出对应位置尺寸的图片

 @return UIImage
 */
-(UIImage *)generateCuttingImage{
    CGRect rect = [self getCutttingImageRealRect];
    UIImage *image= self.portraitIV.image;
    if(self.portraitEditingType ==PortraitEditingTypeSquare){
        return [image rectangleImageInRect:rect];
    }
    return [image circleImageInRect:rect];
}


#pragma mark 点击事件
-(void)cancelBtnClick{
    if(self.delegate&&[self.delegate respondsToSelector:@selector(portraitEditingViewCancel:)]){
        [self.delegate portraitEditingViewCancel:self];
    }
}
-(void)resetBtnClick{
    [self resetPortraiIVScale];
}
-(void)completeBtnClick{
    if(self.delegate&&[self.delegate respondsToSelector:@selector(portraitEditingViewComplete:image:)]){
        [self.delegate portraitEditingViewComplete:self image:[self generateCuttingImage]];
    }
}
@end
