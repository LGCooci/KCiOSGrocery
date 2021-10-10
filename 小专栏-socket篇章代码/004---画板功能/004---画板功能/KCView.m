//
//  KCView.m
//  004---画板服务器
//
//  Created by Cooci on 2021/10/10.

#import "KCView.h"

@implementation KCView

#pragma mark -- init Method

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib{
    [super awakeFromNib];
    [self setup];
}


- (void)setup{
    _lineColor = @"0xFF0000";
    _lineWidth = 5;
}

#pragma mark - drawRect

- (void)drawRect:(CGRect)rect {
    
    if (self.pathArray.count) {
        for (NSMutableDictionary *dict in self.pathArray) {
            UIBezierPath *path = dict[@"drawPath"];
            NSString *lineColor = dict[@"lineColor"];
            CGFloat lineWidth = [dict[@"lineWidth"] floatValue];
            [[self colorWithHexString:lineColor] set];
            path.lineWidth = lineWidth;
            [path stroke];
        }
    }
}

#pragma mark -- UIView Touch Action

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //获取起始坐标
    CGPoint startPoint = [self getCurrentPointWithTouches:[event allTouches]];
    //初始化
    UIBezierPath *tempPath = [UIBezierPath bezierPath];
    //绘制第一个点
    [tempPath moveToPoint:startPoint];
    //设置线条风格
    tempPath.lineCapStyle = kCGLineCapRound;
    //设置连接处效果
    tempPath.lineJoinStyle = kCGLineJoinRound;
    tempPath.lineWidth = _lineWidth;
    _currentPath = tempPath;
    
    [self dealwithData:tempPath lineColor:_lineColor lineWidth:_lineWidth];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //获取坐标
    CGPoint movePoint = [self getCurrentPointWithTouches:[event allTouches]];
    //填充图形
    [_currentPath addLineToPoint:movePoint];
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //一条线完成之后回调
    if (self.onePathEndBlock) {
        self.onePathEndBlock([self.pathArray lastObject]);
    }
}

- (CGPoint)getCurrentPointWithTouches:(NSSet *)touches{
    //视图中的所有对象
    UITouch *touch = [touches anyObject];
    //返回触摸点在视图中的坐标
    return [touch locationInView:touch.view];
}

#pragma mark - 数据处理

- (void)dealwithData:(UIBezierPath *)path lineColor:(NSString *)lineColor lineWidth:(CGFloat)lineWidth{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:1];
    [dict setValue:lineColor forKey:@"lineColor"];
    [dict setValue:path forKey:@"drawPath"];
    [dict setValue:@(lineWidth) forKey:@"lineWidth"];
    [self.pathArray addObject:dict];
}


#pragma mark -- Getter And Setter

- (void)setLineColor:(NSString *)lineColor{
    _lineColor = lineColor;
}

- (void)setLineWidth:(CGFloat)lineWidth{
    _lineWidth = lineWidth;
}

- (NSMutableArray *)pathArray{
    if (!_pathArray) {
        _pathArray = [NSMutableArray arrayWithCapacity:0];
    }
    return _pathArray;
}


- (UIColor *) colorWithHexString: (NSString *) hexString
{
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            blue=0;
            green=0;
            red=0;
            alpha=0;
            break;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: 1];
}

- (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length
{
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent ;
}

@end


