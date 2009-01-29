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

#import "Lite3Table.h"
#import "Lite3DB.h"
#import "Lite3LinkTable.h"



#pragma mark "---Lite3Arg ---"

@implementation Lite3Arg
@synthesize name;
@synthesize preparedType;
@synthesize ivar;

+ (Lite3Arg*)lite3ArgWithName: (NSString*) _name class: cls andType:(int) _preparedType {
    Lite3Arg * pa = [[Lite3Arg alloc] init];
    pa.name = _name;
    pa.preparedType = _preparedType;
    return pa;
}

- (void)dealloc {
    [name release];
    [super dealloc];
}



@end

#pragma mark "-- Lite3Table private --"
@interface Lite3Table(Private)

- (BOOL)mapToClass: (NSString*)clsName;

- (int)updateOwnTable:(id)data;

@end


@implementation Lite3Table
@synthesize tableName;
@synthesize className;
@synthesize arguments;
@synthesize linkedTables;

-(void)setClassName:(NSString*)_className {
    [className release];
    self->className = _className;
    [className retain];
    [classNameLowerCase release];
    classNameLowerCase = [[className lowercaseString] retain];
    [db addLite3Table: self];    
    [self mapToClass: _className];
}

- (Lite3Arg*)findLite3ArgByName: (NSString*)name {
    for ( int i=0; i<[arguments count]; i++ ) {
        Lite3Arg * pa = [arguments objectAtIndex: i];
        if ( [pa.name compare: name ] == NSOrderedSame ) {
            return pa;
        }
    }
    return nil;
}



#pragma mark "--- Lite3Table init/factory ---"
-(Lite3Table*)initWithDB:(Lite3DB*)dp{
    db = dp;
    updateStmt = NULL;
    countStmt = NULL;
    return self;
}

- (void)dealloc {
    [linkedTables release];
    [tableName release]; 
    [arguments release];
    [className release];
    [classNameLowerCase release];
    if ( updateStmt != NULL ) {
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
    pt.className = _clsName;
    [pt compileStatements];
    return pt;
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

- (BOOL)mapToClass: (NSString*)clsName {
    NSMutableArray * _arguments = [[NSMutableArray alloc] init];
    NSMutableDictionary * _linkDictionary = [[NSMutableDictionary alloc] init];
    Class cls = objc_getClass([clsName cStringUsingEncoding: NSASCIIStringEncoding]);
    if ( cls != nil ) {
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
                        if ( [_linkDictionary objectForKey: linkedClassName] == nil ) {
                            Lite3LinkTable * linkTable = [[Lite3LinkTable alloc] initWithDb: db];
                            linkTable.primaryTable = self;
                            linkTable.secondaryClassName = linkedClassName;
                            [_linkDictionary setObject:linkTable forKey:linkedClassName];
                        }
                        // no need to add a  prepared argument for now
                        [pa release];
                        pa = nil;
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
    }
    arguments = _arguments;
    linkedTables = [[NSArray alloc] initWithArray: [_linkDictionary allValues]];
    
    return TRUE;
}

-(BOOL)tableExists {
    NSArray * existing = [db listTables];
    
    for( NSString * one in existing ) {
        if ( [one compare: tableName] == NSOrderedSame ) {
            return TRUE;
        }
    }
    return FALSE;
}


#pragma mark "--- Lite3Table database functions ---"
- (int)update:(id)data {
    int rc = [self updateOwnTable: data];
    if ( linkedTables != nil ) {
        for ( Lite3LinkTable * linkTable in linkedTables ) {
            [linkTable update: data];
        }
    }
    return rc;
}
/**
 * Update from the object or dictionary using Key Value access.
 */
- (int)updateOwnTable:(id)data {
    int rc = sqlite3_clear_bindings(updateStmt);    
    [db checkError: rc message: @"Clearing statement bindings"];
    for( int i=0;i<[arguments count];i++ ) {
        Lite3Arg * pa = [arguments objectAtIndex:i];
        id toBind = [data valueForKey:pa.name];
        if ( toBind != nil && toBind != [NSNull null] ) {
            switch (pa.preparedType) {
                case _LITE3_INT:
                    rc = sqlite3_bind_int(updateStmt, i+1, [toBind intValue]);
                    [db checkError: rc message: @"Binding int"];
                    break;
                case _LITE3_DOUBLE:
                    rc = sqlite3_bind_double(updateStmt, i+1, [toBind floatValue]);
                    [db checkError: rc message: @"Binding float"];
                    break;
                case _LITE3_STRING:
                {
                    const char * cString = [toBind UTF8String];
                    rc = sqlite3_bind_text(updateStmt, i+1, cString, strlen(cString), NULL);
                    [db checkError: rc message: @"Binding string"];
                }
                    break;
                case _LITE3_TIMESTAMP: {
                    const char * cString = [[toBind description] UTF8String];                    
                    rc = sqlite3_bind_text(updateStmt, i+1, cString, strlen(cString), NULL );
                    [db checkError: rc message: @"Binding timestamp"];
                }
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

-(int)count {
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
    [db startTransaction];
    for ( int i=0; i < [objects count]; i++ ) {
        NSDictionary * d = [objects objectAtIndex: i];
        NSDictionary * embedded = [d valueForKey: classNameLowerCase];
        if ( embedded != nil ) {
            d = embedded;
        }
        [self update: d];
    }
    [db endTransaction];
    NSTimeInterval elapsed = [start timeIntervalSinceNow];
    NSLog(@"updateAll %@ duration %f", tableName, -elapsed);    
    return [objects count];
}




/**
 * Class used in the communication to the sqlite3 callback.
 */
struct _SqlOutputHelper {
    Lite3Table * preparedTable;
    NSMutableArray * output;
    Class cls;
};

typedef struct _SqlOuputHelper SqlOutputHelper;


static int multipleRowCallback(void *helperP, int columnCount, char **values, char **columnNames) {
    if ( helperP == NULL ) {
        return 0;
    }
    struct _SqlOutputHelper * helper = (struct _SqlOutputHelper*)helperP;
    
    id object = class_createInstance(helper->cls, 0 );
    int i;
    for(i=0; i<columnCount; i++) {
        const char * name = columnNames[i];
        const char * value = values[i];
        if ( value != NULL ) {
            NSString * nameAsString = [[NSString alloc] initWithCString: name];
            Lite3Arg * pa = [helper->preparedTable findLite3ArgByName: nameAsString];
            [nameAsString release];
            if ( pa != nil ) {
                if ( strcmp(name, "id") == 0 ) {
                    name = "_id";
                }
                
                void * varIndex = (void **)((char *)object + ivar_getOffset(pa.ivar));
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

- (NSMutableArray*)select:(NSString *)whereClause {
    struct _SqlOutputHelper outputHelper;
    outputHelper.output = [NSMutableArray array];
    outputHelper.cls = objc_getClass([className cStringUsingEncoding: NSASCIIStringEncoding]);
    outputHelper.preparedTable = self;
    char *zErrMsg = NULL;
    NSString * sql;
    if ( whereClause == nil ) {
        sql = [NSString stringWithFormat: @"select * from %@", tableName];
    } else {
        sql = [NSString stringWithFormat: @"select * from %@ where %@", tableName, whereClause];
    }
    int rc = sqlite3_exec(db.dbHandle, [sql UTF8String], multipleRowCallback, (void*)&outputHelper, &zErrMsg);
    if ( zErrMsg != NULL ) {
        sqlite3_free(zErrMsg);
    }
    [db checkError: rc message: @"Executing select statement"];
    return outputHelper.output;
}

- (void)truncate {
    char *zErrMsg = NULL;
    NSString * sql = [NSString stringWithFormat: @"delete from %@", tableName];
    int rc = sqlite3_exec(db.dbHandle, [sql UTF8String], multipleRowCallback, NULL, &zErrMsg);
    if ( zErrMsg != NULL ) {
        sqlite3_free(zErrMsg);
    }
    [db checkError: rc message: @"Truncating table"];
    
}


@end
