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

#import <Foundation/Foundation.h>
#import <objc/runtime.h>


#define _LITE3_INT 1
#define _LITE3_DOUBLE 2
#define _LITE3_STRING 3
#define _LITE3_TIMESTAMP 4
#define _LITE3_LINK 5

@class Lite3LinkTable;

@interface Lite3Arg: NSObject {
    NSString * name;
    NSString * className;
    int preparedType;
    Ivar ivar;
    Lite3LinkTable * link;
}

@property(nonatomic,retain) NSString * name;
@property(nonatomic) int preparedType;
@property(nonatomic) Ivar ivar;
@property(nonatomic,retain) Lite3LinkTable * link;

+ (Lite3Arg*)lite3ArgWithName: (NSString*) _name class: cls andType:(int) _preparedType;

+(Lite3Arg*)findByClass: (NSString*)_clsName inArray: (NSArray*)arguments;

+(Lite3Arg*)findByName: (NSString*)name inArray: (NSArray*)arguments;

@end

