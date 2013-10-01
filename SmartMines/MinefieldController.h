//
//  MinefieldController.h
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

#import <Cocoa/Cocoa.h>
#import "TableIndexList.h"
#import "Game.h"

@class JbMinefieldView;
@class JbMinefield;
@class JbStopwatch;

extern NSString* JbNewHighScoreEntryNotification;

@interface JbMinefieldController : NSObject
{
@private
    JbMinefield* mMinefield;
    IBOutlet JbMinefieldView* minefieldView;
    JbTableIndexList* mLoweredSquares;
    JbGame* mGame;
    NSNumber* mNumberOfUnmarkedMines;
    NSNumber* mElapsedTime;
    NSTimer* mElapsedTimeTimer;
    BOOL mIsQuickRestartEnabled;
    NSWindow* mPlayerNameDialog;
    NSString* mCurrentHighScoreToBeat;
    NSImageView* watchImageView;
    NSImageView* mineImageView;
    int mCurrentHighScoreTimeToBeat;
    JbStopwatch* mStopwatch;
    NSNumber* mIsRunning;
    NSNumber* mIsPaused;
    NSMenuItem* keyboardMenuItem;
}
- (void)applicationDidFinishLaunching:(NSNotification*)notification;

- (NSNumber*)numberOfUnmarkedMines;
- (void)setNumberOfUnmarkedMines:(NSNumber*)numberOfUnmarkedMines;
- (NSNumber*)elapsedTime;
- (void)setElapsedTime:(NSNumber*)seconds;
- (void)setPlayerNameDialog:(NSWindow*)window;
- (NSString*)currentHighScoreToBeat;
- (void)setCurrentHighScoreToBeat:(NSString*)newCurrentHighScoreToBeat;
- (NSWindow*)window;
/// Boolean value that enables/disables "Pause" menu item
- (NSNumber*)isRunning;
- (void)setIsRunning:(NSNumber*)newIsRunning;
/// Boolean value that controls the title of "Pause" menu item 
- (NSNumber*)isPaused;
- (void)setIsPaused:(NSNumber*)newIsPaused;


- (void)setGame:(JbGame*)newGame;
- (IBAction)newGame:(id)sender;
- (IBAction)pauseGame:(id)sender;
- (IBAction)updateTimer:(id)sender;
- (IBAction)usesQuestionMarksChanged:(id)sender;
- (IBAction)usesSmartMarkChanged:(id)sender;
- (IBAction)usesSmartUncoverChanged:(id)sender;
- (IBAction)usesEasyStartChanged:(id)sender;
- (IBAction)usesSafeUncoverChanged:(id)sender;
- (IBAction)addHighScoreEntry:(id)sender;
@end
