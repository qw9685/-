//
//  XMScrollView.h
//  securityCamera
//
//  Created by foxdingding on 2018/11/27.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XMScrollView : UIView

//焦距
@property(nonatomic,copy) void(^tapPointBlock)(CGPoint point);
//捏合
@property(nonatomic,copy) void(^videoScaleBlock)(CGFloat scale);
//滑动
@property(nonatomic,copy) void(^scrollViewDidEndDeceleratingBlock)(NSInteger index);

@property (nonatomic, strong) UIScrollView *scroll;


@end
