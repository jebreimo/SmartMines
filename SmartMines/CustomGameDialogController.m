//
//  CustomGameDialogController.m
//
//  Created by Jan Erik Breimo on 2007-02-25.
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

#import "CustomGameDialogController.h"
#import <math.h>

@implementation JbCustomGameDialogController

- (id)init
{
    self = [super initWithWindowNibName:@"CustomGame"];
    if (self)
    {
        mRows = [[NSNumber alloc] initWithInt:5];
        mColumns = [[NSNumber alloc] initWithInt:5];
        mMines = [[NSNumber alloc] initWithInt:5];
        mMaxMines = [[NSNumber alloc] initWithInt:5 * 5 / 2];
        mDelegate = nil;
        canStartGame = YES;
    }
    return self;
}

- (void)dealloc
{
    [mRows release];
    [mColumns release];
    [mMines release];
    [mMaxMines release];
    [super dealloc];
}

- (void)copyProperties:(JbGame*)game
{
    JbTableSize size = [game size];
    [self setValue:[NSNumber numberWithInt:size.rows] forKey:@"rows"];
    [self setValue:[NSNumber numberWithInt:size.columns] forKey:@"columns"];
    [self setValue:[NSNumber numberWithInt:[game mines]] forKey:@"mines"];
}

- (void)updateMaxMines
{
    int maxMines = [mRows intValue] * [mColumns intValue] / 2;
    if ([mMines intValue] > maxMines)
        [self setValue:[NSNumber numberWithInt:maxMines] forKey:@"mines"];
    [self setValue:[NSNumber numberWithInt:maxMines] forKey:@"maxMines"];
}

- (void)updateCanStartGame
{
    JbTableSize size = JbMakeTableSize([mRows intValue], [mColumns intValue]);
    BOOL valid = [JbGame isValidGameSize:size mines:[mMines intValue]];
    [self setValue:[NSNumber numberWithBool:valid] forKey:@"canStartGame"];
}

- (NSNumber*)rows
{
    return mRows;
}

- (void)setRows:(NSNumber*)newRows
{
    NSNumber* oldRows = mRows;
    int rows = (int)([newRows floatValue] + 0.5);
    mRows = [[NSNumber numberWithInt:rows] retain];
    [oldRows release];
    [self updateMaxMines];
    [self updateCanStartGame];
}

- (NSNumber*)columns
{
    return mColumns;
}

- (void)setColumns:(NSNumber*)newColumns
{
    NSNumber* oldColumns = mColumns;
    int columns = (int)([newColumns floatValue] + 0.5);
    mColumns = [[NSNumber numberWithInt:columns] retain];
    [oldColumns release];
    [self updateMaxMines];
    [self updateCanStartGame];
}

- (NSNumber*)mines
{
    return mMines;
}

- (void)setMines:(NSNumber*)newMines
{
    NSNumber* oldMines = mMines;
    int mines = (int)([newMines floatValue] + 0.5);
    mMines = [[NSNumber numberWithInt:mines] retain];
    [oldMines release];
    [self updateCanStartGame];
}

- (NSNumber*)maxMines
{
    return mMaxMines;
}

- (void)setMaxMines:(NSNumber*)newMaxMines
{
    NSNumber* oldMaxMines = mMaxMines;
    mMaxMines = [newMaxMines retain];
    [oldMaxMines release];
}

- (id)delegate
{
    return mDelegate;
}

- (void)setDelegate:(id)newDelegate
{
    mDelegate = newDelegate;
}

- (NSString*)gameDescription
{
    JbTableSize size = JbMakeTableSize([mRows intValue], [mColumns intValue]);
    return [JbGame describeGameWithSize:size mines:[mMines intValue]];
}

- (IBAction)cancel:(id)sender
{
    if ([[self delegate] respondsToSelector:@selector(cancelNewCustomGame:)])
        [[self delegate] cancelNewCustomGame:self];
    [[self window] close];
}

- (IBAction)startGame:(id)sender
{
    if ([[self delegate] respondsToSelector:@selector(startNewCustomGame:)])
        [[self delegate] startNewCustomGame:self];
    [[self window] close];
}

@end
