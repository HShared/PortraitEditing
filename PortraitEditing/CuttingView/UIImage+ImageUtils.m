//
//  UIImage+ImageUtils.m
//  PortraitEditing
//
//  Created by ATH on 2019/10/30.
//  Copyright © 2019 ath. All rights reserved.
//

#import "UIImage+ImageUtils.h"
@interface CircleImageHelperView:UIView
@property(nonatomic,assign)CGRect cuttingRect;
@property(nonatomic,strong)UIImage *image;
@end

@implementation CircleImageHelperView


@end
@implementation UIImage (ImageUtils)

-(UIImage *)rectangleImageInRect:(CGRect)rect{
    CGImageRef cuttingImage = CGImageCreateWithImageInRect(self.CGImage, rect);
    CGRect cuttingRect = CGRectMake(0, 0, CGImageGetWidth(cuttingImage), CGImageGetHeight(cuttingImage));
    UIGraphicsBeginImageContext(cuttingRect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, cuttingRect, cuttingImage);
    UIImage *image = [UIImage imageWithCGImage:cuttingImage];
    UIGraphicsEndImageContext();
    return image;
}

-(UIImage *)circleImageInRect:(CGRect)rect{
    UIImage *rectImage = [self rectangleImageInRect:rect];
    return [rectImage circleImage];
}
-(UIImage*)circleImage{
    UIGraphicsBeginImageContext(self.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0,0,self.size.width,self.size.height);
    CGContextAddEllipseInRect(ctx, rect);
    CGContextClip(ctx);
    [self drawInRect:rect];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end
