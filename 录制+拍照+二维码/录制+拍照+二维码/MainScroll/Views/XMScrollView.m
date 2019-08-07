//
//  XMScrollView.m
//  securityCamera
//
//  Created by foxdingding on 2018/11/27.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import "XMScrollView.h"
#import "Masonry.h"

// 屏幕尺寸
#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height

@interface XMScrollView ()<UIScrollViewDelegate>

@property (nonatomic, strong) UIImageView* focusImage;

@end

@implementation XMScrollView

-(instancetype)init{
    if (self = [super init]) {
        [self setupViews];
    }
    return self;
}

-(void)layoutSubviews{
    [self.scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}

-(void)setupViews{
    
    [self initScroll];
    [self addGenstureRecognizer];
}

- (void)initScroll{
    
    [self addSubview:self.scroll];
    self.scroll.delegate = self;
    self.scroll.pagingEnabled = YES;
}

-(void)addGenstureRecognizer{
    
    self.focusImage.hidden = YES;
    [self.scroll addSubview:self.focusImage];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    [self.scroll addGestureRecognizer:tapGesture];
    
    UIPinchGestureRecognizer *doubleTapGesture = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    
    doubleTapGesture.delaysTouchesBegan = YES;
    [tapGesture requireGestureRecognizerToFail:doubleTapGesture];
    [self.scroll addGestureRecognizer:doubleTapGesture];
}


- (void)tapScreen:(UIGestureRecognizer*)ges{
    
    CGPoint point = [ges locationInView:self.scroll];
    self.focusImage.bounds = CGRectMake(0, 0, 70, 70);
    self.focusImage.center = point;
    self.focusImage.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.focusImage.bounds = CGRectMake(0, 0, 50, 50);
    } completion:^(BOOL finished) {
        self.focusImage.hidden = YES;
        
        if (self.tapPointBlock) {
            self.tapPointBlock(point);
        }

    }];
}

- (void)doubleTap:(UIPinchGestureRecognizer*)ges{
    
    CGFloat scale = ges.scale;
    ges.scale = MAX(1.0, scale);
    
    if (scale < 1.0f || scale > 3.0)
        return;
    
    NSLog(@"捏合%f",scale);
    if (self.videoScaleBlock) {
        self.videoScaleBlock(scale);
    }
}

#pragma mark -------------- UIScrollViewDelegate --------------
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == self.scroll){
        NSInteger index = scrollView.contentOffset.x/kScreenWidth;
        if (self.scrollViewDidEndDeceleratingBlock) {
            self.scrollViewDidEndDeceleratingBlock(index);
        }
    }
}

-(UIImageView *)focusImage{
    if (!_focusImage) {
        _focusImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"对焦"]];
    }
    return _focusImage;
}

- (UIScrollView *)scroll{
    if (!_scroll) {
        _scroll = [[UIScrollView alloc]initWithFrame:self.bounds];
        _scroll.scrollEnabled = YES;
        _scroll.showsVerticalScrollIndicator = NO;
        _scroll.showsHorizontalScrollIndicator = NO;
        
    }
    return _scroll;
}

@end
