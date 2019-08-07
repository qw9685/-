//
//  assetWriterEncode.m
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/4/2.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import "assetWriterEncode.h"
#import <AVFoundation/AVFoundation.h>

@interface assetWriterEncode ()

@property (nonatomic, strong) AVAssetWriter *writer;//媒体写入对象
@property (nonatomic, strong) AVAssetWriterInput *videoInput;//视频写入
@property (nonatomic, strong) AVAssetWriterInput *audioInput;//音频写入
@property (nonatomic, strong) NSString *path;//写入路径
@property (nonatomic, assign) CGAffineTransform transfrom;

@end

@implementation assetWriterEncode

+ (assetWriterEncode*)encoderForPath:(NSString*)path transfrom:(CGAffineTransform)transfrom Height:(NSInteger)videoHeight width:(NSInteger)videoWight  videoRate:(Float64)videoRate BitRate:(NSInteger)BitRate channels: (int)channels samples:(Float64)rate audioBitRate:(Float64)audioBitRate{
    
    assetWriterEncode* enc = [assetWriterEncode alloc];
    enc.transfrom = transfrom;
    return [enc initPath:path Height:videoHeight width:videoWight channels:channels samples:rate audioBitRate:audioBitRate videoRate:videoRate BitRate:BitRate];
}

//初始化方法
- (instancetype)initPath:(NSString*)path Height:(NSInteger)videoHeight width:(NSInteger)videoWight channels:(int)channels samples:(Float64) audioRate audioBitRate:(Float64)audioBitRate  videoRate:(Float64)videoRate BitRate:(NSInteger)BitRate{
    self = [super init];
    if (self) {
        self.path = path;
        [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
        NSURL* url = [NSURL fileURLWithPath:self.path];
        //初始化写入媒体类型为MP4类型
        _writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:nil];
        //使其更适合在网络上播放
        _writer.shouldOptimizeForNetworkUse = YES;
        //初始化视频输出、
        if (videoRate!=0 && BitRate!=0) {
           [self initVideoInputHeight:videoHeight width:videoWight FrameRate:videoRate BitRate:BitRate];
        }

        if (channels != 0 && audioRate!= 0) {
            //初始化音频输出
            [self initAudioInputChannels:channels samples:audioRate audioBitRate:audioBitRate];
        }
    }
    
    return self;
}

//初始化视频输入
- (void)initVideoInputHeight:(NSInteger)videoHeight width:(NSInteger)videoWight FrameRate:(NSInteger)FrameRate BitRate:(NSInteger)BitRate{
    //录制视频的一些配置，分辨率，编码方式等等
    
    NSDictionary *videoCompressionProps;
    NSDictionary *videoSettings;
    
//    switch (cameraModel.videoResolution) {
//        case AVCaptureSessionPreset3840x2160:
//            videoCompressionProps = @{
//                                      AVVideoAverageBitRateKey:@(50*1024.0*1024),
//                                      AVVideoH264EntropyModeKey:AVVideoH264EntropyModeCABAC,
//                                      AVVideoMaxKeyFrameIntervalKey:@(30),
//                                      AVVideoAllowFrameReorderingKey:@NO,
//                                      AVVideoExpectedSourceFrameRateKey:@30,
//                                      };
//            break;
//        case AVCaptureSessionPreset1920x1080:
//            videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
//                                     [NSNumber numberWithDouble:18*1024.0*1024], AVVideoAverageBitRateKey,
//                                     AVVideoH264EntropyModeCABAC,AVVideoH264EntropyModeKey,
//                                     nil];
//            break;
//        case AVCaptureSessionPreset1280x720:
//            videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
//                                     [NSNumber numberWithDouble:8*1024.0*1024], AVVideoAverageBitRateKey,
//                                     AVVideoH264EntropyModeCABAC,AVVideoH264EntropyModeKey,
//                                     nil ];
//            break;
//        default:
//            break;
//    }
    
                videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInteger:FrameRate], AVVideoMaxKeyFrameIntervalKey,
                                         [NSNumber numberWithInteger:BitRate], AVVideoAverageBitRateKey,
                                         AVVideoH264EntropyModeCABAC,AVVideoH264EntropyModeKey,
                                         nil];
    
    videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                     AVVideoCodecH264,AVVideoCodecKey,
                     videoCompressionProps, AVVideoCompressionPropertiesKey,
                     AVVideoScalingModeResizeAspectFill,AVVideoScalingModeKey,
                     [NSNumber numberWithInteger:videoWight],AVVideoWidthKey,
                     [NSNumber numberWithInteger:videoHeight],AVVideoHeightKey,
                     nil];

    //初始化视频写入类
    _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    //表明输入是否应该调整其处理为实时数据源的数据
    _videoInput.expectsMediaDataInRealTime = YES;
    _videoInput.transform = self.transfrom;
    //将视频输入源加入
    [_writer addInput:_videoInput];
}

//初始化音频输入
- (void)initAudioInputChannels:(int)channels samples:(Float64)rate audioBitRate:(Float64)BitRate{
    //音频的一些配置包括音频各种这里为AAC,音频通道、采样率和音频的比特率
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                              [ NSNumber numberWithInt: channels], AVNumberOfChannelsKey,
                              [ NSNumber numberWithFloat: rate], AVSampleRateKey,
                              [ NSNumber numberWithInt: BitRate], AVEncoderBitRateKey,
                              nil];
    //初始化音频写入类
    _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:settings];
    //表明输入是否应该调整其处理为实时数据源的数据
    _audioInput.expectsMediaDataInRealTime = YES;
    //将音频输入源加入
    [_writer addInput:_audioInput];
}

//完成视频录制时调用
- (void)finishWithCompletionHandler:(void (^)(void))handler {
    [_writer finishWritingWithCompletionHandler:^{
        self.writer = nil;
        if (handler) {
            handler();
        }
    }];
}

//通过这个方法写入数据
- (BOOL)encodeFrame:(CMSampleBufferRef) sampleBuffer isVideo:(BOOL)isVideo {
    
    if (sampleBuffer == NULL)
    {
        NSLog(@"empty sampleBuffer");
        return NO;
    }

    @autoreleasepool
    {
        if (CMSampleBufferDataIsReady(sampleBuffer)){
            if (_writer.status == AVAssetWriterStatusUnknown && isVideo){
                CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                //开始写入
                [self.writer startWriting];
                [self.writer startSessionAtSourceTime:startTime];
            }
            
            //写入视频数据
            if (isVideo)
            {
                if (self.videoInput.readyForMoreMediaData)
                {
                    BOOL success = [self.videoInput appendSampleBuffer:sampleBuffer];
                    if (!success)
                    {
                        return NO;
                    }
                }
            }else{
                //写入音频数据
                if (self.audioInput.readyForMoreMediaData)
                {
                    BOOL success = [self.audioInput appendSampleBuffer:sampleBuffer];
                    if (!success)
                    {
                        return NO;
                    }
                }
                
            }
        }
    }
    return YES;
}

@end
