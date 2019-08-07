//
//  XMScrollViewController.m
//  securityCamera
//
//  Created by foxdingding on 2018/11/22.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import "XMScrollViewController.h"
#import "XMScrollViewModel.h"
#import "bottomView.h"
#import "headView.h"
#import "XMScrollView.h"
#import "assetWriterManager.h"
#import "Masonry.h"
#import <ReactiveObjC/ReactiveObjC.h>

// 屏幕尺寸
#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height


@interface XMScrollViewController ()<UIScrollViewDelegate,UIGestureRecognizerDelegate,CAAnimationDelegate>

@property(nonatomic,strong) XMScrollViewModel *scrollViewModel;
@property(nonatomic,strong) bottomView *bottomView;
@property(nonatomic,strong) UIView *layerView;
@property(nonatomic,strong) headView *headView;
@property(nonatomic,strong) UILabel *timeLabel;
@property(nonatomic,strong) XMScrollView *scrollView;

@end

@implementation XMScrollViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    [self setupViews];
    [self callBack];
}


-(void)setupViews{
    
    [self.view addSubview:self.layerView];
    [self.view addSubview:self.timeLabel];
    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.bottomView];
    [self.view addSubview:self.headView];
    
    self.timeLabel.hidden = YES;
    
    self.scrollView.scroll.contentSize = CGSizeMake(kScreenWidth*self.scrollViewModel.scrollModel.cameraNames.count, kScreenHeight);
    [self.scrollViewModel initCameraWithView:self.layerView frame:CGRectMake(0, 0, kScreenWidth, self.view.frame.size.height - 124)];
    [self resetScrollDataWithPage:self.scrollViewModel.currentPage isScroll:YES isViewdidLoad:YES];
    [self.bottomView.segmentView jumpIndex:self.scrollViewModel.currentPage];
}


-(void)viewWillLayoutSubviews{
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self.view);
        make.height.equalTo(@(124));
    }];
    
    [self.headView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.equalTo(self.view);
        make.height.equalTo(@(64));
    }];
    
    [self.layerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.equalTo(self.view);
        make.bottom.equalTo(self.bottomView.mas_top);
    }];

    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.layerView);
    }];
}

-(void)callBack{
    
    [self callBack_scroll];
    [self callBack_head];
    [self callBack_bottom];
    [self callBack_viewModel];
    [self callBack_Record];
}

- (void)callBack_Record{
    @weakify(self);
    self.scrollViewModel.recordManager.recordProgressBlock = ^(CGFloat time) {
        @strongify(self);
        self.timeLabel.text = [self.scrollViewModel changeRecordTimeWithTime:time];
    };
    
    //二维码结果
    self.scrollViewModel.recordManager.assetManager.QRCodeSuccessBlock = ^(NSString *result) {
        @strongify(self);
        [self.scrollViewModel qrCodeJumpWithResult:result];
    };
    
    //录制状态
    self.scrollViewModel.recordActionBlock = ^(BOOL isRecord, BOOL success) {
        @strongify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.scrollViewModel.scrollModel.cameraType == cameraType_record) {
                self.timeLabel.text = @"00:00:00";
                self.timeLabel.hidden = !isRecord;
                [self.bottomView.circleBtn setBackgroundImage:[UIImage imageNamed:isRecord?@"ic_button":@"ic_shutter"] forState:UIControlStateNormal];
                
                [self canScroll:!isRecord];
                self.headView.setBtn.userInteractionEnabled = !isRecord;
            }
            self.bottomView.circleBtn.userInteractionEnabled = YES;
        });
    };
}

- (void)resetScrollDataWithPage:(NSInteger)page isScroll:(BOOL)isScroll isViewdidLoad:(BOOL)isViewdidLoad{
    
    //点击滑动
    @weakify(self);
    if (self.scrollViewModel.currentPage!=page || isViewdidLoad) {
        self.scrollViewModel.currentPage = page;
        @strongify(self);
        if (isScroll) {
            [self.scrollView.scroll setContentOffset:CGPointMake(kScreenWidth*page, 0)];
        }else{
            [self.bottomView.segmentView jumpIndex:self.scrollViewModel.currentPage];
        }
        
        cameraType type = self.scrollViewModel.scrollModel.cameraType;
        
        self.bottomView.cameraPositionBtn.hidden = type == cameraType_qrCode;
        self.bottomView.circleBtn.hidden = type == cameraType_qrCode;

    }
}

- (void)callBack_scroll{
    @weakify(self);
    self.scrollView.scrollViewDidEndDeceleratingBlock = ^(NSInteger page) {
        //滑动
        @strongify(self);
        [self resetScrollDataWithPage:page isScroll:NO isViewdidLoad:NO];
    };
    
    self.scrollView.tapPointBlock = ^(CGPoint point) {
        //焦距
        @strongify(self);
        [self.scrollViewModel.recordManager.assetManager setFocusCursorWithPoint:point];
    };
    
    self.scrollView.videoScaleBlock = ^(CGFloat scale) {
        //捏合
        @strongify(self);
        [self.scrollViewModel.recordManager.assetManager setVideoScaleAndCropFactor:scale];
    };
}

- (void)callBack_head{
    @weakify(self);
    //闪光灯
    [[self.headView.flashBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        
        RecordFlashState flashState;
        if (self.scrollViewModel.recordManager.assetManager.FlashState == RecordFlashState_Open) {
            flashState = RecordFlashState_Close;
        }else{
            flashState = RecordFlashState_Open;
        }
        [self.scrollViewModel.recordManager.assetManager setFlashState:flashState handler:^(BOOL success) {
            @strongify(self);
            if (success) {
                [self.headView.flashBtn setBackgroundImage:[UIImage imageNamed: flashState == RecordFlashState_Close ? @"ic_iight-close" : @"ic_iight-open"] forState:UIControlStateNormal];
            }
        }];
    }];
}

- (void)callBack_bottom{
    @weakify(self)
    self.bottomView.segmentView.currentPage = ^(NSInteger page) {
        @strongify(self);
        [self resetScrollDataWithPage:page isScroll:YES isViewdidLoad:NO];
    };
    
    //点击录制
    [[self.bottomView.circleBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        //录制/拍照
        self.bottomView.circleBtn.userInteractionEnabled = NO;
        [self.scrollViewModel recordAction];
    }];
    
    //前后置
    [[self.bottomView.cameraPositionBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        
        if (!self.scrollViewModel.recordManager.assetManager.isCapturing) {
            RecordCameraPosition camePositon;
            if (self.scrollViewModel.recordManager.assetManager.cameraPosition == RecordCameraPosition_Front) {
                camePositon = RecordCameraPosition_Back;
            }else{
                camePositon = RecordCameraPosition_Front;
            }
            [self.scrollViewModel.recordManager.assetManager setCameraPosition:camePositon handler:^(BOOL success) {
                if (success) {
                    
                }
            }];
        }
    }];
}

- (void)callBack_viewModel{
    
    @weakify(self);
    //视频旋转
    self.scrollViewModel.orientationBlock = ^(UIDeviceOrientation orientation) {
        @strongify(self);
        switch (orientation) {
            case UIDeviceOrientationPortrait:
                [self transfromViewWithAngle:CGAffineTransformIdentity transfromFrame:CGRectMake(0, self.layerView.frame.size.height - 25, self.layerView.frame.size.width, 18)];
                break;
            case UIDeviceOrientationLandscapeRight:
                [self transfromViewWithAngle:CGAffineTransformMakeRotation(-M_PI_2) transfromFrame:CGRectMake(25 - 18, 64, 18, self.layerView.frame.size.height - 64)];
                break;
            case UIDeviceOrientationLandscapeLeft:
                [self transfromViewWithAngle:CGAffineTransformMakeRotation(M_PI_2) transfromFrame:CGRectMake(self.layerView.frame.size.width - 25, 64, 18, self.layerView.frame.size.height - 64)];
                break;
            default:
                break;
        }
    };
}

- (void)transfromViewWithAngle:(CGAffineTransform)angle transfromFrame:(CGRect)transfromFrame{
    
    self.headView.flashBtn.transform = angle;
    self.headView.setBtn.transform = angle;
    self.bottomView.cameraPositionBtn.transform = angle;
    
    if (!self.scrollViewModel.recordManager.assetManager.isCapturing){
        self.timeLabel.transform = angle;
        self.timeLabel.frame = transfromFrame;
    }
}

//设置是否可滑动/点击
- (void)canScroll:(BOOL)canScroll{
    self.scrollView.scroll.scrollEnabled = canScroll;
    [self.bottomView.segmentView setSegmentBtnEnable:canScroll];
}

#pragma mark -------------- set&get --------------
-(XMScrollView *)scrollView{
    if (!_scrollView) {
        _scrollView = [[XMScrollView alloc] init];
    }
    return _scrollView;
}

-(bottomView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[bottomView alloc] initWithTitles:self.scrollViewModel.scrollModel.cameraNames];
    }
    return _bottomView;
}

-(headView *)headView{
    if (!_headView) {
        _headView = [[headView alloc] init];
    }
    return _headView;
}

-(UIView *)layerView{
    if (!_layerView) {
        _layerView = [[UIView alloc] init];
    }
    return _layerView;
}

-(XMScrollViewModel *)scrollViewModel{
    if (!_scrollViewModel) {
        _scrollViewModel = [[XMScrollViewModel alloc] init];
    }
    return _scrollViewModel;
}

-(UILabel *)timeLabel{
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 124 -25, kScreenWidth, 18)];
        _timeLabel.font = [UIFont systemFontOfSize:17];
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.backgroundColor = [UIColor clearColor];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _timeLabel;
}

@end




