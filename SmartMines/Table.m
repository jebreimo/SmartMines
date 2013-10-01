//
//  Table.m
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

#import "Table.h"
#import <stdlib.h>
#import <assert.h>

JbTableIndex JbMakeTableIndex(size_t row, size_t column)
{
    JbTableIndex index = {row, column};
    return index;
}

BOOL JbEqualTableIndexes(JbTableIndex a, JbTableIndex b)
{
    return a.row == b.row && a.column == b.column;
}

JbTableSize JbMakeTableSize(size_t rows, size_t columns)
{
    JbTableSize index = {rows, columns};
    return index;
}

BOOL JbEqualTableSizes(JbTableSize a, JbTableSize b)
{
    return a.rows == b.rows && a.columns == b.columns;
}

JbTableRect JbMakeTableRect(size_t fromRow, size_t fromColumn,
                            size_t rows, size_t columns)
{
    JbTableRect rect;
    rect.origin.row = fromRow;
    rect.origin.column = fromColumn;
    rect.size.rows = rows;
    rect.size.columns = columns;
    return rect;
}

JbTableIterator JbMakeTableIterator(unsigned rowBegin, unsigned columnBegin,
                                    unsigned rowEnd, unsigned columnEnd)
{
    assert(rowEnd >= rowBegin && columnEnd >= columnBegin);
    JbTableIterator it;
    it.begin.row = rowBegin;
    it.begin.column = columnBegin;
    it.end.row = rowEnd;
    it.end.column = columnEnd;
    JbTableIteratorFirst(&it);
    return it;
}

BOOL JbTableIteratorNext(JbTableIterator* it)
{
    if (it->index.row == it->end.row)
        return NO;

    if (++it->index.column == it->end.column)
    {
        it->index.column = it->begin.column;
        if (++it->index.row == it->end.row)
            return NO;
    }
    return YES;
}

void JbTableIteratorFirst(JbTableIterator* it)
{
    if (it->begin.row >= it->end.row || it->begin.column >= it->end.column)
        it->index.row = it->end.row;
    else
        it->index.row = it->begin.row - 1;
    it->index.column = it->end.column - 1;
}

void** JbAllocTable(size_t rows, size_t columns, size_t valueSize)
{
    size_t row;
    size_t rowIndexSize = rows * sizeof(void*);
    size_t rowSize = columns * valueSize;
    void** table = (void**)malloc(rowIndexSize + rows * rowSize);
    char* values;

    if (table == NULL)
      return NULL;

    values = (char*)&table[rows];
    for (row = 0; row != rows; ++row)
      table[row] = &values[row * rowSize];

    return table;
}
