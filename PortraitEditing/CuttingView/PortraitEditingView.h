//
//  PortraitEditingView.h
//  PortraitEditing
//
//  Created by ATH on 2019/10/28.
//  Copyright © 2019 ath. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSInteger,PortraitEditingType){
    PortraitEditingTypeSquare,//正方形
    PortraitEditingTypeCircle//圆形
};
@class PortraitEditingView;
@protocol PortraitEditingViewDelegate <NSObject>
-(void)portraitEditingViewCancel:(PortraitEditingView * _Nonnull )portraitEditingView;
-(void)portraitEditingViewComplete:(PortraitEditingView *_Nonnull)portraitEditingView image:(UIImage*_Nonnull)image;

@end
NS_ASSUME_NONNULL_BEGIN
@interface PortraitEditingView : UIView
@property(nonatomic,strong)UIImageView *portraitIV;//头像
@property(nonatomic,strong)UIView *maskView;//遮罩层
@property(nonatomic,strong)UIImageView *frameIV;//头像框
@property(nonatomic,strong)UIView *dividerView;//分割线
@property(nonatomic,strong)UIButton *cancelBtn;//取消按钮
@property(nonatomic,strong)UIButton *resetBtn;//重置按钮
@property(nonatomic,strong)UIButton *completeBtn;//完成按钮

@property(nonatomic,assign)CGFloat minFrameIVW;//头像框缩小的最小值
@property(nonatomic,assign)CGFloat maxFrameIVW;//头像框放大的最大值
@property(nonatomic,assign)CGFloat maxTransformScale;//图像放大的最大倍数
@property(nonatomic,assign)CGFloat minTransformScale;//图像缩小的最小倍数
@property(nonatomic,weak)id <PortraitEditingViewDelegate>delegate;
@property(nonatomic,assign)PortraitEditingType portraitEditingType;//头像框模式：圆形或正方形
+(id)portraitEditingViewWithImage:(UIImage *)portraitImage type:(PortraitEditingType)portraitEditiingType;
-(id)initWithFrame:(CGRect)frame portratitImage:(UIImage *)portraitImage portraitEditingType:(PortraitEditingType)portraitEditingType;
/**
 根据当前头像框的位置剪出对应位置尺寸的图片
 @return UIImage
 */
-(UIImage *)generateCuttingImage;
/**
 恢复到默认大小
 */
-(void)resetPortraiIVScale;
@end

NS_ASSUME_NONNULL_END
