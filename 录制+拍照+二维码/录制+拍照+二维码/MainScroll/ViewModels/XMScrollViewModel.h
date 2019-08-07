//
//  XMScrollViewModel.h
//  
//
//  Created by foxdingding on 2018/11/23.
//

#import "XMScrollModel.h"
#import "recordManager.h"

@interface XMScrollViewModel : NSObject

@property(nonatomic,strong) XMScrollModel* scrollModel;

@property(nonatomic,strong) recordManager* recordManager;

@property(nonatomic,assign) NSInteger currentPage;//当前页

@property(nonatomic,copy) void(^orientationBlock)(UIDeviceOrientation);

@property(nonatomic,copy) void(^recordActionBlock)(BOOL, BOOL);//录制完成

- (void)initCameraWithView:(UIView*)view frame:(CGRect)frame;

-(void)recordAction;

- (NSString*)changeRecordTimeWithTime:(CGFloat)time;

- (void)qrCodeJumpWithResult:(NSString*)result;//二维码扫描完成 跳转

@end
