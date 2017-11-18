//
//  NSDate+Double.m
//  MotionTest
//
//  Created by Ashif Khan on 13/07/16.
//  Copyright © 2016 Local. All rights reserved.
//

#import "NSDate+Double.h"

@implementation NSDate (Double)
+(double)doubleValue{
    NSTimeInterval seconds = [NSDate timeIntervalSinceReferenceDate];
    return seconds*1000;
}
@end
