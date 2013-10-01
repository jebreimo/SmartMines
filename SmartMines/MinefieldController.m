//
//  MinefieldController.m
//
//  Created by Jan Erik Breimo on 2007-01-09.
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

#import "MinefieldController.h"

#import "BoolToStringTransformer.h"
#import "HighScores.h"
#import "Minefield.h"
#import "MinefieldView.h"
#import "Stopwatch.h"

NSString* JbNewHighScoreEntryNotification = @"JbNewHighScoreEntryNotification";

static NSString* QuestionMarksKey = @"QuestionMarks";
static NSString* SmartMarkKey = @"SmartMark";
static NSString* SmartUncoverKey = @"SmartUncover";
static NSString* EasyStartKey = @"EasyStart";
static NSString* PlayerNameKey = @"PlayerName";
static NSString* SafeUncoverKey = @"SafeUncover";
static NSString* EnableKeyboardKey = @"EnableKeyboard";

@implementation JbMinefieldController
+ (void)initialize
{
    NSMutableDictionary* defaultDict = [[[NSMutableDictionary alloc] init] autorelease];
    [defaultDict setObject:[NSNumber numberWithBool:YES] forKey:QuestionMarksKey];
    [defaultDict setObject:[NSNumber numberWithBool:YES] forKey:SmartMarkKey];
    [defaultDict setObject:[NSNumber numberWithBool:YES] forKey:SmartUncoverKey];
    [defaultDict setObject:[NSNumber numberWithBool:YES] forKey:EasyStartKey];
    [defaultDict setObject:[NSNumber numberWithBool:YES] forKey:SafeUncoverKey];
    [defaultDict setObject:[NSNumber numberWithBool:NO] forKey:EnableKeyboardKey];
    [defaultDict setObject:NSFullUserName() forKey:PlayerNameKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultDict];
    [JbBoolToStringTransformer transformerWithName:@"PauseMenuItemTitleTransformer"
                                          yesValue:@"Resume"
                                           noValue:@"Pause"];
}

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        mMinefield = [[JbMinefield alloc] init];
        minefieldView = nil;
        mLoweredSquares = nil;
        mNumberOfUnmarkedMines = nil;
        mElapsedTime = nil;
        mElapsedTimeTimer = nil;
        mGame = nil;
        mCurrentHighScoreToBeat = nil;
        mCurrentHighScoreTimeToBeat = 0;
        mIsQuickRestartEnabled = NO;
        watchImageView = nil;
        mineImageView = nil;
        mStopwatch = [[JbStopwatch alloc] init];
        mIsRunning = [[NSNumber numberWithBool:NO] retain];
        mIsPaused = [[NSNumber numberWithBool:NO] retain];
    }
    return self;
}

- (void)dealloc
{
    [mGame release];
    [mMinefield release];
    [mLoweredSquares release];
    [mNumberOfUnmarkedMines release];
    [mElapsedTime release];
    [mElapsedTimeTimer release];
    [mStopwatch release];
    [mIsRunning release];
    [mIsPaused release];
    [super dealloc];
}

- (void)stopTimer
{
    [mElapsedTimeTimer invalidate];
    [mElapsedTimeTimer release];
    mElapsedTimeTimer = nil;
    [self setValue:[NSNumber numberWithInt:[mStopwatch stop]] forKey:@"elapsedTime"];
    [self setValue:[NSNumber numberWithBool:NO] forKey:@"isRunning"];
}

- (NSWindow*)window
{
    return [minefieldView window];
}

- (void)updateTimeToBeat:(NSNumber*)elapsedTime
{
    JbHighScores* highScores = [mGame highScores];
    int rank = [highScores rankOfElapsedTime:elapsedTime];
    if (rank < [highScores count])
    {
        mCurrentHighScoreTimeToBeat = [[highScores elapsedTimeAtIndex:rank] intValue];
        [self setValue:[NSString stringWithFormat:@"%d. %@ (%@)",
                        rank + 1,
                        [highScores playerNameAtIndex:rank],
                        [highScores elapsedTimeAtIndex:rank]]
                forKey:@"currentHighScoreToBeat"];
    }
    else
    {
        mCurrentHighScoreTimeToBeat = INT_MAX;
        [self setValue:@"" forKey:@"currentHighScoreToBeat"];
    }
}

- (IBAction)newGame:(id)sender
{
    if (mElapsedTimeTimer != nil)
    {
        [self stopTimer];
    }
    [self setValue:[NSNumber numberWithInt:0] forKey:@"elapsedTime"];
    [mMinefield clear];
    [minefieldView clear];
    [self setValue:[NSNumber numberWithInt:[mGame mines]]
            forKey:@"numberOfUnmarkedMines"];
    [self updateTimeToBeat:[NSNumber numberWithInt:0]];
    [self setValue:[NSNumber numberWithBool:NO] forKey:@"isRunning"];
    [self setValue:[NSNumber numberWithBool:NO] forKey:@"isPaused"];
}

- (IBAction)pauseGame:(id)sender
{
    assert([mIsRunning boolValue]);

    if ([mIsPaused boolValue])
    {
        [minefieldView setEnabled:YES];
        [minefieldView setBackgroundImage:JbNoBackgroundImage];
        [self setValue:[NSNumber numberWithBool:NO] forKey:@"isPaused"];
        [mStopwatch start];
    }
    else
    {
        [mStopwatch stop];
        [minefieldView setEnabled:NO];
        [minefieldView setBackgroundImage:JbVictoryBackgroundImage];
        [self setValue:[NSNumber numberWithBool:YES] forKey:@"isPaused"];
    }
}

- (void)updateViewWithAffectedSquares:(JbTableIndexList*)affected
{
    JbTableIndex* it = [affected begin];
    JbTableIndex* end = [affected end];
    for (; it != end; ++it)
    {
        switch ([mMinefield stateAt:*it])
        {
        case JbUncovered:
            [minefieldView setLowered:YES atIndex:*it];
            if ([mMinefield hasMineAt:*it])
                [minefieldView setSymbol:JbMinefieldExplosion atIndex:*it];
            else
            {
                unsigned mines = [mMinefield countNeighborsWithMinesAt:*it];
                [minefieldView setSymbol:(JbMinefieldSymbol)mines atIndex:*it];
            }
            break;
        case JbUnmarked:
            [minefieldView setSymbol:JbMinefieldEmpty atIndex:*it];
            break;
        case JbMarked:
            [minefieldView setSymbol:JbMinefieldMark atIndex:*it];
            break;
        case JbQuestionMarked:
            [minefieldView setSymbol:JbMinefieldQuestionMark atIndex:*it];
            break;
        }
    }
}

- (void)setPlayerNameDialog:(NSWindow*)window
{
    mPlayerNameDialog = [window retain];
}

- (IBAction)usesQuestionMarksChanged:(id)sender
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    JbTableIndexList* affected = [mMinefield setUsesQuestionMarks:[[ud valueForKey:QuestionMarksKey] boolValue]];
    [self updateViewWithAffectedSquares:affected];
}

- (IBAction)usesSmartMarkChanged:(id)sender
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [mMinefield setUsesSmartMark:[[ud valueForKey:SmartMarkKey] boolValue]];
}

- (IBAction)usesSmartUncoverChanged:(id)sender
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [mMinefield setUsesSmartUncover:[[ud valueForKey:SmartUncoverKey] boolValue]];
}

- (IBAction)usesEasyStartChanged:(id)sender
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [mMinefield setUsesEasyStart:[[ud valueForKey:EasyStartKey] boolValue]];
}

- (IBAction)usesSafeUncoverChanged:(id)sender
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [minefieldView setCancelMode:[[ud valueForKey:SafeUncoverKey] boolValue]
                                 ? JbOutsideSquareCancels
                                 : JbOutsideMinefieldCancels];
}

- (IBAction)keyboardEnabledChanged:(id)sender
{
    BOOL newState = ![minefieldView showsKeyboardCursor];

    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setValue:[NSNumber numberWithBool:newState] forKey:EnableKeyboardKey];
    [keyboardMenuItem setState:newState ? NSOnState : NSOffState];
    [minefieldView setShowKeyboardCursor:newState];
}

- (void)setDefaultWindowSize
{
    JbTableSize mfSize = [mGame size];
    NSRect scrRect = [[[minefieldView window] screen] visibleFrame];
    NSRect winRect = [[minefieldView window] frame];
    NSRect viewRect = [minefieldView bounds];
    scrRect.size.height -= winRect.size.height - viewRect.size.height;
    scrRect.size.width -= winRect.size.width - viewRect.size.width;
    float maxRowSize = MIN(25.0, floor(scrRect.size.height / mfSize.rows));
    float maxColSize = MIN(25.0, floor(scrRect.size.width / mfSize.columns));
    float squareSize = MIN(maxRowSize, maxColSize);
    winRect.size.height += squareSize * mfSize.rows - viewRect.size.height;
    winRect.size.width += squareSize * mfSize.columns - viewRect.size.width;
    [minefieldView setUsesContentResizeIncrement:NO];
    [[self window] setFrame:winRect display:YES];
    [minefieldView setUsesContentResizeIncrement:YES];
}

- (void)setGame:(JbGame*)newGame
{
    if (mGame)
    {
        [[minefieldView window] saveFrameUsingName:[mGame sizeDescription]];
        [mGame release];
    }
    mGame = [newGame retain];
    [mMinefield setSize:[mGame size] numberOfMines:[mGame mines]];
    [minefieldView setMinefieldSize:[mGame size]];
    [minefieldView setUsesContentResizeIncrement:NO];
    if (![[minefieldView window] setFrameUsingName:[mGame sizeDescription]])
        [self setDefaultWindowSize];
    [minefieldView setUsesContentResizeIncrement:YES];
    [self newGame:(self)];
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
    [self usesQuestionMarksChanged:self];
    [self usesSmartMarkChanged:self];
    [self usesSmartUncoverChanged:self];
    [self usesEasyStartChanged:self];
    [self usesSafeUncoverChanged:self];
    // Disabling the cache is a workaround that prevent images from becoming
    // pixellated when the window is resized. I know of no other way.
    [[watchImageView image] setCacheMode:NSImageCacheNever];
    [[mineImageView image] setCacheMode:NSImageCacheNever];

    [[self window] makeKeyAndOrderFront:self];

    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    BOOL keyboardCursorState = [[ud valueForKey:EnableKeyboardKey] boolValue];

    [keyboardMenuItem setState:keyboardCursorState ? NSOnState : NSOffState];
    [minefieldView setShowKeyboardCursor:keyboardCursorState];
}

- (void)windowWillMiniaturize:(NSNotification*)notification
{
    if ([mIsRunning boolValue] && ![mIsPaused boolValue])
        [self pauseGame:self];
}

- (void)windowWillClose:(NSNotification*)notification
{
    if (mMinefield == nil || minefieldView == nil)
        return;
    NSApplication* app = [NSApplication sharedApplication];
    if ([app isRunning])
    {
        [[minefieldView window] saveFrameUsingName:[mGame sizeDescription]];
        [app terminate:self];
    }
}

- (void)revealMinefield
{
    [minefieldView setNeedsDisplay:YES];
    JbTableSize size = [mMinefield size];
    for (unsigned row = 0; row != size.rows; ++row)
    {
        for (unsigned col = 0; col != size.columns; ++col)
        {
            JbTableIndex index = JbMakeTableIndex(row, col);
            switch ([mMinefield stateAt:index])
            {
            case JbUnmarked:
                if ([mMinefield hasMineAt:index])
                    [minefieldView setSymbol:JbMinefieldUnmarkedMine atIndex:index];
                break;
            case JbMarked:
                if (![mMinefield hasMineAt:index])
                    [minefieldView setSymbol:JbMinefieldIncorrectMark atIndex:index];
                break;
            case JbQuestionMarked:
                if ([mMinefield hasMineAt:index])
                    [minefieldView setSymbol:JbMinefieldQuestionMarkedMine atIndex:index];
                else
                    [minefieldView setSymbol:JbMinefieldIncorrectQuestionMark atIndex:index];
                break;
            }
        }
    };
}

- (NSNumber*)numberOfUnmarkedMines
{
    return mNumberOfUnmarkedMines;
}

- (void)setNumberOfUnmarkedMines:(NSNumber*)newNumberOfUnmarkedMines
{
    NSNumber* oldNumberOfUnmarkedMines = mNumberOfUnmarkedMines;
    mNumberOfUnmarkedMines = [newNumberOfUnmarkedMines retain];
    [oldNumberOfUnmarkedMines release];
}

- (NSNumber*)elapsedTime
{
    return mElapsedTime;
}

- (void)setElapsedTime:(NSNumber*)newElapsedTime
{
    NSNumber* oldElapsedTime = mElapsedTime;
    mElapsedTime = [newElapsedTime retain];
    [oldElapsedTime release];
}

- (NSString*)currentHighScoreToBeat
{
    return mCurrentHighScoreToBeat;
}

- (void)setCurrentHighScoreToBeat:(NSString*)newCurrentHighScoreToBeat
{
    NSString* oldCurrentHighScoreToBeat = mCurrentHighScoreToBeat;
    mCurrentHighScoreToBeat = [newCurrentHighScoreToBeat retain];
    [oldCurrentHighScoreToBeat release];
}

- (BOOL)tryMarkAtIndex:(JbTableIndex)index
{
    JbTableIndexList* affected = [mMinefield markAt:index];
    if ([affected count] == 0)
        return NO;

    [self updateViewWithAffectedSquares:affected];
    [self setValue:[NSNumber numberWithInt:[mMinefield numberOfMines] - [mMinefield numberOfMarkedSquares]]
            forKey:@"numberOfUnmarkedMines"];

    return YES;
}

- (void)lowerSquaresAtIndex:(JbTableIndex)index
{
    mLoweredSquares = [[mMinefield uncoverableAt:index] retain];
    JbTableIndex* it = [mLoweredSquares begin];
    JbTableIndex* end = [mLoweredSquares end];
    for (; it != end; ++it)
    {
        [minefieldView setLowered:YES atIndex:*it];
    }
}

- (IBAction)updateTimer:(id)sender
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    int elapsedTime = (int)floor([mStopwatch seconds]);
    [self setValue:[NSNumber numberWithInt:elapsedTime] forKey:@"elapsedTime"];
    if (elapsedTime >= mCurrentHighScoreTimeToBeat)
        [self updateTimeToBeat:[NSNumber numberWithInt:elapsedTime]];
    [pool release];
}

- (IBAction)addHighScoreEntry:(id)sender
{   
    [[NSApplication sharedApplication] stopModal];
    [mPlayerNameDialog close];
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    JbHighScores* highScores = [mGame highScores];
    [highScores addElapsedTime:mElapsedTime
                     forPlayer:[ud objectForKey:PlayerNameKey]];
    [[NSNotificationCenter defaultCenter] postNotificationName:JbNewHighScoreEntryNotification
                                                        object:mGame];
}

- (IBAction)cancelHighScoreEntry:(id)sender
{
    [[NSApplication sharedApplication] stopModal];
    [mPlayerNameDialog close];
}

- (void)startTimer
{
    [mStopwatch reset];
    [mStopwatch start];
    [self setValue:[NSNumber numberWithInt:0] forKey:@"elapsedTime"];
    mElapsedTimeTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
                                                          target:self
                                                        selector:@selector(updateTimer:)
                                                        userInfo:nil
                                                         repeats:YES] retain];
    [self setValue:[NSNumber numberWithBool:YES] forKey:@"isRunning"];
}

- (void)enableQuickRestart:(id)sender
{
    mIsQuickRestartEnabled = YES;
}

- (void)beginRightMouseDownInView:(JbMinefieldView*)view atIndex:(JbTableIndex)index
{
    JbMinefieldState state = [mMinefield state];
    if (state == JbBlownUp || state == JbCompleted || [mIsPaused boolValue])
        return;

    if (state == JbNotCompleted && ([self tryMarkAtIndex:index] || [mMinefield stateAt:index] != JbUncovered))
        return;

    [self lowerSquaresAtIndex:index];
}

- (void)beginMouseDownInView:(JbMinefieldView*)view atIndex:(JbTableIndex)index
{
    JbMinefieldState state = [mMinefield state];
    if (state == JbBlownUp || state == JbCompleted || [mIsPaused boolValue])
        return;
    
    if ([mMinefield stateAt:index] == JbUncovered
        && [self tryMarkAtIndex:index])
        return;

    [self lowerSquaresAtIndex:index];
}

- (void)cancelMouseDownInView:(JbMinefieldView*)view atIndex:(JbTableIndex)index
{
    JbMinefieldState state = [mMinefield state];
    if (state != JbNotStarted && state != JbNotCompleted
        || !mLoweredSquares
        || [mLoweredSquares count] == 0)
        return;
    JbTableIndex* it = [mLoweredSquares begin];
    JbTableIndex* end = [mLoweredSquares end];
    for (; it != end; ++it)
        [view setLowered:NO atIndex:*it];
}

- (void)cancelRightMouseDownInView:(JbMinefieldView*)view atIndex:(JbTableIndex)index
{
    [self cancelMouseDownInView:view atIndex:index];
}

- (void)commitMouseDownInView:(JbMinefieldView*)view atIndex:(JbTableIndex)index
{
    if ([mIsPaused boolValue])
    {
        [self pauseGame:self];
        return;
    }

    if (mLoweredSquares != nil)
    {
        [mLoweredSquares release];
        mLoweredSquares = nil;
    }

    JbMinefieldState state = [mMinefield state];
    if (state == JbNotStarted)
    {
        [self startTimer];
        [mGame gameStarted];
        [self updateTimeToBeat:[NSNumber numberWithInt:0]];
    }
    else if (state != JbNotCompleted)
    {
        if (mIsQuickRestartEnabled)
            [self newGame:self];
        return;
    }

    JbTableIndexList* affected = [mMinefield uncoverAt:index];
    state = [mMinefield state];
    if (state == JbCompleted)
    {
        [self stopTimer];
        [mGame gameWon];
        [minefieldView setBackgroundImage:JbVictoryBackgroundImage];
        [self updateViewWithAffectedSquares:affected];
        [self revealMinefield];
        JbHighScores* highScores = [mGame highScores];
        if ([highScores isNewHighScoreEntry:mElapsedTime])
        {
            //[mPlayerNameDialog makeKeyAndOrderFront:self];
            [[NSApplication sharedApplication] runModalForWindow:mPlayerNameDialog];
            mIsQuickRestartEnabled = YES;
        }
        else
        {
            // Prevent user from clearing the minefield too quickly.
            mIsQuickRestartEnabled = NO;
            [NSTimer scheduledTimerWithTimeInterval:1
                                             target:self
                                           selector:@selector(enableQuickRestart:)
                                           userInfo:nil
                                            repeats:NO];
        }
    }
    else if (state == JbBlownUp)
    {
        [self stopTimer];
        [mGame gameLost];
        [minefieldView setBackgroundImage:JbDefeatBackgroundImage];
        [self updateViewWithAffectedSquares:affected];
        [self revealMinefield];
        // Prevent user from clearing the minefield too quickly.
        mIsQuickRestartEnabled = NO;
        [NSTimer scheduledTimerWithTimeInterval:1
                                         target:self
                                       selector:@selector(enableQuickRestart:)
                                       userInfo:nil
                                        repeats:NO];
    }
    else
    {
        [self updateViewWithAffectedSquares:affected];
    }
}

- (void)commitRightMouseDownInView:(JbMinefieldView*)view atIndex:(JbTableIndex)index
{
    JbMinefieldState state = [mMinefield state];
    if ((state == JbBlownUp || state == JbCompleted)
        || (mLoweredSquares && [mLoweredSquares count] != 0)
        || [mIsPaused boolValue])
    {
        [self commitMouseDownInView:view atIndex:index];
    }
}

- (void)showsKeyboardCursorChangedInView:(JbMinefieldView*)view
{
    BOOL newState = [minefieldView showsKeyboardCursor];

    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setValue:[NSNumber numberWithBool:newState] forKey:EnableKeyboardKey];
    [keyboardMenuItem setState:newState ? NSOnState : NSOffState];
}

- (NSNumber*)isRunning
{
    return mIsRunning;
}

- (void)setIsRunning:(NSNumber*)newIsRunning
{
    NSNumber* oldIsRunning = mIsRunning;
    mIsRunning = [newIsRunning retain];
    [oldIsRunning release];
}

- (NSNumber*)isPaused
{
    return mIsPaused;
}

- (void)setIsPaused:(NSNumber*)newIsPaused
{
    NSNumber* oldIsPaused = mIsPaused;
    mIsPaused = [newIsPaused retain];
    [oldIsPaused release];
}
@end

// FIXME: Strange, virtually irreproducible bug where a large rectangular area
//        of the minefield is erased for no apparent reason. Turns out this
//        only happens when the game is run from TextMate.
