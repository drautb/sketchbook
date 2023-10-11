use emu_6502::cpu::Cpu;
use emu_6502::rom::Rom;

use std::io::{stdin, stdout, Read, Write};

fn pause() {
    let mut stdout = stdout();
    stdout.write(b"Press any key to continue...").unwrap();
    stdout.flush().unwrap();
    stdin().read(&mut [0]).unwrap();
}

fn main() {
    let mut cpu = Cpu::new();
    let mut mem = [0; 65_536];
    let rom = Rom::load_binary("binary.out".to_string());

    loop {
        cpu.step(&rom, &mut mem);
        println!("{}", cpu);
        pause();
    }
}
