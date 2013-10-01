//
//  TableIndexListUnitTest.m
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

#import "TableIndexListUnitTest.h"
#import <SenTestingKit/SenTestCase.h>
#import "TableIndexList.h"

@implementation JbTableIndexListUnitTest

- (void)testTableIndexList
{
    enum {NumberOfElements = 1000};
    JbTableIndexList* list = [[JbTableIndexList alloc] initWithCapacity:10];
    STAssertFalse(list == nil, @"List wasn't created.");
    for (size_t i = 0; i != NumberOfElements; ++i)
    {
        //NSLog(@"Index = %d", i);
        STAssertTrue([list count] == i,
                     @"Size check failed at index %d (reported size = %d)",
                     i, [list count]);
        JbTableIndex index = JbMakeTableIndex(i, NumberOfElements - i - 1);
        STAssertTrue(index.row == i && index.column == NumberOfElements - i - 1,
                     @"Incorrect table index at index %d (%d, %d)",
                     i, index.row, index.column);
        [list addValue:index];
        STAssertTrue([list count] == i + 1,
                     @"Unable to append value at index %d", i);
        STAssertTrue([list valueAtIndex:i].row == index.row &&
                     [list valueAtIndex:i].column == index.column,
                     @"Value retrieved from list is not the same as the one appended to it");
    }
    STAssertTrue([list count] == NumberOfElements,
                 @"Final size check failed (expected size = %d, reported size = %d)",
                 NumberOfElements, [list count]);
    //NSLog(@"%s", _cmd);
    [list release];
}

@end
