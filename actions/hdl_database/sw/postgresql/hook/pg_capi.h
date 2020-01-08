/*
 * Copyright 2019 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef __PG_CAPI_H__
#define __PG_CAPI_H__

#include "postgres.h"
#include "access/relscan.h"
#include "access/sysattr.h"
#include "catalog/pg_operator.h"
#include "catalog/pg_type.h"
#include "commands/defrem.h"
#include "commands/explain.h"
#include "executor/executor.h"
#include "executor/nodeCustom.h"
#include "fmgr.h"
#include "miscadmin.h"
#include "nodes/makefuncs.h"
#include "nodes/nodeFuncs.h"
#include "optimizer/clauses.h"
#include "optimizer/cost.h"
#include "optimizer/paths.h"
#include "optimizer/pathnode.h"
#include "optimizer/plancat.h"
#include "optimizer/planmain.h"
#include "optimizer/placeholder.h"
#include "optimizer/restrictinfo.h"
#include "optimizer/subselect.h"
#include "parser/parsetree.h"
#include "storage/bufmgr.h"
#include "storage/itemptr.h"
#include "utils/builtins.h"
#include "utils/fmgroids.h"
#include "utils/guc.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/rel.h"
#include "utils/ruleutils.h"
#include "utils/spccache.h"
#include "funcapi.h"
#include "pg_capi_internal.h"

/*
 * PGCAPIScanState - state object of PGCAPIscan on executor.
 * Job descriptors and relation information is passed with this struct.
 */
typedef struct PGCAPIScanState_s {
    CustomScanState          css;

    // Relation related variables
    List*                    PGCAPI_quals;
    AttInMetadata*           attinmeta;

    // Capi related variables and job descriptors
    const char*              capi_regex_pattern;
    int                      capi_regex_attr_id;
    CAPIRegexJobDescriptor** capi_regex_job_descs;
    int                      capi_regex_curr_job;
    int                      capi_regex_num_jobs;
} PGCAPIScanState;

#endif  /* PG_CAPI_H */
