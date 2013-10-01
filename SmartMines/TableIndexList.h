//
//  TableIndexList.h
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

#import <stddef.h>
#import "Table.h"

#import <stddef.h>
#import <Foundation/NSObject.h>

/// JbTableIndexList is a growable list (array) of JbTableIndex values.
@interface JbTableIndexList : NSObject <NSCopying>
{
@private
    JbTableIndex* mList;
    size_t mCapacity;
    size_t mCount;
}
/// Create a new auto-released list of JbTableIndex with initial capcity of 0.
+ (JbTableIndexList*)list;

/// Create a new auto-released list of JbTableIndex.
/** @param capacity the function allocates enough memory to hold this number
                    of values initially. More memory will be allocated when
                    the number of values grows beyond @a capacity.
*/
+ (JbTableIndexList*)listWithCapacity:(size_t)capacity;

+ (JbTableIndexList*)listWithValues:(JbTableIndex*)values count:(size_t)count;

/// Create a new list of JbTableIndex.
/** @param capacity the function allocates enough memory to hold this number
                    of values initially. More memory will be allocated when
                    the number of values grows beyond @a capacity.
*/
- (id)initWithCapacity:(size_t)capacity;

/// Create a new list of JbTableIndex and insert @a count values from @a values.
- (id)initWithValues:(JbTableIndex*)values count:(size_t)count;

/// Create a new list of JbTableIndex that is a copy of @a list.
- (id)initWithList:(JbTableIndexList*)list;

/// Appends @a value to the list, increasing its capacity if necessary.
/** If @a list's current capacity current capacity has been reached, more
    memory is allocated. The amount of memory that is allocated each time
    this happens grows exponentially by a factor of 1.5 times the current
    capacity.
    @return 1 if @a value was successfully appended, otherwise 0.
*/
- (void)addValue:(JbTableIndex)value;

/// Returns a pointer to the first element in the list.
/** The rest of the elements in the list are accessed through
    the index operator or by using a the pointer as pointer as
    an iterator.
*/
- (JbTableIndex*)begin;

/// Returns the number of values in the list.
- (size_t)count;

/// Returns a pointer to the element after the last element in the list.
/** Intended to be used together with begin to iterate over the list.
    @note The returned pointer can not be dereferenced: it does not point
    to a valid JbTableIndex, and may not even point to allocated memory at all.
*/
- (JbTableIndex*)end;

/// Returns a pointer to the value at @a index.
- (JbTableIndex*)pointerToValueAtIndex:(size_t)index;

/// Sets the list's number of values to 0.
/** @note The amount of memory allocated for the list (ie. the capacity) is
    not altered by this function.
*/
- (void)removeAllValues;

/// Replaces the current value at @a index with @a value.
- (void)setValue:(JbTableIndex)value atIndex:(size_t)index;

/// Returns a copy of the value at @a index.
- (JbTableIndex)valueAtIndex:(size_t)index;
@end
