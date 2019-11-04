//
//  UIImage+ImageUtils.h
//  PortraitEditing
//
//  Created by ATH on 2019/10/30.
//  Copyright © 2019 ath. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (ImageUtils)
-(UIImage *)rectangleImageInRect:(CGRect)rect;
-(UIImage *)circleImageInRect:(CGRect)rect;
-(UIImage*)circleImage;
@end

NS_ASSUME_NONNULL_END
