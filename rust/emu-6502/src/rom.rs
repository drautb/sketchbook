use std::fs::File;

use memmap::Mmap;

pub struct Rom {
    pub data: Mmap,
}

impl Rom {
    pub fn load_binary(filepath: String) -> Self {
        let file = File::open(filepath).expect("Failed to open ROM file");
        let metadata = file.metadata().expect("Failed to get file metadata");
        if metadata.len() != 32768 {
            panic!(
                "ROM file length must be exactly 32,768 bytes, but was {}",
                metadata.len()
            );
        }

        let mmap = unsafe { Mmap::map(&file).expect("Failed to mmap ROM") };
        Rom { data: mmap }
    }
}
