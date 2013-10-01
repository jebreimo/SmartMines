//
//  Game.h
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

#import <Cocoa/Cocoa.h>
#import "HighScores.h"
#import "Table.h"

@interface JbGame : NSObject  <NSCoding>
{
    JbHighScores* mHighScores;
    JbTableSize mSize;
    unsigned mMines;
    NSString* mName;
    NSDate* mLastPlayed;
    unsigned mTimesPlayed;
    unsigned mTimesWon;
    unsigned mTimesLost;
    BOOL mIsCustomGame;
}
+ (NSString*)describeGameWithSize:(JbTableSize)size mines:(unsigned)mines;
+ (BOOL)isValidGameSize:(JbTableSize)size mines:(unsigned)mines;
- (id)initWithSize:(JbTableSize)size
             mines:(unsigned)mines;
- (id)initWithSize:(JbTableSize)size
             mines:(unsigned)mines
              name:(NSString*)name;
- (id)initWithDescription:(NSString*)description;
- (id)initWithCoder:(NSCoder*)theCoder;
- (void)encodeWithCoder:(NSCoder*)theCoder;
- (BOOL)isPlayedMoreRecentlyThan:(JbGame*)game;
- (NSString*)description;
- (NSString*)sizeDescription;
- (JbTableSize)size;
- (unsigned)mines;
- (NSString*)name;
- (void)setName:(NSString*)newName;
- (JbHighScores*)highScores;
- (void)gameStarted;
- (void)gameWon;
- (void)gameLost;
- (NSDate*)lastPlayed;
- (unsigned)timesStarted;
- (unsigned)timesWon;
- (unsigned)timesLost;
- (BOOL)isCustomGame;
- (void)setCustomGame:(BOOL)newCustomGame;
@end
