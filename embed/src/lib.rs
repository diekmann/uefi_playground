#![no_std]

#![feature(asm)] 
#![feature(panic_info_message)]

// memset, memcopy, ...
extern crate rlibc;

extern{
    //returns EFI_STATUS which is u64 on my 64bit system
    fn Print(str: *const u16, ...) -> i64;
}

fn uefi_str(rstr: &'static str) -> [u16; 500] {
    let mut s: [u16; 500] = [0; 500];
    for (i, c) in rstr.chars().enumerate() {
        let ucs2_char: u16 = c as u16;
        s[i] = ucs2_char;
    }
    return s
}

#[no_mangle]
pub extern fn rust_hello() {
    let s = ['H' as u16, 'e' as u16, '\r' as u16, '\n' as u16, 0];
    unsafe{
        Print(s.as_ptr());
        //Print(uefi_str("Hello, world, str2\r\n").as_ptr());
    }
}



#[panic_handler]
fn panic_handler(_info: &core::panic::PanicInfo) -> ! {
	//TODO
    loop {
        unsafe {
            asm!("hlt" :::: "volatile");
        }
    }
}
