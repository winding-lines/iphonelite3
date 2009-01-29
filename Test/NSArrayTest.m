/*
 Copyright (c) 2009 copyright@de-co-de.com
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */
#import "GTMSenTestCase.h"
#import "GTMUnitTestDevLog.h"

/***********
 * These are not really tests of the framework but more tests of my understanding of the framework.
 ***********/

@interface NSArrayTest : SenTestCase {
    
}
@end

@implementation NSArrayTest

- (void) testStringIsEqual {
    NSString * one = [NSString stringWithFormat: @"he%@", @"lo"];
    NSString * two = @"hello";
    STAssertFalse ( [one isEqual: two], @"String isEqual fails %@", one );
}

- (void) testContains {
    NSArray * array = [NSArray arrayWithObjects: [NSMutableString stringWithFormat: @"he%@", @"lo"], [NSString stringWithCString: "world"], nil];
    STAssertFalse( [array containsObject: [NSString stringWithCString:"hello"]], @"Array contains does not work for strings", nil );
}

@end
