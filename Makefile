CC = gcc
LD = ld
OBJCOPY = objcopy

ARCH ?= $(shell $(CC) -dumpmachine | cut -f1 -d- | sed s,i[3456789]86,ia32,)
OBJCOPY_GTE224 = $(shell expr `$(OBJCOPY) --version |grep ^"GNU objcopy" | sed 's/^.*\((.*)\|version\) //g' | cut -f1-2 -d.` \>= 2.24)

EFI_INCLUDE	:= /usr/include/efi
EFI_INCLUDES = -nostdinc -I$(EFI_INCLUDE) -I$(EFI_INCLUDE)/$(ARCH) -I$(EFI_INCLUDE)/protocol

LIB_GCC = $(shell $(CC) -print-libgcc-file-name)
EFI_LIBS = -lgnuefi $(LIB_GCC) -lefi

EFI_CRT_OBJS = $(EFI_PATH)/crt0-efi-$(ARCH).o
EFI_LDS = elf_$(ARCH)_efi.lds

CFLAGS = -ggdb -O2 -fno-stack-protector -fno-strict-aliasing -fpic \
		-fshort-wchar -Wall -Wsign-compare -Werror -fno-builtin \
		-Werror=sign-compare -ffreestanding -std=gnu89 \
		-mno-mmx -mno-sse -mno-red-zone -nostdinc \
		-maccumulate-outgoing-args \
		-DEFI_FUNCTION_WRAPPER -DGNU_EFI_USE_MS_ABI \
		-DNO_BUILTIN_VA_FUNCS -DMDE_CPU_X64 -DPAGE_SIZE=4096 \
		"-DEFI_ARCH=L\"x64\"" \
		-I$(shell $(CC) -print-file-name=include) \
		$(EFI_INCLUDES)

FORMAT ?= --target efi-app-$(ARCH)
EFI_PATH ?= /usr/lib64/gnuefi

LDFLAGS = --hash-style=sysv -nostdlib -znocombreloc -T $(EFI_LDS) -shared -Bsymbolic -L$(EFI_PATH) -L/usr/lib64 $(EFI_CRT_OBJS) --build-id=sha1 --no-undefined

all: shimx64.efi

shim.o: shim.c
	$(CC) $(CFLAGS) -c -o shim.o shim.c

.PHONY: libembed.a

libembed.a:
ifneq ($(ARCH),x86_64)
	$(error only tested on X64)
endif
	$(MAKE) -C embed/ all
	# we keep rust in its won directory
	cp embed/target/release/libembed.a libembed.a

shimx64.so: shim.o libembed.a
	$(LD) -o $@ $(LDFLAGS) $^ $(EFI_LIBS) 

shimx64.efi: shimx64.so
ifneq ($(OBJCOPY_GTE224),1)
	$(error objcopy >= 2.24 is required)
endif
	$(OBJCOPY) -j .text -j .sdata -j .data -j .data.ident \
		-j .dynamic -j .dynsym -j .rel* \
		-j .rela* -j .reloc -j .eh_frame \
		-j .text.* \
		$(FORMAT) $^ $@
# The rust stuff ends up in its own .text.... section, we need to copy it over

clean:
	$(MAKE) -C embed/ clean
	rm -rf efi_test/
	rm -f *.o
	rm -f *.debug *.so *.efi *.efi.*
	rm -f libembed.a

run: shimx64.efi
	mkdir -p efi_test/EFI/BOOT
	cp shimx64.efi efi_test/EFI/BOOT/BOOTx64.EFI && echo okay
	qemu-system-x86_64 -L /usr/share/ovmf/ --bios OVMF.fd -drive media=disk,file=fat:rw:./efi_test,format=raw -net none -serial stdio
