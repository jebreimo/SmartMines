//
//  Minefield.h
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

#import <Cocoa/Cocoa.h>
#import "Minefield.h"
#import "TableIndexList.h"

typedef enum 
{
    JbUnmarked,
    JbMarked,
    JbQuestionMarked,
    JbUncovered
} JbMinefieldSquareState;

typedef enum
{
    JbNotStarted,
    JbNotCompleted,
    JbCompleted,
    JbBlownUp
} JbMinefieldState;

@interface JbMinefield : NSObject
{
    struct JbMinefieldSquareStruct** mSquares;
    JbTableSize mSize;
    unsigned mNumberOfMines;
    unsigned mNumberOfCoveredSquares;
    unsigned mNumberOfMarkedSquares;
    BOOL mUsesEasyStart;
    BOOL mUsesSmartUncover;
    BOOL mUsesSmartMark;
    BOOL mUsesQuestionMarks;
    JbMinefieldState mState;
    // JbTableIndexList mAffectedSquares;
}

- (id)initWithSize:(JbTableSize)size numberOfMines:(unsigned)mines;
- (void)clear;

- (JbTableSize)size;
- (void)setSize:(JbTableSize)size numberOfMines:(unsigned)mines;

- (unsigned)numberOfMines;
/** True if the squares surrounding the first uncovered square are
    guaranteed to be without mines.
*/
- (BOOL)usesEasyStart;
- (void)setUsesEasyStart:(BOOL)newUsesEasyStart;
- (BOOL)usesSmartUncover;
- (void)setUsesSmartUncover:(BOOL)newUsesSmartUncover;
- (BOOL)usesSmartMark;
- (void)setUsesSmartMark:(BOOL)newUsesSmartMark;

/// Enables or disables the use of question marks.
/** If question marks are disabled, all squares with question marks are cleared.
    @return indices of the squares that had their question marks removed.
*/
- (BOOL)usesQuestionMarks;
- (JbTableIndexList*)setUsesQuestionMarks:(BOOL)newUsesQuestionMarks;

- (JbMinefieldState)state;

- (unsigned)numberOfCoveredSquares;
- (unsigned)numberOfMarkedSquares;

- (BOOL)hasMineAt:(JbTableIndex)index;
- (JbMinefieldSquareState)stateAt:(JbTableIndex)index;
- (unsigned)countNeighborsWithMinesAt:(JbTableIndex)index;
- (JbTableIndexList*)uncoverableAt:(JbTableIndex)index;

- (JbTableIndexList*)markAt:(JbTableIndex)index;
- (JbTableIndexList*)uncoverAt:(JbTableIndex)index;
@end
