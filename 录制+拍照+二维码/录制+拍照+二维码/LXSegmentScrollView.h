//
//  LXSegmentScrollView.h
//  LiuXSegment
//
//  Created by liuxin on 16/5/17.
//  Copyright © 2016年 liuxin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LXSegmentScrollView : UIView

-(instancetype)initWithFrame:(CGRect)frame
                  titleArray:(NSArray *)titleArray;

@property(nonatomic,assign) BOOL hideLine;
@property(nonatomic,strong) UIColor *lineColor;
@property(nonatomic,strong) UIColor *textNomalColor;
@property(nonatomic,strong) UIColor *textSelectedColor;
@property(nonatomic,assign) NSInteger titleFont;
@property(nonatomic,assign) NSInteger titleSelectedFont;

@property(nonatomic,strong) UIColor *segmentBgColor;
@property(nonatomic,strong) UIColor *segmentBgSelectColor;


/**
 横线颜色
 */
@property (nonatomic, assign)float lineWidth;

@property (strong,nonatomic)UIScrollView *bgScrollView;

@property(nonatomic,copy) void(^currentPage)(NSInteger page);

- (void)jumpIndex:(NSInteger)index;

//设置按钮/滑动是否可用
- (void)setSegmentBtnEnable:(BOOL)enable;

@end
