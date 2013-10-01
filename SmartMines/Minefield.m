//
//  Minefield.m
//
//  Created by Jan Erik Breimo on 2007-01-05.
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

#import "Minefield.h"
#import <stdlib.h>

typedef struct JbMinefieldSquareStruct
{
    BOOL hasMine;
    unsigned minedNeighbors;
    JbMinefieldSquareState state;
} JbMinefieldSquare;

typedef struct
{
    unsigned neighbors;
    unsigned markedNeighbors;
    unsigned questionMarkedNeighbors;
    unsigned coveredNeighbors;
    unsigned minedNeighbors;
} JbNeighborStatistics;

static JbMinefieldSquare** AllocMinefieldSquareTable(JbTableSize size);

static inline BOOL NextNeighbor(JbTableIterator* it, JbTableIndex idx)
{
    if (!JbTableIteratorNext(it))
        return NO;
    
    if (!JbEqualTableIndexes(it->index, idx))
        return YES;
    
    return JbTableIteratorNext(it); 
}

static inline JbMinefieldSquare* GetSquare(JbMinefieldSquare** table,
                                           JbTableIterator* it)
{
    return &table[it->index.row][it->index.column];
}

@implementation JbMinefield

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        mSquares = nil;
        mSize = JbMakeTableSize(0, 0);
        mNumberOfMines = 0;
        mNumberOfCoveredSquares = 0;
        mNumberOfMarkedSquares = 0;
        mUsesEasyStart = YES;
        mUsesSmartUncover = YES;
        mUsesSmartMark = YES;
        mUsesQuestionMarks = YES;
        mState = JbNotStarted;
    }
    return self;
}

- (id)initWithSize:(JbTableSize)size numberOfMines:(unsigned)mines
{
    assert(size.rows > 0 && size.columns > 0);
    self = [self init];
    if (self)
    {
        mSize = size;
        mSquares = AllocMinefieldSquareTable(size);
        mNumberOfMines = mines;
        [self clear];
    }
    return self;
}

- (void)dealloc
{
    if (mSquares != nil)
        free(mSquares);
    [super dealloc];
}

- (void)clear
{
    assert(mSquares != nil);
    JbMinefieldSquare* end = &mSquares[mSize.rows - 1][mSize.columns];
    for (JbMinefieldSquare* it = &mSquares[0][0]; it != end; ++it)
    {
        it->hasMine = NO;
        it->minedNeighbors = 0;
        it->state = JbUnmarked;
    }
    mNumberOfCoveredSquares = mSize.rows * mSize.columns;
    mNumberOfMarkedSquares = 0;
    mState = JbNotStarted;
}

- (JbTableSize)size
{
    return mSize;
}

- (void)setSize:(JbTableSize)size numberOfMines:(unsigned)mines
{
    if (!JbEqualTableSizes(size, mSize) || mines != mNumberOfMines)
    {
        if (mSquares != nil)
            free(mSquares);
        mSquares = AllocMinefieldSquareTable(size);
        mSize = size;
        mNumberOfMines = mines;
        [self clear];
    }
    else if (mState != JbNotStarted)
        [self clear];
}

- (unsigned)numberOfMines
{
    return mNumberOfMines;
}

- (JbTableIterator)neighborIteratorAt:(JbTableIndex)idx
{
    unsigned rowBegin = idx.row - 1;
    unsigned colBegin = idx.column - 1;
    unsigned rowEnd = idx.row + 2;
    unsigned colEnd = idx.column + 2;

    if (rowBegin >= mSize.rows) rowBegin = 0;
    if (colBegin >= mSize.columns) colBegin = 0;
    if (rowEnd > mSize.rows) rowEnd = mSize.rows;
    if (colEnd > mSize.columns) colEnd = mSize.columns;
    
    return JbMakeTableIterator(rowBegin, colBegin, rowEnd, colEnd);
}

- (void)setHasMine:(BOOL)hasMine aroundFirstUncoveredSquareAt:(JbTableIndex)idx
{
    if (mUsesEasyStart)
    {
        JbTableIterator it = [self neighborIteratorAt:idx];
        while (JbTableIteratorNext(&it))
            mSquares[it.index.row][it.index.column].hasMine = hasMine;
    }
    else
    {
        mSquares[idx.row][idx.column].hasMine = hasMine;
    }
}

- (void)computeMinedNeighborCounts
{
    JbTableIndex idx;
    for (idx.row = 0; idx.row != mSize.rows; ++idx.row)
        for (idx.column = 0; idx.column != mSize.columns; ++idx.column)
        {
            unsigned mines = 0;
            JbTableIterator it = [self neighborIteratorAt:idx];
            while (NextNeighbor(&it, idx))
            {
                if (GetSquare(mSquares, &it)->hasMine)
                    ++mines;
            }
            mSquares[idx.row][idx.column].minedNeighbors = mines;
        }
}

- (void)createMinefieldAroundFirstUncoveredSquareAt:(JbTableIndex)idx
{
    assert(mSquares != nil);
    assert(mState == JbNotStarted);
    NSAssert(mNumberOfMines < mSize.rows * mSize.columns - (mUsesEasyStart ? 9 : 1),
             @"The number of mines is as great or greater than the number of available squares");
    
    [self setHasMine:YES aroundFirstUncoveredSquareAt:idx];
    
    JbMinefieldSquare* squares = &mSquares[0][0];
    unsigned mines = 0;
    while (mines < mNumberOfMines)
    {
        unsigned i = random() % (mSize.rows * mSize.columns);
        if (!squares[i].hasMine)
        {
            squares[i].hasMine = YES;
            ++mines;
        }
    }
    
    [self setHasMine:NO aroundFirstUncoveredSquareAt:idx];
    [self computeMinedNeighborCounts];
    mState = JbNotCompleted;
}

- (BOOL)usesEasyStart
{
    return mUsesEasyStart;
}

- (void)setUsesEasyStart:(BOOL)newUsesEasyStart
{
    mUsesEasyStart = newUsesEasyStart;
}

- (BOOL)usesSmartUncover
{
    return mUsesSmartUncover;
}

- (void)setUsesSmartUncover:(BOOL)newUsesSmartUncover
{
    mUsesSmartUncover = newUsesSmartUncover;
}

- (BOOL)usesSmartMark
{
    return mUsesSmartMark;
}

- (void)setUsesSmartMark:(BOOL)newUsesSmartMark
{
    mUsesSmartMark = newUsesSmartMark;
}

- (BOOL)usesQuestionMarks
{
    return mUsesQuestionMarks;
}

- (JbTableIndexList*)setUsesQuestionMarks:(BOOL)newUsesQuestionMarks
{
    JbTableIndexList* affectedSquares = [JbTableIndexList listWithCapacity:10];
    if (mSquares && mUsesQuestionMarks && !newUsesQuestionMarks)
    {
        // Remove existing question marks.
        JbTableIndex idx;
        for (idx.row = 0; idx.row != mSize.rows; ++idx.row)
            for (idx.column = 0; idx.column != mSize.columns; ++idx.column)
                if (mSquares[idx.row][idx.column].state == JbQuestionMarked)
                {
                    mSquares[idx.row][idx.column].state = JbUnmarked;
                    [affectedSquares addValue:idx];
                }
    }
    mUsesQuestionMarks = newUsesQuestionMarks;
    return affectedSquares;
}

- (JbMinefieldState)state
{
    return mState;
}

- (unsigned)numberOfCoveredSquares
{
    return mNumberOfCoveredSquares;
}

- (unsigned)numberOfMarkedSquares
{
    return mNumberOfMarkedSquares;
}

- (BOOL)hasMineAt:(JbTableIndex)idx
{
    assert(mSquares != nil);
    assert(idx.row < mSize.rows && idx.column < mSize.columns);
    return mSquares[idx.row][idx.column].hasMine;
}

- (JbMinefieldSquareState)stateAt:(JbTableIndex)idx
{
    assert(mSquares != nil);
    assert(idx.row < mSize.rows && idx.column < mSize.columns);
    return mSquares[idx.row][idx.column].state;
}

- (unsigned)countNeighborsWithMinesAt:(JbTableIndex)idx
{
    assert(mSquares != nil);
    assert(idx.row < mSize.rows && idx.column < mSize.columns);
    return mSquares[idx.row][idx.column].minedNeighbors;
}

- (JbNeighborStatistics)neighborStatisticsAt:(JbTableIndex)idx
{
    JbNeighborStatistics stats = {0, 0, 0, 0, 0};
    JbTableIterator it = [self neighborIteratorAt:idx];
    while (NextNeighbor(&it, idx))
    {
        ++stats.neighbors;
        switch (GetSquare(mSquares, &it)->state)
        {
        case JbUnmarked:
            ++stats.coveredNeighbors;
            break;
        case JbMarked:
            ++stats.coveredNeighbors;
            ++stats.markedNeighbors;
            break;
        case JbQuestionMarked:
            ++stats.coveredNeighbors;
            ++stats.questionMarkedNeighbors;
            break;
        }
    }
    stats.minedNeighbors = mSquares[idx.row][idx.column].minedNeighbors;
    return stats;
}

- (JbTableIndexList*)uncoverableAt:(JbTableIndex)idx;
{
    assert(mSquares != nil);
    assert(idx.row < mSize.rows && idx.column < mSize.columns);

    JbTableIndexList* affectedSquares = [JbTableIndexList listWithCapacity:8];
    if (mSquares[idx.row][idx.column].state != JbUncovered)
    {
        JbMinefieldSquareState state = mSquares[idx.row][idx.column].state;
        if (state != JbMarked && state != JbQuestionMarked)
            [affectedSquares addValue:idx];
        return affectedSquares;
    }
    else if (!mUsesSmartUncover)
        return affectedSquares;

    JbNeighborStatistics stats = [self neighborStatisticsAt:idx];
    if (stats.coveredNeighbors == stats.markedNeighbors
        || stats.questionMarkedNeighbors != 0
        || stats.markedNeighbors < stats.minedNeighbors)
        return affectedSquares;

    JbTableIterator it = [self neighborIteratorAt:idx];
    while (NextNeighbor(&it, idx))
        if (GetSquare(mSquares, &it)->state == JbUnmarked)
            [affectedSquares addValue:it.index];
    return affectedSquares;
}

- (JbTableIndexList*)smartMarkAt:(JbTableIndex)idx
{
    JbTableIndexList* affectedSquares = [JbTableIndexList listWithCapacity:10];
    
    if (!mUsesSmartMark)
        return affectedSquares;

    JbNeighborStatistics stats = [self neighborStatisticsAt:idx];
    if (stats.coveredNeighbors > stats.minedNeighbors
        || stats.markedNeighbors == stats.minedNeighbors)
        return affectedSquares;

    JbTableIterator it = [self neighborIteratorAt:idx];
    while (NextNeighbor(&it, idx))
    {
        JbMinefieldSquareState* state = &GetSquare(mSquares, &it)->state;
        if (*state != JbUncovered && *state != JbMarked)
        {
            *state = JbMarked;
            [affectedSquares addValue:it.index];
            ++mNumberOfMarkedSquares;
        }
    }
    return affectedSquares;
}

- (void)markAllUnmarked:(JbTableIndexList*)affectedSquares
{
    JbTableIndex idx;
    for (idx.row = 0; idx.row != mSize.rows; ++idx.row)
    {
        for (idx.column = 0; idx.column != mSize.columns; ++idx.column)
        {
            JbMinefieldSquare* square = &mSquares[idx.row][idx.column];
            if (square->hasMine && square->state == JbUnmarked)
            {
                square->state = JbMarked;
                [affectedSquares addValue:idx];
            }
        }
    }
}

- (JbTableIndexList*)markAt:(JbTableIndex)idx
{
    assert(mSquares != nil);
    assert(idx.row < mSize.rows && idx.column < mSize.columns);
    assert(mState != JbBlownUp && mState != JbCompleted);

    if (mSquares[idx.row][idx.column].state == JbUncovered)
        return [self smartMarkAt:idx];
    
    switch (mSquares[idx.row][idx.column].state)
    {
    case JbUnmarked:
        {
            JbNeighborStatistics stats = [self neighborStatisticsAt:idx];
            if (stats.coveredNeighbors != stats.neighbors)
            {
                mSquares[idx.row][idx.column].state = JbMarked;
                ++mNumberOfMarkedSquares;
            }
        }
        break;
    case JbMarked:
        mSquares[idx.row][idx.column].state =
                            mUsesQuestionMarks ? JbQuestionMarked : JbUnmarked;
        --mNumberOfMarkedSquares;
        break;
    case JbQuestionMarked:
        mSquares[idx.row][idx.column].state = JbUnmarked;
        break;
    }
    return [JbTableIndexList listWithValues:&idx count:1];
}

- (void)uncoverRecursivelyAt:(JbTableIndex)idx
             affectedSquares:(JbTableIndexList*)affectedSquares
{
    mSquares[idx.row][idx.column].state = JbUncovered;
    [affectedSquares addValue:idx];
    --mNumberOfCoveredSquares;

    if (mSquares[idx.row][idx.column].hasMine)
    {
        mState = JbBlownUp;
    }
    else if (mSquares[idx.row][idx.column].minedNeighbors == 0)
    {
        JbTableIterator it = [self neighborIteratorAt:idx];
        while (NextNeighbor(&it, idx))
            if (GetSquare(mSquares, &it)->state == JbUnmarked)
                [self uncoverRecursivelyAt:it.index
                           affectedSquares:affectedSquares];
    }
}

- (JbTableIndexList*)smartUncoverAt:(JbTableIndex)idx
{
    JbTableIndexList* affectedSquares = [JbTableIndexList listWithCapacity:10];
    
    JbNeighborStatistics stats = [self neighborStatisticsAt:idx];
    if (stats.coveredNeighbors == stats.markedNeighbors
        || stats.questionMarkedNeighbors != 0
        || stats.markedNeighbors < stats.minedNeighbors)
        return affectedSquares;

    JbTableIterator it = [self neighborIteratorAt:idx];
    while (NextNeighbor(&it, idx))
        if (GetSquare(mSquares, &it)->state == JbUnmarked)
            [self uncoverRecursivelyAt:it.index
                       affectedSquares:affectedSquares];

    if (stats.markedNeighbors > stats.minedNeighbors)
        mState = JbBlownUp;
    else if (mState != JbBlownUp && mNumberOfCoveredSquares == mNumberOfMines)
    {
        mState = JbCompleted;
        [self markAllUnmarked:affectedSquares];
    }

    return affectedSquares;
}

- (JbTableIndexList*)uncoverAt:(JbTableIndex)idx
{
    assert(mSquares != nil);
    assert(idx.row < mSize.rows && idx.column < mSize.columns);
    assert(mState != JbBlownUp && mState != JbCompleted);
    
    if (mState == JbNotStarted)
        [self createMinefieldAroundFirstUncoveredSquareAt:idx];

    if (mUsesSmartUncover && mSquares[idx.row][idx.column].state == JbUncovered)
        return [self smartUncoverAt:idx];

    JbTableIndexList* affectedSquares = [JbTableIndexList listWithCapacity:10];

    if (mSquares[idx.row][idx.column].state != JbUnmarked)
        return affectedSquares;
        
    [self uncoverRecursivelyAt:idx affectedSquares:affectedSquares];

    if (mState != JbBlownUp && mNumberOfCoveredSquares == mNumberOfMines)
    {
        mState = JbCompleted;
        [self markAllUnmarked:affectedSquares];
    }

    return affectedSquares;
}

@end

static JbMinefieldSquare** AllocMinefieldSquareTable(JbTableSize size)
{
    assert(size.rows != 0 && size.columns != 0);
    return (JbMinefieldSquare**)JbAllocTable(size.rows,
                                             size.columns,
                                             sizeof(JbMinefieldSquare));
}
