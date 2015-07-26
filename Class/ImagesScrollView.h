//
//  ImagesScrollView.h
//  ImagesScrollViewDemo
//
//  Created by 王博 on 15/6/24.
//  Copyright (c) 2015年 wangbo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImagesScrollView;

@protocol ImagesScrollViewDelegate <NSObject>

/**
 * 返回图片总数
 */
- (NSInteger)numberOfImagesInImagesScrollView:(ImagesScrollView *)imagesScrollView;

@optional
/**
 * 返回UIImage * 图片
 * imagesScrollView : 要获取图片的ImagesScrollView
 * index : 获取图片的序号
 */
- (UIImage *)imagesScrollView:(ImagesScrollView *)imagesScrollView imageWithIndex:(NSInteger)index;

/**
 * 返回NSString * 图片的url地址字符串
 * imagesScrollView : 要获取图片的ImagesScrollView
 * index : 获取图片的序号
 */
- (NSString *)imagesScrollView:(ImagesScrollView *)imagesScrollView imageUrlStringWithIndex:(NSInteger)index ;

/**
 * 用户点选动作
 * index : 图片的序号
 */
- (void)imagesScrollView:(ImagesScrollView *)imagesScrollView didSelectIndex:(NSInteger)index;

/**
 * imagesScrollView已经滚动到index页
 */
- (void)imagesScrollView:(ImagesScrollView *)imagesScrollView didScrollToIndex:(NSInteger)index;

@end

@interface ImagesScrollView : UIView

@property (nonatomic, weak) id<ImagesScrollViewDelegate> delegate;
@property (nonatomic) BOOL isLoop; // 是否循环显示
@property (nonatomic) UIImage * placeholderImage; // 设置占位图片
@property (nonatomic, readonly) NSInteger currentIndex; // 当前索引号
@property (nonatomic) UIPageControl * pageControl; // 页码控件，可以自定义设置或创建
@property (nonatomic) BOOL showPageControl; // 是否显示页码控件
@property (nonatomic) NSTimeInterval autoScrollInterval; // 自动滚动间隔(秒)，默认为0，不自动滚动

/**
 刷新显示
 */
- (void)reloadData;

/**
 设置UIImageView上图片的UIViewContentMode
 */
- (void)setImageViewContentMode:(UIViewContentMode)contentMode;

@end
