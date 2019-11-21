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

#ifndef __SNAP_CONSTANTS__
#define __SNAP_CONSTANTS__

/* Header file for SNAP Framework nvdla code */
#define ACTION_TYPE_NVDLA     0x00000006    /* Action Type */

#define ACTION_INT_HANDLER_HI       0x00000018    /* Global Interrupt Handler High */
#define ACTION_INT_HANDLER_LO       0x0000001C    /* Global Interrupt Handler Low */
#define ACTION_INT_CTRL             0x00000030    /* Global Interrupt Control */
#define ACTION_INT_MASK             0x00000034    /* Global Interrupt Mask */

#endif/* __SNAP_CONSTANTS__ */
