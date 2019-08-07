//
//  XMScrollModel.h
//  securityCamera
//
//  Created by foxdingding on 2018/11/23.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, cameraType) {
    cameraType_photo,//普通
    cameraType_record,//视频
    cameraType_qrCode,//二维码
};

@interface XMScrollModel : NSObject

@property(nonatomic,strong) NSArray* cameraNames;//类名

@property(nonatomic,assign) cameraType cameraType;//当前类型

@property(nonatomic,strong) NSString *resourcePath;//资源路径

@property(nonatomic,strong) NSString *resourceStr;//资源数据

@property(nonatomic,strong) NSString *takeTime;//拍摄时间


@end
