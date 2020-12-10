## Action Type Assignment
Vendor | Range Start | Range End | Description
:--- | :--- | :--- | :---
Reserved | 00.00.00.00 | 00.00.00.00 | Reserved
free  00.00.00.01 | 00.00.FF.FF | Free for experimental use
IBM | 10.14.20.00 | 10.14.20.00 | HDL_example in VHDL  (512b)
IBM | 10.14.20.02 | 10.14.20.02 | HDL single_engine in Verilog (1024b)
IBM | 10.14.20.04 | 10.14.20.04 | UVM test for unit verification (no OCSE and software)
IBM | 10.14.20.0E | 10.14.20.0E | HDL_multi-process example
IBM | 10.14.20.0F | 10.14.0F.FF | Reserved for HDL IBM Actions
IBM | 10.14.30.04 | 10.14.30.04 | HLS Helloworld_python (1024b)
IBM | 10.14.30.08 | 10.14.30.08 | HLS Helloworld_512    (512b)
IBM | 10.14.30.09 | 10.14.30.09 | HLS Helloworld_1024   (1024b)
IBM | 10.14.30.0B | 10.14.30.0B | HLS Memcopy_1024 (1024b)
IBM | 10.14.30.0C | 10.14.30.0C | HLS HBM Memcopy  (1024b)
IBM | 10.14.30.0D | 10.14.30.0D | HLS Image_Filter  (512b)
IBM | 10.14.30.0E | 10.14.30.0E | HLS Memcopy_512   (512b)
IBM | 10.14.30.0F | 10.14.30.0F | HLS Decimal Mult  (512b)
IBM | 10.14.30.10 | 10.14.30.10 | HLS UDP           (512b)
IBM | 10.14.30.11 | 10.14.FF.FF | Reserved for HLS IBM Actions
PSI | 52.32.01.00 | 52.32.01.00 | JUNGFRAU X-ray Detector Data Acquisition and Analysis
PSI | 52.32.01.01 | 52.32.01.FF | X-ray Detector Data Acquisition and Analysis
Reserved | FF.FF.00.00 | FF.FF.FF.FF | Reserved

### How to apply for a new Action Type

With every line in the table above a range of Action Type IDs is
being reserved for a specific vendor or the range is defined as
*reserved* (not to be used) or as *free* (for experimental use).

Each new action type should get a unique number.
The number is defined as pair of 16-bit vendor and 16-bit action id.
To obtain a number, please add the new action type in the table above.
Create a git pull request and get it approved and included
(see instructions in [./CONTRIBUTING.md](./CONTRIBUTING.md).
By following this procedure duplicate action types will be avoided.
For the first 16 bit of your action types you may use your own 16-bit
vendor id.
