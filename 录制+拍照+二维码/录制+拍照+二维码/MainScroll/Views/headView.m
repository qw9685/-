//
//  headView.m
//  securityCamera
//
//  Created by foxdingding on 2018/11/26.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import "headView.h"
#import "Masonry.h"

@interface headView ()

@property(nonatomic,strong) NSArray *titles;

@end

@implementation headView

-(instancetype)init{
    if (self = [super init]) {
        
        [self setupViews];
    }
    return self;
}

-(void)setupViews{
    
    [self addSubview:self.flashBtn];
}

- (void)layoutSubviews{

    [self.flashBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(22);
        make.top.equalTo(self).offset(24);
        make.width.height.equalTo(@(32));
    }];
}

#pragma mark -------------- set&get --------------

-(UIButton *)flashBtn{
    if (!_flashBtn) {
        _flashBtn = [[UIButton alloc] init];
        [_flashBtn setBackgroundImage:[UIImage imageNamed:@"ic_iight-close"] forState:UIControlStateNormal];
    }
    return _flashBtn;
}





@end
