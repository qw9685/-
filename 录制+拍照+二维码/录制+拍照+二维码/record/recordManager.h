//
//  recordManager.h
//  securityCamera
//
//  Created by foxdingding on 2019/5/27.
//  Copyright © 2019年 tdy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "assetWriterManager.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface recordManager : NSObject

@property(nonatomic,strong) assetWriterManager *assetManager;
@property(nonatomic,copy) void(^recordProgressBlock)(CGFloat time);

- (void)initCameraManagerWithView:(UIView *)view frame:(CGRect)frame VideoPath:(NSString*)videoPath photoPath:(NSString*)photoPath;

@end

NS_ASSUME_NONNULL_END
