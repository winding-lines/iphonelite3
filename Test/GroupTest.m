//
//  GroupsTest.m
//  WindyUsers
//
//  Created by Marius Seritan on 1/27/09.
//  Copyright 2009 de-co-de. All rights reserved.
//
#import "GTMSenTestCase.h"
#import "GTMUnitTestDevLog.h"
#import "Lite3DB.h"
#import "Lite3Table.h"
#import "Lite3LinkTable.h"

@interface GroupTest : SenTestCase {
    Lite3DB * db;
    Lite3Table * groupsTable;
    Lite3Table * usersTable;
}

@end

static const char * ddl = 
"create table \"users\" ("
"\"id\" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,"
"\"name\" varchar(255)"
");"
"create table \"groups\" ("
"\"id\" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,"
"\"name\" varchar(255) "
");"
"create table \"groups_users\" ("
"  group_id integer,"
"  user_id integer"
");"
;



@implementation GroupTest
- (void)setUp {
    db = [Lite3DB alloc];        
    db = [db initWithDbName: @"user_test" andSql:[NSString stringWithCString:ddl]];
    [GTMUnitTestDevLog log: @"full path: %@", db.dbPath];
    usersTable = [[Lite3Table lite3TableName: @"users" withDb: db forClassName:@"User"] retain];
    groupsTable = [[Lite3Table lite3TableName: @"groups" withDb: db forClassName:@"Group"] retain];
    // need to traverse all the tables and fix 
    [db checkConsistency];
    
}

- (void) testDDL {
    // we expect two tables to be created
    NSArray * tables  =[db listTables];
    STAssertNotNil( tables, @"No tables", nil );
    STAssertEquals( (int)[tables count], 3, @"Wrong number of tables, got %d", [tables count]);
}

- (void)testGroupsTableSetup {
    STAssertNotNil( groupsTable, @"Valid groupsTable", nil );
    STAssertTrue( [groupsTable tableExists], @"Table regions does not exist", nil );
    STAssertNotNil( groupsTable.linkedTables, nil, @"No linked tables", nil );
    STAssertEquals( (int)[groupsTable.linkedTables count],1,@"Bad number of linkedTables %d", [groupsTable.linkedTables count]);
}

-(void)testUsersTableSetup {
    STAssertNotNil( usersTable, @"Valid usersTable", nil );
    STAssertTrue( [usersTable tableExists], @"Table places does not exist", nil );    
    STAssertNotNil( usersTable.arguments, @"Bad arguments in usersTable", nil );
}

- (void)testGroupsLinkedTableSetup {
    Lite3LinkTable * regionsUsers = [groupsTable.linkedTables objectAtIndex: 0];
    STAssertNotNil( regionsUsers, @"Empty linkedTables", nil );
    STAssertNotNil( regionsUsers.ownTable, @"LinkedTable does not have its own table", nil );
    STAssertTrue( [regionsUsers.ownTable tableExists], @"LinkedTable not in the database %@", regionsUsers.ownTable.tableName );
}

- (void) testImport {
    
    id input = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects: @"1", @"group1", [NSArray arrayWithObjects: @"1", @"2", @"3",nil],nil] forKeys:[NSArray arrayWithObjects: @"_id", @"name", @"user_ids", nil]];
    NSArray * data = [NSArray arrayWithObjects: input, nil];
    STAssertNotNil ( data, @"data not nil", data );
    STAssertGreaterThan( (int)[data count], 0, @"data is empty", nil );
    
    
    [groupsTable truncate];
    STAssertEquals( 0, [groupsTable count], @"Groups table not empty after truncate, instead %d", [groupsTable count] );
    [groupsTable updateAll: data];
    [data release];
    STAssertEquals ( 1, [groupsTable count], @"Groups table does not have proper count of rows %d", [groupsTable count] );
    
    Lite3LinkTable * regionsUsers = [groupsTable.linkedTables objectAtIndex: 0];
    int linksCount = [regionsUsers.ownTable count];
    STAssertGreaterThan( linksCount, 0, @"Linked table is empty", nil);
}

- (void)tearDown {
    [usersTable release];
    [groupsTable release];
    [db release];
    
}

@end
