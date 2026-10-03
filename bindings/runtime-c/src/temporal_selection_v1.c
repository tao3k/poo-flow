// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
#define _POSIX_C_SOURCE 200809L
#include <poo_flow/temporal_selection_v1.h>
#include <sqlite3.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <inttypes.h>
#include <limits.h>

struct poo_flow_temporal_store_v1 {
  sqlite3 *db;
  pthread_mutex_t lock;
  poo_flow_temporal_verify_v1 verify;
  poo_flow_temporal_sign_v1 sign;
  void *host;
  char budget[513];
};

static const char *schema =
 "CREATE TABLE IF NOT EXISTS temporal_selection_v1("
 "subject TEXT NOT NULL, scope TEXT NOT NULL, version INTEGER NOT NULL,"
 "revision TEXT NOT NULL, payload BLOB NOT NULL, signature BLOB NOT NULL,"
 "PRIMARY KEY(subject,scope));"
 "CREATE TABLE IF NOT EXISTS temporal_effect_v1("
 "subject TEXT NOT NULL,scope TEXT NOT NULL,nonce TEXT NOT NULL,"
 "version INTEGER NOT NULL,payload BLOB NOT NULL,signature BLOB NOT NULL,"
 "PRIMARY KEY(subject,scope,nonce));";

static void fields(const poo_flow_temporal_publish_v1 *r, const char **f) {
  f[0]=r->subject; f[1]=r->scope; f[2]=r->predecessor; f[3]=r->revision;
  f[4]=r->proof; f[5]=r->policy; f[6]=r->generation; f[7]=r->cut;
  f[8]=r->projection; f[9]=r->journal; f[10]=r->model; f[11]=r->nonce;
  f[12]=r->operation;
}
/* Reject overlong encodings, surrogate code points and values above U+10FFFF. */
static int utf8(const unsigned char *p) {
  while (*p) {
    uint32_t value; unsigned count, i;
    if (*p < 0x80) {p++;continue;}
    if (*p >= 0xc2 && *p <= 0xdf) {value=*p & 0x1f;count=1;}
    else if (*p >= 0xe0 && *p <= 0xef) {value=*p & 0x0f;count=2;}
    else if (*p >= 0xf0 && *p <= 0xf4) {value=*p & 7;count=3;}
    else return 0;
    p++;
    for(i=0;i<count;i++) {
      if ((*p & 0xc0)!=0x80) return 0;
      value=(value<<6)|(*p++ & 0x3f);
    }
    if((count==2 && value<0x800) || (count==3 && value<0x10000) ||
       (value>=0xd800 && value<=0xdfff) || value>0x10ffff) return 0;
  }
  return 1;
}
static int valid(const poo_flow_temporal_publish_v1 *r) {
  const char *f[13]; size_t i;
  if (!r || r->expected_version >= (uint64_t)INT64_MAX ||
      r->expires_unix > (uint64_t)INT64_MAX) return 0;
  fields(r,f);
  for(i=0;i<13;i++) if (!f[i] || strlen(f[i])>512 || (i!=2 && !*f[i]) || !utf8((const unsigned char *)f[i])) return 0;
  if (!strcmp(r->operation,"assert"))
    return r->expected_version==0 && !*r->predecessor;
  return r->expected_version>0 && *r->predecessor &&
    (!strcmp(r->operation,"correct") || !strcmp(r->operation,"retract"));
}
static size_t frame_size(const char *s) {
  char n[32]; size_t len=strlen(s);
  return (size_t)snprintf(n,sizeof(n),"%zu",len)+len+2;
}
static size_t frame(uint8_t *out,const char *s) {
  size_t len=strlen(s), n=(size_t)sprintf((char *)out,"%zu:",len);
  memcpy(out+n,s,len); out[n+len]=','; return n+len+1;
}
int poo_flow_temporal_payload_v1(const poo_flow_temporal_publish_v1 *r,
    uint8_t *out,size_t capacity,size_t *length) {
  const char *f[16]; char version[32],expires[32]; size_t n=0,i,offset=0;
  if (!valid(r) || !length) return 0;
  f[0]="poo-flow.temporal.publish.v1"; fields(r,f+1);
  snprintf(version,sizeof(version),"%" PRIu64,r->expected_version);
  snprintf(expires,sizeof(expires),"%" PRIu64,r->expires_unix);
  f[14]=version; f[15]=expires;
  for(i=0;i<16;i++) n+=frame_size(f[i]);
  *length=n; if (!out) return 1; if(capacity<n) return 0;
  for(i=0;i<16;i++) offset+=frame(out+offset,f[i]);
  return offset==n;
}
static uint8_t *effect_bytes(const uint8_t *payload,size_t length,uint64_t version,
    const char *role,size_t *total) {
  char v[32]; uint8_t *result; size_t prefix;
  snprintf(v,sizeof(v),"%" PRIu64,version);
  prefix=frame_size(role)+frame_size(v); *total=prefix+length;
  result=malloc(*total+1); if(!result) return NULL;
  prefix=frame(result,role); prefix+=frame(result+prefix,v);
  memcpy(result+prefix,payload,length); return result;
}
static int sql(sqlite3 *db,const char *s) {return sqlite3_exec(db,s,NULL,NULL,NULL)==SQLITE_OK;}
int poo_flow_temporal_open_v1(const char *path,poo_flow_temporal_verify_v1 verify,
    poo_flow_temporal_sign_v1 sign,void *host,poo_flow_temporal_store_v1 **out) {
  poo_flow_temporal_store_v1 *s;
  if(!path || !*path || !strcmp(path,":memory:") || !verify || !sign || !out) return 0;
  *out=NULL; s=calloc(1,sizeof(*s)); if(!s) return 0;
  if(pthread_mutex_init(&s->lock,NULL)) {free(s);return 0;}
  if(sqlite3_open_v2(path,&s->db,SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE|SQLITE_OPEN_FULLMUTEX,NULL)!=SQLITE_OK)
    goto fail;
  sqlite3_busy_timeout(s->db,5000);
  if(!sql(s->db,"PRAGMA journal_mode=WAL;PRAGMA synchronous=FULL;") || !sql(s->db,schema)) goto fail;
  s->verify=verify;s->sign=sign;s->host=host;*out=s;return 1;
fail:
  sqlite3_close(s->db);pthread_mutex_destroy(&s->lock);free(s);return 0;
}
void poo_flow_temporal_close_v1(poo_flow_temporal_store_v1 *s) {
  if(s) {sqlite3_close(s->db);pthread_mutex_destroy(&s->lock);free(s);}
}
static int bind_scope(sqlite3_stmt *q,const poo_flow_temporal_publish_v1 *r) {
  return sqlite3_bind_text(q,1,r->subject,-1,SQLITE_TRANSIENT)==SQLITE_OK &&
         sqlite3_bind_text(q,2,r->scope,-1,SQLITE_TRANSIENT)==SQLITE_OK;
}
int poo_flow_temporal_require_budget_v1(poo_flow_temporal_store_v1 *s,const char *budget) {
  int ok=0;
  if(!s || !budget || !*budget || strlen(budget)>512 || !utf8((const unsigned char *)budget)) return 0;
  pthread_mutex_lock(&s->lock);
  if(!*s->budget || !strcmp(s->budget,budget)) {strcpy(s->budget,budget);ok=1;}
  pthread_mutex_unlock(&s->lock);return ok;
}
static uint8_t *lease_bytes(const char *budget,const poo_flow_temporal_publish_v1 *r,
    sqlite3_int64 amount,const char *state,const uint8_t *payload,size_t length,size_t *total) {
  char number[32];const char *f[7];size_t n=0,i,offset=0;uint8_t *bytes;
  snprintf(number,sizeof(number),"%" PRId64,(int64_t)amount);
  f[0]="poo-flow.temporal.budget-lease.v1";f[1]=budget;f[2]=r->subject;
  f[3]=r->scope;f[4]=r->nonce;f[5]=number;f[6]=state;
  for(i=0;i<7;i++) n+=frame_size(f[i]);
  *total=n+length;bytes=malloc(*total+1);if(!bytes) return NULL;
  for(i=0;i<7;i++) offset+=frame(bytes+offset,f[i]);
  memcpy(bytes+offset,payload,length);return bytes;
}
/* Consume the authenticated grant in its own durable transaction. Failure of
 * the publication cannot refund it. Replays still authenticate the effect in
 * the normal publication transaction below. */
static uint32_t activate_budget(poo_flow_temporal_store_v1 *s,
    const poo_flow_temporal_publish_v1 *r,const uint8_t *payload,size_t length,uint64_t *grant) {
  sqlite3_stmt *q=NULL;uint8_t *bytes=NULL,signature[32];size_t total=0;
  uint32_t status=POO_FLOW_TEMPORAL_STORAGE_ERROR;int step;sqlite3_int64 amount;
  *grant=0;if(!sql(s->db,"BEGIN IMMEDIATE")) return status;
  if(sqlite3_prepare_v2(s->db,"SELECT payload FROM temporal_effect_v1 WHERE subject=? AND scope=? AND nonce=?",-1,&q,NULL)!=SQLITE_OK ||
     !bind_scope(q,r) || sqlite3_bind_text(q,3,r->nonce,-1,SQLITE_TRANSIENT)!=SQLITE_OK) goto done;
  step=sqlite3_step(q);
  if(step==SQLITE_ROW && sqlite3_column_bytes(q,0)==(int)length && !memcmp(sqlite3_column_blob(q,0),payload,length)) {
    status=POO_FLOW_TEMPORAL_COMMITTED;goto done;
  }
  if(step!=SQLITE_ROW && step!=SQLITE_DONE) goto done;
  sqlite3_finalize(q);q=NULL;
  if(sqlite3_prepare_v2(s->db,"SELECT budget,amount,state,payload,signature FROM temporal_budget_lease_v1 WHERE subject=? AND scope=? AND nonce=?",-1,&q,NULL)!=SQLITE_OK ||
     !bind_scope(q,r) || sqlite3_bind_text(q,3,r->nonce,-1,SQLITE_TRANSIENT)!=SQLITE_OK) goto done;
  step=sqlite3_step(q);
  if(step==SQLITE_DONE) {status=POO_FLOW_TEMPORAL_BUDGET_EXHAUSTED;goto done;}
  if(step!=SQLITE_ROW) goto done;
  {
    const char *root=(const char *)sqlite3_column_text(q,0),*state=(const char *)sqlite3_column_text(q,2);
    const uint8_t *stored=sqlite3_column_blob(q,3),*sig=sqlite3_column_blob(q,4);
    int size=sqlite3_column_bytes(q,3);amount=sqlite3_column_int64(q,1);
    if(!root || !state || amount<=0 || size<=0 || sqlite3_column_bytes(q,4)!=32 ||
       (strcmp(state,"ready") && strcmp(state,"spent"))) {status=POO_FLOW_TEMPORAL_CORRUPT;goto done;}
    bytes=lease_bytes(root,r,amount,state,stored,(size_t)size,&total);
    if(!bytes || !s->verify(s->host,3,bytes,total,sig)) {status=POO_FLOW_TEMPORAL_CORRUPT;goto done;}
    free(bytes);bytes=NULL;
    if(strcmp(root,s->budget) || strcmp(state,"ready") || size!=(int)length || memcmp(stored,payload,length)) {
      status=POO_FLOW_TEMPORAL_BUDGET_EXHAUSTED;goto done;
    }
    bytes=lease_bytes(root,r,amount,"spent",payload,length,&total);
    if(!bytes || !s->sign(s->host,bytes,total,signature)) goto done;
  }
  sqlite3_finalize(q);q=NULL;
  if(sqlite3_prepare_v2(s->db,"UPDATE temporal_budget_lease_v1 SET state='spent',signature=? WHERE subject=? AND scope=? AND nonce=?",-1,&q,NULL)!=SQLITE_OK ||
     sqlite3_bind_blob(q,1,signature,32,SQLITE_TRANSIENT)!=SQLITE_OK ||
     sqlite3_bind_text(q,2,r->subject,-1,SQLITE_TRANSIENT)!=SQLITE_OK ||
     sqlite3_bind_text(q,3,r->scope,-1,SQLITE_TRANSIENT)!=SQLITE_OK ||
     sqlite3_bind_text(q,4,r->nonce,-1,SQLITE_TRANSIENT)!=SQLITE_OK || sqlite3_step(q)!=SQLITE_DONE) goto done;
  sqlite3_finalize(q);q=NULL;
  if(!sql(s->db,"COMMIT")) goto done;
  *grant=(uint64_t)amount;status=POO_FLOW_TEMPORAL_COMMITTED;
done:
  sqlite3_finalize(q);free(bytes);if(!sqlite3_get_autocommit(s->db)) sql(s->db,"ROLLBACK");return status;
}
/* Check that a stored pointer's visible fields are exactly its signed request.
 * Netstring framing prevents a scope/identity delimiter injection. */
static int row_matches(const uint8_t *p,size_t n,const char *subject,const char *scope,
    const char *revision,uint64_t version) {
  size_t offset=0,index=0;
  while(offset<n && index<16) {
    size_t size=0,start=offset,digits=0;
    while(offset<n && p[offset]>='0' && p[offset]<='9') {
      if(++digits>5) return 0;
      size=size*10+(size_t)(p[offset++]-'0');
    }
    if(!digits || (digits>1 && p[start]=='0') || offset>=n || p[offset++]!=':' ||
       size>n-offset || size==n-offset || p[offset+size]!=',') return 0;
    if(index==0 || index==1 || index==2 || index==4) {
      const char *want=index==0?"poo-flow.temporal.publish.v1":index==1?subject:index==2?scope:revision;
      if(size!=strlen(want) || memcmp(p+offset,want,size)) return 0;
    }
    if(index==14) {
      char want[32];snprintf(want,sizeof(want),"%" PRIu64,version-1);
      if(size!=strlen(want) || memcmp(p+offset,want,size)) return 0;
    }
    offset+=size+1;index++;
  }
  return offset==n && index==16;
}
uint32_t poo_flow_temporal_publish_selection_v1(poo_flow_temporal_store_v1 *s,
    const poo_flow_temporal_publish_v1 *r,poo_flow_temporal_effect_v1 *result) {
  uint32_t status=POO_FLOW_TEMPORAL_STORAGE_ERROR;uint8_t *payload=NULL,*signed_bytes=NULL;
  size_t length=0,total=0;uint64_t version=0;sqlite3_stmt *q=NULL;int step,conflict=0;
  uint8_t state_sig[32],effect_sig[32];time_t now;
  struct timespec started,finished;uint64_t grant=0;
  if(clock_gettime(CLOCK_MONOTONIC,&started)) return POO_FLOW_TEMPORAL_STORAGE_ERROR;
  if(!result) return POO_FLOW_TEMPORAL_INVALID;
  memset(result,0,sizeof(*result));result->status=POO_FLOW_TEMPORAL_INVALID;
  if(!s || !poo_flow_temporal_payload_v1(r,NULL,0,&length)) return result->status;
  payload=malloc(length+1);if(!payload) return result->status;
  if(!poo_flow_temporal_payload_v1(r,payload,length,&length)) goto done;
  if(!s->verify(s->host,1,payload,length,r->authorization_signature) ||
     !s->verify(s->host,2,payload,length,r->evaluation_signature)) {
    status=POO_FLOW_TEMPORAL_DENIED;goto done;
  }
  pthread_mutex_lock(&s->lock);
  if(*s->budget) {
    status=activate_budget(s,r,payload,length,&grant);
    if(status!=POO_FLOW_TEMPORAL_COMMITTED) goto unlock;
    status=POO_FLOW_TEMPORAL_STORAGE_ERROR;
  }
  if(!sql(s->db,"BEGIN IMMEDIATE")) goto unlock;
  now=time(NULL);
  if(now<0 || (uint64_t)now>=r->expires_unix) {status=POO_FLOW_TEMPORAL_EXPIRED;goto rollback;}
  if(sqlite3_prepare_v2(s->db,"SELECT version,revision,payload,signature FROM temporal_selection_v1 WHERE subject=? AND scope=?",-1,&q,NULL)!=SQLITE_OK ||
     !bind_scope(q,r)) goto rollback;
  step=sqlite3_step(q);
  if(step==SQLITE_ROW) {
    const uint8_t *stored=sqlite3_column_blob(q,2),*signature=sqlite3_column_blob(q,3);
    const char *selected=(const char *)sqlite3_column_text(q,1);
    int size=sqlite3_column_bytes(q,2);sqlite3_int64 raw_version=sqlite3_column_int64(q,0);
    version=(uint64_t)raw_version;
    if(raw_version<=0 || !selected || size<=0 || sqlite3_column_bytes(q,3)!=32 ||
       !row_matches(stored,(size_t)size,r->subject,r->scope,selected,version)) {
      status=POO_FLOW_TEMPORAL_CORRUPT;goto rollback;
    }
    signed_bytes=effect_bytes(stored,(size_t)size,version,"poo-flow.temporal.pointer.v1",&total);
    if(!signed_bytes || !s->verify(s->host,3,signed_bytes,total,signature)) {
      status=POO_FLOW_TEMPORAL_CORRUPT;goto rollback;
    }
    free(signed_bytes);signed_bytes=NULL;
    /* Receipt lookup follows pointer integrity validation, including replays. */
    result->version=version;
    if(version!=r->expected_version || strcmp(selected,r->predecessor)) conflict=1;
  } else if(step!=SQLITE_DONE) goto rollback;
  else if(r->expected_version || *r->predecessor) conflict=1;
  sqlite3_finalize(q);q=NULL;
  if(sqlite3_prepare_v2(s->db,"SELECT version,payload,signature FROM temporal_effect_v1 WHERE subject=? AND scope=? AND nonce=?",-1,&q,NULL)!=SQLITE_OK ||
     !bind_scope(q,r) || sqlite3_bind_text(q,3,r->nonce,-1,SQLITE_TRANSIENT)!=SQLITE_OK) goto rollback;
  step=sqlite3_step(q);
  if(step==SQLITE_ROW) {
    const uint8_t *stored=sqlite3_column_blob(q,1),*signature=sqlite3_column_blob(q,2);
    int size=sqlite3_column_bytes(q,1);sqlite3_int64 effect_version=sqlite3_column_int64(q,0);
    if(size!=(int)length || memcmp(stored,payload,length)) {status=POO_FLOW_TEMPORAL_DENIED;goto rollback;}
    signed_bytes=effect_bytes(payload,length,(uint64_t)effect_version,"poo-flow.temporal.effect.v1",&total);
    if(effect_version<=0 || sqlite3_column_bytes(q,2)!=32 || !signed_bytes ||
       !s->verify(s->host,3,signed_bytes,total,signature)) {status=POO_FLOW_TEMPORAL_CORRUPT;goto rollback;}
    status=POO_FLOW_TEMPORAL_REPLAYED;result->version=(uint64_t)effect_version;
    memcpy(result->effect_signature,signature,32);goto rollback;
  }
  if(step!=SQLITE_DONE) goto rollback;
  sqlite3_finalize(q);q=NULL;
  if(conflict) {status=POO_FLOW_TEMPORAL_CONFLICT;goto rollback;}
  version++;
  signed_bytes=effect_bytes(payload,length,version,"poo-flow.temporal.pointer.v1",&total);
  if(!signed_bytes || !s->sign(s->host,signed_bytes,total,state_sig)) goto rollback;
  free(signed_bytes);signed_bytes=NULL;
  if(sqlite3_prepare_v2(s->db,"INSERT INTO temporal_selection_v1 VALUES(?,?,?,?,?,?) ON CONFLICT(subject,scope) DO UPDATE SET version=excluded.version,revision=excluded.revision,payload=excluded.payload,signature=excluded.signature",-1,&q,NULL)!=SQLITE_OK ||
     !bind_scope(q,r) || sqlite3_bind_int64(q,3,(sqlite3_int64)version)!=SQLITE_OK ||
     sqlite3_bind_text(q,4,r->revision,-1,SQLITE_TRANSIENT)!=SQLITE_OK ||
     sqlite3_bind_blob(q,5,payload,(int)length,SQLITE_TRANSIENT)!=SQLITE_OK ||
     sqlite3_bind_blob(q,6,state_sig,32,SQLITE_TRANSIENT)!=SQLITE_OK || sqlite3_step(q)!=SQLITE_DONE) goto rollback;
  sqlite3_finalize(q);q=NULL;
  signed_bytes=effect_bytes(payload,length,version,"poo-flow.temporal.effect.v1",&total);
  if(!signed_bytes || !s->sign(s->host,signed_bytes,total,effect_sig)) goto rollback;
  if(sqlite3_prepare_v2(s->db,"INSERT INTO temporal_effect_v1 VALUES(?,?,?,?,?,?)",-1,&q,NULL)!=SQLITE_OK ||
     !bind_scope(q,r) || sqlite3_bind_text(q,3,r->nonce,-1,SQLITE_TRANSIENT)!=SQLITE_OK ||
     sqlite3_bind_int64(q,4,(sqlite3_int64)version)!=SQLITE_OK ||
     sqlite3_bind_blob(q,5,payload,(int)length,SQLITE_TRANSIENT)!=SQLITE_OK ||
     sqlite3_bind_blob(q,6,effect_sig,32,SQLITE_TRANSIENT)!=SQLITE_OK || sqlite3_step(q)!=SQLITE_DONE) goto rollback;
  sqlite3_finalize(q);q=NULL;
  now=time(NULL);
  if(now<0 || (uint64_t)now>=r->expires_unix) {status=POO_FLOW_TEMPORAL_EXPIRED;goto rollback;}
  if(grant) {
    int64_t elapsed;
    if(clock_gettime(CLOCK_MONOTONIC,&finished)) goto rollback;
    elapsed=(int64_t)(finished.tv_sec-started.tv_sec)*INT64_C(1000000000)+finished.tv_nsec-started.tv_nsec;
    if(elapsed<0 || (uint64_t)(elapsed/1000000+(elapsed%1000000!=0))>grant) {
      status=POO_FLOW_TEMPORAL_BUDGET_EXHAUSTED;goto rollback;
    }
  }
  if(!sql(s->db,"COMMIT")) goto rollback;
  status=POO_FLOW_TEMPORAL_COMMITTED;result->version=version;
  memcpy(result->effect_signature,effect_sig,32);goto unlock;
rollback:
  sqlite3_finalize(q);q=NULL;sql(s->db,"ROLLBACK");
unlock:
  pthread_mutex_unlock(&s->lock);
done:
  sqlite3_finalize(q);free(signed_bytes);free(payload);result->status=status;return status;
}

uint32_t poo_flow_temporal_observe_selection_v1(poo_flow_temporal_store_v1 *s,
    const char *subject,const char *scope,uint8_t *payload,size_t capacity,
    size_t *length,poo_flow_temporal_effect_v1 *result) {
  sqlite3_stmt *q=NULL;uint32_t status=POO_FLOW_TEMPORAL_STORAGE_ERROR;
  uint8_t *bytes=NULL;size_t total=0;int step;
  if(!s || !subject || !scope || !*subject || !*scope || !payload || !length || !result)
    return POO_FLOW_TEMPORAL_INVALID;
  memset(result,0,sizeof(*result));*length=0;
  pthread_mutex_lock(&s->lock);
  if(sqlite3_prepare_v2(s->db,"SELECT version,revision,payload,signature FROM temporal_selection_v1 WHERE subject=? AND scope=?",-1,&q,NULL)!=SQLITE_OK ||
     sqlite3_bind_text(q,1,subject,-1,SQLITE_TRANSIENT)!=SQLITE_OK ||
     sqlite3_bind_text(q,2,scope,-1,SQLITE_TRANSIENT)!=SQLITE_OK) goto done;
  step=sqlite3_step(q);
  if(step==SQLITE_DONE) {status=POO_FLOW_TEMPORAL_ABSENT;goto done;}
  if(step==SQLITE_ROW) {
    sqlite3_int64 version=sqlite3_column_int64(q,0);
    const char *revision=(const char *)sqlite3_column_text(q,1);
    const uint8_t *stored=sqlite3_column_blob(q,2),*signature=sqlite3_column_blob(q,3);
    int size=sqlite3_column_bytes(q,2);
    if(version<=0 || !revision || size<=0 || sqlite3_column_bytes(q,3)!=32 ||
       !row_matches(stored,(size_t)size,subject,scope,revision,(uint64_t)version)) {
      status=POO_FLOW_TEMPORAL_CORRUPT;goto done;
    }
    bytes=effect_bytes(stored,(size_t)size,(uint64_t)version,"poo-flow.temporal.pointer.v1",&total);
    if(!bytes || !s->verify(s->host,3,bytes,total,signature)) {status=POO_FLOW_TEMPORAL_CORRUPT;goto done;}
    if(capacity<(size_t)size) {status=POO_FLOW_TEMPORAL_INVALID;goto done;}
    memcpy(payload,stored,(size_t)size);*length=(size_t)size;
    result->version=(uint64_t)version;memcpy(result->effect_signature,signature,32);
    status=POO_FLOW_TEMPORAL_COMMITTED;
  }
done:
  sqlite3_finalize(q);free(bytes);pthread_mutex_unlock(&s->lock);
  result->status=status;return status;
}
