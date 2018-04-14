//
//  Table.h
//
//  Created by Jan Erik Breimo on 2007-01-04.
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

#import <Foundation/Foundation.h>

typedef struct JbTableIndexStruct
{
    unsigned row;
    unsigned column;
} JbTableIndex;

typedef struct JbTableSizeStruct
{
    unsigned rows;
    unsigned columns;
} JbTableSize;

typedef struct JbTableRectStruct
{
    JbTableIndex origin;
    JbTableSize size;
} JbTableRect;

typedef struct JbTableIteratorStruct
{
    JbTableIndex index;
    JbTableIndex begin;
    JbTableIndex end;
} JbTableIterator;

JbTableIndex JbMakeTableIndex(unsigned row, unsigned column);
BOOL JbEqualTableIndexes(JbTableIndex a, JbTableIndex b);

JbTableSize JbMakeTableSize(unsigned rows, unsigned columns);
BOOL JbEqualTableSizes(JbTableSize a, JbTableSize b);

JbTableRect JbMakeTableRect(unsigned row, unsigned column,
                            unsigned rows, unsigned columns);
BOOL JbEqualTableRects(JbTableRect a, JbTableRect b);

JbTableIterator JbMakeTableIterator(unsigned rowBegin, unsigned columnBegin,
                                    unsigned rowEnd, unsigned columnEnd);
void JbTableIteratorFirst(JbTableIterator* iterator);
BOOL JbTableIteratorNext(JbTableIterator* iterator);

/// Allocates memory for a two-dimensional array of an arbitrary type.
/** Individual values in the table can be accessed with double index operators
    (ie. table[row][column]). The table is an contigous block of memory so
    it is freed with a single call to free() defined in <stdlib.h>. This
    also means that the table can be iterated over with a pointer starting
    at &table[0][0] and ending at &table[rows][columns].
    @param valueSize the size of an individual value in the array
           (ie. sizeof(table[0][0])).
*/
void** JbAllocTable(unsigned rows, unsigned columns, unsigned valueSize);
