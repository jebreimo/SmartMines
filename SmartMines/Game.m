//
//  Game.m
//
//  Created by Jan Erik Breimo on 2007-02-15.
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

#import "Game.h"

static NSString* HighScoresKey = @"HighScores";
static NSString* RowsKey = @"Rows";
static NSString* ColumnsKey = @"Columns";
static NSString* MinesKey = @"Mines";
static NSString* NameKey = @"Name";
static NSString* LastPlayedKey = @"LastPlayed";
static NSString* TimesPlayedKey = @"TimesPlayed";
static NSString* TimesWonKey = @"TimesWon";
static NSString* TimesLostKey = @"TimesLost";
static NSString* IsCustomGameKey = @"IsCustomGame";


static BOOL ParseMinefieldSize(NSString* description,
                               JbTableSize* size,
                               unsigned* mines);

@implementation JbGame

+ (NSString*)describeGameWithSize:(JbTableSize)size mines:(unsigned)mines
{
    return [NSString stringWithFormat:@"%dx%dx%d", size.rows, size.columns, mines];
}

+ (BOOL)isValidGameSize:(JbTableSize)size mines:(unsigned)mines
{
    return size.rows >= 5 && size.rows < 100
           && size.columns >= 5 && size.columns < 100
           && mines <= (size.rows * size.columns) / 2;
}

- (id)init
{
    return [self initWithSize:JbMakeTableSize(0, 0) mines:0 name:nil];
}

- (id)initWithSize:(JbTableSize)size
             mines:(unsigned)mines
{
    NSString* name = [NSString stringWithFormat:@"%d X %d, %d mines", size.columns, size.rows, mines];
    return [self initWithSize:size mines:mines name:name];
}

- (id)initWithSize:(JbTableSize)size
             mines:(unsigned)mines
              name:(NSString*)name
{
    self = [super init];
    if (self)
    {
        mHighScores = [[JbHighScores alloc] init];
        mSize = size;
        mMines = mines;
        if (name)
            mName = [name retain];
        else
            mName = nil;
        mLastPlayed = [[NSDate date] retain];
        mTimesPlayed = 0;
        mTimesWon = 0;
        mTimesLost = 0;
        mIsCustomGame = YES;
    }
    return self;
}

- (id)initWithDescription:(NSString*)description
{
    JbTableSize size;
    unsigned mines;
    if (!ParseMinefieldSize(description, &size, &mines))
        return nil;
    return [self initWithSize:size mines:mines];
}

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super init];
    if (self)
    {
        mHighScores = [[coder decodeObjectForKey:HighScoresKey] retain];
        mSize.rows = [coder decodeInt32ForKey:RowsKey];
        mSize.columns = [coder decodeInt32ForKey:ColumnsKey];
        mMines = [coder decodeInt32ForKey:MinesKey];
        mName = [[coder decodeObjectForKey:NameKey] retain];
        mLastPlayed = [[coder decodeObjectForKey:LastPlayedKey] retain];
        mTimesPlayed = [coder decodeInt32ForKey:TimesPlayedKey];
        mTimesWon = [coder decodeInt32ForKey:TimesWonKey];
        mTimesLost = [coder decodeInt32ForKey:TimesLostKey];
        mIsCustomGame = [coder decodeBoolForKey:IsCustomGameKey];
    }
    return self;
}

- (void)dealloc
{
    [mHighScores release];
    [mName release];
    [mLastPlayed release];
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:mHighScores forKey:HighScoresKey];
    [coder encodeInt32:mSize.rows forKey:RowsKey];
    [coder encodeInt32:mSize.columns forKey:ColumnsKey];
    [coder encodeInt32:mMines forKey:MinesKey];
    [coder encodeObject:mName forKey:NameKey];
    [coder encodeObject:mLastPlayed forKey:LastPlayedKey];
    [coder encodeInt32:mTimesPlayed forKey:TimesPlayedKey];
    [coder encodeInt32:mTimesWon forKey:TimesWonKey];
    [coder encodeInt32:mTimesLost forKey:TimesLostKey];
    [coder encodeBool:mIsCustomGame forKey:IsCustomGameKey];
}

- (BOOL)isPlayedMoreRecentlyThan:(JbGame*)game
{
    if (mLastPlayed == nil)
        return NO;

    NSDate* other = [game lastPlayed];
    if (other == nil)
        return YES;
    
    return [mLastPlayed compare:other] == NSOrderedDescending;
}

- (NSString*)description
{
    return [JbGame describeGameWithSize:mSize mines:mMines];
}

- (NSString*)sizeDescription
{
    return [NSString stringWithFormat:@"%dx%d", mSize.rows, mSize.columns];
}

- (JbHighScores*)highScores
{
    return mHighScores;
}

- (JbTableSize)size
{
    return mSize;
}

- (unsigned)mines
{
    return mMines;
}

- (NSString*)name
{
    return mName;
}

- (void)setName:(NSString*)newName
{
    NSString* oldName = mName;
    mName = [newName retain];
    [oldName release];
}

- (void)gameStarted
{
    ++mTimesPlayed;
    [mLastPlayed release];
    mLastPlayed = [[NSDate date] retain];
}

- (void)gameWon
{
    ++mTimesWon;
}

- (void)gameLost
{
    ++mTimesLost;
}

- (NSDate*)lastPlayed
{
    return mLastPlayed;
}

- (unsigned)timesStarted
{
    return mTimesPlayed;
}

- (unsigned)timesWon
{
    return mTimesWon;
}

- (unsigned)timesLost
{
    return mTimesLost;
}

- (BOOL)isCustomGame
{
    return mIsCustomGame;
}

- (void)setCustomGame:(BOOL)newIsCustomGame
{
    mIsCustomGame = newIsCustomGame;
}

@end

BOOL ParseMinefieldSize(NSString* description,
                        JbTableSize* size,
                        unsigned* mines)
{
    NSScanner* scanner = [NSScanner scannerWithString:description];
    int rows, cols, mines_;
    if (![scanner scanInt:&rows]
        || ![scanner scanString:@"X" intoString:NULL]
        || ![scanner scanInt:&cols]
        || ![scanner scanString:@"X" intoString:NULL]
        || ![scanner scanInt:&mines_])
        return NO;

    size->rows = rows;
    size->columns = cols;
    *mines = mines_;

    return [JbGame isValidGameSize:*size mines:*mines];
}
