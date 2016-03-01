//
//  ViewController.m
//  二维码扫描
//
//  Created by 谢小御 on 15/12/17.
//  Copyright © 2015年 谢小御. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>
// 它是输入和输入的桥梁，主要协调 input 和 output 之间的数据传递
@property(nonatomic, strong)AVCaptureSession *captureSession;
// 管理显示相机的类
@property(nonatomic, strong)AVCaptureVideoPreviewLayer *previewLayer;

@property(nonatomic, assign)BOOL isLightOn;


// 线条距离上方的约束
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *lintTopContrait;


@property(nonatomic, strong)NSTimer *timer;


@property(nonatomic, assign)CGFloat number;
@end

@implementation ViewController


-(AVCaptureSession *)captureSession
{
    if (_captureSession == nil) {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return _captureSession;
}

-(AVCaptureVideoPreviewLayer *)previewLayer
{
    if (_previewLayer == nil) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    }
    return _previewLayer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.number = 1;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(animateineAction) userInfo:nil repeats:YES];

    // 最好把 timer 加入运行循环
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];






    // 灯光打开标志为  没有打开
    self.isLightOn = NO;

    CGFloat version = [UIDevice currentDevice].systemVersion.floatValue;
    if (version > 7.0f) {
        // 苹果从 ios7以后才提供了摄像机扫描二维码识别的功能

        //1、 首先判断相机是够可以使用
        // 2、判断前置摄像头是否可以使用
        // 3、判断后置摄像头是否可以使用
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] && [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] && [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            // 开始扫描二维码
            [self startScan];

        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"相机不可用" delegate:nil cancelButtonTitle:@"我知道了" otherButtonTitles: nil];
            [alert show];

        }
    }
}
#pragma mark 扫描二维码部分
-(void)startScan
{
    // 获取手机的硬件设备
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 输入设备，连接到上面获取到的硬件
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (error == nil) {

        [self.captureSession addInput:input];

    }
    // 输出流（硬件的）
    AVCaptureMetadataOutput *outPut = [[AVCaptureMetadataOutput alloc] init];
    [self.captureSession addOutput:outPut];



    // 设置 output
    dispatch_queue_t queue = dispatch_queue_create("com.guoxiaomin", DISPATCH_QUEUE_CONCURRENT);
    // 扫描的结果苹果是通过代理的方式去回调，所以 output 需要添加代理，并且因为扫描是耗时的工作，所以把它放到子线程里面
    [outPut setMetadataObjectsDelegate:self queue:queue];
    // 设置支持二维码和条形码的扫描
    [outPut setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];


    // 适应屏幕
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    self.previewLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];



    // 开始扫描
    [self.captureSession startRunning];

}


#pragma mark  扫描结果的代理回调方法
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    // 停止扫描
    [self.captureSession stopRunning];

    // 扫描二维码的结果  是一个字符串

    AVMetadataMachineReadableCodeObject *object = metadataObjects.firstObject;


    dispatch_async(dispatch_get_main_queue(), ^{
        if ([object.stringValue isEqualToString:@"打开微信"]) {


            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"weixin:"]];
        }
    });

}

#pragma mark 打开灯光的 button
- (IBAction)lightUpButtonDidClicked:(id)sender {

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    // 判断手机是否有闪光灯
    if ([device hasTorch]) {
        // 呼叫手机操作系统，控制手机硬件
        NSError *error = nil;
        [device lockForConfiguration:&error];
        if (self.isLightOn == NO) {
            [device setTorchMode:AVCaptureTorchModeOn];
            self.isLightOn = YES;
        }else{
            [device setTorchMode:AVCaptureTorchModeOff];
            self.isLightOn = NO;
        }
        // 结束对硬件的控制，跟上面lockForConfiguration是配对的 API
        [device unlockForConfiguration];

    }



}

-(void)animateineAction
{
    if (self.lintTopContrait.constant < 300) {
        self.lintTopContrait.constant = 100 + self.number ;
        self.number += 2;
    }else{
        self.lintTopContrait.constant = 100;
        self.number = 1;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
