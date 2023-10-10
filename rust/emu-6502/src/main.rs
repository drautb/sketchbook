use emu_6502::cpu::Cpu;
use emu_6502::rom::Rom;

fn main() {
    let _c = Cpu::new();

    let rom = Rom::load_binary("binary.out".to_string());

    println!(
        "Welocme! First byte: {:#04X} Size: {}",
        rom.data[0],
        rom.data.len()
    );
}
