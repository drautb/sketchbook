use core::ops::Index;
use std::fs::File;

use memmap::Mmap;

pub struct Rom {
    pub data: Mmap,
}

impl Rom {
    pub fn load_binary(filepath: String) -> Self {
        let file = File::open(filepath).expect("Failed to open ROM file");
        let metadata = file.metadata().expect("Failed to get file metadata");
        if metadata.len() > 65_536 {
            panic!(
                "ROM file length must be less than 65,536 bytes, but was {}",
                metadata.len()
            );
        }

        let mmap = unsafe { Mmap::map(&file).expect("Failed to mmap ROM") };
        Rom { data: mmap }
    }
}

impl Index<usize> for Rom {
    type Output = u8;

    fn index(&self, idx: usize) -> &Self::Output {
        &self.data[idx]
    }
}
