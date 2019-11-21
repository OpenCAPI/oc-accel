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
// ****************************************************************
// (C) Copyright International Business Machines Corporation 2017
// Author: Gou Peng Fei (shgoupf@cn.ibm.com)
// ****************************************************************

#include <iostream>
#include <string>
#include <vector>
#include <map>
#include "regex_ref.h"
#include "constants.h"
#include "re_match.h"

using namespace std;

class RegexRef
{
public:
    RegexRef()
    {
        patterns.clear();
        stats.clear();
        num_matched_packets = 0;
    }
    ~RegexRef() {}

    void push_pattern (string & in_patt)
    {
        patterns.push_back (in_patt);
    }

    void run_match ()
    {
        if (patterns.size() == 0) {
            cout << "WARNING! No patterns in regex_ref" << endl;
        }

        if (packets.size() == 0) {
            cout << "WARNING! No packets in regex_ref" << endl;
        }

        for (uint32_t i = 0; i < packets.size(); i++) {
            for (uint32_t j = 0; j < patterns.size(); j++) {
                // PATTERN ID and PACKET ID start from 1
                if (gen_result (packets[i], i + 1, patterns[j], j + 1)) {
                    break;
                }
            }
        }
    }

    void push_packet (string & in_pkt)
    {
        packets.push_back (in_pkt);
    }

    sm_stat get_result (uint32_t in_pkt_id)
    {
        if (stats.find(in_pkt_id) == stats.end()) {
            stats[in_pkt_id].packet_id = 0;
            stats[in_pkt_id].pattern_id = 0;
            stats[in_pkt_id].offset = 0;
        }

        return stats[in_pkt_id];
    }

    int get_num_matched_pkt()
    {
        return num_matched_packets;
    }

private:
    vector<string> patterns;
    vector<string> packets;

    // <key = PKT ID, value = sm_stat>
    map<uint32_t, sm_stat> stats;

    int num_matched_packets;

    int gen_result (string & in_pkt, uint32_t in_pkt_id,
                    string & in_patt, uint32_t in_patt_id)
    {
        int offset = re_match_mod (in_patt.c_str(), in_pkt.c_str());

        if (offset == -2) {
            cout << "WARNING! Pattern[ " << dec << in_patt_id << "] "
                 << in_patt << " compiled error" << endl;
            return 1;
        }

        if (offset == -1) {
            cout << "WARNING! Pattern[ "
                 << dec << in_patt_id << "] " << in_patt
                 << " match error on packet["
                 << dec << in_pkt_id << "] " << in_pkt
                 << endl;
            return 1;
        }

        if ((offset != 0) && (in_pkt != "")) {
            cout << "offset " << offset << " on pkt " << in_pkt_id << endl; 
            if (stats.find (in_pkt_id) == stats.end()) {
                stats[in_pkt_id].pattern_id = 0;
                stats[in_pkt_id].packet_id = 0;
                stats[in_pkt_id].offset = 0;
            }

            if (stats[in_pkt_id].pattern_id <= 0) {
                num_matched_packets++;
            }

            if ((stats[in_pkt_id].pattern_id <= 0) ||
                ((stats[in_pkt_id].pattern_id > 0) && (stats[in_pkt_id].offset > offset))) {
                stats[in_pkt_id].pattern_id = in_patt_id;
                stats[in_pkt_id].offset = offset;
                stats[in_pkt_id].packet_id = in_pkt_id;
            }

            if ((stats[in_pkt_id].pattern_id > 0) && ((stats[in_pkt_id].pattern_id % NUM_OF_PU) == 0)) {
                return 1;
            }
        }

        return 0;
    }
};

RegexRef regex_ref;

void regex_ref_push_pattern (const char* in_patt)
{
    string patt (in_patt);
    // Need to push in the patt id order
    regex_ref.push_pattern (patt);
}

void regex_ref_push_packet (const char* in_pkt)
{
    string pkt (in_pkt);
    regex_ref.push_packet (pkt);
}

void regex_ref_run_match()
{
    regex_ref.run_match ();
}

sm_stat regex_ref_get_result (uint32_t in_pkt_id)
{
    return regex_ref.get_result (in_pkt_id);
}

int regex_ref_get_num_matched_pkt()
{
    return regex_ref.get_num_matched_pkt();
}
