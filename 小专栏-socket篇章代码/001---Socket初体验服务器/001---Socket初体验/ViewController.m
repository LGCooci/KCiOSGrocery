//
//  ViewController.m
//  001---Socket初体验
//
//  Created by cooci on 2021/10/10.
//

#import "ViewController.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

#define SocketPort htons(8040)
#define SocketIP   inet_addr("127.0.0.1")

static int const kMaxConnectCount = 5;

@interface ViewController ()
@property (nonatomic, assign) int serverId;
@property (weak, nonatomic) IBOutlet UITextField *sendMsgContent_tf;
@property (nonatomic, strong) NSMutableAttributedString *totalAttributeStr;
@property (nonatomic, copy) NSString *recoderTime;
@property (nonatomic, assign) int client_socket;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

#pragma mark - 创建socket建立连接
- (IBAction)socketConnetAction:(UIButton *)sender {
    
    // 1: 创建socket
    self.serverId = socket(AF_INET, SOCK_STREAM, 0);
    
    if (self.serverId == -1) {
        NSLog(@"创建socket 失败");
        return;
    }
    NSLog(@"创建socket 成功");

    struct sockaddr_in socketAddr;
    socketAddr.sin_family   = AF_INET;
    socketAddr.sin_port     = SocketPort;
    struct in_addr  socketIn_addr;
    socketIn_addr.s_addr    = SocketIP;
    socketAddr.sin_addr     = socketIn_addr;
    bzero(&(socketAddr.sin_zero), 8);
    
    // 2: 绑定socket
    int bind_result = bind(self.serverId, (const struct sockaddr *)&socketAddr, sizeof(socketAddr));
    if (bind_result == -1) {
        NSLog(@"绑定socket 失败");
        return;
    }

    NSLog(@"绑定socket成功");
    
    // 3: 监听socket
    int listen_result = listen(self.serverId, kMaxConnectCount);
    if (listen_result == -1) {
        NSLog(@"监听失败");
        return;
    }
    
    NSLog(@"监听成功");
    // 4: 接受客户端的链接
    for (int i = 0; i < kMaxConnectCount; i++) {
        [self acceptClientConnet];
    }
    
}

#pragma mark - 接受客户端的链接

- (void)acceptClientConnet{
    
    // 阻塞线程
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        struct sockaddr_in client_address;
        socklen_t address_len;
        // accept函数
        int client_socket = accept(self.serverId, (struct sockaddr *)&client_address, &address_len);
        self.client_socket = client_socket;
        
        if (client_socket == -1) {
            NSLog(@"接受 %u 客户端错误",address_len);
            
        }else{
            NSString *acceptInfo = [NSString stringWithFormat:@"客户端 in,socket:%d",client_socket];
            NSLog(@"%@",acceptInfo);
            [self receiveMsgWithClietnSocket:client_socket];
        }

    });
    
}

- (void)receiveMsgWithClietnSocket:(int)clientSocket{
    while (1) {
        // 5: 接受客户端传来的数据
        char buf[1024] = {0};
        long iReturn = recv(clientSocket, buf, 1024, 0);
        if (iReturn>0) {
            NSLog(@"客户端来消息了");
            // 接收到的数据转换
            NSData *recvData  = [NSData dataWithBytes:buf length:iReturn];
            NSString *recvStr = [[NSString alloc] initWithData:recvData encoding:NSUTF8StringEncoding];
            NSLog(@"%@",recvStr);
            
        }else if (iReturn == -1){
            NSLog(@"读取消息失败");
            break;
        }else if (iReturn == 0){
            NSLog(@"客户端走了");
            
            close(clientSocket);
            
            break;
        }
    }
}

#pragma mark - socket 发送消息

- (IBAction)didClickSendAction:(id)sender {

    // 6: 发送消息
    const char *msg = self.sendMsgContent_tf.text.UTF8String;
    ssize_t sendLen = send(self.client_socket, msg, strlen(msg), 0);
    NSLog(@"发送了:%ld字节",sendLen);
    self.sendMsgContent_tf.text = @"";
}

#pragma mark - socket 发送消息
- (IBAction)didClickCloseAction:(id)sender {
    // 7: 关闭socket连接
    int close_result = close(self.client_socket);
    
    if (close_result == -1) {
        NSLog(@"socket 关闭失败");
        return;
    }else{
        NSLog(@"socket 关闭成功");
    }
}



@end
