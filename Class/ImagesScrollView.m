//
//  ImagesScrollView.m
//  ImagesScrollViewDemo
//
//  Created by 王博 on 15/6/24.
//  Copyright (c) 2015年 wangbo. All rights reserved.
//

#import "ImagesScrollView.h"
#import "UIImageView+AFNetworking.h"

typedef NS_ENUM(NSInteger, ImagesScrollViewPage) {
    ImagesScrollViewPagePrevious,
    ImagesScrollViewPageCurrent,
    ImagesScrollViewPageNext
};

@interface ImagesScrollView () <UIScrollViewDelegate>
{
    NSInteger _imagesCount;
    NSInteger _currentIndex;
}

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIScrollView *mainScrollView;
@property (weak, nonatomic) IBOutlet UIImageView *previousImageView;
@property (weak, nonatomic) IBOutlet UIImageView *currentImageView;
@property (weak, nonatomic) IBOutlet UIImageView *nextImageView;

@end

@implementation ImagesScrollView

// 在各个支持的初始化方法中加载Nib内容
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self loadNib];
    }
    return self;
}
// 在storyboard中加载会调用该方法
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self loadNib];
    }
    return self;
}

- (void)dealloc
{
    [self.mainScrollView removeObserver:self forKeyPath:@"center"];
}

- (void)loadNib
{
    [[NSBundle mainBundle] loadNibNamed:@"ImagesScrollView" owner:self options:nil];
    [self addSubview:self.contentView];
    // 关闭AutoresizingMask, 以便使用AutoLayout
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    // 添加约束条件使内容大小随self改变
    NSLayoutConstraint * top = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    NSLayoutConstraint * left = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1 constant:0];
    NSLayoutConstraint * bottom = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    NSLayoutConstraint * right = [NSLayoutConstraint constraintWithItem:self.contentView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1 constant:0];
    [self addConstraints:@[top, left, bottom, right]];
}

// 加载PageControl到view中
- (void)loadPageControl
{
    if (self.pageControl == nil) {
        _pageControl = [[UIPageControl alloc] init];
        self.pageControl.hidesForSinglePage = YES;
    } else {
        [self.pageControl removeFromSuperview];
    }
    self.pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.pageControl];
    self.pageControl.numberOfPages = _imagesCount;
    self.pageControl.currentPage = _currentIndex;
    NSLayoutConstraint * x = [NSLayoutConstraint constraintWithItem:self.pageControl attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0];
    NSLayoutConstraint * y = [NSLayoutConstraint constraintWithItem:self.pageControl attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    [self addConstraints:@[x, y]];
}

// 更新PageControl页数
- (void)changePageControlIndex
{
    if ([self.pageControl respondsToSelector:@selector(setCurrentPage:)]) {
        self.pageControl.currentPage = _currentIndex;
    }
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
    // 初始化设置
    [self initialization];
}

- (void)setDelegate:(id<ImagesScrollViewDelegate>)delegate
{
    _delegate = delegate;
    if (_delegate) {
        [self requestImagesCount];
    }
}

- (void)initialization
{
    self.mainScrollView.delegate = self;
    self.mainScrollView.scrollEnabled = NO;
    _showPageControl = YES;
    if (self.delegate) {
        [self requestImagesCount];
    }
    [self loadPageControl];
    // 监听UIScrollView位置的改变
    [self.mainScrollView addObserver:self forKeyPath:@"center" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"center"]) {
        [self resetContentOffset];
    }
}

// 布局改变时修正UIScrollView的contentOffset
- (void)resetContentOffset
{
    CGFloat newOffset = self.mainScrollView.bounds.size.width;
    if (!self.isLoop) {
        if (_currentIndex == _imagesCount - 1) {
            newOffset *= 2;
        }
        if (_currentIndex == 0) {
            newOffset = 0;
        }
    }
    NSLog(@"%f", newOffset);
    self.mainScrollView.contentOffset = CGPointMake(newOffset, 0);
}

// 通过代理获取图片
- (UIImage *)imageWithIndex:(NSInteger)index
{
    if ([self.delegate respondsToSelector:@selector(imagesScrollView:imageWithIndex:)]) {
        return [self.delegate imagesScrollView:self imageWithIndex:index];
    } else {
        return self.placeholderImage;
    }
}

// 按索引号加载图片到page位置的UIImageView上
- (void)loadImageWithIndex:(NSInteger)index at:(ImagesScrollViewPage)page
{
    UIImageView * imageView = nil;
    switch (page) {
        case ImagesScrollViewPagePrevious:
            imageView = self.previousImageView;
            break;
        case ImagesScrollViewPageCurrent:
            imageView = self.currentImageView;
            break;
        case ImagesScrollViewPageNext:
            imageView = self.nextImageView;
            break;
            
        default:
            break;
    }
    // 判断是否通过网络下载图片
    if ([self.delegate respondsToSelector:@selector(imagesScrollView:imageUrlStringWithIndex:)]) {
        NSString * imageUrlString = [self.delegate imagesScrollView:self imageUrlStringWithIndex:index];
        [imageView setImageWithURL:[NSURL URLWithString:imageUrlString] placeholderImage:self.placeholderImage];
    // 否则直接请求图片
    } else {
        imageView.image = [self imageWithIndex:index];
    }
}

// 初始化时加载所需图片
- (void)requestImagesCount
{
    _imagesCount = [self.delegate numberOfImagesInImagesScrollView:self];
    
    self.mainScrollView.scrollEnabled = (_imagesCount > 1) ? YES : NO;
    if (self.isLoop) {
        self.mainScrollView.contentOffset = CGPointMake(self.bounds.size.width, 0);
    }
    
    if (_imagesCount > 0) {
        [self loadImageWithIndex:0 at:self.isLoop ? ImagesScrollViewPageCurrent : ImagesScrollViewPagePrevious];
    }
    if (_imagesCount > 1) {
        [self loadImageWithIndex:1 at:self.isLoop ? ImagesScrollViewPageNext : ImagesScrollViewPageCurrent];
        if (self.isLoop) {
            [self loadImageWithIndex:_imagesCount - 1 at:ImagesScrollViewPagePrevious];
        }
    }
    if (_imagesCount > 2 && !self.isLoop) {
        [self loadImageWithIndex:2 at:ImagesScrollViewPageNext];
    }
}

// 页面滑动以后设置图片
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat offsetX = scrollView.contentOffset.x;
    CGFloat scrollViewWidth = scrollView.bounds.size.width;
    NSInteger curPage = offsetX / scrollViewWidth;
    // 向后翻页的情况
    if (curPage == ImagesScrollViewPageNext) {
        // 跟新当前页码
        _currentIndex++;
        // 循环显示并且是最后一页的情况
        if (self.isLoop && _currentIndex > _imagesCount - 1) {
            _currentIndex -= _imagesCount;
        }
        // 非循环显示到达最后一页
        if (!self.isLoop && _currentIndex >= _imagesCount - 1) {
            _currentIndex = _imagesCount - 1;
            [self changePageControlIndex];
            return;
        }
        // 一般情况下更新图片位置以便复用UIImageView
        self.previousImageView.image = self.currentImageView.image;
        self.currentImageView.image = self.nextImageView.image;
        self.mainScrollView.contentOffset = CGPointMake(scrollViewWidth, 0);
        NSInteger nextIndex = _currentIndex + 1;
        if (self.isLoop && _currentIndex >= _imagesCount - 1) {
            nextIndex -= _imagesCount;
        }
        // 加载下一张图片
        [self loadImageWithIndex:nextIndex at:ImagesScrollViewPageNext];
    }
    // 向前翻页的情况
    if (curPage == ImagesScrollViewPagePrevious) {
        _currentIndex--;
        if (self.isLoop && _currentIndex < 0) {
            _currentIndex += _imagesCount;
        }
        if (!self.isLoop && _currentIndex <= 0) {
            _currentIndex = 0;
            [self changePageControlIndex];
            return;
        }
        self.nextImageView.image = self.currentImageView.image;
        self.currentImageView.image = self.previousImageView.image;
        self.mainScrollView.contentOffset = CGPointMake(scrollViewWidth, 0);
        NSInteger previousIndex = _currentIndex - 1;
        if (self.isLoop && _currentIndex == 0) {
            previousIndex += _imagesCount;
        }
        [self loadImageWithIndex:previousIndex at:ImagesScrollViewPagePrevious];
    }
    // 非循环显示时的特殊情况
    if (!self.isLoop && curPage == ImagesScrollViewPageCurrent) {
        if (_currentIndex == 0) {
            _currentIndex++;
            if (_imagesCount == 2) {
                self.nextImageView.image = self.currentImageView.image;
                self.currentImageView.image = self.previousImageView.image;
                self.mainScrollView.contentOffset = CGPointMake(2 * scrollViewWidth, 0);
            }
        } else if (_currentIndex == _imagesCount - 1) {
            _currentIndex--;
            if (_imagesCount == 2) {
                self.previousImageView.image = self.currentImageView.image;
                self.currentImageView.image = self.nextImageView.image;
                self.mainScrollView.contentOffset = CGPointMake(0, 0);
            }
        }
    }
    
    [self changePageControlIndex];
}

// 设置是否显示PageControl
- (void)setShowPageControl:(BOOL)showPageControl
{
    _showPageControl = showPageControl;
    if (self.pageControl) {
        self.pageControl.hidden = !showPageControl;
    }
}

// 设置PageControl并显示到view中
- (void)setPageControl:(UIPageControl *)pageControl
{
    _pageControl = pageControl;
    _pageControl.hidden = !self.showPageControl;
    [self loadPageControl];
}

- (void)reloadData
{
    [self requestImagesCount];
    [self loadPageControl];
}

- (void)setImageViewContentMode:(UIViewContentMode)contentMode
{
    self.previousImageView.contentMode = contentMode;
    self.currentImageView.contentMode = contentMode;
    self.nextImageView.contentMode = contentMode;
}

@end
