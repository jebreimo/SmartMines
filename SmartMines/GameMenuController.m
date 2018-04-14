//
//  GameMenuController.m
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

#import "GameMenuController.h"

#import "CustomGameDialogController.h"
#import "GameMenuItem.h"
#import "HighScoresWindowController.h"

NSString* JbNewCustomGameAddedNotification = @"JbNewCustomGameAddedNotification";

static NSString* GameKey = @"Game";
static NSString* CustomGamesMenuKey = @"CustomGamesMenu";

enum {BeginnerMenuItem = 1001,
      IntermediateMenuItem = 1002,
      ExpertMenuItem = 1003,
      CustomGamesMenuItem = 1004};

enum {FirstCustomGameEntry = 2, MaxCustomGamesMenuEntries = 8};

NSString* JbJoinStrings(NSString* separator, NSArray* strings);

@implementation JbGameMenuController

+ (void)initialize
{
    NSMutableDictionary* defaultDict = [[[NSMutableDictionary alloc] init] autorelease];
    [defaultDict setObject:JbBeginnerGame forKey:GameKey];
    [defaultDict setObject:@"" forKey:CustomGamesMenuKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultDict];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        mGames = [[JbGameCollection defaultGameCollection] retain];
        mCurrentGame = nil;
        gameMenu = nil;
        customGamesMenu = nil;
        customGameWindowController = nil;
        highScoresWindowController = nil;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (IBAction)showHighScores:(id)sender
{
    [highScoresWindowController setGames:mGames];
    [highScoresWindowController setCurrentGame:mCurrentGame];
    NSWindow* window = [highScoresWindowController window];
    [window makeKeyAndOrderFront:self];
}

- (NSMenuItem*)menuItemForGame:(JbGame*)game
{
    if ([game isCustomGame])
        return [customGamesMenu itemWithTitle:[game name]];
    else if (game == [mGames beginnerGame])
        return [gameMenu itemWithTag:BeginnerMenuItem];
    else if (game == [mGames intermediateGame])
        return [gameMenu itemWithTag:IntermediateMenuItem];
    else if (game == [mGames expertGame])
        return [gameMenu itemWithTag:ExpertMenuItem];
    else
        return nil;
}

- (void)setCurrentGame:(JbGame*)newCurrentGame
{
    if (mCurrentGame != newCurrentGame)
    {
        [mCurrentGame release];
        mCurrentGame = [newCurrentGame retain];
        NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
        [ud setValue:[mCurrentGame description] forKey:GameKey];
    }
    [minefieldController setGame:mCurrentGame];
}

- (void)storeCustomGamesMenu
{
    NSMutableArray* descriptions = [NSMutableArray arrayWithCapacity:[customGamesMenu numberOfItems]];
    for (unsigned int index = FirstCustomGameEntry; index < [customGamesMenu numberOfItems]; ++index)
    {
        JbGameMenuItem* item = (JbGameMenuItem*)[customGamesMenu itemAtIndex:index];
        [descriptions addObject:[item gameDescription]];
    }
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setValue:JbJoinStrings(@",", descriptions) forKey:CustomGamesMenuKey];
}

- (void)restoreCustomGamesMenu
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSString* description = [ud valueForKey:CustomGamesMenuKey];
    NSArray* descriptions = [description componentsSeparatedByString:@","];
    for (unsigned int index = 0; index < [descriptions count]; ++index)
    {
        NSString* string = [descriptions objectAtIndex:index];
        JbGame* game = [mGames gameWithDescription:string];
        if (game)
        {
            NSMenuItem* menuItem = [JbGameMenuItem menuItemWithTitle:[game name]
                                                              action:@selector(selectGame:)
                                                     gameDescription:string];
            [menuItem setTag:CustomGamesMenuItem];
            [customGamesMenu addItem:menuItem];
        }
    }
}

- (void)setTopCustomGameMenuItem:(NSMenuItem*)theMenuItem
{
    NSInteger index = [customGamesMenu indexOfItem:theMenuItem];
    if (index == FirstCustomGameEntry)
        return;
    else if (index == -1)
    {
        if ([customGamesMenu numberOfItems] - FirstCustomGameEntry >= MaxCustomGamesMenuEntries)
            [customGamesMenu removeItemAtIndex:[customGamesMenu numberOfItems] - 1];
        [customGamesMenu insertItem:theMenuItem atIndex:FirstCustomGameEntry];        
    }
    else
    {
        [theMenuItem retain];
        [customGamesMenu removeItemAtIndex:index];
        [customGamesMenu insertItem:theMenuItem atIndex:FirstCustomGameEntry];
        [theMenuItem release];
    }
    [self storeCustomGamesMenu];
}

- (IBAction)selectGame:(id)sender
{
    if ([sender isKindOfClass:[NSMenuItem class]])
    {
        JbGame* selectedGame = nil;
        switch ([sender tag])
        {
        case BeginnerMenuItem:
            selectedGame =  [mGames beginnerGame];
            break;
        case IntermediateMenuItem:
            selectedGame =  [mGames intermediateGame];
            break;
        case ExpertMenuItem:
            selectedGame =  [mGames expertGame];
            break;
        case CustomGamesMenuItem:
            if ([sender isKindOfClass:[JbGameMenuItem class]])
                selectedGame =  [mGames gameWithDescription:[sender gameDescription]];
            [self setTopCustomGameMenuItem:sender];
            break;
        default:
            return;
        }
        if ([sender state] != NSOnState)
        {
            [[self menuItemForGame:mCurrentGame] setState:NSOffState];
            [sender setState:NSOnState];
            [self setCurrentGame:selectedGame];
        }
        else
            [minefieldController newGame:self];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
    [self restoreCustomGamesMenu];
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    JbGame* game = [mGames gameWithDescription:[ud valueForKey:GameKey]];
    if (game)
        [self setCurrentGame:game];
    else
        [self setCurrentGame:[mGames beginnerGame]];
    NSMenuItem* menuItem = [self menuItemForGame:mCurrentGame];
    if (menuItem)
        [menuItem setState:NSOnState];
    [minefieldController applicationDidFinishLaunching:notification];
    [highScoresWindowController setGames:mGames];
}

- (IBAction)terminate:(id)sender
{
    NSWindow* window = [minefieldController window];
    if (window != nil && ([window isVisible] || [window isMiniaturized]))
        [window performClose:self];
}

- (void)applicationWillTerminate:(NSNotification*)theNotification
{
    [mGames saveDefaultGameCollection];
}

- (IBAction)newCustomGame:(id)sender
{
    [customGameWindowController copyProperties:mCurrentGame];
    [customGameWindowController setDelegate:self];
    [[NSApplication sharedApplication] runModalForWindow:[customGameWindowController window]];
}

- (void)cancelNewCustomGame:(JbCustomGameDialogController*)sender
{
    [[NSApplication sharedApplication] stopModal];
}

- (void)removeLeastRecentlyPlayedCustomGamesMenuItem
{
    JbGameMenuItem* leastRecentMenuItem = (JbGameMenuItem*)[customGamesMenu itemAtIndex:FirstCustomGameEntry];
    JbGame* leastRecentGame = [mGames gameWithDescription:[leastRecentMenuItem gameDescription]];
    int leastRecentIndex = FirstCustomGameEntry;
    for (int i = FirstCustomGameEntry + 1; i < [customGamesMenu numberOfItems]; ++i)
    {
        JbGameMenuItem* menuItem = (JbGameMenuItem*)[customGamesMenu itemAtIndex:i];
        JbGame* game = [mGames gameWithDescription:[menuItem gameDescription]];

        if ([leastRecentGame isPlayedMoreRecentlyThan:game])
        {
            leastRecentMenuItem = menuItem;
            leastRecentGame = game;
            leastRecentIndex = i;
        }
    }
    [customGamesMenu removeItem:leastRecentMenuItem];

    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSMutableArray* array = [ud valueForKey:CustomGamesMenuKey];
    [array removeObjectAtIndex:leastRecentIndex - FirstCustomGameEntry];
    [ud setValue:array forKey:CustomGamesMenuKey];
}

- (void)startNewCustomGame:(JbCustomGameDialogController*)sender
{
    [[NSApplication sharedApplication] stopModal];

    JbGame* game = [mGames gameWithDescription:[sender gameDescription]];
    if (![game isCustomGame])
    {
        [self selectGame:[self menuItemForGame:game]];
        return;
    }

    NSMenuItem* menuItem = [customGamesMenu itemWithTitle:[game name]];
    if (!menuItem)
    {
        menuItem = [JbGameMenuItem menuItemWithTitle:[game name]
                                              action:@selector(selectGame:)
                                     gameDescription:[game description]];
        [menuItem setTag:CustomGamesMenuItem];
    }
    [self setTopCustomGameMenuItem:menuItem];
        
    [self selectGame:menuItem];
}

- (IBAction)showManual:(id)sender
{
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* filePath = [mainBundle pathForResource:@"UserManual" ofType:@"pdf"];
    if (filePath != nil)
    {
        NSLog(@"%s", sel_getName(_cmd));
        if (![[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath: filePath]])
        {
            NSAlert* alert = [[[NSAlert alloc] init] autorelease];
            alert.messageText = [NSString stringWithFormat:@"Unable to open %@.", filePath];
            [alert runModal];
        }
    }
    else
    {
        NSAlert* alert = [[[NSAlert alloc] init] autorelease];
        alert.messageText = @"Unable to open UserManual.pdf";
        [alert runModal];
    }
}

- (void)applicationDidHide:(NSNotification*)theNotification
{
    if ([[minefieldController isRunning] boolValue])
        [minefieldController pauseGame:self];
}

@end

NSString* JbJoinStrings(NSString* separator, NSArray* strings)
{
    size_t stringCount = [strings count];
    if (stringCount == 0)
        return @"";

    size_t size = [separator length] * (stringCount - 1);
    for (unsigned int index = 0; index < stringCount; index += 1)
    {
        NSString* string = [strings objectAtIndex:index];
        size += [string length];
    }

    NSMutableString* result = [NSMutableString stringWithCapacity:size];
    [result appendString:[strings objectAtIndex:0]];
    for (unsigned int index = 1; index < stringCount; index += 1)
    {
        [result appendString:separator];
        NSString* string = [strings objectAtIndex:index];
        [result appendString:string];
    }
    return result;
}
