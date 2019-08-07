//
//  LXSegmentScrollView.m
//  LiuXSegment
//
//  Created by liuxin on 16/5/17.
//  Copyright © 2016年 liuxin. All rights reserved.
//

#define MainScreen_W [UIScreen mainScreen].bounds.size.width

#import "LXSegmentScrollView.h"
#import "SegmentTapView.h"

@interface LXSegmentScrollView()<UIScrollViewDelegate,SegmentTapViewDelegate>

@property (strong,nonatomic)SegmentTapView *segment;
@property (strong,nonatomic)NSArray *titleArray;

@end

@implementation LXSegmentScrollView


-(instancetype)initWithFrame:(CGRect)frame
                  titleArray:(NSArray *)titleArray{
    if (self = [super initWithFrame:frame]) {
        
        self.titleArray = titleArray;
        [self addSubview:self.segment];
    }
    
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
}

- (void)jumpIndex:(NSInteger)index{

    [self.segment selectIndex:index];

}

//设置按钮/滑动是否可用
- (void)setSegmentBtnEnable:(BOOL)enable{
    
    self.bgScrollView.scrollEnabled = enable;
    [self.segment setSegmentBtnEnable:enable];
}

#pragma mark -------------- SegmentTapViewDelegate --------------

-(void)selectedIndex:(NSInteger)index{
    
    if (self.currentPage) {
        self.currentPage(index);
    }
}

#pragma mark -------------- set/get --------------

-(void)setLineColor:(UIColor *)lineColor{
    _segment.lineColor = lineColor;
}

-(void)setTitleFont:(NSInteger)titleFont{
    _segment.titleFont = titleFont;
}
-(void)setTitleSelectedFont:(NSInteger)titleSelectedFont{
    _segment.titleSelectedFont = titleSelectedFont;
}

-(void)setTextNomalColor:(UIColor *)textNomalColor{
    _segment.textNomalColor = textNomalColor;
}

-(void)setTextSelectedColor:(UIColor *)textSelectedColor{
    _segment.textSelectedColor = textSelectedColor;
}

-(void)setSegmentBgColor:(UIColor *)segmentBgColor{
    _segment.segmentBgColor = segmentBgColor;
}

-(void)setSegmentBgSelectColor:(UIColor *)segmentBgSelectColor{
    _segment.segmentBgSelectColor = segmentBgSelectColor;
}

-(void)setLineWidth:(float)lineWidth{
    _lineWidth = lineWidth;
    self.segment.lineWidth = lineWidth;    
}

-(void)setHideLine:(BOOL)hideLine{
    _hideLine = hideLine;
    self.segment.hideLine = hideLine;
}

-(SegmentTapView *)segment{
    if (!_segment) {
        _segment = [[SegmentTapView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) withDataArray:self.titleArray withFont:15];
        _segment.delegate = self;
        _segment.lineColor = [UIColor orangeColor];
        _segment.textNomalColor = [UIColor blackColor];
        _segment.textSelectedColor = [UIColor redColor];
        _segment.titleFont = 14;
    }
    return _segment;
}



@end
