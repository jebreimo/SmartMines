//
//  GameCollection.m
//
//  Created by Jan Erik Breimo on 2007-02-17.
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

#import "GameCollection.h"

static NSString* ApplicationName = @"SmartMines";
static NSString* DefaultFileName = @"SmartMines.plist";
static NSString* GamesKey = @"Games";

NSString* JbBeginnerGame = @"9x9x10";
NSString* JbIntermediateGame = @"16x16x40";
NSString* JbExpertGame = @"16x30x99";

NSString* JbPathForUserApplicationSupport(NSString* applicationName)
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSArray* appSuppDirs = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if ([appSuppDirs count] == 0)
        return nil;
    for (int i = 0; i != [appSuppDirs count]; ++i)
    {
        NSString* path = [NSString stringWithFormat:@"%@/%@", [appSuppDirs objectAtIndex:i], applicationName];
        if ([fm fileExistsAtPath:path])
            return path;
    }
    NSString* path = [NSString stringWithFormat:@"%@/%@", [appSuppDirs objectAtIndex:0], applicationName];
    [fm createDirectoryAtPath:path attributes:nil];
    return path;
}

@implementation JbGameCollection

+ (NSString*)defaultGameCollectionPath
{
    NSString* appSuppPath = JbPathForUserApplicationSupport(ApplicationName);
    return [NSString stringWithFormat:@"%@/%@", appSuppPath, DefaultFileName];
}

+ (JbGameCollection*)defaultGameCollection
{
    NSString* fileName = [JbGameCollection defaultGameCollectionPath];
    NSFileManager* fm = [NSFileManager defaultManager];

    JbGameCollection* gameCollection = nil;
    if ([fm isReadableFileAtPath:fileName])
        gameCollection = [NSKeyedUnarchiver unarchiveObjectWithFile:fileName];

    if (gameCollection == nil)
        gameCollection = [[[JbGameCollection alloc] init] autorelease];
    return gameCollection;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        mGames = [[NSMutableDictionary dictionaryWithCapacity:5] retain];
        [self beginnerGame];
        [self intermediateGame];
        [self expertGame];
    }
    return self;
}

- (id)initWithCoder:(NSCoder*)theCoder
{
    self = [super init];
    if (self)
    {
        mGames = [[theCoder decodeObjectForKey:GamesKey] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)theCoder
{
    [theCoder encodeObject:mGames forKey:GamesKey];
}

- (NSArray*)games
{
    return [mGames allValues];
}

- (void)addGame:(JbGame*)game
{
    if (game && ![mGames objectForKey:[game description]])
        [mGames setObject:game forKey:[game description]];
}

- (JbGame*)beginnerGame
{
    JbGame* game = [self gameWithDescription:JbBeginnerGame];
    [game setName:@"Beginner"];
    [game setCustomGame:NO];
    return game;
}

- (JbGame*)intermediateGame
{
    JbGame* game = [self gameWithDescription:JbIntermediateGame];
    [game setName:@"Intermediate"];
    [game setCustomGame:NO];
    return game;
}

- (JbGame*)expertGame
{
    JbGame* game = [self gameWithDescription:JbExpertGame];
    [game setName:@"Expert"];
    [game setCustomGame:NO];
    return game;
}

- (JbGame*)gameWithDescription:(NSString*)description
{
    JbGame* game = [mGames objectForKey:description];
    if (game != nil)
        return game;

    game = [[[JbGame alloc] initWithDescription:description] autorelease];
    [self addGame:game];
    return game;
}

- (void)saveDefaultGameCollection
{
    [NSKeyedArchiver archiveRootObject:self toFile:[JbGameCollection defaultGameCollectionPath]];
}

@end
