#
# Makefile
#

all:

.PHONY += help
help:
	@echo "OCACCEL configuration system"
	@echo
	@echo "  Please ensure that you have installed your Linux kernel"
	@echo "  sources and the tools to build and configure it. We are"
	@echo "  using the same infrastructure to generate the OCACCEL"
	@echo "  configuration files."
	@echo
	@echo "Possible targets are:"
	@echo "  menuconfig - use menuconfig/ncurses"
	@echo "  gconfig    - use gconfig/GTK+"
	@echo "  xconfig    - use xconfig/QT"
	@echo "  config     - use config/command line version"
	@echo "  prepare    - generate configuration specific header."
	@echo

.PHONY += menuconfig gconfig xconfig config oldconfig silentoldconfig prepare clean distclean
menuconfig gconfig xconfig config oldconfig silentoldconfig prepare: Kconfig
	./ocaccel_cfg -o $@ 2>/dev/null

install:

uninstall:

clean:
	$(RM) build/config build/*~ *~

distclean: clean
	$(RM) ../software/include/autoconf.h
