//
//  HighScoresWindowController.m
//
//  Created by Jan Erik Breimo on 2007-02-04.
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

#import "HighScoresWindowController.h"

#import "GameMenuItem.h"
#import "MinefieldController.h"

static NSComparisonResult CompareGames(id entryA, id entryB, void* context)
{
    BOOL aIsCustom = [entryA isCustomGame];
    BOOL bIsCustom = [entryB isCustomGame];
    if (!aIsCustom && bIsCustom)
        return NSOrderedAscending;
    else if (aIsCustom && !bIsCustom)
        return NSOrderedDescending;

    JbTableSize aSize = [(JbGame*)entryA size];
    JbTableSize bSize = [(JbGame*)entryB size];
    int aArea = aSize.rows * aSize.columns;
    int bArea = bSize.rows * bSize.columns;
    if (aArea < bArea)
        return NSOrderedAscending;
    else if (aArea > bArea)
        return NSOrderedDescending;
    else if (aSize.columns < bSize.columns)
        return NSOrderedAscending;
    else if (aSize.columns > bSize.columns)
        return NSOrderedDescending;
    else if ([entryA mines] < [entryB mines])
        return NSOrderedAscending;
    else if ([entryA mines] > [entryB mines])
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

@implementation JbHighScoresWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"HighScores"];
    if (self)
    {
        mGamePopUp = nil;
        mGames = nil;
        mCurrentGame = nil;
        mHighScoreList = nil;
    }
    return self;
}

- (void)dealloc
{
    [mGames release];
    [mCurrentGame release];
    [mGamePopUp release];
    [mHighScoreList release];
    [super dealloc];
}

- (IBAction)selectGame:(id)menuItem
{
    if ([menuItem isKindOfClass:[JbGameMenuItem class]])
    {
        [self setCurrentGame:[mGames gameWithDescription:[menuItem gameDescription]]];
    }
}

- (void)fillGameMenu
{
    NSMutableArray* games = [NSMutableArray arrayWithArray:[mGames games]];
    [games  sortUsingFunction:CompareGames context:NULL];

    NSMenu* menu = [[NSMenu alloc] initWithTitle:@"Game"];
    for (unsigned int index = 0; index < [games count]; index += 1)
    {
        JbGame* game = [games objectAtIndex:index];
        if (![game isCustomGame] || [[game highScores] count] != 0 || game == mCurrentGame)
        {
            NSString* name = [game name];
            if (!name)
                name = [game description];
            [menu addItem:[JbGameMenuItem menuItemWithTitle:name
                                                     action:@selector(selectGame:)
                                            gameDescription:[game description]]];
        }
    }
    [mGamePopUp setMenu:menu];
    [menu release];
}

- (void)setGames:(JbGameCollection*)newGames
{
    JbGameCollection* oldGames = mGames;
    mGames = [newGames retain];
    [oldGames release];
    if (mGamePopUp)
        [self fillGameMenu];
}

- (IBAction)newHighScoreEntryinGame:(NSNotification*)notification
{
    JbGame* game = [notification object];
    if (game == mCurrentGame)
        [mHighScoreList reloadData];
    [self setCurrentGame:game];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newHighScoreEntryinGame:)
                                                 name:JbNewHighScoreEntryNotification
                                               object:nil];

    if (!mGames)
        return;
        
    [self fillGameMenu];
    if (!mCurrentGame)
        return;

    NSString* title = [mCurrentGame name];
    if (!title)
        title = [mCurrentGame description];
    [mGamePopUp selectItemWithTitle:title];
}

- (NSPopUpButton*)gamePopUp
{
    return mGamePopUp;
}

- (void)setGamePopUp:(NSPopUpButton*)newGamePopUp
{
    NSPopUpButton* oldGamePopUp = mGamePopUp;
    mGamePopUp = [newGamePopUp retain];
    [oldGamePopUp release];
}

- (JbGame*)currentGame
{
    return mCurrentGame;
}

- (void)setCurrentGame:(JbGame*)newCurrentGame
{
    JbGame* oldCurrentGame = mCurrentGame;
    mCurrentGame = [newCurrentGame retain];
    [oldCurrentGame release];
    NSString* title = [mCurrentGame name];
    if (!title)
        title = [mCurrentGame description];
    long index = [mGamePopUp indexOfItemWithTitle:title];
    if (index == -1)
    {
        [self fillGameMenu];
        index = [mGamePopUp indexOfItemWithTitle:title];
    }
    [mGamePopUp selectItemAtIndex:index];
    [mHighScoreList reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (!mCurrentGame)
        return 0;
    JbHighScores* highScores = [mCurrentGame highScores];
    return [highScores count];
}

- (id)tableView:(NSTableView*)aTableView
objectValueForTableColumn:(NSTableColumn*)aTableColumn
            row:(int)rowIndex
{
    JbHighScores* highScores = [mCurrentGame highScores];
    if ([[aTableColumn identifier] isEqualToString:@"Position"])
        return [NSString stringWithFormat:@"%d", rowIndex + 1];
    else if ([[aTableColumn identifier] isEqualToString:@"Player"])
        return [highScores playerNameAtIndex:rowIndex];
    else if ([[aTableColumn identifier] isEqualToString:@"Time"])
        return [highScores elapsedTimeAtIndex:rowIndex];
    return nil;
}

- (NSString*)tableView:(NSTableView*)aTableView
        toolTipForCell:(NSCell*)aCell
                  rect:(NSRectPointer)rect
           tableColumn:(NSTableColumn*)aTableColumn
                   row:(int)row
         mouseLocation:(NSPoint)mouseLocation
{
    JbHighScores* highScores = [mCurrentGame highScores];
    if (row < [highScores count])
        return [[highScores dateAtIndex:row] descriptionWithLocale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
    else
        return nil;
}

- (NSTableView*)highScoreList
{
    return mHighScoreList;
}

- (void)setHighScoreList:(NSTableView*)newHighScoreList
{
    NSTableView* oldHighScoreList = mHighScoreList;
    mHighScoreList = [newHighScoreList retain];
    [oldHighScoreList release];
}

@end
