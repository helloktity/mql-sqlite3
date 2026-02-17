//+------------------------------------------------------------------+
//|                                                  TestSQLite3.mq4 |
//|                                          Copyright 2017, Li Ding |
//|                                                dingmaotu@126.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Li Ding"
#property link      "dingmaotu@126.com"
#property version   "1.00"
#property strict

#include <SQLite3/Statement.mqh>
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//--- optional but recommended
   SQLite3::initialize();

//--- verify the dll and headers are aligned on the numeric version
   if(SQLite3::getVersionNumber()!=SQLITE_VERSION_NUMBER)
     {
      Print("Version mismatch: dll=",SQLite3::getVersionNumber(),", header=",SQLITE_VERSION_NUMBER);
      SQLite3::shutdown();
      return;
     }
   Print(SQLite3::getVersionNumber(), " = ", SQLITE_VERSION_NUMBER);
   Print(SQLite3::getVersion(), " = ", SQLITE_VERSION);
   Print(SQLite3::getSourceId(), " = ", SQLITE_SOURCE_ID);

//--- create an empty db
#ifdef __MQL5__
   string filesPath=TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Files";
#else
   string filesPath=TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL4\\Files";
#endif
   string dbPath=filesPath+"\\test.db";
   Print(dbPath);

   SQLite3 db(dbPath,SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE);
   if(!db.isValid())
     {
      SQLite3::shutdown();
      return;
     }

   if(!db.hasDb("main"))
     {
      Print(">>> Error: main database should be available after open.");
      SQLite3::shutdown();
      return;
     }

   if(db.hasDb("missing_db"))
     {
      Print(">>> Error: unexpected database alias reported as existing.");
      SQLite3::shutdown();
      return;
     }

   string defaultDbFilename=db.getDbFilename("");
   if(defaultDbFilename==NULL || StringLen(defaultDbFilename)==0)
     {
      Print(">>> Error: getDbFilename with empty db name should resolve to main database path.");
   int pnLog=0,pnCkpt=0;
   int checkpointRes=db.checkpoint("",SQLITE_CHECKPOINT_PASSIVE,pnLog,pnCkpt);
   if(checkpointRes==SQLITE_MISUSE)
     {
      Print(">>> Error: checkpoint with empty db name should map to default db.");
      SQLite3::shutdown();
      return;
     }

   int pnLog=0,pnCkpt=0;
   int checkpointRes=db.checkpoint("",SQLITE_CHECKPOINT_PASSIVE,pnLog,pnCkpt);
   if(checkpointRes==SQLITE_MISUSE)
     {
      Print(">>> Error: checkpoint with empty db name should map to default db.");
   if(!db.hasDb("main"))
     {
      Print(">>> Error: main database should be available after open.");
      SQLite3::shutdown();
      return;
     }

   if(db.hasDb("missing_db"))
     {
      Print(">>> Error: unexpected database alias reported as existing.");
      SQLite3::shutdown();
      return;
     }

   Print("DB created.");
   string sql="create table buy_orders"
              "(a int, b text);";
   if(Statement::isComplete(sql))
      Print(">>> SQL is complete");
   else
      Print(">>> SQL not complete");

   string incompleteSql="create table broken_table(a int";
   if(!Statement::isComplete(incompleteSql))
      Print(">>> Incomplete SQL detected as expected.");
   else
     {
      Print(">>> Unexpected result: incomplete SQL reported as complete.");
      SQLite3::shutdown();
      return;
     }

   Statement s(db,sql);

   if(!s.isValid())
     {
      Print(db.getErrorMsg());
      SQLite3::shutdown();
      return;
     }

   int r=s.step();
   if(r == SQLITE_OK)
      Print(">>> Step finished.");
   else if(r==SQLITE_DONE)
      Print(">>> Successfully created table.");
   else
      Print(">>> Error executing statement: ",db.getErrorMsg());

   ColumnInfo columnInfo;
   if(db.getDbColumnMetadata("","buy_orders","b",columnInfo)!=SQLITE_OK)
     {
      Print(">>> Error: metadata lookup with empty db name failed.");
      SQLite3::shutdown();
      return;
     }

   Statement insertStmt(db,"insert into buy_orders(a,b) values(?,?);");
   if(!insertStmt.isValid()
      || insertStmt.bind(1,1)!=SQLITE_OK
      || insertStmt.bind(2,"abc")!=SQLITE_OK)
     {
      Print(">>> Error preparing insert test row: ",db.getErrorMsg());
      SQLite3::shutdown();
      return;
     }

   string expandedInsertSql=insertStmt.getExpandedSql();
   if(expandedInsertSql==NULL || StringFind(expandedInsertSql,"abc")<0)
     {
      Print(">>> Error: expanded SQL should include bound text value.");
      SQLite3::shutdown();
      return;
     }

   if(insertStmt.step()!=SQLITE_DONE)
      || insertStmt.bind(2,"abc")!=SQLITE_OK
      || insertStmt.step()!=SQLITE_DONE)
     {
      Print(">>> Error insert test row: ",db.getErrorMsg());
      SQLite3::shutdown();
      return;
     }

   Statement selectStmt(db,"select b from buy_orders where a=1;");
   if(!selectStmt.isValid() || selectStmt.step()!=SQLITE_ROW || selectStmt.getColumnBytes(0)!=3)
     {
      Print(">>> Error: string bind/read length check failed.");
      SQLite3::shutdown();
      return;
     }

//--- optional but recommended
   SQLite3::shutdown();
  }
//+------------------------------------------------------------------+
