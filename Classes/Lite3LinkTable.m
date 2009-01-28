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

#import "Lite3LinkTable.h"
#import "Lite3Table.h"
#import "Lite3DB.h"


@implementation Lite3LinkTable

@synthesize mainTable;
@synthesize secondaryClassName;
@synthesize secondaryTable;

-(id)initWithDb:(Lite3DB*)_db {
    if (![super init] ) {
        return nil;
    }
    db = _db;
    updateStmt = NULL;
    deleteForPrimaryStmt=NULL;
    return self;
}

-(void)prepareArguments {
    if ( arguments != nil ) {
        return;
    }
    Lite3Arg * primary = [[Lite3Arg alloc] init];
    primary.name = [[NSString alloc] initWithFormat: @"%@_id", [mainTable.className lowercaseString]];
    Lite3Arg * secondary = [[Lite3Arg alloc] init];
    secondary.name = [[NSString alloc] initWithFormat: @"%@_id",[secondaryTable.className lowercaseString]];
    arguments = [[NSMutableArray alloc] initWithObjects: primary, secondary ];
}

-(BOOL)compileStatements  {
    [self prepareArguments];
    NSString * tableName = [NSString stringWithFormat: @"%@_%@", mainTable.tableName, secondaryTable.tableName];
    return [db compileUpdateStatement: &updateStmt tableName: tableName arguments: arguments];
}

-(void)dealloc {
    if ( updateStmt != NULL) {
        sqlite3_finalize(updateStmt); updateStmt=NULL;
    }
    if( deleteForPrimaryStmt != NULL ) {
        sqlite3_finalize(deleteForPrimaryStmt); deleteForPrimaryStmt=NULL;
    }
    [arguments dealloc];
    [mainTable dealloc];
    [secondaryTable dealloc];
    [super dealloc];
}


@end
