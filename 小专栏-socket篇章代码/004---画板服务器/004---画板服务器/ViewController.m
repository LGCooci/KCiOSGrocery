//
//  ViewController.m
//  004---画板服务器
//
//  Created by cooci on 2021/10/10.
//


#import "ViewController.h"
#import "UIBezierPath+point.h"
#import "KCView.h"
#import <GCDAsyncUdpSocket.h>

#define KCScreenWidth [UIScreen mainScreen].bounds.size.width
#define KCScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()<GCDAsyncUdpSocketDelegate>
@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (weak, nonatomic) IBOutlet KCView *drawView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initWithDrawView];
}

- (void)initWithDrawView{
    
    __weak typeof(self) weakSelf = self;
    self.drawView.onePathEndBlock = ^(NSMutableDictionary *dict) {
        
        UIBezierPath *path = dict[@"drawPath"];
        NSString *lineColor = dict[@"lineColor"];
        CGFloat lineWidth = [dict[@"lineWidth"] floatValue];
        
        NSArray *points = [path points];
        NSMutableArray *temp = [NSMutableArray arrayWithCapacity:1];
        for (id value in points) {
            CGPoint point = [value CGPointValue];
            NSDictionary *dict = @{@"x":@(point.x),@"y":@(point.y)};
            [temp addObject:dict];
        }
        NSDictionary *passDic = @{@"points"    : temp,
                                  @"lineWidth" : @(lineWidth),
                                  @"lineColor" : lineColor
                                  };
        NSData *passData = [NSJSONSerialization dataWithJSONObject:passDic
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:nil];
        [weakSelf.udpSocket sendData:passData toHost:@"127.0.0.1" port:8070 withTimeout:-1 tag:10086];
    };
}


#pragma mark - 断开连接
- (IBAction)didClickDisconnectAction:(id)sender {
    
    [self.drawView.pathArray removeAllObjects];
    [self.drawView.currentPath removeAllPoints];
    [self.drawView setNeedsDisplay];
}
#pragma mark - 创建socket
- (IBAction)didClickCreatSocketAction:(id)sender {
    
    // 1 创建socket
    if (!self.udpSocket) {
        self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    }
    NSLog(@"创建socket 成功");
    // 2: 绑定socket
    NSError * error = nil;
    [self.udpSocket bindToPort:8070 error:&error];
    if (error) {
        //监听错误打印错误信息
        NSLog(@"error:%@",error);
    }else {
        // 3: 监听成功则开始接收信息
        [self.udpSocket beginReceiving:&error];
    }
    
}

#pragma mark - GCDAsyncUdpSocketDelegate

// 连接成功
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address{
    NSLog(@"连接成功 --- %@",address);
}

// 连接失败
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error{
    NSLog(@"连接失败 反馈: %@",error);
}

// 发送数据成功
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    
    NSLog(@"%ld tag 发送数据成功",tag);
}

// 发送数据失败
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
    NSLog(@"%ld tag 发送数据失败 : %@",tag,error);
}

// 接受数据的回调
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext{
    
    NSDictionary *tempDic = [NSJSONSerialization JSONObjectWithData:data
                                                            options:kNilOptions
                                                              error:nil];
    NSArray *pointArray = [tempDic objectForKey:@"points"];
    UIBezierPath *tempPath = [UIBezierPath bezierPath];
    for (int i = 0; i < pointArray.count; i++) {
        NSDictionary *pointDict = pointArray[i];
        CGPoint point = CGPointMake([pointDict[@"x"] floatValue] , [pointDict[@"y"] floatValue]);
        if (i == 0) {
            //起始点
            [tempPath moveToPoint:point];
        }else{
            [tempPath addLineToPoint:point];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIBezierPath *path = tempPath;
        NSString *lineColor = [tempDic objectForKey:@"lineColor"];
        CGFloat lineWidth = [[tempDic objectForKey:@"lineWidth"] floatValue];
        
        [self.drawView dealwithData:path lineColor:lineColor lineWidth:lineWidth];
        [self.drawView setNeedsDisplay];
    });
    
}

// 关闭失败
- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error{
    NSLog(@"关闭失败: %@",error);
}




@end
