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
@class Lite3LinkTable;




/**
 * Store the prepared statements for a given table.
 */
@interface Lite3Table : NSObject {
    Lite3DB * db;
    // precompiled update statement
    sqlite3_stmt * updateStmt;
    // precompiled count statement
    sqlite3_stmt * countStmt;
    // the table name
    NSString * tableName;
    // the name of the class being persisted in this table
    NSString * className;
    // lower case of the class name
    NSString * classNameLowerCase;
    // custom representation of the SQL arguments for faster processing
    NSArray * arguments;
}

@property(nonatomic,retain) NSString * tableName;
@property(nonatomic,retain,setter=setClassName:) NSString * className;
@property(nonatomic,retain) NSArray * arguments;

+ (Lite3Table*)lite3TableName:(NSString*)name withDb:(Lite3DB*)_db;
+ (Lite3Table*)lite3TableName:(NSString*)name withDb:(Lite3DB*)_db forClassName:(NSString*)_className;

/**
 * Check if the table mapped by this entity really exists.
 */
-(BOOL)tableExists;

/**
 * Return the link tabke for the given property.
 */
-(Lite3LinkTable*)linkTableFor:(NSString*)propertyName;

/**
 * Check to see if this object has been properly initialized.
 */
- (BOOL)isValid;

/**
 * Compile statements after the class is initialized. 
 * This is not required if passing in a class name to the factory method.
 * Probably better to do this automatically when setting the arguments.
 */
- (BOOL)compileStatements;

/**
 * Return the count of rows in the table.
 */
-(int)count;

/**
 * Update the table from the object or dictionary.
 */
- (int)update:(id)data;

/**
 * Update without setting up a transaction, one should be setup by the caller function.
 */
- (int)updateNoTransaction:(id)data;

/**
 * Update the table from all the elements in the array.
 * Allow some flexibility in the data to be able to import Ruby JSON (with or without an extra class wrapper)
 *   [
 *     { "class_name" : { id: 0, ...} },
 *     { "class_name" : { "id": 1, ...} }
 *   ]
 */
- (int)updateAll:(NSArray*)objects;

/**
 * Return a list of objects that match the optional selectClause.
 */
- (NSMutableArray*) select: (NSString*)selectClause;

/**
 * Select with limits.
 */
- (NSMutableArray*)select:(NSString *)whereClause start: (int)start count:(int)count;

/**
 * Select the first item that matches or nil.
 */
- (id)selectFirst: (NSString*)selectClause;

/**
 * Selects the second side of a many-to-many relationship.
 * In this release you have to pass a pool of objects to select from, the pool will contain the other side of the relationship.
 * The library may decide to track this information in a session/cache but for now the responsibility is on the user of the library.
 */
- (NSMutableArray*)selectLinks: (id) main forProperty: (NSString*)name fromPool:(NSArray*)pool;

/**
 * Delete all the objects in the database.
 */
- (void)truncate;
@end
