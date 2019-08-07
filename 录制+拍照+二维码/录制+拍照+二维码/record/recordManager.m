//
//  recordManager.m
//  securityCamera
//
//  Created by foxdingding on 2019/5/27.
//  Copyright © 2019年 tdy. All rights reserved.
//

#import "recordManager.h"

@interface recordManager ()<assetWriterDelegate>

@end

@implementation recordManager

- (void)initCameraManagerWithView:(UIView *)view frame:(CGRect)frame VideoPath:(NSString*)videoPath photoPath:(NSString*)photoPath{
    
    self.assetManager = [assetWriterManager initCamera];
    self.assetManager.delegate = self;
    
    self.assetManager.videoPath = videoPath;
    self.assetManager.photoPath = photoPath;
    
    self.assetManager.videoHeight = 1280;
    self.assetManager.videoWeight = 720;
    self.assetManager.frameRate = 30;
    self.assetManager.videoRate = 6*self.assetManager.videoHeight*self.assetManager.videoWeight;
    self.assetManager.channels = 2;
    self.assetManager.samplerate = 44100;
    self.assetManager.audioBitRate = 64000;
    
    [self.assetManager setPreviewView:view frame:frame];//预览图层
    [self.assetManager sessionLayerRunning];//开始预览
}

- (void)callBack{
    self.assetManager.recordRrrorBlock = ^(NSString *error) {
        
    };
}

#pragma mark -------------- assetWriterDelegate --------------
//录制进度
-(void)recordProgress:(CGFloat)progress{
    if (self.recordProgressBlock) {
        self.recordProgressBlock(progress);
    }
}

@end
