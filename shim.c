#include <efi.h>
#include <efilib.h>

VOID
msleep(unsigned long msecs){
  uefi_call_wrapper(BS->Stall, 1, msecs);
}


extern void rust_hello(void);

void c_hello(void){};


EFI_STATUS
efi_main (EFI_HANDLE image_handle, EFI_SYSTEM_TABLE *systab){
  EFI_STATUS efi_status;

  InitializeLib(image_handle, systab);

  Print(L"Hello, World!!!\n");
  msleep(200000);
  c_hello();
  rust_hello();
  msleep(8000000);
  Print(L"Exiting\n");
  msleep(2000000);

  efi_status = EFI_NOT_FOUND; //drops to EFI shell.
  return efi_status;
}
