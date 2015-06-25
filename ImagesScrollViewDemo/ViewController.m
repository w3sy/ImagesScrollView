//
//  ViewController.m
//  ImagesScrollViewDemo
//
//  Created by 王博 on 15/6/24.
//  Copyright (c) 2015年 wangbo. All rights reserved.
//

#import "ViewController.h"
#import "ImagesScrollView.h"

@interface ViewController () <ImagesScrollViewDelegate>
{
    NSMutableArray * _images;
}

@property (weak, nonatomic) IBOutlet ImagesScrollView *imagesScrollView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _images = [NSMutableArray array];
    for (NSInteger i = 0; i < 12; i++) {
        NSString * imgName = [NSString stringWithFormat:@"background_0%02ld.jpg", i];
        UIImage * img = [UIImage imageNamed:imgName];
        [_images addObject:img];
    }
    [self.imagesScrollView reloadData];
    self.imagesScrollView.isLoop = YES;
    self.imagesScrollView.delegate = self;
    [self.imagesScrollView setImageViewContentMode:UIViewContentModeScaleAspectFill];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfImagesInImagesScrollView:(ImagesScrollView *)imagesScrollView
{
    return _images.count;
}

- (UIImage *)imagesScrollView:(ImagesScrollView *)imagesScrollView imageWithIndex:(NSInteger)index
{
    return _images[index];
}

@end
