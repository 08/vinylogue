//
//  TCSAlbumArtDetailView.m
//  vinylogue
//
//  Created by Christopher Trott on 3/18/13.
//  Copyright (c) 2013 TwoCentStudios. All rights reserved.
//

#import "TCSAlbumArtDetailView.h"

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <EXTScope.h>
#import "UIImage+TCSImageRepresentativeColors.h"

@interface TCSAlbumArtDetailView ()

@property (nonatomic, strong) UIImageView *albumImageView;
@property (nonatomic, strong) UIImageView *albumImageBackgroundView;
@property (nonatomic, strong) UILabel *artistNameLabel;
@property (nonatomic, strong) UILabel *albumNameLabel;
@property (nonatomic, strong) UILabel *releaseDateLabel;

@property (nonatomic, strong) NSString *albumReleaseDateString;

@property (atomic, strong) UIColor *primaryAlbumColor;
@property (atomic, strong) UIColor *secondaryAlbumColor;
@property (atomic, strong) UIColor *textAlbumColor;
@property (atomic, strong) UIColor *textShadowAlbumColor;

@end

@implementation TCSAlbumArtDetailView

- (id)init{
  self = [super initWithFrame:CGRectZero];
  if (self) {
    self.backgroundColor = BLACKA(0.05);
    
    [self addSubview:self.albumImageBackgroundView];
    [self addSubview:self.albumImageView];
    [self addSubview:self.artistNameLabel];
    [self addSubview:self.albumNameLabel];
    [self addSubview:self.releaseDateLabel];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterLongStyle;
    
    @weakify(self);
    // Set label text
    RAC(self.artistNameLabel.text) = [RACAble(self.artistName) map:^id(NSString *name) {
      return [name uppercaseString];
    }];
    RAC(self.albumNameLabel.text) = RACAble(self.albumName);
    RAC(self.releaseDateLabel.text) = [RACAble(self.albumReleaseDate) map:^id(NSDate *date) {
      NSString *annotatedString = [NSString stringWithFormat:@"Released: %@", [formatter stringFromDate:date]];
      return annotatedString;
    }];
    
    // Set album images
    [[RACAble(self.albumImageURL) map:^id(NSString *imageURLString) {
      return [NSURL URLWithString:imageURLString];
    }] subscribeNext:^(NSURL *imageURL) {
      @strongify(self);
      UIImage *placeholderImage = [UIImage imageNamed:@"placeholder"];
      [self.albumImageView setImageWithURL:imageURL placeholderImage:placeholderImage];
      [self.albumImageBackgroundView setImageWithURL:imageURL placeholderImage:placeholderImage];
      self.albumImageBackgroundView.layer.rasterizationScale = 0.03;
      self.albumImageBackgroundView.layer.shouldRasterize = YES;
    }];
    
    [[[RACAble(self.albumImageView.image) filter:^BOOL(id value) {
      return (value != nil);
    }] deliverOn:[RACScheduler scheduler]]
     subscribeNext:^(UIImage *image) {
       RACTuple *t = [image getRepresentativeColors];
       self.primaryAlbumColor = t.first;
       self.secondaryAlbumColor = t.second;
       self.textAlbumColor = t.fourth;
       self.textShadowAlbumColor = t.fifth;
     }];
    
    [[RACAble(self.textAlbumColor)
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(UIColor *color) {
      self.artistNameLabel.textColor = COLORA(color, 0.85);
      self.albumNameLabel.textColor = color;
      self.releaseDateLabel.textColor = COLORA(color, 0.7);
    }];
    
    [[RACAble(self.textShadowAlbumColor)
      deliverOn:[RACScheduler mainThreadScheduler]]
     subscribeNext:^(UIColor *color) {
      self.artistNameLabel.shadowColor = COLORA(color, 0.85);
      self.albumNameLabel.shadowColor = color;
      self.releaseDateLabel.shadowColor = COLORA(color, 0.7);
    }];
  }
  return self;
}

- (void)layoutSubviews{
  [super layoutSubviews];
  
  CGRect r = self.bounds;
  CGFloat w = CGRectGetWidth(r);
  CGFloat t = CGRectGetMinY(r); // used to set y position and calculate height
  CGFloat centerX = CGRectGetMidX(r);
  static CGFloat viewHMargin = 30.0f;
  static CGFloat imageAndLabelMargin = 14.0f;
  static CGFloat interLabelMargin = -1.0f;
  CGFloat widthWithMargin = w - (viewHMargin * 2);

  // Calculate individual heights and widths
  self.albumImageView.width = widthWithMargin;
  self.albumImageView.height = self.albumImageView.width;
  [self setLabelSizeForLabel:self.artistNameLabel width:widthWithMargin];
  [self setLabelSizeForLabel:self.albumNameLabel width:widthWithMargin];
  [self setLabelSizeForLabel:self.releaseDateLabel width:widthWithMargin];
  
  // Set y position and calculate total height
  self.albumImageBackgroundView.top = t;
  t += viewHMargin;
  self.albumImageView.top = t;
  t += self.albumImageView.height;
  t += imageAndLabelMargin;
  self.artistNameLabel.top = t;
  t += self.artistNameLabel.height;
  t += interLabelMargin;
  self.albumNameLabel.top = t;
  t += self.albumNameLabel.height;
  t += interLabelMargin;
  self.releaseDateLabel.top = t;
  t += self.releaseDateLabel.height;
  t += viewHMargin;
  
  // Then set self.height based on that
  self.albumImageBackgroundView.height = t;
  self.albumImageBackgroundView.width = t;
  
  // self.height depends on component heights
  self.height = t;

  // Set x positions
  self.albumImageBackgroundView.x = centerX;
  self.albumImageView.x = centerX;
  self.artistNameLabel.x = centerX;
  self.albumNameLabel.x = centerX;
  self.releaseDateLabel.x = centerX;
}

- (void)setLabelSizeForLabel:(UILabel *)label width:(CGFloat)width{
  label.size = [label.text sizeWithFont:label.font constrainedToSize:CGSizeMake(width, CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping];
}

- (void)drawRect:(CGRect)rect{
  CGContextRef c = UIGraphicsGetCurrentContext();
  
  CGRect r = rect;
  
  CGContextSaveGState(c);
  {
    // Fill background
    [self.backgroundColor setFill];
    CGContextFillRect(c, r);
    
    CGFloat borderHeight = 1.0f;
    CGRect topBorder = CGRectMake(CGRectGetMinX(r), CGRectGetMinY(r), CGRectGetWidth(r), borderHeight);
    CGRect bottomBorder = CGRectMake(CGRectGetMinX(r), CGRectGetMaxY(r)-borderHeight, CGRectGetWidth(r), borderHeight);
    
    // Fill top & bottom border (inset)
    [BLACKA(0.25f) setFill];
    CGContextFillRect(c, topBorder);
    CGContextFillRect(c, bottomBorder);
  }
  CGContextRestoreGState(c);
}

- (UIImageView *)albumImageBackgroundView{
  if (!_albumImageBackgroundView){
    _albumImageBackgroundView = [[UIImageView alloc] init];
    _albumImageBackgroundView.layer.masksToBounds = YES;
    _albumImageBackgroundView.clipsToBounds = YES;
    _albumImageBackgroundView.hidden = YES; // TEMP?;
  }
  return _albumImageBackgroundView;
}

- (UIImageView *)albumImageView{
  if (!_albumImageView){
    _albumImageView = [[UIImageView alloc] init];
//    _albumImageView.layer.masksToBounds = YES;
    _albumImageView.layer.cornerRadius = 4;
    _albumImageView.layer.borderWidth = 1;
    _albumImageView.layer.borderColor = BLACKA(0.2f).CGColor;
    _albumImageView.layer.shadowColor = BLACK.CGColor;
    _albumImageView.layer.shadowOffset = CGSizeMake(0, 1);
    _albumImageView.layer.shadowOpacity = 0.6f;
  }
  return _albumImageView;
}

- (UILabel *)artistNameLabel{
  if (!_artistNameLabel){
    _artistNameLabel = [[UILabel alloc] init];
    _artistNameLabel.numberOfLines = 0;
    _artistNameLabel.font = FONT_AVN_REGULAR(15);
    _artistNameLabel.backgroundColor = CLEAR;
    _artistNameLabel.textColor = WHITEA(0.85f);
    _artistNameLabel.shadowColor = BLACKA(0.6f);
    _artistNameLabel.shadowOffset = SHADOW_BOTTOM;
    _artistNameLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _artistNameLabel;
}

- (UILabel *)albumNameLabel{
  if (!_albumNameLabel){
    _albumNameLabel = [[UILabel alloc] init];
    _albumNameLabel.numberOfLines = 0;
    _albumNameLabel.font = FONT_AVN_DEMIBOLD(30);
    _albumNameLabel.backgroundColor = CLEAR;
    _albumNameLabel.textColor = WHITE;
    _albumNameLabel.shadowColor = BLACKA(0.9f);
    _albumNameLabel.shadowOffset = SHADOW_BOTTOM;
    _albumNameLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _albumNameLabel;
}

- (UILabel *)releaseDateLabel{
  if (!_releaseDateLabel){
    _releaseDateLabel = [[UILabel alloc] init];
    _releaseDateLabel.numberOfLines = 0;
    _releaseDateLabel.font = FONT_AVN_REGULAR(13);
    _releaseDateLabel.backgroundColor = CLEAR;
    _releaseDateLabel.textColor = WHITEA(0.7f);
    _releaseDateLabel.shadowColor = BLACKA(0.5f);
    _releaseDateLabel.shadowOffset = SHADOW_BOTTOM;
    _releaseDateLabel.textAlignment = NSTextAlignmentCenter;
  }
  return _releaseDateLabel;
}

@end
