//
//  BoolToStringTransformer.m
//
//  Created by Jan Erik Breimo on 2007-04-23.
//  Copyright (c) 2007 Jan Erik Breimo. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any
//  person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the
//  Software without restriction, including without
//  limitation the rights to use, copy, modify, merge,
//  publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the
//  following conditions:
//
//  The above copyright notice and this permission notice
//  shall be included in all copies or substantial portions
//  of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
//  ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
//  TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
//  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
//  SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
//  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.

#import "BoolToStringTransformer.h"

@implementation JbBoolToStringTransformer

+ (BOOL)allowsReverseTransfomation
{
    return YES;
}

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (JbBoolToStringTransformer*)transformerWithName:(NSString*)name
                                         yesValue:(NSString*)yesValue
                                          noValue:(NSString*)noValue
{
    JbBoolToStringTransformer* t;
    t = [[[JbBoolToStringTransformer alloc] initWithYesValue:yesValue noValue:noValue] autorelease];
    [NSValueTransformer setValueTransformer:t forName:name];
    return t;
}

- (id)init
{
    return [self initWithYesValue:@"yes" noValue:@"no"];
}

- (id)initWithYesValue:(NSString*)yesValue noValue:(NSString*)noValue
{
    self = [super init];
    if (self)
    {
        mYesValue = [yesValue retain];
        mNoValue = [noValue retain];
    }
    return self;
}

- (void)dealloc
{
    [mYesValue release];
    [mNoValue release];
    [super dealloc];
}

- (id)transformedValue:(id)value
{
    if (![value isKindOfClass:[NSNumber class]])
        return nil;
    else if ([value boolValue])
        return mYesValue;
    else
        return mNoValue;
}

- (id)reverseTransformedValue:(id)value
{
    if (![value isKindOfClass:[NSString class]])
        return nil;
    else if ([value isEqualToString:mYesValue])
        return [NSNumber numberWithBool:YES];
    else if ([value isEqualToString:mNoValue])
        return [NSNumber numberWithBool:NO];
    else
        return nil;
}

@end