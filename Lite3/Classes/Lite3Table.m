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

#import "Lite3Arg.h"
#import "Lite3Table.h"
#import "Lite3DB.h"
#import "Lite3LinkTable.h"

#pragma mark "-- Lite3Table private --"
@interface Lite3Table(Private)

- (BOOL)mapToClass: (NSString*)clsName;

- (int)updateOwnTable:(id)data;

- (NSMutableArray*)selectOwn:(NSString *)whereClause start: (int)start count:(int)count;

- (void)truncateOwn;


@end

/**
 * SQLite3 callback
 */
static int multipleRowCallback(void *helperP, int columnCount, char **values, char **columnNames);

/**
 * Class used in the communication to the sqlite3 callback.
 */
struct _SqlOutputHelper {
    Lite3Table * preparedTable;
    NSMutableArray * output;
    Class cls;
};

typedef struct _SqlOuputHelper SqlOutputHelper;

@implementation Lite3Table
@synthesize tableName;
@synthesize className;
@synthesize arguments;

-(void)setClassName:(NSString*)_className {
    [className release];
    self->className = _className;
    [className retain];
    [classNameLowerCase release];
    classNameLowerCase = [[className lowercaseString] retain];
    [db addLite3Table: self];    
    [self mapToClass: _className];
}




#pragma mark "--- Lite3Table init/factory ---"
-(Lite3Table*)initWithDB:(Lite3DB*)dp{
    db = dp;
    updateStmt = NULL;
    countStmt = NULL;
    return self;
}

- (void)dealloc {
    [tableName release]; 
    [arguments release];
    [className release];
    [classNameLowerCase release];
    if ( 
        updateStmt != NULL ) {
        sqlite3_finalize(updateStmt);
    }
    if ( countStmt != NULL ) {
        sqlite3_finalize(countStmt);
    }
    [super dealloc];
}

+ (Lite3Table*)lite3TableName:(NSString*)name withDb:(Lite3DB*)_db {
    
    Lite3Table * pt = [[[Lite3Table alloc] initWithDB: _db ] autorelease];
    pt.tableName = name;    
    return pt;
    
}

+ (Lite3Table*)lite3TableName:(NSString*)name withDb:(Lite3DB*)_db forClassName:(NSString*)_clsName {
    Lite3Table * pt = [Lite3Table lite3TableName:name withDb:_db];
    if ( pt != nil ) {
        pt.className = _clsName;
        [pt compileStatements];
    }
    return pt;
}

- (BOOL)isValid {
    return arguments!=nil;
}

- (BOOL)compileStatements {
    if ( ! [db compileUpdateStatement: &updateStmt tableName: tableName arguments: arguments] ) {
        return FALSE;
    }
    if ( ![db compileCountStatement: &countStmt tableName: tableName ] ) {
        return FALSE;
    }
    return TRUE;
}


-(Lite3LinkTable*)linkTableFor:(NSString*)propertyName {
    Lite3Arg * arg = [Lite3Arg findByName: propertyName inArray: arguments];
    if ( arg != nil ) {
        return arg.link;
    }
    return nil;
}
#pragma mark "--- Lite3Table database functions ---"
-(BOOL)tableExists {
    NSArray * existing = [db listTables];
    
    for( NSString * one in existing ) {
        if ( [one compare: tableName] == NSOrderedSame ) {
            return TRUE;
        }
    }
    return FALSE;
}


- (int)updateNoTransaction:(id)data {
    int rc = [self updateOwnTable: data];
    for ( Lite3Arg * arg in arguments ) {
        if ( arg.preparedType == _LITE3_LINK ) {
            [arg.link  updateNoTransaction: data];
        }
    }
    return rc;
}

- (int)update:(id)data {
    [db startTransaction: @"update"];
    int rc = [self updateNoTransaction: data];
    [db endTransaction];
    return rc;
}


-(int)count {
    if ( countStmt == NULL ) {
        return -1;
    }
    int count;
    int rc = sqlite3_step(countStmt);
    [db checkError: rc message: @"Stepping count statement"];
    count =  sqlite3_column_int(countStmt,0);
    rc = sqlite3_reset(countStmt);
    [db checkError: rc message: @"Resetting count statement"];
    return count;
    
}

- (int)updateAll:(NSArray*)objects {
    NSDate * start = [NSDate date];
    [db startTransaction: @"updateAll"];
    for ( int i=0; i < [objects count]; i++ ) {
        NSDictionary * d = [objects objectAtIndex: i];
        NSDictionary * embedded = [d valueForKey: classNameLowerCase];
        if ( embedded != nil ) {
            d = embedded;
        }
        [self updateNoTransaction: d];
    }
    [db endTransaction];
    NSTimeInterval elapsed = [start timeIntervalSinceNow];
    NSLog(@"updateAll %@ duration %f", tableName, -elapsed);    
    return [objects count];
}

- (NSMutableArray*)select:(NSString *)whereClause start: (int)start count:(int)count {
    NSMutableArray * rows = [self selectOwn: whereClause start: start count: count];
    return rows;
}

- (NSMutableArray*)selectLinks: (id) main forProperty: (NSString*)name fromPool:(NSArray*)pool {
    Lite3Arg * arg = [Lite3Arg findByName: name inArray: arguments];
    NSMutableArray * links = [arg.link selectLinksFor:classNameLowerCase andId: [[main valueForKey: @"_id"] intValue]];
    //NSLog( @"---- main %@ ---- id %d ------ links %@", main, [[main valueForKey: @"_id"] intValue], links );
    if ( links == nil ) {
        return nil;
    }
    NSMutableArray * output = [NSMutableArray array];
    NSString * secondaryIdName = [NSString stringWithFormat: @"%@_id", classNameLowerCase];
    for( id linkEntry in links ) {
        int linkId = [[linkEntry valueForKey:secondaryIdName ] intValue];
        for ( id one in pool ) {
            if ( [[one valueForKey:@"_id" ] intValue] ==  linkId ) {
                [output addObject: one];
            }
        }
    }
    return output;
    
}


- (NSMutableArray*)select:(NSString*)whereClause {
    return [self select: whereClause start: -1 count: -1 ];
}

- (id)selectFirst:(NSString*)whereClause {
    NSArray * matches = [self select: whereClause start: -1 count: 1];
    if ( matches == nil || [matches count] == 0 ) {
        return nil;
    }
    return [matches objectAtIndex: 0];
    
}

-(void)truncate {
    [db startTransaction: @"truncate"];
    for( Lite3Arg * arg in arguments ) {
        if ( arg.preparedType == _LITE3_LINK ) {
            [arg.link.ownTable truncateOwn];
        }
    }
    [self truncateOwn];
    [db endTransaction];
}



#pragma mark "-- private implementation --"
- (BOOL)mapToClass: (NSString*)clsName {
    NSMutableArray * _arguments = [[NSMutableArray alloc] init];
    const char * _c = [clsName cStringUsingEncoding: NSASCIIStringEncoding];
    Class cls = objc_getClass(_c);
    if ( cls == nil ) {
        NSLog( @"Cannot class '%s'", _c );
        return FALSE;
    }
    objc_property_t * properties = NULL; 
    unsigned int outCount;
    properties = class_copyPropertyList( cls, &outCount);
    if ( outCount != 0 ) {
        for( int i=0; i<outCount;i++ ) {
            Lite3Arg * pa = [[Lite3Arg alloc] init];
            const char * propertyName =  property_getName(properties[i]);
            pa.ivar = class_getInstanceVariable( cls, propertyName );
            // by convention bypass initial _
            if ( propertyName[0] == '_' ) {
                propertyName = propertyName+1;
            }
            pa.name = [[NSString alloc] initWithCString: propertyName encoding: NSASCIIStringEncoding];
            
            
            const char *attributes = property_getAttributes(properties[i]);
            if ( attributes != NULL ) {
                if ( strncmp(attributes,"Ti",2) == 0 ) {
                    pa.preparedType = _LITE3_INT;
                } else if ( strncmp(attributes,"Td",2) == 0 ) {
                    pa.preparedType = _LITE3_DOUBLE;
                } else if ( strncmp(attributes,"T@\"NSString\"",12) == 0 ) {
                    pa.preparedType = _LITE3_STRING;
                } else if ( strncmp(attributes,"T@\"NSDate\"",10) == 0 ) {
                    pa.preparedType = _LITE3_TIMESTAMP;
                } else if ( strncmp(attributes,"T^@\"", 4 ) == 0 ) {
                    // assume this is a many-to-many relationship and extract the class name
                    const char * comma = strchr( attributes, ',' );
                    comma = comma - 5;
                    NSString * linkedClassName = [NSString stringWithCString: attributes+4 length:(comma-attributes)];
                    Lite3LinkTable * linkTable = [[Lite3LinkTable alloc] initWithDb: db];
                    linkTable.primaryTable = self;
                    linkTable.secondaryClassName = linkedClassName;
                    pa.preparedType = _LITE3_LINK;
                    pa.link = linkTable;
                } else {
                    NSLog( @"Need to decode %s", attributes );
                }
            }
            if( pa != nil ) {
                [_arguments addObject:pa];
            }
        }
    }
    if ( properties != NULL ) {
        free( properties );
    }
    arguments = _arguments;
    
    return TRUE;
}

/**
 * Update from the object or dictionary using Key Value access.
 */
- (int)updateOwnTable:(id)data {
    if ( updateStmt == NULL ) {
        NSLog( @"No update statement" );
        return -1;
    }
    int rc = sqlite3_clear_bindings(updateStmt);    
    [db checkError: rc message: @"Clearing statement bindings"];
    int bindCount = 0;
    for( Lite3Arg * pa in arguments ) {
        if ( pa.preparedType == _LITE3_LINK ) {
            continue;
        }
        bindCount ++;
        id toBind = [data valueForKey:pa.name];
        if ( toBind != nil && toBind != [NSNull null] ) {
            switch (pa.preparedType) {
                case _LITE3_INT:
                    rc = sqlite3_bind_int(updateStmt, bindCount, [toBind intValue]);
                    [db checkError: rc message: @"Binding int"];
                    break;
                case _LITE3_DOUBLE:
                    rc = sqlite3_bind_double(updateStmt, bindCount, [toBind floatValue]);
                    [db checkError: rc message: @"Binding float"];
                    break;
                case _LITE3_STRING:
                {
                    const char * cString = [toBind UTF8String];
                    rc = sqlite3_bind_text(updateStmt, bindCount, cString, strlen(cString), NULL);
                    [db checkError: rc message: @"Binding string"];
                }
                    break;
                case _LITE3_TIMESTAMP: {
                    const char * cString = [[toBind description] UTF8String];                    
                    rc = sqlite3_bind_text(updateStmt, bindCount, cString, strlen(cString), NULL );
                    [db checkError: rc message: @"Binding timestamp"];
                }
                    break;
                default:
                    break;
            }
        }
    }
    rc = sqlite3_step(updateStmt);
    sqlite_int64 lastId = sqlite3_last_insert_rowid(db.dbHandle);
    //NSLog( @"last id: %d", lastId );
    if ( lastId == 0 ) {
        NSLog( @"No value inserted" );
    }
    [db checkError: rc message: @"Getting last insert row"];
    rc = sqlite3_reset(updateStmt);
    [db checkError: rc message: @"Resetting statement" ];
    return lastId;
}

/**
 * Do a select in our own table (as opposed to the link tables).
 */
- (NSMutableArray*)selectOwn:(NSString *)whereClause start: (int)start count:(int)count {
    struct _SqlOutputHelper outputHelper;
    outputHelper.output = [NSMutableArray array];
    outputHelper.cls = objc_getClass([className cStringUsingEncoding: NSASCIIStringEncoding]);
    outputHelper.preparedTable = self;
    char *zErrMsg = NULL;
    NSString * sql;
    NSMutableString * limit = [[NSMutableString alloc] init];
    if ( count > -1 ) {
        [limit appendFormat: @" limit %d", count ];
    }
    if ( start > -1 ) {
        [limit appendFormat: @" offset %d", start ];
    }
    if ( whereClause == nil ) {
        sql = [NSString stringWithFormat: @"select * from %@%@", tableName, limit];
    } else {
        sql = [NSString stringWithFormat: @"select * from %@ where %@%@", tableName, whereClause, limit];
    }
    [limit release];
    int rc = sqlite3_exec(db.dbHandle, [sql UTF8String], multipleRowCallback, (void*)&outputHelper, &zErrMsg);
    if ( zErrMsg != NULL ) {
        sqlite3_free(zErrMsg);
    }
    [db checkError: rc message: @"Executing select statement"];
    return outputHelper.output;
}

- (void)truncateOwn {
    char *zErrMsg = NULL;
    NSString * sql = [NSString stringWithFormat: @"delete from %@", tableName];
    int rc = sqlite3_exec(db.dbHandle, [sql UTF8String], multipleRowCallback, NULL, &zErrMsg);
    if ( zErrMsg != NULL ) {
        sqlite3_free(zErrMsg);
    }
    [db checkError: rc message: @"Truncating table"];
    
}



static int multipleRowCallback(void *helperP, int columnCount, char **values, char **columnNames) {
    if ( helperP == NULL ) {
        return 0;
    }
    struct _SqlOutputHelper * helper = (struct _SqlOutputHelper*)helperP;
    
    id object;
    if ( helper->cls != nil ) {
        object = class_createInstance(helper->cls, 0 );
    } else {
        object = [[NSMutableDictionary alloc] init];
    }
    int i;
    for(i=0; i<columnCount; i++) {
        const char * name = columnNames[i];
        const char * value = values[i];
        if ( value != NULL ) {
            NSString * nameAsString = [[NSString alloc] initWithCString: name];
            Lite3Arg * pa = [Lite3Arg findByName:nameAsString inArray:helper->preparedTable.arguments];
            [nameAsString release];
            if ( pa == nil ) {
                continue;
            }
            if (helper->cls == nil ) {
                // we don't have an user class backing this table
                [object setValue: [[NSString alloc] initWithCString: value] forKey: [[NSString alloc] initWithCString: name]];
            } else {
                if ( strcmp(name, "id") == 0 ) {
                    name = "_id";
                }
                
                void ** varIndex = (void **)((char *)object + ivar_getOffset(pa.ivar));
                if ( varIndex == NULL ) {
                    NSLog( @"----VAR INDEX IS NULL for %s object %p", name, object );
                    continue;
                }
                switch ( pa.preparedType ) {
                    case _LITE3_INT: {
                        long extracted = atol( value );
                        
                        *(long*)varIndex = extracted;
                    }
                        break;
                    case _LITE3_DOUBLE: {
                        double extracted = atof( value );
                        *(double*)varIndex = extracted;
                    } 
                        break;
                    case _LITE3_STRING: {
                        NSString * extracted = [[NSString stringWithCString:value encoding:NSUTF8StringEncoding] retain];
                        object_setInstanceVariable( object, name, extracted );
                    } break;
                    case _LITE3_TIMESTAMP: {
                        NSString * extracted = [[NSString stringWithCString:value encoding:NSUTF8StringEncoding] retain];
                        object_setInstanceVariable( object, name, extracted );
                    } break;
                }
            }                        
        }
    }
    [helper->output addObject: object];
    return 0;
}




@end
