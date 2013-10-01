//
//  MinefieldView.h
//
//  Created by Jan Erik Breimo on 02.01.07.
//  Copyright 2007 Jan Erik Breimo. All rights reserved.
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
#import "Table.h"

typedef struct JbSquareStruct JbSquare;

typedef enum
{
    JbNoMouseButton,
    JbLeftMouseButton,
    JbRightMouseButton
} JbMouseButton;

typedef enum
{
    JbMinefieldEmpty = 0,
    JbMinefield1 = 1,
    JbMinefield2 = 2,
    JbMinefield3 = 3,
    JbMinefield4 = 4,
    JbMinefield5 = 5,
    JbMinefield6 = 6,
    JbMinefield7 = 7,
    JbMinefield8 = 8,
    JbMinefieldExplosion,
    JbMinefieldMark,
    JbMinefieldQuestionMark,
    JbMinefieldMarkedMine,
    JbMinefieldQuestionMarkedMine,
    JbMinefieldUnmarkedMine,
    JbMinefieldIncorrectMark,
    JbMinefieldIncorrectQuestionMark,
} JbMinefieldSymbol;

typedef enum
{
    JbNoBackgroundImage,
    JbVictoryBackgroundImage,
    JbDefeatBackgroundImage
} JbMinefieldBackgroundImage;

typedef enum
{
    JbOutsideSquareCancels,
    JbOutsideMinefieldCancels
} JbCancelMode;

@interface JbMinefieldView : NSView
{
@private
    JbTableSize mMinefieldSize;
    JbSquare** mSquares;
    IBOutlet id delegate;
    JbTableIndex mSelectedSquare;
    JbTableIndex mPressedSquare;
    BOOL mIsCommittable;
    BOOL mIsControlClicking;
    JbMouseButton mPressedMouseButton;
    JbMinefieldBackgroundImage mBackgroundImage;
    NSArray* mStrings;
    NSImageRep* mFlagImage;
    NSImageRep* mMineImage;
    NSImageRep* mTransparentMineImage;
    NSImageRep* mDefeatImage;
    NSImageRep* mVictoryImage;
    NSColor* mErrorColor;
    BOOL mUsesContentResizeIncrement;
    JbCancelMode mCancelMode;
    BOOL mIsEnabled;
}
+ (float)squareSizeForViewSize:(NSSize)viewSize
                 minefieldSize:(JbTableSize)minefieldSize;
- (void)setFont:(NSFont*)newFont;
- (JbTableSize)minefieldSize;
- (void)setMinefieldSize:(JbTableSize)newMinefieldSize;

- (BOOL)usesContentResizeIncrement;
- (void)setUsesContentResizeIncrement:(BOOL)newUsesContentResizeIncrement;

- (void)clear;

- (JbMinefieldBackgroundImage)backgroundImage;
- (void)setBackgroundImage:(JbMinefieldBackgroundImage)newBackgroundImage;

- (BOOL)isLoweredAtIndex:(JbTableIndex)index;
- (void)setLowered:(BOOL)newLoweredAtIndex atIndex:(JbTableIndex)index;

- (JbMinefieldSymbol)symbolAtIndex:(JbTableIndex)index;
- (void)setSymbol:(JbMinefieldSymbol)symbol atIndex:(JbTableIndex)index;

- (JbCancelMode)cancelMode;
- (void)setCancelMode:(JbCancelMode)newCancelMode;

- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)newIsEnabled;

- (BOOL)showsKeyboardCursor;
- (void)setShowKeyboardCursor:(BOOL)value;

@end

@interface NSObject(JbMinefieldViewDelegate)
- (void)beginMouseDownInView:(JbMinefieldView*)view atIndex:(JbTableIndex)index;
- (void)cancelMouseDownInView:(JbMinefieldView*)view atIndex:(JbTableIndex)index;
- (void)commitMouseDownInView:(JbMinefieldView*)view atIndex:(JbTableIndex)index;
- (void)beginRightMouseDownInView:(JbMinefieldView*)view atIndex:(JbTableIndex)index;
- (void)cancelRightMouseDownInView:(JbMinefieldView*)view atIndex:(JbTableIndex)index;
- (void)commitRightMouseDownInView:(JbMinefieldView*)view atIndex:(JbTableIndex)index;
- (void)showsKeyboardCursorChangedInView:(JbMinefieldView*)view;
@end
