//
//  ViewController.m
//  PortraitEditing
//
//  Created by ATH on 2019/10/28.
//  Copyright © 2019 ath. All rights reserved.
//

#import "ViewController.h"
#import "PortraitEditingView.h"
@interface ViewController ()<PortraitEditingViewDelegate>
@property(nonatomic,strong)PortraitEditingView *portraitEditingView;
@property(nonatomic,strong)UIImageView *imageView;
@property(nonatomic,strong)UIButton *showBtn;
@end

@implementation ViewController
-(UIImageView *)imageView{
    if(!_imageView){
        _imageView = [[UIImageView alloc]initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)/2-50, CGRectGetHeight(self.view.frame)/2-50, 100, 100)];
        [_imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.view addSubview:_imageView];
    }
    return _imageView;
}
-(UIButton *)showBtn{
    if(!_showBtn){
        _showBtn = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)/2-40,CGRectGetMaxY(self.imageView.frame)+10, 80, 30)];
        [_showBtn setTitle:@"开始截图" forState:UIControlStateNormal];
        [_showBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_showBtn.titleLabel setFont:[UIFont systemFontOfSize:18]];
        [_showBtn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];

    }
    return _showBtn;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.showBtn];
    self.portraitEditingView = [PortraitEditingView portraitEditingViewWithImage:[UIImage imageNamed:@"bgsource.jpg"] type:PortraitEditingTypeCircle];
    self.portraitEditingView.delegate = self;
    [self.portraitEditingView setHidden:YES];
    [self.view addSubview:self.portraitEditingView];
}
-(void)btnClick{
   
    [self.portraitEditingView setHidden:NO];
  
}


- (void)portraitEditingViewCancel:(PortraitEditingView * _Nonnull)portraitEditingView {
    [portraitEditingView setHidden:YES];
}

- (void)portraitEditingViewComplete:(PortraitEditingView *)portraitEditingView image:(UIImage *)image {
    [self.imageView setImage:image];
    [portraitEditingView setHidden:YES];
}

@end
