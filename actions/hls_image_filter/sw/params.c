/*
 * Copyright 2020 International Business Machines
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

#include "params.h" 

static const char *version = "01";

void usage(const char *prog)
{
	printf("Usage: %s [-h] [-v, --verbose] [-V, --version]\n"
	"  -C, --card <cardno>       can be (0...3)\n"
	"  -i, --input <file.bin>    input file.\n"
	"  -o, --output <file.bin>   output file.\n"
	"  -t, --timeout             timeout in sec to wait for done.\n"
	"  -N, --no-irq              disable Interrupts\n"
	"\n"
	"Useful parameters (to be placed before the command):\n"
	"----------------------------------------------------\n"
	"SNAP_TRACE=0x0   no debug trace  (default mode)\n"
	"SNAP_TRACE=0xF   full debug trace\n"
	"SNAP_CONFIG=FPGA hardware execution   (default mode)\n"
	"SNAP_CONFIG=CPU  software execution\n"
	"\n"
	"Example on a real card:\n"
	"-----------------------\n"
        "cd ~/oc-accel && export ACTION_ROOT=~/oc-accel/actions/hls_image_filter\n"
        "source snap_path.sh\n"
        "echo locate the slot number used by your card\n"
        "oc_find_card -v -AALL\n"
        "echo discover the actions in card in slot 0\n"
        "oc_maint -vv -C0\n"
        "\n"
	"echo Run the application + hardware action on FPGA\n"
	"snap_image_filter -i ./actions/hls_image_filter/sw/tiger.bmp -o ./actions/hls_image_filter/sw/tiger_filtered.bmp\n"
	"...\n"
	"echo Run the application + software action on CPU\n"
	"\n"
        "Example for a simulation\n"
        "------------------------\n"
        "\n"
        "echo clean possible temporary old files \n"
	"rm tiger_small_filtered.bmp\n"
	"\n"
	"echo Run the application + hardware action on the FPGA emulated on CPU\n"
	"snap_image_filter -i ../../../../actions/hls_image_filter/sw/tiger_small.bmp -o tiger_small_filtered.bmp\n"
	"\n"
	"echo Run the application + software action on with trace ON\n"
	"SNAP_TRACE=0xF snap_image_filter -i ../../../../actions/hls_image_filter/sw/tiger_small.bmp -o tiger_small_filtered.bmp\n"
	"\n",
        prog);
}

/* readParams will parse the application parameters       */
STRparam* readParams(int argc, char *argv[])
{
	int ch;

	// collecting the command line arguments
	//const char *default_output = "test.bmp";
	
	//parms.output = default_output;
	while (1) {
		int option_index = 0;
		static struct option long_options[] = {
			{ "card",	 required_argument, NULL, 'C' },
			{ "input",	 required_argument, NULL, 'i' },
			{ "output",	 required_argument, NULL, 'o' },
			{ "timeout",	 required_argument, NULL, 't' },
			{ "no-irq",	 no_argument,	    NULL, 'N' },
			{ "version",	 no_argument,	    NULL, 'V' },
			{ "verbose",	 no_argument,	    NULL, 'v' },
			{ "help",	 no_argument,	    NULL, 'h' },
			{ 0,		 no_argument,	    NULL, 0   },
		};

		ch = getopt_long(argc, argv,
                                 "C:i:o:t:NVvh",
				 long_options, &option_index);
		if (ch == -1)
			break;

		switch (ch) {
		case 'C':
			parms.card_no = strtol(optarg, (char **)NULL, 0);
			break;
		case 'i':
			parms.input = optarg;
			break;
		case 'o':
			parms.output = optarg;
			break;
			/* input data */
                case 't':
                        parms.timeout = strtol(optarg, (char **)NULL, 0);
                        break;		
                case 'N':
                        parms.action_irq = 0;
                        break;
			/* service */
		case 'V':
			printf("%s\n", version);
			exit(EXIT_SUCCESS);
		case 'v':
			parms.verbose_flag = 1;
			break;
		case 'h':
			usage(argv[0]);
			exit(EXIT_SUCCESS);
			break;
		default:
			usage(argv[0]);
			exit(EXIT_FAILURE);
		}
	}

	if (optind != argc) {
		usage(argv[0]);
		exit(EXIT_FAILURE);
	}
	if (argc == 1) {       // to provide help when program is called without argument
	  usage(argv[0]);
	  exit(EXIT_FAILURE);
	}
	
	return(&parms);
		
}


