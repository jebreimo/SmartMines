//
//  TableIndexList.m
//
//  Created by Jan Erik Breimo on 2007-01-06.
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

#import "TableIndexList.h"

#import <assert.h>
#import <stdlib.h>
#import <string.h>

@implementation JbTableIndexList

+ (JbTableIndexList*)list
{
    return [[[JbTableIndexList alloc] init] autorelease];
}

+ (JbTableIndexList*)listWithCapacity:(size_t)capacity
{
   return [[[JbTableIndexList alloc] initWithCapacity:capacity] autorelease];
}

+ (JbTableIndexList*)listWithValues:(JbTableIndex*)values count:(size_t)count
{
    return [[[JbTableIndexList alloc] initWithValues:values count:count] autorelease];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        mCapacity = mCount = 0;
        mList = NULL;
    }
    return self;
}

- (id)initWithCapacity:(size_t)capacity
{
    self = [self init];
    if (self && capacity != 0)
    {
        mCapacity = capacity;
        mList = (JbTableIndex*)malloc(capacity * sizeof(JbTableIndex));
        assert(mList != NULL);
    }
    return self;
}

- (id)initWithValues:(JbTableIndex*)values count:(size_t)count
{
    if (count == 0)
        self = [self init];
    else
    {
        self = [self initWithCapacity:count];
        if (self)
        {
            mCount = count;
            memcpy(mList, values, count * sizeof(JbTableIndex));
        }
    }
    return self;
}

- (id)initWithList:(JbTableIndexList*)list
{
    if (list == nil)
        self = [self init];
    else
        self = [self initWithValues:[list begin] count:[list count]];
    return self;
}

- (void)dealloc
{
    if (mList != NULL)
        free(mList);
    [super dealloc];
}

- (id)copyWithZone:(NSZone*)zone
{
    id copy = [[[self class] allocWithZone:zone] initWithList:self];
    return copy;
}

- (void)addValue:(JbTableIndex)value
{
    if (mCount == mCapacity)
    {
        if (mCapacity == 0)
        {
            mCapacity = 1;
            mList = (JbTableIndex*)malloc(mCapacity * sizeof(JbTableIndex));
        }
        else
        {
            size_t newCapacity = (mCapacity * 3 + 1) / 2;
            JbTableIndex* newList = realloc(mList, newCapacity * sizeof(JbTableIndex));
            if (newList == NULL)
                return;
            mList = newList;
            mCapacity = newCapacity;
        }
    }
    
    mList[mCount++] = value;
    return;
}

- (JbTableIndex*)begin
{
    return mList;
}

- (size_t)count
{
    return mCount;
}

- (JbTableIndex*)end
{
    return &mList[mCount];
}

- (JbTableIndex*)pointerToValueAtIndex:(size_t)index
{
    assert(index < mCount);
    return &mList[index];
}

- (void)removeAllValues
{
    mCount = 0;
}

- (void)setValue:(JbTableIndex)value atIndex:(size_t)index
{
    assert(index < mCount);
    mList[index] = value;
}

- (JbTableIndex)valueAtIndex:(size_t)index
{
    assert(index < mCount);
    return mList[index];
}

@end
