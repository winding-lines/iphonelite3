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

#import <sqlite3.h>
#import "Lite3DB.h"
#import "Lite3Table.h"
#import "Lite3LinkTable.h"



@implementation Lite3DB

@synthesize dbHandle;
@synthesize dbPath;

/**
 * Check to see if there is a sqlite error code and returns if so.
 */
-(BOOL)checkError: (int) rc  {
    if ( rc != SQLITE_DONE && rc != SQLITE_OK && rc!= SQLITE_ROW ) {     
        const char * error = sqlite3_errmsg( dbHandle );
        NSLog( @"Db error %s",  error );
        return FALSE;
    }    
    return TRUE;
}

/**
 * Format the date in the UTC timezone and in a format that will be properly decoded by Ruby On Rails and other backend frameworks.
 */
+(NSString *)formatDateUTC:(NSDate *)localDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
	[dateFormatter setTimeZone:timeZone];
	[dateFormatter setDateFormat:@"yyyy-MM-ddTHH:mm:ssZ"];
	NSString *dateString = [dateFormatter stringFromDate:localDate];
    [dateFormatter release];
    return dateString;
}

/**
 * Copy the database file from the bundle, if it exists, to the work folder.
 * 
 */
+ (NSString *)pathToDB: (NSString*) dbName  {
    NSString *bundleDB = [[NSBundle mainBundle] pathForResource:dbName ofType:@"db"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *appSupportDir = [paths objectAtIndex:0];
    NSString *dbNameDir = [NSString stringWithFormat:@"%@/%@", appSupportDir, dbName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL dirExists = [fileManager fileExistsAtPath:dbNameDir isDirectory:&isDir];
    NSString *dbPath = [NSString stringWithFormat:@"%@/%@.db", dbNameDir, dbName];
    if(dirExists && isDir) {
        BOOL dbExists = [fileManager fileExistsAtPath:dbPath];
        if(!dbExists) {
            NSError *error = nil;
            BOOL success = [fileManager copyItemAtPath:bundleDB toPath:dbPath error:&error];
            if(!success) {
                NSLog(@"error = %@", error);
            }
        }
    } else if(!dirExists) {
        NSError *error = nil;
        BOOL success =[fileManager createDirectoryAtPath:dbNameDir withIntermediateDirectories: YES  attributes:nil error: NULL];
        if(!success) {
            NSLog(@"failed to create dir %@", dbNameDir);
        }
        success = [fileManager copyItemAtPath:bundleDB toPath:dbPath error:&error];
        if(!success) {
            NSLog(@"error = %@", error);
        }
    }
    return dbPath;
}

/**
 * Simple callback that optionally adds the first column to an array.
 */
int listTablesCallback(void *helperP, int columnCount, char **values, char **columnNames) {
    if ( helperP == NULL ) {
        return 0;
    }
    [((NSMutableArray*)helperP) addObject: [[NSString alloc] initWithCString: values[0]]];
    return 0;
    
}


- (id)initWithDbName: (NSString*)name andSql: (NSString*)ddl {
    dbHandle = NULL;
    self.dbPath = [Lite3DB  pathToDB: name];
    int rc = sqlite3_open([dbPath UTF8String], &dbHandle);
    if ( ![self checkError: rc] ) {
        if ( dbHandle != NULL ) {
            sqlite3_close(dbHandle);
            dbHandle = NULL;
        }
        return nil;
    }
    [self listTables];
    if ( [tableNames count] == 0 && ddl != nil ) {
        [tableNames release];
        tableNames = nil;
        char * zErrMsg = NULL;
        int rc = sqlite3_exec(dbHandle,[ddl UTF8String ], 
                              listTablesCallback, NULL, &zErrMsg);
        [self checkError: rc];
    }
    return self;
    
}


- (NSArray*) listTables {
    if ( tableNames != nil ) {
        return tableNames;
    }
    tableNames = [[NSMutableArray alloc] init];
    char * zErrMsg = NULL;
    int rc = sqlite3_exec(dbHandle, "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name", 
                          listTablesCallback, (void*)tableNames, &zErrMsg);
    [self checkError: rc];
    if ( zErrMsg != NULL ) {
        sqlite3_free(zErrMsg);
    }
    return tableNames;
                
}


- (BOOL)startTransaction {
    int rc = sqlite3_exec(dbHandle, "BEGIN TRANSACTION;", 0, 0, 0);
    return [self checkError: rc];    
}

- (BOOL)endTransaction {
    int rc = sqlite3_exec(dbHandle, "END TRANSACTION;", 0, 0, 0);
    return [self checkError: rc];    
}

- (void)addLite3Table:(Lite3Table*)table {
    if ( tableDictionary == nil ) {
        tableDictionary = [[NSMutableDictionary alloc] init];
    }
    if( [tableDictionary objectForKey: table.className] == nil ) {
        [tableDictionary setObject:table forKey:table.className];
    }
}

- (BOOL)checkConsistency {
    if ( [tableDictionary count] == 0 ) {
        // no tables in the db
        return FALSE;
    }
    NSString * className;
    for( className in tableDictionary ) {
        NSLog( @"className %@", className );
        Lite3Table * table = [tableDictionary objectForKey:className];
        if ( table.linkedTables != nil ) {
            Lite3LinkTable * linked;
            for( linked in table.linkedTables ) {
                linked.mainTable = table;
                linked.secondaryTable = [tableDictionary objectForKey:linked.secondaryClassName];
                if( linked.secondaryTable == nil ) {
                    NSLog( @"Bad linked table %@ in primary table %@", linked.secondaryClassName, className );
                    return FALSE;
                }
            }
        }
    }
    return TRUE;
}


- (void)dealloc {
    [tableDictionary release];
    [tableNames release];
    [dbPath release];
    if ( dbHandle != NULL ) { 
        sqlite3_close(dbHandle);
    }
    [super dealloc];
}
@end
