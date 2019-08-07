//
//  bottomView.m
//  securityCamera
//
//  Created by foxdingding on 2018/11/23.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import "bottomView.h"
#import "XMScrollViewModel.h"
#import "Masonry.h"

// 屏幕尺寸
#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height

@interface bottomView ()

@property(nonatomic,strong) NSArray *titles;

@end

@implementation bottomView

-(instancetype)initWithTitles:(NSArray*)titles{
    if (self = [super init]) {
        _titles = titles;
        [self setupViews];
    }
    return self;
}

- (void)setupViews{
    
    self.backgroundColor = [UIColor whiteColor];
    
    [self addSubview:self.segmentView];
    [self addSubview:self.circleBtn];
    [self addSubview:self.cameraPositionBtn];
}


-(void)layoutSubviews{
    [_circleBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.width.height.equalTo(@(70));
        make.top.equalTo(@(40));
    }];
    
    [_cameraPositionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-22);
        make.width.height.equalTo(@(44));
        make.centerY.equalTo(self->_circleBtn);
    }];

}

-(UIButton *)circleBtn{
    if (!_circleBtn) {
        _circleBtn = [[UIButton alloc] init];
        [_circleBtn setBackgroundImage:[UIImage imageNamed:@"ic_shutter"] forState:UIControlStateNormal];
    }
    return _circleBtn;
}

-(UIButton *)cameraPositionBtn{
    if (!_cameraPositionBtn) {
        _cameraPositionBtn = [[UIButton alloc] init];
        [_cameraPositionBtn setBackgroundImage:[UIImage imageNamed:@"ic_change"] forState:UIControlStateNormal];
    }
    return _cameraPositionBtn;
}

-(LXSegmentScrollView *)segmentView{
    if (!_segmentView) {
        _segmentView = [[LXSegmentScrollView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 25) titleArray:self.titles];
        _segmentView.segmentBgColor = [UIColor whiteColor];
        _segmentView.titleFont = 14;
        _segmentView.titleSelectedFont = 18;
        _segmentView.hideLine = YES;
        _segmentView.textSelectedColor = [UIColor redColor];
        _segmentView.textNomalColor = [UIColor blackColor];
    }
    return _segmentView;
}


@end
