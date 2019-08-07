//
//  SegmentTapView.m
//  SegmentTapView

#import "SegmentTapView.h"

@interface SegmentTapView ()

@property (nonatomic, strong)NSMutableArray *buttonsArray;
@property (nonatomic, strong)UIImageView *lineImageView;

@end

@implementation SegmentTapView

-(instancetype)initWithFrame:(CGRect)frame withDataArray:(NSArray *)dataArray withFont:(CGFloat)font {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.frame = frame;
        self.backgroundColor = [UIColor whiteColor];
        
        _buttonsArray = [[NSMutableArray alloc] init];
        _dataArray = dataArray;
        _titleFont = font;
        
        //默认
        self.textNomalColor = [UIColor blackColor];
        self.textSelectedColor = [UIColor redColor];
        self.segmentBgColor = [UIColor whiteColor];
        self.segmentBgSelectColor = [UIColor whiteColor];
        
        self.lineColor = [UIColor redColor];
        
        [self addSubSegmentView];
    }
    return self;
}

-(void)addSubSegmentView
{
    float width = self.frame.size.width/_dataArray.count;
    
    for (int i = 0 ; i < _dataArray.count ; i++) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(i * width , 0, width, self.frame.size.height)];
        button.tag = i+1;
        [button setTitle:[_dataArray objectAtIndex:i] forState:UIControlStateNormal];
        [button setTitleColor:self.textNomalColor    forState:UIControlStateNormal];
        [button setTitleColor:self.textSelectedColor forState:UIControlStateSelected];
        [button setBackgroundColor:self.segmentBgColor];
        
        button.titleLabel.font = [UIFont systemFontOfSize:_titleFont];
        [button addTarget:self action:@selector(tapAction:) forControlEvents:UIControlEventTouchUpInside];
        
        //默认第一个选中
        if (i == 0) {
            button.selected = YES;
            button.titleLabel.font = [UIFont systemFontOfSize:self.titleSelectedFont];
            button.backgroundColor = self.segmentBgSelectColor;
        }
        else{
            button.selected = NO;
            button.titleLabel.font = [UIFont systemFontOfSize:self.titleFont];
            button.backgroundColor = self.segmentBgColor;
        }
        
        [self.buttonsArray addObject:button];
        [self addSubview:button];

    }
    self.lineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, self.frame.size.height-2, width-40, 2)];
    
    self.lineImageView.backgroundColor = _lineColor;
    [self addSubview:self.lineImageView];
}

-(void)setLineWidth:(float)lineWidth{
    
    _lineWidth = lineWidth;
    for (int i = 0 ; i < self.buttonsArray.count ; i++) {
        UIButton* button = self.buttonsArray[i];
        if (button.selected) {
            float x = button.frame.origin.x + (button.frame.size.width - lineWidth)/2;
            self.lineImageView.frame = CGRectMake(x, self.frame.size.height-2, lineWidth, 2);
            break;
        }
    }
}

-(void)tapAction:(id)sender{
    
//    for (UIButton *subButton in self.buttonsArray) {
//        subButton.userInteractionEnabled = NO;
//    }
    
    UIButton *button = (UIButton *)sender;
    [UIView animateWithDuration:0.2 animations:^{
       
        if (self.lineWidth!=0) {
                    float x = button.frame.origin.x + (button.frame.size.width - self.lineWidth)/2;
                    self.lineImageView.frame = CGRectMake(x, self.frame.size.height-2, self.lineWidth, 2);
        }else{
                   self.lineImageView.frame = CGRectMake(button.frame.origin.x+20, self.frame.size.height-2, button.frame.size.width-40, 2);
        }
    }];
    for (UIButton *subButton in self.buttonsArray) {
        if (button == subButton) {
            subButton.selected = YES;
            subButton.titleLabel.font = [UIFont systemFontOfSize:self.titleSelectedFont];
            subButton.backgroundColor = self.segmentBgSelectColor;
        }
        else{
            subButton.selected = NO;
            subButton.titleLabel.font = [UIFont systemFontOfSize:self.titleFont];
            subButton.backgroundColor = self.segmentBgColor;
        }
    }
    if ([self.delegate respondsToSelector:@selector(selectedIndex:)]) {
        [self.delegate selectedIndex:button.tag -1];
    }
}

-(void)setHideLine:(BOOL)hideLine{
    _hideLine = hideLine;
    self.lineImageView.hidden = hideLine;
}

//设置按钮是否可点
- (void)setSegmentBtnEnable:(BOOL)enable{
 
    for (UIButton *subButton in self.buttonsArray) {
        subButton.userInteractionEnabled = enable;
    }
}

-(void)selectIndex:(NSInteger)index
{
    for (UIButton *subButton in self.buttonsArray) {
        if (index != subButton.tag - 1) {
            subButton.selected = NO;
            subButton.titleLabel.font = [UIFont systemFontOfSize:self.titleFont];
        }
        else{
            subButton.selected = YES;
            subButton.titleLabel.font = [UIFont systemFontOfSize:self.titleSelectedFont];
            [UIView animateWithDuration:0.2 animations:^{
                
                subButton.titleLabel.font = [UIFont systemFontOfSize:self.titleSelectedFont];
                
                if (self.lineWidth!=0) {
                    float x = subButton.frame.origin.x + (subButton.frame.size.width - self.lineWidth)/2;
                    self.lineImageView.frame = CGRectMake(x, self.frame.size.height-2, self.lineWidth, 2);
                }else{
                    self.lineImageView.frame = CGRectMake(subButton.frame.origin.x+20, self.frame.size.height-2, subButton.frame.size.width-40, 2);
                }
                
            }];
        }
    }
}

#pragma mark -- set

-(void)setSegmentBgColor:(UIColor *)segmentBgColor{
    _segmentBgColor = segmentBgColor;
    for (UIButton *subButton in self.buttonsArray){
        if (!subButton.selected) {
            [subButton setBackgroundColor:segmentBgColor];
        }
    }
}

-(void)setSegmentBgSelectColor:(UIColor *)segmentBgSelectColor{
    _segmentBgSelectColor = segmentBgSelectColor;
    for (UIButton *subButton in self.buttonsArray){
        if (subButton.selected) {
            [subButton setBackgroundColor:segmentBgSelectColor];
        }
    }
}

-(void)setLineColor:(UIColor *)lineColor{
    if (_lineColor != lineColor) {
        self.lineImageView.backgroundColor = lineColor;
        _lineColor = lineColor;
    }
}
-(void)setTextNomalColor:(UIColor *)textNomalColor{
    if (_textNomalColor != textNomalColor) {
        for (UIButton *subButton in self.buttonsArray){
            [subButton setTitleColor:textNomalColor forState:UIControlStateNormal];
        }
        _textNomalColor = textNomalColor;
    }
}

-(void)setTextSelectedColor:(UIColor *)textSelectedColor{
    if (_textSelectedColor != textSelectedColor) {
        for (UIButton *subButton in self.buttonsArray){
            [subButton setTitleColor:textSelectedColor forState:UIControlStateSelected];
        }
        _textSelectedColor = textSelectedColor;
    }
}
-(void)setTitleFont:(CGFloat)titleFont{
    if (_titleFont != titleFont) {
        for (UIButton *subButton in self.buttonsArray){
            subButton.titleLabel.font = [UIFont systemFontOfSize:titleFont] ;
        }
        _titleFont = titleFont;
    }
}

-(void)setTitleSelectedFont:(CGFloat)titleSelectedFont{
    if (_titleSelectedFont != titleSelectedFont) {
        for (UIButton *subButton in self.buttonsArray){
            if (subButton.isSelected) {
                subButton.titleLabel.font = [UIFont systemFontOfSize: titleSelectedFont];
                break;
            }
        }
    }
    _titleSelectedFont = titleSelectedFont;
}

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    
    for (UIView* view in self.subviews) {
        CGPoint viewPoint = [self convertPoint:point toView:view];
        UIView* eventView = [view hitTest:viewPoint withEvent:event];
        if ([eventView isKindOfClass:[UIButton class]]) {
            return eventView;
        }
    }
    return nil;
}


@end
