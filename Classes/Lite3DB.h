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

@class Lite3Table;


@interface Lite3DB : NSObject {
    // a pointer to the sqlite3 database
    sqlite3 * dbHandle;
    NSString * dbPath;
    // names of the tables in this db
    NSArray * tableNames;
    // a registry of the enhanced tables in this db
    NSMutableDictionary * tableDictionary;
}

@property (nonatomic) sqlite3 * dbHandle;
@property (nonatomic, retain) NSString * dbPath;

- (id)initWithDbName: (NSString*)name andSql: (NSString*)sql;

- (void)addLite3Table: (Lite3Table*)table;

- (BOOL)checkConsistency;

- (NSArray*) listTables;

/**
 * Check if the error code indicates an error and log it if so.
 */
- (BOOL)checkError: (int) rc;

/**
 * Format the date.
 */
+(NSString *)formatDateUTC:(NSDate *)localDate;

/**
 */
- (BOOL)startTransaction;

/**
 */
- (BOOL)endTransaction;

-(BOOL)compileUpdateStatement:(sqlite3_stmt**)stmt_p tableName: (NSString*)tableName arguments: (NSArray*)arguments;

-(BOOL)compileCountStatement:(sqlite3_stmt**)stmt_p tableName: (NSString*)tableName;

@end
