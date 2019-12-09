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
      m_timeout_sec (0),
      m_timeout_usec (1000)
{
    //printf("create hardware manager\n");
}

HardwareManager::HardwareManager (int in_card_num, int in_timeout_sec, int in_timeout_usec)
    : m_card_num (in_card_num),
      m_capi_card (NULL),
      m_capi_action (NULL),
      m_attach_flags ((snap_action_flag_t)0),
      m_timeout_sec (in_timeout_sec),
      m_timeout_usec (in_timeout_usec)
{
    //printf("create hardware manager\n");
}


HardwareManager::HardwareManager (int in_card_num,
                                 CAPICard* in_capi_card,
                                 CAPIAction* in_capi_action,
                                 snap_action_flag_t in_attach_flags,
                                 int in_timeout_sec, int in_timeout_usec)
    : m_card_num (in_card_num),
      m_capi_card (in_capi_card),
      m_capi_action (in_capi_action),
      m_attach_flags (in_attach_flags),
      m_timeout_sec (in_timeout_sec),
      m_timeout_usec (in_timeout_usec)
{
    //printf("create hardware manager\n");
}

HardwareManager::~HardwareManager()
{
}

int HardwareManager::init()
{
    // Prepare the card and action
    if (NULL == m_capi_card) {
        printf ("ERROR: CAPI card is NULL\n");
        return -1;
    }

    if (NULL == m_capi_action) {
        printf ("ERROR: cannot get action. Actions is NULL\n");
        return -1;
    }

    return 0;

}

void HardwareManager::reg_write (uint32_t in_addr, uint32_t in_data, int in_eng_id)
{
    action_write (m_capi_card, REG(in_addr, in_eng_id), in_data);
    return;
}

uint32_t HardwareManager::reg_read (uint32_t in_addr, int in_eng_id)
{
    return action_read (m_capi_card, REG(in_addr, in_eng_id));
}

void HardwareManager::cleanup()
{
    //printf("cleaning hardware manager... do nothing.\n");
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

void HardwareManager::reset_engine (int in_eng_id)
{
    soft_reset (m_capi_card, in_eng_id);
}

CAPICard* HardwareManager::get_capi_card()
{
    return m_capi_card;
}

