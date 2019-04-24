#![no_std]

#![feature(asm)] 
#![feature(panic_info_message)]

// memset, memcopy, ...
extern crate rlibc;

extern{
    //EFI_STATUS is u64 on my 64bit system

    fn Output(str: *const u16);
}

// improvised attempt to convert to wide string without memory management.
fn uefi_str(rstr: &'static str) -> [u16; 500] {
    let mut s: [u16; 500] = [0; 500];
    for (i, c) in rstr.chars().enumerate() {
        let ucs2_char: u16 = c as u16;
        s[i] = ucs2_char;
    }
    return s
}

// improvised attempt to convert to wide string at compile time.
macro_rules! wide {
    ( $( $x:expr ),* ) => {
        {
            let tmp_str = [
            $(
                $x as u16,
            )*
			'\0' as u16];
            tmp_str
        }
    };
}

//TODO check out https://docs.rs/wchar/0.2.0/wchar/

#[no_mangle]
pub extern fn rust_hello() {
    // I'm too lazy to type a wide char string by hand in rust.
    let s1 = [':' as u16, ')' as u16, '\r' as u16, '\n' as u16, 0];
    // A macro does not help much, since I can't find a way to iterate a string at compile time.
    // At least `strings --encoding=l` will find this string.
    let s2 = wide!('H', 'e', 'l', 'l', 'o', ',', ' ', 'W', 'o', 'r', 'l', 'd', ',', ' ', 'f', 'r', 'o', 'm', ' ', 'R', 'u', 's', 't', '!','\r', '\n');
    unsafe{
        Output(s1.as_ptr());
		Output(s2.as_ptr());
        // This string will appear as utf8 string in the binary and only gets converted as runtime.
        Output(uefi_str("Hello, world, from rust with uefi_str\r\n\0").as_ptr());
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
