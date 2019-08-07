//
//  assetWriterModel.m
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/3/1.
//  Copyright © 2018年 tdy. All rights reserved.


#import "assetWriterManager.h"
#import <UIKit/UIKit.h>
#import "assetWriterEncode.h"
#import <Photos/Photos.h>

@interface assetWriterManager ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate, CAAnimationDelegate,AVCaptureMetadataOutputObjectsDelegate>

@property (strong, nonatomic) AVCaptureDeviceInput       *cameraInput;//摄像头输入
@property (strong, nonatomic) AVCaptureDeviceInput       *audioMicInput;//麦克风输入
@property (strong, nonatomic) AVCaptureSession           *recordSession;//捕获视频的会话
@property (copy  , nonatomic) dispatch_queue_t           captureQueue;//录制的队列
@property (strong, nonatomic) AVCaptureConnection        *audioConnection;//音频录制连接
@property (strong, nonatomic) AVCaptureConnection        *videoConnection;//视频录制连接
@property (strong, nonatomic) AVCaptureVideoDataOutput   *videoOutput;//视频输出
@property (strong, nonatomic) AVCaptureAudioDataOutput   *audioOutput;//音频输出
@property (strong, nonatomic) AVCaptureStillImageOutput  *stillImageOutput;//图片输出

@property (strong, nonatomic) AVCaptureMetadataOutput *metadataOutput;

@property (strong,nonatomic)  UIView *previewView;//呈现的View
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *recordPreviewLayer;//捕获到的视频呈现的layer
@property (strong, nonatomic) assetWriterEncode *recordEncoder;//录制编码
@property (strong,nonatomic)  dispatch_source_t timer;         //录制队列
@property (assign,nonatomic)  CGAffineTransform RecordTransfrom;//录制旋转角度
@property (assign,nonatomic)  AVCaptureVideoOrientation recordOrientation;//拍照视频方向

@property (atomic, assign) BOOL isCapturing;//正在录制
@property (atomic, assign) CGFloat currentRecordTime;//当前录制时间

@property (strong,nonatomic) UIView* preViewView_QrCode;//展示的二维码View
@property (strong,nonatomic) UIImageView *scanLayer;
@property (strong,nonatomic) UIImageView *boxView;//扫描框
@property (strong,nonatomic) CAShapeLayer *fillLayer;
@property (strong,nonatomic) UILabel *showDesLabel;

@end

@implementation assetWriterManager

@synthesize FlashState = _FlashState;
@synthesize cameraPosition = _cameraPosition;
@synthesize resolutionType = _resolutionType;

//初始化
+ (instancetype)initCamera{
    assetWriterManager* manager = [[assetWriterManager alloc] init];
    [manager startUp];
    return manager;
}

//初始化录制
- (void)startUp {
    // 默认设置
    self.isCapturing = NO;
    _videoOrientation = RecordVideoOrientation_Portrait;
    _resolutionType = RecordResolution_1280x720;
    _FlashState = RecordFlashState_Close;
    _cameraPosition = RecordCameraPosition_Back;
    self.videoOrientation = RecordVideoOrientation_Portrait;
    
    [self videoConnection];
    [self audioConnection];
}

#pragma mark -------------- publicMethod --------------
//开始录制
- (void)startCapture{
    if (!self.isCapturing) {
        AVCaptureDevice* device = self.cameraInput.device;
        if (device.isSmoothAutoFocusSupported) {
            NSError *error;
            if ( [device lockForConfiguration:&error] ) {
                device.smoothAutoFocusEnabled = YES;
                [device unlockForConfiguration];
                [self recordVideo];
            }else{
                [self recordVideo];
            }
        }else{
            [self recordVideo];
        }
    }
}

//停止录制
- (void)stopCaptureHandler:(void (^)(BOOL success))handler{
    if (self.isCapturing) {
        self.isCapturing = NO;
        self.currentRecordTime = 0;
        [self.recordEncoder finishWithCompletionHandler:^{
            self.recordEncoder = nil;
            handler(YES);
        }];
    }
}

//拍照
- (void)takePhoto:(void(^)(UIImage *image))callback{
    AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    if (connection.isVideoOrientationSupported) {
        connection.videoOrientation = self.recordOrientation;
    }
    id takePictureSuccess = ^(CMSampleBufferRef sampleBuffer,NSError *error){
        if (sampleBuffer == NULL) {
            return ;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
        UIImage *image = [[UIImage alloc]initWithData:imageData];
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.photoPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.photoPath error:nil];
        }
        BOOL success = [imageData writeToFile:self.photoPath atomically:YES];
        if (success) {
            callback(image);
        }else{
            callback(nil);
        }
    };
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:takePictureSuccess];
}

// 设置/切换预览图层
- (void)setPreviewView:(UIView *)previewView frame:(CGRect)frame{
    
    if (self.recordPreviewLayer) {
        [self.recordPreviewLayer removeFromSuperlayer];
    }
    self.previewView = previewView;
    self.recordPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.recordSession];
    self.recordPreviewLayer.frame = frame;
    self.recordPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [previewView.layer addSublayer:self.recordPreviewLayer];
}

- (void)sessionLayerRunning{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setAutoFocusMode];
        [self addListening];
        if (self.isQrCodeType) {
            [self addQrCodeLayer];
            [self addAnimation];
        }
        if (![self.recordSession isRunning]) {
            [self.recordSession startRunning];
        }
    });
}

- (void)sessionLayerStop{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeListening];
        [self setFlashState:RecordFlashState_Close handler:nil];
        [self removeQrCodeLayer];
        [self removeAnimation];
        if ([self.recordSession isRunning]) {
            [self.recordSession stopRunning];
        }
    });

}

- (void)addQrCodeLayer{
    // 创建预览图层
    [self.previewView addSubview:self.preViewView_QrCode];
    [self.previewView addSubview:self.showDesLabel];
    
    [self.preViewView_QrCode addSubview:self.boxView];
    [self.preViewView_QrCode.layer addSublayer:self.fillLayer];
}

- (void)removeQrCodeLayer{
    [self.boxView removeFromSuperview];
    [self.fillLayer removeFromSuperlayer];
    [self.showDesLabel removeFromSuperview];
    [self.preViewView_QrCode removeFromSuperview];
    self.boxView = nil;
    self.fillLayer = nil;
    self.showDesLabel = nil;
    self.preViewView_QrCode = nil;
    [self removeAnimation];
}

- (void)addAnimation{
    
    [self removeAnimation];
    [self.boxView addSubview:self.scanLayer];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:2];
    [UIView setAnimationRepeatCount:10000];
    [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.scanLayer cache:NO];
    [UIView setAnimationRepeatAutoreverses:YES];
    CGRect frame = self.scanLayer.frame;
    frame.origin.y = self.boxView.frame.size.height - 5;
    self.scanLayer.frame = frame;
    [UIView commitAnimations];
    
}

- (void)removeAnimation{
    [self.scanLayer.layer removeAllAnimations];
    [self.scanLayer removeFromSuperview];
    self.scanLayer = nil;
}

//闪光灯
- (void)setFlashState:(RecordFlashState)flashState handler:(void (^)(BOOL success))handler{
    
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        AVCaptureTorchMode TorchMode;
        switch (flashState) {
            case 0:
                TorchMode = AVCaptureTorchModeOff;
                self->_FlashState = RecordFlashState_Close;
                break;
            case 1:
                TorchMode = AVCaptureTorchModeOn;
                self->_FlashState = RecordFlashState_Open;
                break;
            case 2:
                TorchMode = AVCaptureTorchModeAuto;
                self->_FlashState = RecordFlashState_Auto;
                break;
            default:
                break;
        }
        
        if ([captureDevice isTorchModeSupported:TorchMode]){
            [captureDevice setTorchMode:TorchMode];
            if (handler) {
                handler(YES);
            }
        }else{
            NSLog(@"====FlashState----NOSupported");
            switch (captureDevice.torchMode) {
                case 0:
                    self->_FlashState = RecordFlashState_Open;
                    break;
                case 1:
                    self->_FlashState = RecordFlashState_Close;
                    break;
                case 2:
                    self->_FlashState = RecordFlashState_Auto;
                    break;
                default:
                    break;
            }
            if (handler) {
                handler(NO);
            }
        }
    }];
}

//分辨率设置
- (void)setCameraResolution:(RecordResolution)type handle:(void(^)(BOOL success))handle{
    _resolutionType = type;
    __block BOOL success;
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        if (type == RecordResolution_640x480) {
            self.videoHeight = 640;
            self.videoWeight = 480;
            if ([self.recordSession canSetSessionPreset:AVCaptureSessionPreset640x480]){
                [self.recordSession setSessionPreset:AVCaptureSessionPreset640x480];
                success = YES;
            }else{
                success = NO;
            }
        }else if (type == RecordResolution_1280x720){
            self.videoHeight = 1280;
            self.videoWeight = 720;
            if ([self.recordSession canSetSessionPreset:AVCaptureSessionPreset1280x720]){
                [self.recordSession setSessionPreset:AVCaptureSessionPreset1280x720];
                success = YES;
            }else{
                success = NO;
            }
        }else{
            self.videoHeight = 1920;
            self.videoWeight = 1080;
            if ([self.recordSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]){
                [self.recordSession setSessionPreset:AVCaptureSessionPreset1920x1080];
                success = YES;
            }else{
                success = NO;
            }
        }
        if (handle) {
            handle(success);
        }
        if (!success) {
            self.recordRrrorBlock(@"当前设备不支持此分辨率");
        }
    }];
}

//切换摄像头
- (void)setCameraPosition:(RecordCameraPosition)position handler:(void (^)(BOOL success))handler{
    
    AVCaptureDevicePosition currentPosition = [self getCameraPosition];
    AVCaptureDevicePosition toPosition;
    
    if (!currentPosition) {
        //获取失败
        NSLog(@"获取摄像头失败");
        handler(NO);
    }
    if (currentPosition == AVCaptureDevicePositionBack || currentPosition == AVCaptureDevicePositionUnspecified)
    {
        toPosition = AVCaptureDevicePositionFront;
    }else{
        toPosition = AVCaptureDevicePositionBack;
    }
    
    // 获取摄像头设备
    AVCaptureDevice *camera = [self getCameraDeviceWithPosition:toPosition];
    
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        NSError *error = nil;
        AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
        [self.recordSession removeInput:self.cameraInput];
        if ([_recordSession canAddInput:newInput]){
            [_recordSession addInput:newInput];
            self.cameraInput = newInput;
        }
        
        [self setCameraResolution:self.resolutionType handle:nil];
        // 重新获取连接并设置视频的方向、是否镜像
        self.videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
        self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        if (camera.position == AVCaptureDevicePositionFront && self.videoConnection.supportsVideoMirroring)
        {
            self.videoConnection.videoMirrored = YES;
        }
    }];
}

//聚焦点
- (void)setFocusCursorWithPoint:(CGPoint)point{
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        
        CGPoint cameraPoint= [self.recordPreviewLayer captureDevicePointOfInterestForPoint:point];
        
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:cameraPoint];
        }
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:cameraPoint];
        }
    }];
}

//设置焦距
- (void)setVideoScaleAndCropFactor:(float)scale{
    AVCaptureDevice *captureDevice= [self.cameraInput device];
    NSError *error;
    if ([captureDevice lockForConfiguration:&error]) {
        [captureDevice rampToVideoZoomFactor:scale withRate:10];
    }
}

// 调节ISO，光感度 0.0-1.0
- (void)setCameraBackgroundDidChangeISO:(CGFloat)iso{
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        CGFloat minISO = captureDevice.activeFormat.minISO;
        CGFloat maxISO = captureDevice.activeFormat.maxISO;
        CGFloat currentISO = (maxISO - minISO) * iso + minISO;
        [captureDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:currentISO completionHandler:nil];
        [captureDevice unlockForConfiguration];
    }];
}

#pragma mark -------------- privateMethod --------------

- (void)addListening{
    
    //注意添加区域改变捕获通知必须首先设置设备允许捕获
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        //自动对象,苹果提供了对应的通知api接口,可以直接添加通知
        captureDevice.subjectAreaChangeMonitoringEnabled=YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
    }];
}

- (void)removeListening{
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }];
}

- (void)startTimer{
    NSTimeInterval period = 1.0;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_timer, ^{
        //执行事件
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(recordProgress:)]) {
                [self.delegate recordProgress:self.currentRecordTime];
            }
            self.currentRecordTime++;
        });
    });
    dispatch_resume(_timer);
}

-(void)recordVideo{
    self.recordEncoder = nil;
    self.currentRecordTime = 0;
    self.isCapturing = YES;
    [self startTimer];
}

//获取摄像头方向
- (AVCaptureDevicePosition)getCameraPosition{
    return self.cameraInput.device.position;
}

//改变设备属性前一定要首先调用lockForConfiguration方法加锁,调用完之后使用unlockForConfiguration方法解锁.
-(void)changeDevicePropertySafety:(void (^)(AVCaptureDevice *captureDevice))propertyChange{
    
    //也可以直接用_videoDevice,但是下面这种更好
    AVCaptureDevice *captureDevice= [self.cameraInput device];
    NSError *error;
    
    BOOL lockAcquired = [captureDevice lockForConfiguration:&error];
    if (!lockAcquired) {
        self.recordRrrorBlock([NSString stringWithFormat:@"锁定设备过程error，错误信息：%@",error.localizedDescription]);
    }else{
        [self.recordSession beginConfiguration];
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
        [self.recordSession commitConfiguration];
    }
}

- (void)setAutoFocusMode{
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
    }];
}

//摄像头设备
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    //返回和视频录制相关的所有默认设备
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //遍历这些设备返回跟position相关的设备
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}


#pragma mark -------------- set&get --------------

- (CAShapeLayer *)fillLayer{
    if (!_fillLayer) {
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.recordPreviewLayer.bounds cornerRadius:0];
        UIBezierPath *framePath = [UIBezierPath bezierPathWithRoundedRect:self.boxView.frame cornerRadius:0];
        [path appendPath:framePath];
        [path setUsesEvenOddFillRule:YES];
        
        _fillLayer = [CAShapeLayer layer];
        
        _fillLayer.path = path.CGPath;
        
        _fillLayer.fillRule =kCAFillRuleEvenOdd;
        
        _fillLayer.fillColor = [UIColor blackColor].CGColor;
        
        _fillLayer.opacity = 0.5;
    }
    return _fillLayer;
}

-(UIView *)preViewView_QrCode{
    if (!_preViewView_QrCode) {
        _preViewView_QrCode = [[UIView alloc] initWithFrame:self.previewView.bounds];
    }
    return _preViewView_QrCode;
}

- (UILabel *)showDesLabel{
    if (!_showDesLabel) {
        _showDesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.boxView.frame.origin.y+self.boxView.frame.size.height + 20, self.recordPreviewLayer.frame.size.width, 20)];
        _showDesLabel.text = @"将二维码／条码放入框内，即可自动扫描";
        _showDesLabel.textColor = [UIColor whiteColor];
        _showDesLabel.textAlignment = NSTextAlignmentCenter;
        _showDesLabel.font = [UIFont systemFontOfSize:12];
    }
    return _showDesLabel;
}


-(UIImageView *)boxView{
    if (!_boxView) {
        _boxView = [[UIImageView alloc] initWithFrame:CGRectMake(self.recordPreviewLayer.frame.size.width * 0.2, self.recordPreviewLayer.frame.size.height*0.4, self.recordPreviewLayer.frame.size.width - self.recordPreviewLayer.frame.size.width * 0.4f, self.recordPreviewLayer.frame.size.width - self.recordPreviewLayer.frame.size.width * 0.4f)];
        [_boxView setImage:[UIImage imageNamed:@"矩形边框"]];
    }
    return _boxView;
}

- (UIImageView *)scanLayer{
    if (!_scanLayer) {
        _scanLayer = [[UIImageView alloc] init];
        [_scanLayer setImage:[UIImage imageNamed:@"扫描"]];
        _scanLayer.frame = CGRectMake(10, 0, _boxView.bounds.size.width - 20, 7);
    }
    return _scanLayer;
}

-(AVCaptureMetadataOutput *)metadataOutput{
    if (!_metadataOutput) {
        _metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    }
    return _metadataOutput;
}

//静态图像输出
- (AVCaptureStillImageOutput *)stillImageOutput{
    if (_stillImageOutput == nil) {
        _stillImageOutput = [[AVCaptureStillImageOutput alloc]init];
        _stillImageOutput.outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    }
    return _stillImageOutput;
}

//设置录制方向
-(void)setVideoOrientation:(RecordVideoOrientation)videoOrientation{
    _videoOrientation = videoOrientation;
    CGAffineTransform transfrom = CGAffineTransformMakeRotation(0);
    switch (self.videoOrientation) {
        case RecordVideoOrientation_Portrait:
            transfrom = CGAffineTransformMakeRotation(0);
            _recordOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case RecordVideoOrientation_Left:
            transfrom = CGAffineTransformMakeRotation(-M_PI/2);
            _recordOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case RecordVideoOrientation_Right:
            transfrom = CGAffineTransformMakeRotation(M_PI/2);
            _recordOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            break;
    }
    _RecordTransfrom = transfrom;
}

//初始化编码器
-(assetWriterEncode *)recordEncoder{
    if (!_recordEncoder) {
        _recordEncoder = [assetWriterEncode encoderForPath:self.videoPath transfrom:self.RecordTransfrom Height:_videoHeight width:_videoWeight videoRate:_frameRate BitRate:_videoRate channels:_channels samples:_samplerate audioBitRate:_audioBitRate];
    }
    return _recordEncoder;
}


// 获取摄像头设备
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            
            if ([device supportsAVCaptureSessionPreset:[self getSessionPreset]]){
                return device;
            }else{
                return nil;
            }
        }
    }
    return nil;
}

- (AVCaptureSessionPreset)getSessionPreset{
    AVCaptureSessionPreset sessionPreset;
    switch (self.resolutionType) {
        case 0:
            sessionPreset = AVCaptureSessionPreset640x480;
            break;
        case 1:
            sessionPreset = AVCaptureSessionPreset1280x720;
            break;
        case 2:
            sessionPreset = AVCaptureSessionPreset1920x1080;
            break;
            
        default:
            break;
    }
    
    return sessionPreset;
}

//捕获视频的会话
- (AVCaptureSession *)recordSession {
    if (_recordSession == nil) {
        _recordSession = [[AVCaptureSession alloc] init];
        //添加后置摄像头的输出
        if ([_recordSession canAddInput:self.cameraInput]) {
            [_recordSession addInput:self.cameraInput];
        }
        //添加后置麦克风的输出
        if ([_recordSession canAddInput:self.audioMicInput]) {
            [_recordSession addInput:self.audioMicInput];
        }
        //添加视频输出
        if ([_recordSession canAddOutput:self.videoOutput]) {
            [_recordSession addOutput:self.videoOutput];
        }
        //添加音频输出
        if ([_recordSession canAddOutput:self.audioOutput]) {
            [_recordSession addOutput:self.audioOutput];
        }
        
        // 静态图像输出
        if ([_recordSession canAddOutput:self.stillImageOutput]) {
            [_recordSession addOutput:self.stillImageOutput];
        }
        
        // 二维码添加
        if ([_recordSession canAddOutput:self.metadataOutput]) {
            [_recordSession addOutput:self.metadataOutput];
        }
        
        [self.metadataOutput setMetadataObjectsDelegate:self queue:self.captureQueue];
        // 4.设置输出能够解析的数据类型
        // 注意点: 设置数据类型一定要在输出对象添加到会话之后才能设置
        self.metadataOutput.metadataObjectTypes= @[AVMetadataObjectTypeQRCode,//二维码
                                                   //以下为条形码，如果项目只需要扫描二维码，下面都不要写
                                                   AVMetadataObjectTypeEAN13Code,
                                                   AVMetadataObjectTypeEAN8Code,
                                                   AVMetadataObjectTypeUPCECode,
                                                   AVMetadataObjectTypeCode39Code,
                                                   AVMetadataObjectTypeCode39Mod43Code,
                                                   AVMetadataObjectTypeCode93Code,
                                                   AVMetadataObjectTypeCode128Code,
                                                   AVMetadataObjectTypePDF417Code];
        
        //self.metadataOutput.availableMetadataObjectTypes;
        //        self.metadataOutput.metadataObjectTypes=@[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
        //设置扫描范围
        self.metadataOutput.rectOfInterest = CGRectMake(0.2f, 0.2f, 0.8f, 0.8f);
        
        //设置视频录制的方向
        self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        
        //分辨率
        [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
            if ([self.recordSession canSetSessionPreset:AVCaptureSessionPreset1280x720]){
                self.recordSession.sessionPreset = AVCaptureSessionPreset1280x720;
            }
        }];
        
        //自动白平衡
        if ([self.cameraInput.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [self.cameraInput.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
    }
    return _recordSession;
}

//摄像头输入
- (AVCaptureDeviceInput *)cameraInput {
    if (_cameraInput == nil) {
        NSError *error;
        _cameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraWithPosition:AVCaptureDevicePositionBack] error:&error];
        if (error) {
            NSLog(@"获取后置摄像头失败");
            if (self.recordRrrorBlock) {
                self.recordRrrorBlock(@"获取后置摄像头失败");
            }
        }
    }
    return _cameraInput;
}

//麦克风输入
- (AVCaptureDeviceInput *)audioMicInput {
    if (_audioMicInput == nil) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audioMicInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error) {
            NSLog(@"获取麦克风失败");
            if (self.recordRrrorBlock) {
                self.recordRrrorBlock(@"获取麦克风失败");
            }
        }
    }
    return _audioMicInput;
}

//录制的队列
- (dispatch_queue_t)captureQueue {
    if (_captureQueue == nil) {
        _captureQueue = dispatch_queue_create(0, 0);
    }
    return _captureQueue;
}


//视频输出
- (AVCaptureVideoDataOutput *)videoOutput {
    if (!_videoOutput) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
        NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                                        nil];
        _videoOutput.videoSettings = setcapSettings;
    }
    return _videoOutput;
}

//音频输出
- (AVCaptureAudioDataOutput *)audioOutput {
    if (_audioOutput == nil) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
    }
    return _audioOutput;
}

//视频连接
- (AVCaptureConnection *)videoConnection {
    if (!_videoConnection) {
        _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    }
    return _videoConnection;
}

//音频连接
- (AVCaptureConnection *)audioConnection {
    if (_audioConnection == nil) {
        _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    //判断是否有数据
    if (metadataObjects.count && self.isQrCodeType) {
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects[0];
        NSString *result = metadataObject.stringValue;
        if (self.QRCodeSuccessBlock) {
            self.QRCodeSuccessBlock(result);
        }
    }
}

#pragma mark - 写入数据
- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (!self.isCapturing) {
        return;
    }
    
    @autoreleasepool
    {
        // 进行数据编码
        BOOL isVideo;
        if (connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo])
        {
            isVideo = YES;
        }else{
            isVideo = NO;
        }
        @synchronized(self)
        {
            
            BOOL append = [self.recordEncoder encodeFrame:sampleBuffer isVideo:isVideo];
            if (!append) {
                //停止录制
                [self stopCaptureHandler:^(BOOL success) {
                    
                }];
            }
        }
    }

}

#pragma mark -------------- noti --------------
- (void)subjectAreaDidChange:(NSNotification *)notification{
    [self setAutoFocusMode];
}
@end



