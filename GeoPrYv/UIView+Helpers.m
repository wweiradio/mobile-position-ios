//
//  Created by sobees on 01.03.11.
//  Copyright 2011 deskNET. All rights reserved.
//

#import "UIView+Helpers.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (Helpers)

- (CGFloat)left {
  return self.frame.origin.x;
}

- (void)setLeft:(CGFloat)x {
  CGRect frame = self.frame;
  frame.origin.x = x;
  self.frame = frame;
}

- (CGFloat)right {
  return self.frame.origin.x + self.frame.size.width;
}

- (void)setRight:(CGFloat)right {
  CGRect frame = self.frame;
  frame.origin.x = right - frame.size.width;
  self.frame = frame;
}

- (CGFloat)top {
  return self.frame.origin.y;
}

- (void)setTop:(CGFloat)y {
  CGRect frame = self.frame;
  frame.origin.y = y;
  self.frame = frame;
}

- (CGFloat)bottom {
  return self.frame.origin.y + self.frame.size.height;
}

- (void)setBottom:(CGFloat)bottom {
  CGRect frame = self.frame;
  frame.origin.y = bottom - frame.size.height;
  self.frame = frame;
}

- (CGFloat)width {
  return self.frame.size.width;
}

- (void)setWidth:(CGFloat)width {
  CGRect frame = self.frame;
  frame.size.width = width;
  self.frame = frame;
}

- (CGFloat)height {
  return self.frame.size.height;
}

- (void)setHeight:(CGFloat)height {
  CGRect frame = self.frame;
  frame.size.height = height;
  self.frame = frame;
}

- (UIImage*)renderToImage
{
    if(UIGraphicsBeginImageContextWithOptions != NULL){
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.width, self.height), NO, 0.0);
    } 
    else {
        UIGraphicsBeginImageContext(self.frame.size);
    }
    
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();  
    return image;
}


@end
