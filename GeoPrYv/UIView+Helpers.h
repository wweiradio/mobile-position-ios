//
//  Created by sobees on 01.03.11.
//  Copyright 2011 deskNET. All rights reserved.
//

@interface UIView (Helpers)

@property(nonatomic) CGFloat left;
@property(nonatomic) CGFloat right;
@property(nonatomic) CGFloat top;
@property(nonatomic) CGFloat bottom;
@property(nonatomic) CGFloat width;
@property(nonatomic) CGFloat height;

- (UIImage *)renderToImage;

@end
