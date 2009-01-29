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
#import <sqlite3.h>

@class Lite3DB;
@class Lite3Table;


/**
 * Store information about a table that backs a many-to-many relationship.
 */
@interface Lite3LinkTable : NSObject {
    Lite3DB * db;
    
    // Provide functionality on the link table itself
    Lite3Table *ownTable;
    // link to the main table, one side of the many-to-many relationship
    Lite3Table * primaryTable;
    
    // name of the class for the other side of the relationship
    NSString * secondaryClassName;
    // link to the second table (only linked after all the tables have been read in)
    Lite3Table * secondaryTable;
    // precompiled delete statement for a given primary class id
    sqlite3_stmt * deleteForPrimaryStmt;
    
    NSArray * arguments;
}

@property (nonatomic,retain) Lite3Table * ownTable;
@property (nonatomic,retain) Lite3Table * primaryTable;
@property (nonatomic,retain) NSString * secondaryClassName;
@property (nonatomic,retain) Lite3Table * secondaryTable;

-(id)initWithDb:(Lite3DB*) _db;
-(BOOL)compileStatements;


@end
