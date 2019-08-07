//
//  SegmentTapView.h
//  SegmentTapView
//
//  Created by fujin on 15/6/20.
//  Copyright (c) 2015年 fujin. All rights reserved.
//


#import <UIKit/UIKit.h>

@protocol SegmentTapViewDelegate <NSObject>
@optional
/**
 选择index回调
 */
-(void)selectedIndex:(NSInteger)index;
@end

@interface SegmentTapView : UIView

/**
 选择回调
 */
@property (nonatomic, assign)id<SegmentTapViewDelegate> delegate;
/**
 数据源
 */
@property (nonatomic, strong)NSArray *dataArray;
/**
 字体非选中时颜色
 */
@property (nonatomic, strong)UIColor *textNomalColor;
/**
 字体选中时颜色
 */
@property (nonatomic, strong)UIColor *textSelectedColor;
/**
 横线颜色
 */
@property (nonatomic, strong)UIColor *lineColor;
/**
 横线颜色
 */
@property (nonatomic, assign)float lineWidth;
/**
 字体大小
 */
@property (nonatomic, assign)CGFloat titleFont;

@property(nonatomic,assign) CGFloat titleSelectedFont;

@property(nonatomic,assign) BOOL hideLine;

//选中 默认背景颜色
@property(nonatomic,strong) UIColor *segmentBgColor;
@property(nonatomic,strong) UIColor *segmentBgSelectColor;

/**
Initialization
 
 @param frame     fram
 @param dataArray 标题数组
 @param font      标题字体大小
 
 @return instance
 */
-(instancetype)initWithFrame:(CGRect)frame withDataArray:(NSArray *)dataArray withFont:(CGFloat)font;
/**
 手动选择
 
 @param index inde（从1开始）
 */
-(void)selectIndex:(NSInteger)index;

//设置按钮是否可点
- (void)setSegmentBtnEnable:(BOOL)enable;

@end
