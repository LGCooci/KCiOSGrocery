//
//  ViewController.m
//  003---粘包拆包
//
//  Created by cooci on 2021/10/10.
//

#import "ViewController.h"
#import <GCDAsyncSocket.h>

//图片
#define kcImageDataType 0x00000001
#define kcVideoDataType 0x00000002

@interface ViewController ()<GCDAsyncSocketDelegate>
@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSMutableData  *dataM;
@property (nonatomic, assign) unsigned int totalSize;
@property (nonatomic, assign) unsigned int currentCommandId;
@property (nonatomic, strong) NSMutableArray *clientSockets;
@property (nonatomic, copy) NSString *name;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}
- (IBAction)didClickConnectSocket:(id)sender {
    
    // 创建socket
    if (self.socket == nil)
        self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    // 绑定socket
    if (!self.socket.isConnected){
        NSError *error;
        [self.socket acceptOnPort:8060 error:&error];
        if (error) NSLog(@"%@",error);
        NSLog(@"服务器socket 开启成功");
    }
}

- (IBAction)didClickSendAction:(id)sender {
    // 这是我们原始发送的数据
    UIImage *image = [UIImage imageNamed:@"test"];
    NSData  *imageData  = UIImagePNGRepresentation(image);
    
    NSMutableData *mData = [NSMutableData data];
    // 计算数据总长度 data
    unsigned int dataLength = 4+4+(int)imageData.length;
    NSData *lengthData = [NSData dataWithBytes:&dataLength length:4];
    [mData appendData:lengthData];
    
    // 数据类型 data
    // 2.拼接指令类型(4~7:指令)
    unsigned int command = kcImageDataType;
    NSData *typeData = [NSData dataWithBytes:&command length:4];
    [mData appendData:typeData];

    // 最后拼接数据
    [mData appendData:imageData];
    NSLog(@"发送数据的总字节大小:%ld",mData.length);
    
//    NSMutableArray *hostArrM = [NSMutableArray array];
//    for (GCDAsyncSocket *clientSocket in self.clientSockets) {
//        NSString *host_port = [NSString stringWithFormat:@"%@:%d",clientSocket.connectedHost,clientSocket.connectedPort];
//        [hostArrM addObject:host_port];
//    }
    //再把数组发送给每一个连接的客户端
    for (GCDAsyncSocket *clientSocket in self.clientSockets) {
        [clientSocket writeData:mData withTimeout:-1 tag:10010];
    }
 
    // 发数据
//    [self.socket writeData:mData withTimeout:-1 tag:10010];

}

- (IBAction)didClickDisconnectAction:(id)sender {
    [self.socket disconnect];
    self.socket = nil;
}
#pragma mark - GCDAsyncSocketDelegate

//已经连接到服务器
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{

    NSLog(@"当前客户端的IP:%@ 端口号%d",newSocket.connectedHost,newSocket.connectedPort);
    // 1.存储客户端面的Socket对象
     [self.clientSockets addObject:newSocket];
     NSLog(@"当前有%ld个客户端连接",self.clientSockets.count);

    // 2.客户连接建立后,设置可以读取数据
    [newSocket readDataWithTimeout:-1 tag:10010];
    [self.socket readDataWithTimeout:-1 tag:10010];
}

// 连接断开
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"断开 socket连接 原因:%@",err);
}

//已经接收服务器返回来的数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSLog(@"接收到tag = %ld : %ld 长度的数据",tag,data.length);
    
    if (data.length == 0) {
        NSLog(@"传输数据长度为: 0");
        return;
    }
    
    // 1.第一次接收数据
    if(self.dataM.length == 0){
        // 获取总的数据包大小
        NSData *totalSizeData = [data subdataWithRange:NSMakeRange(0, 4)];
        unsigned int totalSize = 0;
        //读取前四个字节
        [totalSizeData getBytes:&totalSize length:4];
        NSLog(@"接收总数据的大小 %u",totalSize);
        self.totalSize = totalSize;
        
        // 获取指令类型
        NSData *commandIdData = [data subdataWithRange:NSMakeRange(4, 4)];
        unsigned int commandId = 0;
        [commandIdData getBytes:&commandId length:4];
        self.currentCommandId = commandId;
    }
    
    // 2.拼接二进
    [self.dataM appendData:data];
    
    // 3.图片数据已经接收完成
    // 判断当前是否是图片数据的最后一段?
    NSLog(@"此次接收的数据包大小 %ld",data.length);
    
    if (self.dataM.length == self.totalSize) {
        //丢包的现象
        NSLog(@"数据已经接收完成");
        if (self.currentCommandId == kcImageDataType) {//图片
            [self saveImage];
        }else if  (self.currentCommandId == kcVideoDataType){
            [self saveVideo];
        }
        // 响应客户端
    }
    
    [sock readDataWithTimeout:-1 tag:10010];
    [self.socket readDataWithTimeout:-1 tag:10010];

}

//消息发送成功 代理函数 向服务器 发送消息
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
    NSLog(@"服务器发送 laile ");

    NSLog(@"%ld 发送数据成功",tag);
}


#pragma mark - 保存图片

-(void)saveImage{
    NSData *imgData = [self.dataM subdataWithRange:NSMakeRange(8, self.dataM.length - 8)];
    UIImage *acceptImage = [UIImage imageWithData:imgData];
    UIImageWriteToSavedPhotosAlbum(acceptImage, self, @selector(savedPhotoImage:didFinishSavingWithError:contextInfo:), nil);
    // 清除数据
    self.dataM = [NSMutableData data];
}
//保存完成后调用的方法
- (void)savedPhotoImage:(UIImage*)image didFinishSavingWithError: (NSError *)error contextInfo: (void *)contextInfo {
    if (error) {
        NSLog(@"保存图片出错%@", error.localizedDescription);
    }else {
        NSLog(@"保存图片成功");
    }
}

//videoPath为视频下载到本地路径
- (void)saveVideo{
    NSString *videoPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"netVideo.mp4"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData *videoData = [self.dataM subdataWithRange:NSMakeRange(8, self.dataM.length - 8)];
        BOOL success = [videoData writeToFile:videoPath atomically:YES];
        NSLog(@"写入视频: %d 路径: %@",success,videoPath);
        // 清除数据
        self.dataM = [NSMutableData data];
    });
}


#pragma mark -- lazy

-(NSMutableData *)dataM{
    if (!_dataM) {
        _dataM = [NSMutableData data];
    }
    return _dataM;
}

- (NSMutableArray *)clientSockets{
    if (!_clientSockets) {
        _clientSockets = [NSMutableArray arrayWithCapacity:10];
    }
    return _clientSockets;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
