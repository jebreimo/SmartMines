//
//  HighScores.m
//
//  Created by Jan Erik Breimo on 2007-02-03.
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

#import "HighScores.h"

static NSString* HighScoresKey = @"HighScores";
static NSString* ElapsedTimeKey = @"ElapsedTime";
static NSString* PlayerNameKey = @"PlayerName";
static NSString* DateKey = @"Date";
enum {GamesWonIndex, GamesLostIndex};
enum {MaxHighScoreEntries = 50};

static NSComparisonResult CompareHighScoreEntries(id entryA, id entryB, void* context)
{
    NSNumber* elapsedTimeA = [(NSDictionary*)entryA valueForKey:ElapsedTimeKey];
    NSNumber* elapsedTimeB = [(NSDictionary*)entryB valueForKey:ElapsedTimeKey];
    assert(elapsedTimeA != nil && elapsedTimeB != nil);
    
    NSComparisonResult compRes = [elapsedTimeA compare:elapsedTimeB];
    if (compRes != NSOrderedSame)
        return compRes;

    NSDate* entryDateA = [(NSDate*)entryA valueForKey:DateKey];
    NSDate* entryDateB = [(NSDate*)entryB valueForKey:DateKey];
    return [entryDateA compare:entryDateB];
}

size_t FindUpperBound(NSArray* highScores, NSNumber* elapsedTime)
{
    size_t min = 0, max = [highScores count];
    if (max == 0)
        return 0;
    while (min < max)
    {
        size_t index = (max + min) / 2;
        NSDictionary* entry = [highScores objectAtIndex:index];
        if ([elapsedTime compare:[entry objectForKey:ElapsedTimeKey]] == NSOrderedAscending)
            max = index;
        else
            min = index + 1;
    }
    return min;
}

@implementation JbHighScores

- (id)init
{
    self = [super init];
    if (self)
    {
        mHighScores = [[NSMutableArray arrayWithCapacity:25] retain];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    assert(coder != nil);
    self = [super init];
    if (self)
    {
        mHighScores = [[coder decodeObjectForKey:HighScoresKey] retain];
        if (mHighScores == nil || ![mHighScores isKindOfClass:[NSMutableArray class]])
        {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    [mHighScores release];
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:mHighScores forKey:HighScoresKey];
}

- (void)addElapsedTime:(NSNumber*)seconds forPlayer:(NSString*)player
{
    NSMutableDictionary* newEntry = [NSMutableDictionary dictionaryWithCapacity:3];
    [newEntry setObject:seconds forKey:ElapsedTimeKey];
    [newEntry setObject:player forKey:PlayerNameKey];
    [newEntry setObject:[NSDate date] forKey:DateKey];

    if ([mHighScores count] < MaxHighScoreEntries)
        [mHighScores addObject:newEntry];
    else
        [mHighScores replaceObjectAtIndex:[mHighScores count] - 1 withObject:newEntry];
    [mHighScores sortUsingFunction:CompareHighScoreEntries context:NULL];
}

- (unsigned)count
{
    return (unsigned)[mHighScores count];
}

- (NSString*)playerNameAtIndex:(unsigned)index
{
    return [[mHighScores objectAtIndex:index] objectForKey:PlayerNameKey];
}

- (NSNumber*)elapsedTimeAtIndex:(unsigned)index
{
    return [[mHighScores objectAtIndex:index] objectForKey:ElapsedTimeKey];
}

- (NSDate*)dateAtIndex:(unsigned)index
{
    return [[mHighScores objectAtIndex:index] objectForKey:DateKey];
}

- (unsigned)rankOfElapsedTime:(NSNumber*)seconds
{
    assert(seconds != nil);
        
    return (unsigned)FindUpperBound(mHighScores, seconds);
}

- (BOOL)isNewHighScoreEntry:(NSNumber*)seconds
{
    return [self rankOfElapsedTime:seconds] < MaxHighScoreEntries;
}

@end
