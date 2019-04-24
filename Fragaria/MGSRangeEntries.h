/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/Foundation.h>

// an ordered, nonoverlapping set of NSRanges and related value
typedef struct MGSRangeEntries MGSRangeEntries;

typedef struct {
   MGSRangeEntries *self;
   NSUInteger      index;
} MGSRangeEnumerator;

FOUNDATION_EXPORT MGSRangeEntries *MGSCreateRangeToCopiedObjectEntries(NSUInteger capacity);

FOUNDATION_EXPORT void MGSFreeRangeEntries(MGSRangeEntries *self);
FOUNDATION_EXPORT void  MGSResetRangeEntries(MGSRangeEntries *self);
FOUNDATION_EXPORT NSUInteger MGSCountRangeEntries(MGSRangeEntries *self);
FOUNDATION_EXPORT void MGSRangeEntriesRemoveEntryAtIndex(MGSRangeEntries *self,NSUInteger index);

FOUNDATION_EXPORT void  MGSRangeEntryInsert(MGSRangeEntries *self,NSRange range,id value);
FOUNDATION_EXPORT id MGSRangeEntryAtIndex(MGSRangeEntries *self,NSUInteger index,NSRange *effectiveRange);
FOUNDATION_EXPORT id MGSRangeEntryAtRange(MGSRangeEntries *self,NSRange range);

FOUNDATION_EXPORT MGSRangeEnumerator MGSRangeEntryEnumerator(MGSRangeEntries *self);
FOUNDATION_EXPORT BOOL MGSNextRangeEnumeratorEntry(MGSRangeEnumerator *state,NSRange *rangep, id *value);

FOUNDATION_EXPORT void MGSRangeEntriesExpandAndWipe(MGSRangeEntries *self,NSRange range,NSInteger delta);
FOUNDATION_EXPORT void MGSRangeEntriesDivideAndConquer(MGSRangeEntries *self,NSRange range);
FOUNDATION_EXPORT void MGSRangeEntriesDump(MGSRangeEntries *self);
FOUNDATION_EXPORT void MGSRangeEntriesVerify(MGSRangeEntries *self,NSUInteger length);
