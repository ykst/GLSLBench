//
//  ViewController.h
//  GLSLBench
//
//  Created by Yukishita Yohsuke on 2013/12/23.
//  Copyright (c) 2013年 monadworks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *log;

@property (weak, nonatomic) IBOutlet UITextField *dir_path;
@property (weak, nonatomic) IBOutlet UITextField *fs_path;
@property (weak, nonatomic) IBOutlet UITextField *vs_path;
@property (weak, nonatomic) IBOutlet UILabel *last_modified;

@end
