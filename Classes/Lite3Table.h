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
#import <objc/runtime.h>
@class Lite3DB;

#define _LITE3_INT 1
#define _LITE3_DOUBLE 2
#define _LITE3_STRING 3
#define _LITE3_TIMESTAMP 4

@interface Lite3Arg: NSObject {
    NSString * name;
    int preparedType;
    Ivar ivar;
}
@property(nonatomic,retain) NSString * name;
@property(nonatomic) int preparedType;
@property(nonatomic) Ivar ivar;

+ (Lite3Arg*)lite3ArgWithName: (NSString*) _name class: cls andType:(int) _preparedType;

@end



/**
 * Store the prepared statements for a given table.
 */
@interface Lite3Table : NSObject {
    Lite3DB * db;
    // precompiled update statement
    sqlite3_stmt * updateStmt;
    // the table name
    NSString * tableName;
    // the name of the class being persisted in this table
    NSString * className;
    // custom representation of the SQL arguments for faster processing
    NSArray * arguments;
    // list of linked tables for many-to-many relationships
    NSArray * linkedTables;
}

@property(nonatomic,retain) NSString * tableName;
@property(nonatomic,retain) NSString * className;
@property(nonatomic,retain) NSArray * arguments;
@property(nonatomic,retain) NSArray * linkedTables;

+ (Lite3Table*)lite3TableName:(NSString*)name withDb:(Lite3DB*)_db forClassName:(NSString*)clsName;

/**
 * Update the database from the object or  dictionary.
 */
- (int)update:(id)data;

/**
 * Return a list of objects that match the optional selectClause.
 */
- (NSMutableArray*) select: (NSString*)selectClause;

/**
 * Delete all the objects in the database.
 */
- (void)truncate;
@end
