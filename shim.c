#include <efi.h>
#include <efilib.h>

// EFI system table
EFI_SYSTEM_TABLE        *ST;
// boot services table
EFI_BOOT_SERVICES       *BS;

VOID
msleep(unsigned long msecs){
  uefi_call_wrapper(BS->Stall, 1, msecs);
}


extern void rust_hello(void);

void c_hello(void){};

void Output(CHAR16 *str){
  uefi_call_wrapper(ST->ConOut->OutputString, 2, ST->ConOut, str);
}



EFI_STATUS
efi_main (EFI_HANDLE image_handle, EFI_SYSTEM_TABLE *systab){
  EFI_STATUS efi_status;

  // gnuefi would want us to call InitializeLib(image_handle, systab).
  // However, we don't link against libefi (from gnuefi).
  // Since our Output and msleep functions use those global variables, we need to set them.
  ST = systab;
  BS = systab->BootServices;

  Output(L"Hello, World from C.\r\n");
  msleep(200000);
  c_hello();
  rust_hello();
  msleep(8000000);
  Output(L"Exiting\n");
  msleep(2000000);

  efi_status = EFI_NOT_FOUND; //drops to EFI shell.
  return efi_status;
}
