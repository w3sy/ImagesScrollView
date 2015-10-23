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
    NSTimer * _autoScrollTimer;
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
        [self initialize];
    }
    return self;
}

// 在storyboard中加载会调用该方法
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

// View显示时初始设置
- (void)drawRect:(CGRect)rect {
    // Drawing code
    [self initializeWhenDraw];
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

// 添加点击响应手势
- (void)addTapAction
{
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self addGestureRecognizer:tap];
}

- (void)tapAction:(UITapGestureRecognizer *)sender
{
    if ([self.delegate respondsToSelector:@selector(imagesScrollView:didSelectIndex:)]) {
        [self.delegate imagesScrollView:self didSelectIndex:_currentIndex];
    }
}

// 代理设置
- (void)setDelegate:(id<ImagesScrollViewDelegate>)delegate
{
    _delegate = delegate;
    if (_delegate) {
        [self requestImagesCount];
    }
}

// 初始化设置
- (void)initialize
{
    [self loadNib];
    [self addTapAction];
}

// 初始化设置
- (void)initializeWhenDraw
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

// 监听View显示位置变化
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
    //NSLog(@"%f", newOffset);
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
    __weak UIImageView * imageView = nil;
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
    // 同步请求图片或占位图
    imageView.image = [self imageWithIndex:index];
    // 判断是否通过网络下载图片
    if ([self.delegate respondsToSelector:@selector(imagesScrollView:imageUrlStringWithIndex:)]) {
        NSString * imageUrlString = [self.delegate imagesScrollView:self imageUrlStringWithIndex:index];
        if (imageUrlString) {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:imageUrlString]];
            [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
            imageView.image = self.placeholderImage;
            [imageView setImageWithURLRequest:request placeholderImage:self.placeholderImage success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                
                imageView.image = image;
                
            } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                NSLog(@"%@", error);
            }];
        }
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
        // 回调当前Index
        [self callbackScrollToIndex];
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
            [self callbackScrollToIndex];
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
            [self callbackScrollToIndex];
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
    [self callbackScrollToIndex];
}

// 开始拖动View时暂停自动滚动
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self autoScrollImages:NO];
}

// 结束拖动View时继续自动滚动
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self autoScrollImages:YES];
}

// 自动滚动后修正显示数据
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self scrollViewDidEndDecelerating:scrollView];
}

// 定时器控制自动滚动
- (void)autoScrollImages:(BOOL)autoScroll
{
    if (autoScroll && self.autoScrollInterval) {
        if (_autoScrollTimer) {
            [_autoScrollTimer invalidate];
        }
        _autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:self.autoScrollInterval target:self selector:@selector(autoScrollAction) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_autoScrollTimer forMode:NSRunLoopCommonModes];
    } else {
        [_autoScrollTimer invalidate];
        _autoScrollTimer = nil;
    }
}

// 自动滚动动作
- (void)autoScrollAction
{
    CGFloat offsetX = self.mainScrollView.contentOffset.x;
    CGFloat scrollViewWidth = self.mainScrollView.bounds.size.width;
    if (_imagesCount <= 1) {
        return;
    }
    // 不循环情况下初始滚动
    if (offsetX == 0) {
        [self.mainScrollView setContentOffset:CGPointMake(scrollViewWidth, 0) animated:YES];
    // 一般情况下
    } else if (offsetX == scrollViewWidth) {
        [self.mainScrollView setContentOffset:CGPointMake(scrollViewWidth * 2, 0) animated:YES];
    // 不循环情况下末位滚动
    } else if (offsetX == scrollViewWidth * 2) {
        [self autoScrollImages:NO];
        NSTimeInterval interval = 1.0 / MIN(60, _imagesCount);
        [self scrollBackToFirst:_imagesCount - 1 interval:interval];
    }
}

// 不循环状态下回滚至最前一页
- (void)scrollBackToFirst:(NSInteger)numToScroll interval:(NSTimeInterval)interval
{
    self.mainScrollView.userInteractionEnabled = NO;
    CGFloat scrollViewWidth = self.mainScrollView.bounds.size.width;
    if (numToScroll == _imagesCount - 1) {
        [UIView animateWithDuration:interval delay:0.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.mainScrollView.contentOffset = CGPointMake(scrollViewWidth, 0);
        } completion:^(BOOL finished) {
            [self scrollViewDidEndDecelerating:self.mainScrollView];
            [self scrollBackToFirst:numToScroll - 1 interval:interval];
        }];
    } else if (numToScroll > 0) {
        [UIView animateWithDuration:interval delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.mainScrollView.contentOffset = CGPointMake(0, 0);
        } completion:^(BOOL finished) {
            [self scrollViewDidEndDecelerating:self.mainScrollView];
            [self scrollBackToFirst:numToScroll - 1 interval:interval];
        }];
    } else if (numToScroll == 0) {
        [self scrollViewDidEndDecelerating:self.mainScrollView];
        self.mainScrollView.userInteractionEnabled = YES;
        [self autoScrollImages:YES];
    }
}

// 设置自动滚动间隔并启用
- (void)setAutoScrollInterval:(NSTimeInterval)autoScrollInterval
{
    _autoScrollInterval = autoScrollInterval;
    [self autoScrollImages:YES];
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

// 回调当前页面Index
- (void)callbackScrollToIndex
{
    if ([self.delegate respondsToSelector:@selector(imagesScrollView:didScrollToIndex:)]) {
        [self.delegate imagesScrollView:self didScrollToIndex:_currentIndex];
    }
}

// 刷新显示内容
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
