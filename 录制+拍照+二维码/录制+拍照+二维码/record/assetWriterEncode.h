//
//  assetWriterEncode.h
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/4/2.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface assetWriterEncode : NSObject

@property (nonatomic, readonly) NSString *path;

/**
 *
 *  path 视频路径
 *  videoHeight   视频分辨率的高
 *  videoWight   视频分辨率的宽
 *  channels   音频通道
 *  audioBitRate 音频比特率
 *  rate 音频的采样率
 *  BitRate 视频码率
 *  videoRate 视频最大帧率
 */

+ (assetWriterEncode*)encoderForPath:(NSString*)path transfrom:(CGAffineTransform)transfrom Height:(NSInteger)videoHeight width:(NSInteger)videoWight  videoRate:(Float64)videoRate BitRate:(NSInteger)BitRate channels: (int)channels samples:(Float64)rate audioBitRate:(Float64)audioBitRate;

//结束录制 完成写入
- (void)finishWithCompletionHandler:(void (^)(void))handler;

/**
 *  通过这个方法写入数据
 *
 *  @param sampleBuffer 写入的数据
 *  @param isVideo      是否写入的是视频
 *
 *  @return 写入是否成功
 */
- (BOOL)encodeFrame:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)isVideo;

@end
