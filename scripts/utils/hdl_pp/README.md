# A tool to support embedded perl in verilog/vhdl

You can use the following syntax to insert perl in verilog:

test.v:
```
module foo ();
//: my $x = X;
//: my $y = Y;
//: for (my $i = 0; $i < 16; $i++) {
//: print qq(
//:     wire    [$x*$y:0] bufin_pd_$i;
//: );
//: }

endmodule

```

def.h:
```
#define X 8
#define Y 8

```

Run command:
```
$ ./vcp -i test.v -o test.v.vcp -imacros ./def.h -cpp /bin/cpp
$ perl -I ./plugins -Meperl ./eperl -o test.v.generated test.v.vcp
```

In test.v.generated, you will see:
```
module foo ();
//: my $x = 8;
//: my $y = 8;
//: for (my $i = 0; $i < 16; $i++) {
//: print qq(
//: wire [$x*$y:0] bufin_pd_$i;
//: );
//: }
//| eperl: generated_beg (DO NOT EDIT BELOW)

wire [8*8:0] bufin_pd_0;

wire [8*8:0] bufin_pd_1;

wire [8*8:0] bufin_pd_2;

wire [8*8:0] bufin_pd_3;

wire [8*8:0] bufin_pd_4;

wire [8*8:0] bufin_pd_5;

wire [8*8:0] bufin_pd_6;

wire [8*8:0] bufin_pd_7;

wire [8*8:0] bufin_pd_8;

wire [8*8:0] bufin_pd_9;

wire [8*8:0] bufin_pd_10;

wire [8*8:0] bufin_pd_11;

wire [8*8:0] bufin_pd_12;

wire [8*8:0] bufin_pd_13;

wire [8*8:0] bufin_pd_14;

wire [8*8:0] bufin_pd_15;

//| eperl: generated_end (DO NOT EDIT ABOVE)
endmodule
```

# The tool is copied from the open source project NVDLA

See details in github:
`https://github.com/nvdla/hw/tree/nvdlav1/tools/bin`

`https://github.com/nvdla/hw/tree/nvdlav1/vmod/plugins`
