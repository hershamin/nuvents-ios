//
//  MapViewAnnotationView.m
//  NuVents-ios
//
//  Created by Hersh on 8/16/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//      Code from: http://natashatherobot.com/ios-resized-image-mkannotationview/

#import "MapViewAnnotationView.h"

@implementation MapViewAnnotationView
{
    UIImageView *_imageView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // make sure the x and y of the CGRect are half it's
        // width and height, so the callout shows when user clicks
        // in the middle of the image
        CGRect  viewRect = CGRectMake(-15, -15, 30, 30);
        UIImageView* imageView = [[UIImageView alloc] initWithFrame:viewRect];
        
        // keeps the image dimensions correct
        // so if you have a rectangle image, it will show up as a rectangle,
        // instead of being resized into a square
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        _imageView = imageView;
        
        [self addSubview:imageView];
    }
    return self;
}

- (void)setImage:(UIImage *)image
{
    // when an image is set for the annotation view,
    // it actually adds the image to the image view
    _imageView.image = image;
}

@end
