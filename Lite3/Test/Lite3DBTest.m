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
#import "GTMSenTestCase.h"
#import "GTMUnitTestDevLog.h"
#import "Lite3DB.h"
#import "Lite3Table.h"
#import "User.h"

@interface Lite3DBTest: SenTestCase {
    Lite3DB * db;
    Lite3Table * userTable;
}

@end

@implementation Lite3DBTest

- (void)setUp {
    db = [Lite3DB alloc];        
    db = [db initWithDbName: @"test" andSql:@"create table users(id integer, name text);"];
    //[GTMUnitTestDevLog log: @"full path: %@", db.dbPath];
    userTable = [[Lite3Table lite3TableName: @"users" withDb: db forClassName:@"User"] retain];
}


- (void)tearDown {
   [userTable release];
   [db release];
}

- (void)testListTables {
    STAssertNotNil( db, @"db should not be nil", db );
    NSArray * tables = [db listTables];
    STAssertNotNil( tables,@"tables should not be nil",tables);
}

- (void)testTablesCount {
    int count = [ [db listTables] count];
    STAssertGreaterThan( count, 0, @"table count should be bigger than zero", nil );
}

- (void) testTable {
    STAssertNotNil( userTable, @"HelloTable is nil", userTable );
    STAssertTrue( [userTable tableExists], @"Table does not exists", nil );
    [userTable truncate];
    NSArray * all = [userTable select: nil];
    STAssertNotNil( all, @"Result from empty table is null", all );
    int count = [all count];
    STAssertEquals( count, 0, @"Count not zero", count );
}

- (void) testSavingIncreasesCount {
    User * user = [[User alloc] init];
    [userTable update: user];
    NSArray * all = [userTable select: nil];
    STAssertNotNil( all, @"Result from table with content is %@", all );
    int count = [all count];
    STAssertEquals( count, 1, @"Count not one -- through 'select'", count );
    // count though the count method
    count = [userTable count];
    STAssertEquals( count, 1, @"Count not one -- through 'count'", count );
    
}


@end