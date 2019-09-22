//
//  ViewController.m
//  DataDemo
//
//  Created by yangfan on 2019/9/22.
//  Copyright © 2019 yangfan. All rights reserved.
//

#import "ViewController.h"
#import "QRDataPersistence.h"

@interface ViewController ()

@property (nonatomic, strong)UILabel *tipsLb;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.yellowColor;
}

- (void)viewDidAppear:(BOOL)animated {
    if (QRDataPersistence.shareInstance.bShowAlert) {
        [self showAlert];
    }
    [self showTips];
}

- (void)showAlert {
    __block UITextField *TF = nil;
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"欢迎" message:@"说点什么吧,下次显示" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * textField) {
        textField.placeholder = @"请输入";
        TF = textField;
    }];
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (TF.text.length > 0) {
            QRDataPersistence.shareInstance.tips = [QRDataPersistence.shareInstance.tips arrayByAddingObject:TF.text];
        }
    }];
    
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"无话可说" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        QRDataPersistence.shareInstance.bShowAlert = NO;
    }];
    
    [alertVC addAction:action1];
    [alertVC addAction:action2];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)showTips {
    [self.view addSubview:self.tipsLb];
    self.tipsLb.text = [QRDataPersistence.shareInstance.tips componentsJoinedByString:@"\n"];
}

- (UILabel *)tipsLb {
    if (!_tipsLb) {
        _tipsLb = [[UILabel alloc] initWithFrame:self.view.bounds];
        _tipsLb.textAlignment = NSTextAlignmentCenter;
        _tipsLb.numberOfLines = 0;
    }
    return _tipsLb;
}


@end
