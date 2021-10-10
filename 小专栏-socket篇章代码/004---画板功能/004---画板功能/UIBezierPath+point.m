#import "UIBezierPath+point.h"

@implementation UIBezierPath (point)

#define VALUE(_INDEX_) [NSValue valueWithCGPoint:points[_INDEX_]]

void getPointsFromBezier(void *info,const CGPathElement *element){
    
    NSMutableArray *bezierPoints = (__bridge NSMutableArray *)info;
    CGPathElementType type = element->type;
    CGPoint *points = element->points;
    
    if (type != kCGPathElementCloseSubpath) {
        [bezierPoints addObject:VALUE(0)];
        if ((type != kCGPathElementAddLineToPoint) && (type != kCGPathElementMoveToPoint)) {
            [bezierPoints addObject:VALUE(1)];
        }
    }
    
    if (type == kCGPathElementAddCurveToPoint) {
        [bezierPoints addObject:VALUE(2)];
    }
}
/*!
 @method  获得UIBezierPath曲线上的所有点坐标
 @abstract 获得UIBezierPath曲线上的所有点坐标
 @result 坐标点数组
 */
- (NSArray *)points
{
    NSMutableArray *points = [NSMutableArray array];
    CGPathApply(self.CGPath, (__bridge void *)points, getPointsFromBezier);
    return points;
}
@end
