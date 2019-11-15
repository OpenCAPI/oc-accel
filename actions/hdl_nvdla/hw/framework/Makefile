v_srcs=$(wildcard *.v_source)
v_files=$(v_srcs:.v_source=.v)
vcp_files=$(v_srcs:.v_source=.vcp)
vinter_files=$(v_srcs:.v_source=.vinter)

.PHONY: all config clean vhdl

all: config

config:


clean:
	@$(RM) $(v_files)
	@$(RM) $(vcp_files)
	@$(RM) $(vinter_files)

vhdl:
