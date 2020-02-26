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

#include "HardwareManager.h"
#include "constants.h"

HardwareManager::HardwareManager (int in_card_num)
    : m_card_num (in_card_num),
      m_capi_card (NULL),
      m_capi_action (NULL),
      m_attach_flags ((snap_action_flag_t)0),
      m_context (NULL),
      m_num_engines (0),
      m_timeout_sec (0),
      m_timeout_usec (1000)
{
}

HardwareManager::HardwareManager (int in_card_num, int in_timeout_sec, int in_timeout_usec)
    : m_card_num (in_card_num),
      m_capi_card (NULL),
      m_capi_action (NULL),
      m_attach_flags ((snap_action_flag_t)0),
      m_context (NULL),
      m_num_engines (0),
      m_timeout_sec (in_timeout_sec),
      m_timeout_usec (in_timeout_usec)
{
}

HardwareManager::~HardwareManager()
{
    elog (DEBUG5, "Hardware manager destroyed!");
}

int HardwareManager::init()
{
    m_context = (CAPIContext*) palloc0 (sizeof (CAPIContext));

    if (capi_regex_context_init (m_context)) {
        return -1;
    }

    m_capi_card = m_context->dn;
    m_capi_action = m_context->act;
    m_attach_flags = m_context->attach_flags;

    // This is a global register, make ID to -1
    uint32_t hw_version = action_read (m_context->dn, SNAP_ACTION_VERS_REG, -1);

    int num_patt_pipes = (int) ((hw_version & 0xFF000000) >> 24);
    int num_pkt_pipes = (int) ((hw_version & 0x00FF0000) >> 16);
    int num_engines = (int) ((hw_version & 0x0000FF00) >> 8);
    int revision = (int) (hw_version & 0x000000FF);

    elog (INFO, "Running with %d %dx%d regex engine(s), revision: %d", num_engines, num_pkt_pipes, num_patt_pipes, revision);

    // TODO: workaround for old hardware which don't have configuration information in version register
    if (0 == num_engines) {
        elog (INFO, "Warning! Number of engines == 0, old hardware? Workaround number of engines to 1");
        m_num_engines = 1;
    } else {
        m_num_engines = num_engines;
    }

    return 0;
}

void HardwareManager::reg_write (uint32_t in_addr, uint32_t in_data, int in_eng_id)
{
    action_write (m_capi_card, in_addr, in_data, in_eng_id);
    return;
}

uint32_t HardwareManager::reg_read (uint32_t in_addr, int in_eng_id)
{
    return action_read (m_capi_card, in_addr, in_eng_id);
}

void HardwareManager::cleanup()
{
    //soft_reset (m_capi_card);

    snap_detach_action (m_capi_action);
    snap_card_free (m_capi_card);

    if (m_context) {
        pfree (m_context);
    }

    elog (INFO, "Deattach the card.");
}

int HardwareManager::wait_interrupt()
{
    // TODO: not implemented yet
    //if (snap_action_wait_interrupt (m_capi_action, m_timeout_sec, m_timeout_usec)) {
    //    //std::cout << "Retry waiting interrupt ... " << std::endl;
    //    return -1;
    //}

    return 0;
}

CAPIContext* HardwareManager::get_context()
{
    return m_context;
}

void HardwareManager::reset_engine (int in_eng_id)
{
    soft_reset (m_capi_card, in_eng_id);
}

int HardwareManager::get_num_engines ()
{
    return m_num_engines;
}
