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


/**
 * Define the naming conventions used by the code.
 * Can be changed to adapt to a different set of conventions.
 */
@interface Lite3LinkTable(NamingConventions)

/**
 * Compute the table name for the link table (ruby on rails convention)
 * - sort the table names alphabetically
 * - join them with '_'
 * 
 */
- (NSString*) computeLinkTableName;

/**
 * Compute the property name to look for the array of IDs in the incoming data.
 */
- (NSString*) computePropertyName;
@end

@implementation Lite3LinkTable

@synthesize ownTable;
@synthesize primaryTable;
@synthesize secondaryClassName;
@synthesize secondaryTable;

-(id)initWithDb:(Lite3DB*)_db {
    if (![super init] ) {
        return nil;
    }
    db = _db;
    deleteForPrimaryStmt=NULL;
    return self;
}

-(void)prepareArguments {
    if ( arguments != nil ) {
        return;
    }
    Lite3Arg * primary = [[Lite3Arg alloc] init];
    primary.name = [NSString stringWithFormat: @"%@_id", [primaryTable.className lowercaseString]];
    Lite3Arg * secondary = [[Lite3Arg alloc] init];
    secondary.name = [NSString stringWithFormat: @"%@_id",[secondaryTable.className lowercaseString]];
    arguments = [[NSArray alloc] initWithObjects: primary, secondary, nil ];
    [primary release];
    [secondary release];
}

-(BOOL)compileStatements  {
    [self prepareArguments];
    ownTable = [Lite3Table lite3TableName:[self computeLinkTableName] withDb:db];
    ownTable.arguments = arguments;
    return [ownTable compileStatements];
}

-(void)dealloc {
    [ownTable release];
    if( deleteForPrimaryStmt != NULL ) {
        sqlite3_finalize(deleteForPrimaryStmt); deleteForPrimaryStmt=NULL;
    }
    [arguments release];
    [primaryTable release];
    [secondaryTable release];
    [ownTable release];
    [super dealloc];
}

-(int)update: (id)data {
    NSArray * secondaryIds = [data objectForKey: [self computePropertyName]];
    NSString * _id = [data objectForKey: @"id"];
    if ( secondaryIds == nil  || _id == nil ) {
        return 0;
    }
    NSMutableDictionary * entry = [[NSMutableDictionary alloc] init];
    [entry setObject: _id forKey: ((Lite3Arg*)[arguments objectAtIndex: 0]).name];
    for( NSString  * secondaryId in secondaryIds ) {
        [entry setObject:secondaryId forKey:((Lite3Arg*)[arguments objectAtIndex:1]).name];
    }
    [entry release];
    return 0;
}

#pragma mark "-- NamingConventions --"
- (NSString*) computeLinkTableName {
    if ( [primaryTable.tableName compare: secondaryTable.tableName ] == NSOrderedAscending ) {
        return [NSString stringWithFormat: @"%@_%@", primaryTable.tableName, secondaryTable.tableName];
    } else {
        return [NSString stringWithFormat: @"%@_%@", secondaryTable.tableName, primaryTable.tableName];
    }
}

- (NSString*) computePropertyName {
    return [NSString stringWithFormat: @"%@_ids", [secondaryTable.className lowercaseString] ];
}
@end
