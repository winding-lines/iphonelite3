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
#import "Hello.h"

@interface Lite3DBTest: SenTestCase {
    Lite3DB * db;
    Lite3Table * helloTable;
}

@end

@implementation Lite3DBTest

- (void)setUp {
    db = [Lite3DB alloc];        
    db = [db initWithDbName: @"test" andSql:@"create table hello(id integer, name text);"];
    [GTMUnitTestDevLog log: @"full path: %@", db.dbPath];
    helloTable = [Lite3Table lite3TableName: @"hello" withDb: db forClassName:@"Hello"];
    
}


- (void)tearDown {
    //[helloTable release];
    [db release];
}

- (void)testListTables {
    STAssertNotNil( db, @"db should not be nil", db );
    NSArray * tables = [db listTables];
    STAssertNotNil( tables,@"tables should not be nil",tables);
    int count = [tables count];
    STAssertGreaterThan( count, 0, @"table count should be bigger than zero", nil );
    [GTMUnitTestDevLog log: @"table count %d, first table %@", [tables count], [tables objectAtIndex: 0]];
}

- (void)testHelloTable {
    STAssertNotNil( helloTable, @"HelloTable is nil", helloTable );
    [helloTable truncate];
    NSArray * all = [helloTable select: nil];
    STAssertNotNil( all, @"Result from empty table is null", all );
    int count = [all count];
    STAssertEquals( count, 0, @"Count not zero", count );
    Hello * hello = [[Hello alloc] init];
    [helloTable update: hello];
    all = [helloTable select: nil];
    STAssertNotNil( all, @"Result from table with content is null", all );
    count = [all count];
    STAssertEquals( count, 1, @"Count not one", count );
}

/**
 * This is a sample test that fails.
 */
- (void)testFAIL {
    STAssertNotNil( nil, @"Just to show a failing test :-)", nil );

}

@end