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
#ifndef __ACTION_CHANGECASE_H__
#define __ACTION_CHANGECASE_H__

/*
 * Copyright 2017 International Business Machines
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

#include <osnap_types.h>

#ifdef __cplusplus
extern "C" {
#endif

// ------------ MUST READ -----------
// ACTION_TYPE and RELEASE_LEVEL are automatically handled. 
// 1. Define them in header file (here), use HEX 32bits numbers
// 2. They will be extracted by hardware/setup/patch_version.sh
// 3. And put into snap_global_vars.v
// 4. Used by hardware/hdl/hls/action_wrapper.v
#define ACTION_TYPE               0x10143009
#define RELEASE_LEVEL             0x00000010
// When using oc_maint, Action descriptions are decoded with the help of software/tools/snap_actions.h
// Please modify this file so oc_maint can recognize this action.
// ------------ MUST READ -----------


/* Data structure used to exchange information between action and application */
/* Size limit is 108 Bytes */
typedef struct helloworld_1024_job {
	struct snap_addr in;	/* input data */
	struct snap_addr out;   /* offset table */
} helloworld_1024_job_t;

#ifdef __cplusplus
}
#endif

#endif	/* __ACTION_CHANGECASE_H__ */
