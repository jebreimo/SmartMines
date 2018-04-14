//  MinefieldView.mm
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

#import "MinefieldView.h"

struct JbSquareStruct
{
    BOOL isLowered;
    JbMinefieldSymbol symbol;
};

static void InitializeSquares(JbSquare* squares, size_t count);
static NSArray* StringTuple(NSString* str, NSColor* color);
static NSImageRep* GetImage(NSString* name);
static inline BOOL IsLessThanSize(JbTableIndex index, JbTableSize size)
{
    return index.row < size.rows && index.column < size.columns;
}

@implementation JbMinefieldView

+ (float)squareSizeForViewSize:(NSSize)viewSize
                 minefieldSize:(JbTableSize)minefieldSize
{
    float maxSquareHeight = viewSize.height / minefieldSize.rows;
    float maxSquareWidth = viewSize.width / minefieldSize.columns;
    return floor(MIN(maxSquareHeight, maxSquareWidth));
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        delegate = nil;
        mPressedMouseButton = JbNoMouseButton;
        mStrings = [[NSArray arrayWithObjects:StringTuple(@"1", [NSColor darkGrayColor]),
                                              StringTuple(@"2", [NSColor brownColor]),
                                              StringTuple(@"3", [NSColor purpleColor]),
                                              StringTuple(@"4", [NSColor magentaColor]),
                                              StringTuple(@"5", [NSColor yellowColor]),
                                              StringTuple(@"6", [NSColor orangeColor]),
                                              StringTuple(@"7", [NSColor redColor]),
                                              StringTuple(@"8", [NSColor blueColor]),
                                              StringTuple(@"M", [NSColor blackColor]),
                                              StringTuple(@"V", [NSColor blackColor]),
                                              StringTuple(@"?", [NSColor blackColor]),
                                              nil] retain];
        mBackgroundImage = JbNoBackgroundImage;
        mFlagImage = GetImage(@"Flag");
        mMineImage = GetImage(@"Mine");
        mTransparentMineImage = GetImage(@"TransparentMine");
        mDefeatImage = GetImage(@"SadMine");
        mVictoryImage = GetImage(@"HappyMine");
        mErrorColor = [[NSColor colorWithDeviceRed:1.0 green:0 blue:0 alpha:0.25] retain];
        mSquares = NULL;
        mUsesContentResizeIncrement = YES;
        mMinefieldSize = JbMakeTableSize(0, 0);
        [self setMinefieldSize:JbMakeTableSize(1, 1)];
        mCancelMode = JbOutsideSquareCancels;
        mIsEnabled = YES;
        mSelectedSquare = JbMakeTableIndex(UINT_MAX, UINT_MAX);
    }
    return self;
}

- (void)dealloc
{
    if (mSquares != NULL)
        free(mSquares);
    [mFlagImage dealloc];
    [mMineImage dealloc];
    [mTransparentMineImage dealloc];
    [mDefeatImage dealloc];
    [mVictoryImage dealloc];
    [super dealloc];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)setFont:(NSFont*)newFont
{
    for (unsigned int index = 0; index < [mStrings count]; index += 1)
    {
        NSArray* tuple = [mStrings objectAtIndex:index];
        NSMutableDictionary* attrs = [tuple objectAtIndex:1];
        [attrs setObject:newFont forKey:NSFontAttributeName];
    }
    [self setNeedsDisplay:YES];
}

- (JbTableSize)minefieldSize
{
    return mMinefieldSize;
}

- (void)setMinefieldSize:(JbTableSize)newMinefieldSize
{
    if (!JbEqualTableSizes(mMinefieldSize, newMinefieldSize))
    {
        if (mSquares != NULL)
            free(mSquares);
        mMinefieldSize = newMinefieldSize;
        mSquares =  (JbSquare**)JbAllocTable(mMinefieldSize.rows, mMinefieldSize.columns, sizeof(JbSquare));
    }
    
    InitializeSquares(&mSquares[0][0], mMinefieldSize.rows * mMinefieldSize.columns);

    [self setNeedsDisplay:YES];
    if (mUsesContentResizeIncrement)
        [[self window] setContentResizeIncrements:NSMakeSize((float)mMinefieldSize.columns, (float)mMinefieldSize.rows)];
    
    if (mSelectedSquare.row != UINT_MAX)
    {
        mSelectedSquare.row = mMinefieldSize.rows / 2;
        mSelectedSquare.column = mMinefieldSize.columns / 2;
    }
}

- (BOOL)usesContentResizeIncrement
{
    return mUsesContentResizeIncrement;
}

- (void)setUsesContentResizeIncrement:(BOOL)newUsesContentResizeIncrement
{
    if (mUsesContentResizeIncrement == newUsesContentResizeIncrement)
        return;
        
    mUsesContentResizeIncrement = newUsesContentResizeIncrement;
    if (mUsesContentResizeIncrement)
        [[self window] setContentResizeIncrements:NSMakeSize((float)mMinefieldSize.columns, (float)mMinefieldSize.rows)];
    else
        [[self window] setContentResizeIncrements:NSMakeSize(1.0, 1.0)];
}

- (void)clear
{
    [self setBackgroundImage:JbNoBackgroundImage];
    mIsEnabled = YES;
    [self setMinefieldSize:mMinefieldSize];
}

- (BOOL)mouseDownCanMoveWindow
{
    return NO;
}

- (void)computeSquareSize:(float*)squareSize
         horizontalOffset:(float*)horOffset
           verticalOffset:(float*)verOffset
{
    size_t rows = mMinefieldSize.rows, cols = mMinefieldSize.columns;
    NSRect bounds = [self bounds];
    *squareSize = [JbMinefieldView squareSizeForViewSize:bounds.size
                                           minefieldSize:mMinefieldSize];
    *horOffset = floor((bounds.size.width - cols * *squareSize) / 2.0);
    *verOffset = floor((bounds.size.height - rows * *squareSize) / 2.0);
}

- (JbTableIndex)minefieldIndexAtViewLocation:(NSPoint)location
{
    float squareSize, horOffset, verOffset;
    [self computeSquareSize:&squareSize
           horizontalOffset:&horOffset
             verticalOffset:&verOffset];
    return JbMakeTableIndex(floor((location.y - verOffset) / squareSize),
                            floor((location.x - horOffset) / squareSize));
}

- (NSRect)bestFitForImage:(NSImageRep*)image
{
    float squareSize, horOffset, verOffset;
    [self computeSquareSize:&squareSize
           horizontalOffset:&horOffset
             verticalOffset:&verOffset];
             
    NSRect viewRect = [self bounds];
    viewRect.origin.x += horOffset;
    viewRect.origin.y += verOffset;
    viewRect.size.width -= 2 * horOffset;
    viewRect.size.height -= 2 * verOffset;
    NSSize imgSize = [image size];
    float viewAspectRatio = viewRect.size.height / viewRect.size.width;
    float imgAspectRatio = imgSize.height / imgSize.width;
    NSRect imgRect;
    if (viewAspectRatio < imgAspectRatio)
    {
        imgRect.size.height = viewRect.size.height;
        imgRect.size.width = viewRect.size.height / imgAspectRatio;
        imgRect.origin.x = viewRect.origin.x + (viewRect.size.width - imgRect.size.width) / 2;
        imgRect.origin.y = viewRect.origin.y;
    }
    else
    {
        imgRect.size.width = viewRect.size.width;
        imgRect.size.height = viewRect.size.width * imgAspectRatio;
        imgRect.origin.x = viewRect.origin.x;
        imgRect.origin.y = viewRect.origin.y + (viewRect.size.height - imgRect.size.height) / 2;
    }
    return imgRect;
}

- (NSImageRep*)backgroundImage:(JbMinefieldBackgroundImage)imageType
{
    switch (imageType)
    {
    case JbVictoryBackgroundImage:
        return mVictoryImage;
    case JbDefeatBackgroundImage:
        return mDefeatImage;
    default:
        return nil;
    }
}

- (JbMinefieldBackgroundImage)backgroundImage
{
    return mBackgroundImage;
}

- (void)setBackgroundImage:(JbMinefieldBackgroundImage)newBackgroundImage
{
    if (newBackgroundImage == mBackgroundImage)
        return;
    if (mBackgroundImage != JbNoBackgroundImage)
    {
        NSImageRep* img = [self backgroundImage:mBackgroundImage];
        if (img)
            [self setNeedsDisplayInRect:[self bestFitForImage:img]];
    }
    if (newBackgroundImage != JbNoBackgroundImage)
    {
        NSImageRep* img = [self backgroundImage:newBackgroundImage];
        if (img)
            [self setNeedsDisplayInRect:[self bestFitForImage:img]];
    }
    mBackgroundImage = newBackgroundImage;
}

- (void)drawRaisedFrameInRect:(NSRect)rect thickness:(float)thickness
{
    rect.origin.x += thickness / 2.0;
    rect.origin.y += thickness / 2.0;
    rect.size.width -= thickness;
    rect.size.height -= thickness;

    NSBezierPath* path = [NSBezierPath bezierPath];
    [path setLineWidth:thickness];
    [path setLineCapStyle:NSRoundLineCapStyle];
    [path setLineJoinStyle:NSBevelLineJoinStyle];

    [[NSColor colorWithDeviceWhite:1.0 alpha:0.5] set];
    [path moveToPoint:rect.origin];
    [path lineToPoint:NSMakePoint(rect.origin.x, NSMaxY(rect))];
    [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
    [path stroke];
    
    [path removeAllPoints];
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.5] set];
    [path moveToPoint:rect.origin];
    [path lineToPoint:NSMakePoint(NSMaxX(rect), rect.origin.y)];
    [path lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
    [path stroke];
}

- (void)drawLoweredFrameInRect:(NSRect)rect
{
    float lineWidth = 0.1;
    rect.origin.x += 0.5;
    rect.origin.y += 0.5;
    rect.size.width -= 1;
    rect.size.height -= 1;

    NSBezierPath* path = [NSBezierPath bezierPath];
    [path setLineWidth:lineWidth];

    [[NSColor colorWithDeviceWhite:0.0 alpha:1] set];
    [path appendBezierPathWithRect:rect];
    [path stroke];
}

- (NSRect)computeOffsetsForImage:(NSImageRep*)image
                      squareSize:(float)squareSize
                  frameThickness:(float)thickness
{
    NSSize imgSize = [image size];
    float imgMaxDim = MAX(imgSize.width, imgSize.height);
    float imgSquareSize = squareSize - 2 * thickness;
    imgSize = NSMakeSize(imgSquareSize * imgSize.width / imgMaxDim,
                         imgSquareSize * imgSize.height / imgMaxDim);
    return NSMakeRect((squareSize - imgSize.width) / 2,
                      (squareSize - imgSize.height) / 2,
                      imgSize.width,
                      imgSize.height);
}

- (void)drawSymbol:(JbMinefieldSymbol)symbol inRect:(NSRect)rect
{
    assert(rect.size.width == rect.size.height);
    BOOL mine = NO, transparentMine = NO, flag = NO, text = NO, error = NO;
    int textIndex = 0;
    switch (symbol)
    {
    case JbMinefieldEmpty:
        break;
    case JbMinefieldExplosion:
        mine = error = YES;
        break;
    case JbMinefieldMark:
        flag = YES;
        break;
    case JbMinefieldMarkedMine:
        flag = transparentMine = YES;
        break;
    case JbMinefieldQuestionMarkedMine:
        text = transparentMine = YES;
        textIndex = JbMinefieldQuestionMark - 1;
        break;
    case JbMinefieldUnmarkedMine:
        transparentMine = YES;
        break;
    case JbMinefieldIncorrectMark:
        flag = error = YES;
        break;
    case JbMinefieldIncorrectQuestionMark:
        text = error = YES;
        textIndex = JbMinefieldQuestionMark - 1;
        break;
    default:
        text = YES;
        textIndex = symbol - 1;
        break;
    }
    if (error)
    {
        [mErrorColor setFill];
        [NSBezierPath fillRect:rect];
    }
    if (transparentMine)
    {
        NSRect imgRect = [self computeOffsetsForImage:mTransparentMineImage
                                           squareSize:rect.size.width
                                       frameThickness:1.0];
        imgRect.origin.x += rect.origin.x;
        imgRect.origin.y += rect.origin.y;
        [mTransparentMineImage drawInRect:imgRect];
    }
    if (text)
    {
        NSArray* tuple = [mStrings objectAtIndex:textIndex];
        NSString* text = [tuple objectAtIndex:0];
        NSDictionary* attrs = [tuple objectAtIndex:1];
        NSSize numberSize = [text sizeWithAttributes:attrs];
        float verTextOffset = (rect.size.width - numberSize.height) / 2.0;
        rect.size.height -= verTextOffset;
        [text drawInRect:rect withAttributes:attrs];
    }
    else if (flag)
    {
        NSRect imgRect = [self computeOffsetsForImage:mFlagImage
                                           squareSize:rect.size.width
                                       frameThickness:1.0];
        imgRect.origin.x += rect.origin.x;
        imgRect.origin.y += rect.origin.y;
        [mFlagImage drawInRect:imgRect];
    }
    else if (mine)
    {
        NSRect imgRect = [self computeOffsetsForImage:mMineImage
                                           squareSize:rect.size.width
                                       frameThickness:1.0];
        imgRect.origin.x += rect.origin.x;
        imgRect.origin.y += rect.origin.y;
        [mMineImage drawInRect:imgRect];
    }
}

- (void)drawBackgroundImage:(NSImageRep*)image
{
    NSRect imgRect = [self bestFitForImage:image];
    [image drawInRect:imgRect];
}

- (void)drawRect:(NSRect)rect
{
    float squareSize, horOffset, verOffset;
    [self computeSquareSize:&squareSize
           horizontalOffset:&horOffset
             verticalOffset:&verOffset];

    int row0 = floor((NSMinY(rect) - verOffset) / squareSize);
    int row1 = ceil((NSMaxY(rect) - verOffset) / squareSize);
    if (row0 < 0) row0 = 0;
    if (row1 > mMinefieldSize.rows) row1 = mMinefieldSize.rows;

    int col0 = floor((NSMinX(rect) - horOffset) / squareSize);
    int col1 = ceil((NSMaxX(rect) - horOffset) / squareSize);
    if (col0 < 0) col0 = 0;
    if (col1 > mMinefieldSize.columns) col1 = mMinefieldSize.columns;

    NSRect squareRect = NSMakeRect(horOffset + col0 * squareSize,
                                   verOffset + row0 * squareSize,
                                   squareSize, squareSize);
    float frameThickness = ceil(squareSize / 25.0);
    for (unsigned row = row0; row != row1; ++row)
    {
        for (unsigned col = col0; col != col1; ++col)
        {
            JbSquare* square = &mSquares[row][col];
            if (mIsEnabled && square->isLowered)
                [self drawLoweredFrameInRect:squareRect];
            else
                [self drawRaisedFrameInRect:squareRect thickness:frameThickness];
            if (mIsEnabled && square->symbol != JbMinefieldEmpty)
                [self drawSymbol:square->symbol inRect:NSMakeRect(
                                squareRect.origin.x + frameThickness,
                                squareRect.origin.y + frameThickness,
                                squareRect.size.width - 2 * frameThickness,
                                squareRect.size.height - 2 * frameThickness)];
            squareRect.origin.x += squareRect.size.width;
        }
        squareRect.origin.x = horOffset + col0 * squareSize;
        squareRect.origin.y += squareRect.size.height;
    }

    NSImageRep* img = [self backgroundImage:mBackgroundImage];
    if (img)
        [self drawBackgroundImage:img];
    
    if (mSelectedSquare.row >= row0 && mSelectedSquare.row < row1 &&
        mSelectedSquare.column >= col0 && mSelectedSquare.column < col1)
    {
        squareRect.origin.x = horOffset + mSelectedSquare.column * squareSize + frameThickness;
        squareRect.origin.y = verOffset + mSelectedSquare.row * squareSize + frameThickness;
        squareRect.size.width -= 2 * frameThickness;
        squareRect.size.height -= 2 * frameThickness;
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        [[NSBezierPath bezierPathWithRect: NSInsetRect(squareRect,3,3)] fill];
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (void)setNeedsDisplayAtIndex:(JbTableIndex)index
{
    float squareSize, horOffset, verOffset;
    [self computeSquareSize:&squareSize
           horizontalOffset:&horOffset
             verticalOffset:&verOffset];
    [self setNeedsDisplayInRect:NSMakeRect(horOffset + squareSize * index.column,
                                           verOffset + squareSize * index.row,
                                           squareSize, squareSize)];
}

- (BOOL)isLoweredAtIndex:(JbTableIndex)index
{
    NSAssert2(IsLessThanSize(index, mMinefieldSize), @"Row and/or column is out of range: %d, %d", index.row, index.column);
    return mSquares[index.row][index.column].isLowered;
}

- (void)setLowered:(BOOL)newLoweredAtIndex atIndex:(JbTableIndex)index
{
    NSAssert2(IsLessThanSize(index, mMinefieldSize), @"Row and/or column is out of range: %d, %d", index.row, index.column);
    if (mSquares[index.row][index.column].isLowered == newLoweredAtIndex)
        return;
    
    mSquares[index.row][index.column].isLowered = newLoweredAtIndex;
    [self setNeedsDisplayAtIndex:index];
}

- (JbMinefieldSymbol)symbolAtIndex:(JbTableIndex)index
{
    NSAssert2(IsLessThanSize(index, mMinefieldSize), @"Row and/or column is out of range: %d, %d", index.row, index.column);
    return JbMinefieldEmpty;
}

- (void)setSymbol:(JbMinefieldSymbol)symbol atIndex:(JbTableIndex)index
{
    NSAssert2(IsLessThanSize(index, mMinefieldSize), @"Row and/or column is out of range: %d, %d", index.row, index.column);
    assert(symbol >= JbMinefieldEmpty && symbol <= JbMinefieldIncorrectQuestionMark);

    JbSquare* square = &mSquares[index.row][index.column];
    square->symbol = symbol;
    
    [self setNeedsDisplayAtIndex:index];
}

- (void)setFrame:(NSRect)rect
{
    float squareSize = [JbMinefieldView squareSizeForViewSize:rect.size
                                                minefieldSize:mMinefieldSize];
    float fontSize = squareSize * 3.0 / 5.0;
    [self setFont:[NSFont fontWithName:@"Helvetica" size:fontSize]];
    [super setFrame:rect];
}

- (JbCancelMode)cancelMode
{
    return mCancelMode;
}

- (void)setCancelMode:(JbCancelMode)newCancelMode
{
    mCancelMode = newCancelMode;
}

- (BOOL)isEnabled
{
    return mIsEnabled;
}

- (void)setEnabled:(BOOL)newIsEnabled
{
    if (newIsEnabled == mIsEnabled)
        return;
    mIsEnabled = newIsEnabled;
    [self setNeedsDisplayInRect:[self bounds]];

    if (mIsEnabled || mPressedMouseButton == JbNoMouseButton)
        return;
    else if (mPressedMouseButton == JbLeftMouseButton &&
             [delegate respondsToSelector:@selector(cancelMouseDownInView:atIndex:)])
    {
        [delegate cancelMouseDownInView:self atIndex:mPressedSquare];
        mPressedMouseButton = JbNoMouseButton;
    }
    else if (mPressedMouseButton == JbRightMouseButton &&
             [delegate respondsToSelector:@selector(cancelRightMouseDownInView:atIndex:)])
    {
        [delegate cancelRightMouseDownInView:self atIndex:mPressedSquare];
        mPressedMouseButton = JbNoMouseButton;
    }
}

- (BOOL)showsKeyboardCursor
{
    return mSelectedSquare.row != UINT_MAX;
}

- (void)setShowKeyboardCursor:(BOOL)value
{
    if (value && ![self showsKeyboardCursor])
    {
        mSelectedSquare.row = mMinefieldSize.rows / 2;
        mSelectedSquare.column = mMinefieldSize.columns / 2;
        [self setNeedsDisplayAtIndex:mSelectedSquare];
    }
    else if (!value && [self showsKeyboardCursor])
    {
        [self setNeedsDisplayAtIndex:mSelectedSquare];
        mSelectedSquare.row = mSelectedSquare.column = UINT_MAX;
    }
}

/** @note Since this function notifies the delegate, it should only be
          called when keyboard mode is initiated by a pressed key.
*/
- (void)activateKeyboardCursor
{
    mSelectedSquare.row = mMinefieldSize.rows / 2;
    mSelectedSquare.column = mMinefieldSize.columns / 2;
    if ([delegate respondsToSelector:@selector(showsKeyboardCursorChangedInView:)])
        [delegate showsKeyboardCursorChangedInView:self];
}

#pragma mark Mouse handling

- (BOOL)processMouseButton:(JbMouseButton)button down:(NSEvent*)theEvent
{
    if (mPressedMouseButton != JbNoMouseButton)
        return NO;

    NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    mPressedSquare = [self minefieldIndexAtViewLocation:loc];
    if (!IsLessThanSize(mPressedSquare, mMinefieldSize))
        return NO;

    mIsCommittable = YES;
    mPressedMouseButton = button;
    return YES;
}

- (void)rightMouseDown:(NSEvent*)theEvent
{
    if (![self processMouseButton:JbRightMouseButton down:theEvent])
        return;
    if ([delegate respondsToSelector:@selector(beginRightMouseDownInView:atIndex:)])
        [delegate beginRightMouseDownInView:self atIndex:mPressedSquare];
}

- (void)mouseDown:(NSEvent*)theEvent
{
    mIsControlClicking = ([theEvent modifierFlags] & NSEventModifierFlagControl) == NSEventModifierFlagControl;
    if (mIsControlClicking)
        [self rightMouseDown:theEvent];

    if (![self processMouseButton:JbLeftMouseButton down:theEvent])
        return;
    if ([delegate respondsToSelector:@selector(beginMouseDownInView:atIndex:)])
        [delegate beginMouseDownInView:self atIndex:mPressedSquare];
}

- (BOOL)processMouseButton:(JbMouseButton)button dragged:(NSEvent*)theEvent
{
    if (mPressedMouseButton != button)
        return NO;

    NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    JbTableIndex index = [self minefieldIndexAtViewLocation:loc];

    if (mCancelMode == JbOutsideSquareCancels)
    {
        if (mIsCommittable && !JbEqualTableIndexes(index, mPressedSquare))
        {
            mIsCommittable = NO;
            return YES;
        }
        else if (!mIsCommittable && JbEqualTableIndexes(index, mPressedSquare))
        {
            mIsCommittable = YES;
            return YES;
        }
    }
    else
    {
        if (mIsCommittable && !IsLessThanSize(index, mMinefieldSize))
        {
            mIsCommittable = NO;
            return YES;
        }
        else if (!mIsCommittable && IsLessThanSize(index, mMinefieldSize))
        {
            mIsCommittable = YES;
            return YES;
        }
    }
    return NO;
}

- (void)rightMouseDragged:(NSEvent*)theEvent
{
    if (![self processMouseButton:JbRightMouseButton dragged:theEvent])
        return;

    if (mIsCommittable && [delegate respondsToSelector:@selector(beginRightMouseDownInView:atIndex:)])
        [delegate beginRightMouseDownInView:self atIndex:mPressedSquare];
    else if ([delegate respondsToSelector:@selector(cancelRightMouseDownInView:atIndex:)])
        [delegate cancelRightMouseDownInView:self atIndex:mPressedSquare];
}

- (void)mouseDragged:(NSEvent*)theEvent
{
    if (mIsControlClicking)
        [self rightMouseDragged:theEvent];

    if (![self processMouseButton:JbLeftMouseButton dragged:theEvent])
        return;
    if (mIsCommittable && [delegate respondsToSelector:@selector(beginMouseDownInView:atIndex:)])
        [delegate beginMouseDownInView:self atIndex:mPressedSquare];
    else if ([delegate respondsToSelector:@selector(cancelMouseDownInView:atIndex:)])
        [delegate cancelMouseDownInView:self atIndex:mPressedSquare];
}

- (BOOL)processMouseButton:(JbMouseButton)button up:(NSEvent*)theEvent
{
    if (button != mPressedMouseButton)
        return NO;

    mPressedMouseButton = JbNoMouseButton;
    NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    JbTableIndex index = [self minefieldIndexAtViewLocation:loc];
    if (mCancelMode == JbOutsideSquareCancels && !JbEqualTableIndexes(index, mPressedSquare))
        return NO;
    else if (mCancelMode == JbOutsideMinefieldCancels && !IsLessThanSize(index, mMinefieldSize))
        return NO;

    return YES;
}

- (void)rightMouseUp:(NSEvent*)theEvent
{
    if (![self processMouseButton:JbRightMouseButton up:theEvent])
        return;

    if ([delegate respondsToSelector:@selector(commitRightMouseDownInView:atIndex:)])
        [delegate commitRightMouseDownInView:self atIndex:mPressedSquare];
}

- (void)mouseUp:(NSEvent*)theEvent
{
    if (mIsControlClicking)
        [self rightMouseUp:theEvent];

    if (![self processMouseButton:JbLeftMouseButton up:theEvent])
        return;
    if ([delegate respondsToSelector:@selector(commitMouseDownInView:atIndex:)])
        [delegate commitMouseDownInView:self atIndex:mPressedSquare];
}

#pragma mark Keyboard handling

- (void)moveDown:(id)theSender
{
    if (mSelectedSquare.row == UINT_MAX)
        [self activateKeyboardCursor];
    else
    {
        [self setNeedsDisplayAtIndex:mSelectedSquare];
        mSelectedSquare.row = MIN(mSelectedSquare.row - 1, mMinefieldSize.rows - 1);
    }
    [self setNeedsDisplayAtIndex:mSelectedSquare];
}

- (void)moveLeft:(id)theSender
{
    if (mSelectedSquare.row == UINT_MAX)
        [self activateKeyboardCursor];
    else
    {
        [self setNeedsDisplayAtIndex:mSelectedSquare];
        mSelectedSquare.column = MIN(mSelectedSquare.column - 1, mMinefieldSize.columns - 1);
    }
    [self setNeedsDisplayAtIndex:mSelectedSquare];
}

- (void)moveRight:(id)theSender
{
    if (mSelectedSquare.row == UINT_MAX)
        [self activateKeyboardCursor];
    else
    {
        [self setNeedsDisplayAtIndex:mSelectedSquare];
        if (++mSelectedSquare.column == mMinefieldSize.columns)
            mSelectedSquare.column = 0;
    }
    [self setNeedsDisplayAtIndex:mSelectedSquare];
}

- (void)moveUp:(id)theSender
{
    if (mSelectedSquare.row == UINT_MAX)
        [self activateKeyboardCursor];
    else
    {
        [self setNeedsDisplayAtIndex:mSelectedSquare];
        if (++mSelectedSquare.row == mMinefieldSize.rows)
            mSelectedSquare.row = 0;
    }
    [self setNeedsDisplayAtIndex:mSelectedSquare];
}

- (void)insertNewline:(id)sender
{
    if (mSelectedSquare.row == UINT_MAX)
        [self activateKeyboardCursor];

    if ([delegate respondsToSelector:@selector(commitRightMouseDownInView:atIndex:)]
     && [delegate respondsToSelector:@selector(beginRightMouseDownInView:atIndex:)])
     {
        [delegate beginRightMouseDownInView:self atIndex:mSelectedSquare];
        [delegate commitRightMouseDownInView:self atIndex:mSelectedSquare];
    }
}

- (void)insertSpace:(id)sender
{
    if (mSelectedSquare.row == UINT_MAX)
        [self activateKeyboardCursor];

    if ([delegate respondsToSelector:@selector(commitMouseDownInView:atIndex:)]
     && [delegate respondsToSelector:@selector(beginMouseDownInView:atIndex:)])
     {
        [delegate beginMouseDownInView:self atIndex:mSelectedSquare];
        [delegate commitMouseDownInView:self atIndex:mSelectedSquare];
    }
        
}

- (void)cancelOperation:(id)sender
{
    if (mSelectedSquare.row != UINT_MAX)
    {
        [self setNeedsDisplayAtIndex:mSelectedSquare];
        mSelectedSquare.row = mSelectedSquare.column = UINT_MAX;
        if ([delegate respondsToSelector:@selector(showsKeyboardCursorChangedInView:)])
            [delegate showsKeyboardCursorChangedInView:self];
    }
}

- (void)keyDown:(NSEvent*)theEvent
{
    switch([[theEvent characters] characterAtIndex:0])
    {
    case 0x0D: [self insertNewline:self]; break;
    case 0x1B: [self cancelOperation:self]; break;
    case 0x1C: [self moveRight:self]; break;
    case 0x1D: [self moveLeft:self]; break;
    case 0x1E: [self moveUp:self]; break;
    case 0x1F: [self moveDown:self]; break;
    case 0x20: [self insertSpace:self]; break;
    default:
        {
            NSResponder* nextResponder = [self nextResponder];
            if (nextResponder != nil)
                [nextResponder keyDown:theEvent];
            else
                [self noResponderFor:@selector(keyDown:)];
        }
        break;
    }
}

@end

static void InitializeSquares(JbSquare* squares, size_t count)
{
    for (size_t i = 0; i != count; ++i)
    {
        squares[i].isLowered = NO;
        squares[i].symbol = JbMinefieldEmpty;
    }
}

static NSArray* StringTuple(NSString* str, NSColor* color)
{
    NSMutableParagraphStyle* paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
    [paragraphStyle setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    NSArray* objs = [NSArray arrayWithObjects:color, paragraphStyle, nil];
    NSArray* keys = [NSArray arrayWithObjects:NSForegroundColorAttributeName,
                                              NSParagraphStyleAttributeName,
                                              nil];
    return [NSArray arrayWithObjects:str, [NSMutableDictionary dictionaryWithObjects:objs forKeys:keys], nil];
}

static NSImageRep* GetImage(NSString* name)
{
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* path = [mainBundle pathForImageResource:name];
    if (path != nil)
        return [[NSImageRep imageRepWithContentsOfFile:path] retain];
    else
        return nil;
}
