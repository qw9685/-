//
//  bottomView.h
//  securityCamera
//
//  Created by foxdingding on 2018/11/23.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import "LXSegmentScrollView.h"

@interface bottomView : UIView

@property(nonatomic,strong) LXSegmentScrollView *segmentView;

@property(nonatomic,strong) UIButton *circleBtn;
@property(nonatomic,strong) UIButton *cameraPositionBtn;

-(instancetype)initWithTitles:(NSArray*)titles;

@end
