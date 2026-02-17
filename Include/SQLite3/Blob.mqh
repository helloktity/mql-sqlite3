//+------------------------------------------------------------------+
//|                                                         Blob.mqh |
//|                                          Copyright 2017, Li Ding |
//|                                                dingmaotu@126.com |
//+------------------------------------------------------------------+
#property strict

#include "SQLite3.mqh"
//+------------------------------------------------------------------+
//| Blob for streaming IO                                            |
//+------------------------------------------------------------------+
class Blob
  {
private:
   bool              m_valid;
   intptr_t          m_ref;
public:
                     Blob(const SQLite3 &conn,string db,string table,string column,long row,bool readonly=true)
     {
      m_valid=false;
      m_ref=0;
      char zDb[];
      char zTable[];
      char zColumn[];
      if(db==NULL || db=="")
         StringToUtf8("main",zDb);
      else
         StringToUtf8(db,zDb);
      StringToUtf8(table,zTable);
      StringToUtf8(column,zColumn);

      int res=sqlite3_blob_open(conn.ref(),zDb,zTable,zColumn,row,readonly?0:1,m_ref);
      m_valid=(res==SQLITE_OK);
     }
                    ~Blob() {if(m_ref!=0) sqlite3_blob_close(m_ref);}

   bool              isValid() const {return m_valid;}
   intptr_t          ref() const {return m_ref;}

   int               size() const {if(!m_valid)return -1;return sqlite3_blob_bytes(m_ref); }

   int               moveTo(long rowId) {if(!m_valid)return SQLITE_MISUSE;return sqlite3_blob_reopen(m_ref,rowId);}
   int               read(uchar &buf[],int size,int offset) {if(!m_valid)return SQLITE_MISUSE;return sqlite3_blob_read(m_ref,buf,size,offset);}
   int               write(const uchar &buf[],int size,int offset) {if(!m_valid)return SQLITE_MISUSE;return sqlite3_blob_write(m_ref,buf,size,offset);}
  };
//+------------------------------------------------------------------+
