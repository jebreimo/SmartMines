//
//  GameMenuController.h
//
//  Created by Jan Erik Breimo on 2007-03-08.
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

#import "GameCollection.h"
#import "MinefieldController.h"

@class JbCustomGameDialogController;
@class JbHighScoresWindowController;

extern NSString* JbNewCustomGameAddedNotification;

@interface JbGameMenuController : NSObject
{
    JbGameCollection* mGames;
    JbGame* mCurrentGame;
    IBOutlet JbCustomGameDialogController* customGameWindowController;
    IBOutlet JbHighScoresWindowController* highScoresWindowController;
    IBOutlet JbMinefieldController* minefieldController;
    IBOutlet NSMenu* gameMenu;
    IBOutlet NSMenu* customGamesMenu;
}

+ (void)initialize;
- (id)init;
- (void)dealloc;

- (NSMenuItem*)menuItemForGame:(JbGame*)game;
- (void)restoreCustomGamesMenu;
- (void)setCurrentGame:(JbGame*)newCurrentGame;
- (void)storeCustomGamesMenu;
- (void)setTopCustomGameMenuItem:(NSMenuItem*)theMenuItem;
- (void)cancelNewCustomGame:(JbCustomGameDialogController*)sender;
- (void)removeLeastRecentlyPlayedCustomGamesMenuItem;
- (void)startNewCustomGame:(JbCustomGameDialogController*)sender;

// NSApplication delegate
- (void)applicationDidFinishLaunching:(NSNotification*)notification;
- (void)applicationWillTerminate:(NSNotification*)theNotification;

// IBActions
- (IBAction)newCustomGame:(id)sender;
- (IBAction)selectGame:(id)sender;
- (IBAction)showHighScores:(id)sender;
- (IBAction)showManual:(id)sender;
- (IBAction)terminate:(id)sender;

@end
