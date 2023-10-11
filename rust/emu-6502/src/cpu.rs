#![allow(non_camel_case_types)]

/**
 * https://www.westerndesigncenter.com/wdc/documentation/w65c02s.pdf
 * https://eater.net/datasheets/w65c02s.pdf
 * https://www.pagetable.com/c64ref/6502/?cpu=65c02s
 */
use std::fmt;
use std::num::Wrapping;
use std::ops::Index;
use std::ops::IndexMut;

#[derive(Debug)]
enum AddressMode {
    ABS,
    AII,
    AIX,
    AIY,
    AI,
    ACC,
    IMMEDIATE,
    ZP,
    ZPII,
    ZPIX,
    ZPIY,
    ZPI,
    ZPIIY,
}

#[derive(Debug)]
enum Instruction {
    ADC(u8, AddressMode), // ADd memory to accumulator with Carry
    AND(u8, AddressMode), // AND memory with accumulator
    ASL(u8, AddressMode), // Arithmetic Shift one bit Left, memory or accumulator

    BBR(u8, u8), // Branch on Bit Reset
    BBS(u8, u8), // Branch on Bit Set

    BCC(u8), // Branch on Carry Clear (Pc=0)
    BCS(u8), // Branch on Carry Set (Pc=1)
    BEQ(u8), // Branch if EQual (Pz=1)

    BIT(u8, AddressMode), // BIt Test

    BMI(u8), // Branch if result MInus (Pn=1)
    BNE(u8), // Branch if result Not Equal (Pz=0)
    BPL(u8), // Branch if result PLus (Pn=0)
    BRA(u8), // BRanch Always
    BRK(u8), // BReaK instruction
    BVC(u8), // Branch on oVerflow Clear (Pv=0)
    BVS(u8), // Branch on oVerflow Set (Pv=1)

    CLC(u8), // CLear Carry flag
    CLD(u8), // CLear Decimal mode
    CLI(u8), // CLear Interrupt disable bit
    CLV(u8), // CLear oVerflow flag

    CMP(u8, AddressMode), // CoMPare memory and accumulator

    CPX(u8, AddressMode), // ComPare memory and X register

    CPY(u8, AddressMode), // ComPare memory and Y register

    DEC(u8, AddressMode), // DECrement memory or accumulate by one

    DEX(u8), // DEcrement X by one
    DEY(u8), // DEcrement Y by one

    EOR(u8, AddressMode), // Exclusive OR memory with accumulate

    INC(u8, AddressMode), // INCrement memory or accumulate by one

    INX(u8), // INcrement X register by one
    INY(u8), // INcrement Y register by one

    JMP(u8, AddressMode), // JuMP to new location

    JSR(u8), // Jump to new location Saving Return (Jump to SubRoutine)

    LDA(u8, AddressMode), // LoaD Accumulator with memory

    LDX(u8, AddressMode), // LoaD the X register with memory

    LDY(u8, AddressMode), // LoaD the Y register with memory

    LSR(u8, AddressMode), // Logical Shift one bit Right memory or accumulator

    NOP(u8), // No OPeration

    ORA(u8, AddressMode), // "OR" memory with Accumulator

    PHA(u8), // PusH Accumulator on stack
    PHP(u8), // PusH Processor status on stack
    PHX(u8), // PusH X register on stack
    PHY(u8), // PusH Y register on stack
    PLA(u8), // PuLl Accumulator from stack
    PLP(u8), // PuLl Processor status from stack
    PLX(u8), // PuLl X register from stack
    PLY(u8), // PuLl Y register from stack

    RMB(u8, u8), // Reset Memory Bit

    ROL(u8, AddressMode), // ROtate one bit Left memory or accumulator

    ROR(u8, AddressMode), // ROtate one bit Right memory or accumulator

    RTI(u8), // ReTurn from Interrupt
    RTS(u8), // ReTurn from Subroutine

    SBC(u8, AddressMode), // SuBtract memory from accumulator with borrow (Carry bit)

    SEC(u8), // SEt Carry
    SED(u8), // SEt Decimal mode
    SEI(u8), // SEt Interrupt disable status

    SMB(u8, u8), // Set Memory Bit

    STA(u8, AddressMode), // STore Accumulator in memory

    STP(u8), // SToP mode

    STX(u8, AddressMode), // STore the X register in memory

    STY(u8, AddressMode), // STore the Y register in memory

    STZ(u8, AddressMode), // STore Zero in memory

    TAX(u8), // Transfer the Accumulator to the X register
    TAY(u8), // Transfer the Accumulator to the Y register

    TRB(u8, AddressMode), // Test and Reset memory Bit

    TSB(u8, AddressMode), // Test and Set memory Bit

    TSX(u8), // Transfer the Stack pointer to the X register
    TXA(u8), // Transfer the X register to the Accumulator
    TXS(u8), // Transfer the X register to the Stack pointer register
    TYA(u8), // Transfer Y register to the Accumulator

    WAI(u8), // WAit for Interrupt
}

fn load_instruction(opcode: u8) -> Instruction {
    match opcode {
        0x61 => Instruction::ADC(opcode, AddressMode::ZPII),
        0x65 => Instruction::ADC(opcode, AddressMode::ZP),
        0x69 => Instruction::ADC(opcode, AddressMode::IMMEDIATE),
        0x6D => Instruction::ADC(opcode, AddressMode::ABS),
        0x71 => Instruction::ADC(opcode, AddressMode::ZPIIY),
        0x72 => Instruction::ADC(opcode, AddressMode::ZPI),
        0x75 => Instruction::ADC(opcode, AddressMode::ZPIX),
        0x79 => Instruction::ADC(opcode, AddressMode::AIY),
        0x7D => Instruction::ADC(opcode, AddressMode::AIX),

        0x29 => Instruction::AND(opcode, AddressMode::IMMEDIATE),
        0x2D => Instruction::AND(opcode, AddressMode::ABS),
        0x3D => Instruction::AND(opcode, AddressMode::AIX),
        0x39 => Instruction::AND(opcode, AddressMode::AIY),
        0x25 => Instruction::AND(opcode, AddressMode::ZP),
        0x35 => Instruction::AND(opcode, AddressMode::ZPIX),
        0x32 => Instruction::AND(opcode, AddressMode::ZPI),
        0x21 => Instruction::AND(opcode, AddressMode::ZPII),
        0x31 => Instruction::AND(opcode, AddressMode::ZPIIY),

        0x06 => Instruction::ASL(opcode, AddressMode::ZP),
        0x0A => Instruction::ASL(opcode, AddressMode::ACC),
        0x0E => Instruction::ASL(opcode, AddressMode::ABS),
        0x16 => Instruction::ASL(opcode, AddressMode::ZPIX),
        0x1E => Instruction::ASL(opcode, AddressMode::AIX),

        0x0F => Instruction::BBR(opcode, 0),
        0x1F => Instruction::BBR(opcode, 1),
        0x2F => Instruction::BBR(opcode, 2),
        0x3F => Instruction::BBR(opcode, 3),
        0x4F => Instruction::BBR(opcode, 4),
        0x5F => Instruction::BBR(opcode, 5),
        0x6F => Instruction::BBR(opcode, 6),
        0x7F => Instruction::BBR(opcode, 7),

        0x8F => Instruction::BBS(opcode, 0),
        0x9F => Instruction::BBS(opcode, 1),
        0xAF => Instruction::BBS(opcode, 2),
        0xBF => Instruction::BBS(opcode, 3),
        0xCF => Instruction::BBS(opcode, 4),
        0xDF => Instruction::BBS(opcode, 5),
        0xEF => Instruction::BBS(opcode, 6),
        0xFF => Instruction::BBS(opcode, 7),

        0x90 => Instruction::BCC(opcode),
        0xB0 => Instruction::BCS(opcode),
        0xF0 => Instruction::BEQ(opcode),

        0x24 => Instruction::BIT(opcode, AddressMode::ZP),
        0x2C => Instruction::BIT(opcode, AddressMode::ABS),
        0x34 => Instruction::BIT(opcode, AddressMode::ZPIX),
        0x3C => Instruction::BIT(opcode, AddressMode::AIX),
        0x89 => Instruction::BIT(opcode, AddressMode::IMMEDIATE),

        0x30 => Instruction::BMI(opcode),
        0xD0 => Instruction::BNE(opcode),
        0x10 => Instruction::BPL(opcode),
        0x80 => Instruction::BRA(opcode),
        0x00 => Instruction::BRK(opcode),
        0x50 => Instruction::BVC(opcode),
        0x70 => Instruction::BVS(opcode),

        0x18 => Instruction::CLC(opcode),
        0xD8 => Instruction::CLD(opcode),
        0x58 => Instruction::CLI(opcode),
        0xB8 => Instruction::CLV(opcode),

        0xC1 => Instruction::CMP(opcode, AddressMode::ZPII),
        0xC5 => Instruction::CMP(opcode, AddressMode::ZP),
        0xC9 => Instruction::CMP(opcode, AddressMode::IMMEDIATE),
        0xCD => Instruction::CMP(opcode, AddressMode::ABS),
        0xD1 => Instruction::CMP(opcode, AddressMode::ZPIIY),
        0xD2 => Instruction::CMP(opcode, AddressMode::ZPI),
        0xD5 => Instruction::CMP(opcode, AddressMode::ZPIX),
        0xD9 => Instruction::CMP(opcode, AddressMode::AIY),
        0xDD => Instruction::CMP(opcode, AddressMode::AIX),

        0xE0 => Instruction::CPX(opcode, AddressMode::IMMEDIATE),
        0xE4 => Instruction::CPX(opcode, AddressMode::ZP),
        0xEC => Instruction::CPX(opcode, AddressMode::ABS),

        0xC0 => Instruction::CPY(opcode, AddressMode::IMMEDIATE),
        0xC4 => Instruction::CPY(opcode, AddressMode::ZP),
        0xCC => Instruction::CPY(opcode, AddressMode::ABS),

        0x3A => Instruction::DEC(opcode, AddressMode::ACC),
        0xC6 => Instruction::DEC(opcode, AddressMode::ZP),
        0xCE => Instruction::DEC(opcode, AddressMode::ABS),
        0xD6 => Instruction::DEC(opcode, AddressMode::ZPIX),
        0xDE => Instruction::DEC(opcode, AddressMode::AIX),

        0xCA => Instruction::DEX(opcode),
        0x88 => Instruction::DEY(opcode),

        0x41 => Instruction::EOR(opcode, AddressMode::ZPII),
        0x45 => Instruction::EOR(opcode, AddressMode::ZP),
        0x49 => Instruction::EOR(opcode, AddressMode::IMMEDIATE),
        0x4D => Instruction::EOR(opcode, AddressMode::ABS),
        0x51 => Instruction::EOR(opcode, AddressMode::ZPIIY),
        0x52 => Instruction::EOR(opcode, AddressMode::ZPI),
        0x55 => Instruction::EOR(opcode, AddressMode::ZPIX),
        0x59 => Instruction::EOR(opcode, AddressMode::AIY),
        0x5D => Instruction::EOR(opcode, AddressMode::AIX),

        0x1A => Instruction::INC(opcode, AddressMode::ACC),
        0xE6 => Instruction::INC(opcode, AddressMode::ZP),
        0xEE => Instruction::INC(opcode, AddressMode::ABS),
        0xF6 => Instruction::INC(opcode, AddressMode::ZPIX),
        0xFE => Instruction::INC(opcode, AddressMode::AIX),

        0xE8 => Instruction::INX(opcode),
        0xC8 => Instruction::INY(opcode),

        0x4C => Instruction::JMP(opcode, AddressMode::ABS),
        0x6C => Instruction::JMP(opcode, AddressMode::AI),
        0x7C => Instruction::JMP(opcode, AddressMode::AII),

        0x20 => Instruction::JSR(opcode),

        0xA1 => Instruction::LDA(opcode, AddressMode::ZPII),
        0xA5 => Instruction::LDA(opcode, AddressMode::ZP),
        0xA9 => Instruction::LDA(opcode, AddressMode::IMMEDIATE),
        0xAD => Instruction::LDA(opcode, AddressMode::ABS),
        0xB1 => Instruction::LDA(opcode, AddressMode::ZPIIY),
        0xB2 => Instruction::LDA(opcode, AddressMode::ZPI),
        0xB5 => Instruction::LDA(opcode, AddressMode::ZPIX),
        0xB9 => Instruction::LDA(opcode, AddressMode::AIY),
        0xBD => Instruction::LDA(opcode, AddressMode::AIX),

        0xA2 => Instruction::LDX(opcode, AddressMode::IMMEDIATE),
        0xA6 => Instruction::LDX(opcode, AddressMode::ZP),
        0xAE => Instruction::LDX(opcode, AddressMode::ABS),
        0xB6 => Instruction::LDX(opcode, AddressMode::ZPIY),
        0xBE => Instruction::LDX(opcode, AddressMode::AIY),

        0xA0 => Instruction::LDY(opcode, AddressMode::IMMEDIATE),
        0xA4 => Instruction::LDY(opcode, AddressMode::ZP),
        0xAC => Instruction::LDY(opcode, AddressMode::ABS),
        0xB4 => Instruction::LDY(opcode, AddressMode::ZPIX),
        0xBC => Instruction::LDY(opcode, AddressMode::AIX),

        0x46 => Instruction::LSR(opcode, AddressMode::ZP),
        0x4A => Instruction::LSR(opcode, AddressMode::ACC),
        0x4E => Instruction::LSR(opcode, AddressMode::ABS),
        0x56 => Instruction::LSR(opcode, AddressMode::ZPIX),
        0x5E => Instruction::LSR(opcode, AddressMode::AIX),

        0xEA => Instruction::NOP(opcode),

        0x01 => Instruction::ORA(opcode, AddressMode::ZPII),
        0x05 => Instruction::ORA(opcode, AddressMode::ZP),
        0x09 => Instruction::ORA(opcode, AddressMode::IMMEDIATE),
        0x0D => Instruction::ORA(opcode, AddressMode::ABS),
        0x11 => Instruction::ORA(opcode, AddressMode::ZPIIY),
        0x12 => Instruction::ORA(opcode, AddressMode::ZPI),
        0x15 => Instruction::ORA(opcode, AddressMode::ZPIX),
        0x19 => Instruction::ORA(opcode, AddressMode::AIY),
        0x1D => Instruction::ORA(opcode, AddressMode::AIX),

        0x48 => Instruction::PHA(opcode),
        0x08 => Instruction::PHP(opcode),
        0xDA => Instruction::PHX(opcode),
        0x5A => Instruction::PHY(opcode),
        0x68 => Instruction::PLA(opcode),
        0x28 => Instruction::PLP(opcode),
        0xFA => Instruction::PLX(opcode),
        0x7A => Instruction::PLY(opcode),

        0x07 => Instruction::RMB(opcode, 0),
        0x17 => Instruction::RMB(opcode, 1),
        0x27 => Instruction::RMB(opcode, 2),
        0x37 => Instruction::RMB(opcode, 3),
        0x47 => Instruction::RMB(opcode, 4),
        0x57 => Instruction::RMB(opcode, 5),
        0x67 => Instruction::RMB(opcode, 6),
        0x77 => Instruction::RMB(opcode, 7),

        0x26 => Instruction::ROL(opcode, AddressMode::ZP),
        0x2A => Instruction::ROL(opcode, AddressMode::ACC),
        0x2E => Instruction::ROL(opcode, AddressMode::ABS),
        0x36 => Instruction::ROL(opcode, AddressMode::ZPIX),
        0x3E => Instruction::ROL(opcode, AddressMode::AIX),

        0x66 => Instruction::ROR(opcode, AddressMode::ZP),
        0x6A => Instruction::ROR(opcode, AddressMode::ACC),
        0x6E => Instruction::ROR(opcode, AddressMode::ABS),
        0x76 => Instruction::ROR(opcode, AddressMode::ZPIX),
        0x7E => Instruction::ROR(opcode, AddressMode::AIX),

        0x40 => Instruction::RTI(opcode),
        0x60 => Instruction::RTS(opcode),

        0xE1 => Instruction::SBC(opcode, AddressMode::ZPII),
        0xE5 => Instruction::SBC(opcode, AddressMode::ZP),
        0xE9 => Instruction::SBC(opcode, AddressMode::IMMEDIATE),
        0xED => Instruction::SBC(opcode, AddressMode::ABS),
        0xF1 => Instruction::SBC(opcode, AddressMode::ZPIIY),
        0xF2 => Instruction::SBC(opcode, AddressMode::ZPI),
        0xF5 => Instruction::SBC(opcode, AddressMode::ZPIX),
        0xF9 => Instruction::SBC(opcode, AddressMode::AIY),
        0xFD => Instruction::SBC(opcode, AddressMode::AIX),

        0x38 => Instruction::SEC(opcode),
        0xF8 => Instruction::SED(opcode),
        0x78 => Instruction::SEI(opcode),

        0x87 => Instruction::SMB(opcode, 0),
        0x97 => Instruction::SMB(opcode, 1),
        0xA7 => Instruction::SMB(opcode, 2),
        0xB7 => Instruction::SMB(opcode, 3),
        0xC7 => Instruction::SMB(opcode, 4),
        0xD7 => Instruction::SMB(opcode, 5),
        0xE7 => Instruction::SMB(opcode, 6),
        0xF7 => Instruction::SMB(opcode, 7),

        0x81 => Instruction::STA(opcode, AddressMode::ZPII),
        0x85 => Instruction::STA(opcode, AddressMode::ZP),
        0x8D => Instruction::STA(opcode, AddressMode::ABS),
        0x91 => Instruction::STA(opcode, AddressMode::ZPIIY),
        0x92 => Instruction::STA(opcode, AddressMode::ZPI),
        0x95 => Instruction::STA(opcode, AddressMode::ZPIX),
        0x99 => Instruction::STA(opcode, AddressMode::AIY),
        0x9D => Instruction::STA(opcode, AddressMode::AIX),

        0xDB => Instruction::STP(opcode),

        0x86 => Instruction::STX(opcode, AddressMode::ZP),
        0x8E => Instruction::STX(opcode, AddressMode::ABS),
        0x96 => Instruction::STX(opcode, AddressMode::ZPIY),

        0x84 => Instruction::STY(opcode, AddressMode::ZP),
        0x8C => Instruction::STY(opcode, AddressMode::ABS),
        0x94 => Instruction::STY(opcode, AddressMode::ZPIX),

        0x64 => Instruction::STZ(opcode, AddressMode::ZP),
        0x74 => Instruction::STZ(opcode, AddressMode::ZPIX),
        0x9C => Instruction::STZ(opcode, AddressMode::ABS),
        0x9E => Instruction::STZ(opcode, AddressMode::AIX),

        0xAA => Instruction::TAX(opcode),
        0xA8 => Instruction::TAY(opcode),

        0x14 => Instruction::TRB(opcode, AddressMode::ZP),
        0x1C => Instruction::TRB(opcode, AddressMode::ABS),

        0x04 => Instruction::TSB(opcode, AddressMode::ZP),
        0x0C => Instruction::TSB(opcode, AddressMode::ABS),

        0xBA => Instruction::TSX(opcode),
        0x8A => Instruction::TXA(opcode),
        0x9A => Instruction::TXS(opcode),
        0x98 => Instruction::TYA(opcode),

        0xCB => Instruction::WAI(opcode),

        _ => {
            println!("Unrecognized opcode! {}", opcode);
            panic!("Unrecognized opcode!")
        }
    }
}

const PN_MASK: u8 = 0b10000000;
// const PV_MASK: u8 = 0b01000000;
// const PB_MASK: u8 = 0b00010000;
// const PD_MASK: u8 = 0b00001000;
// const PI_MASK: u8 = 0b00000100;
const PZ_MASK: u8 = 0b00000010;
// const PC_MASK: u8 = 0b00000001;

fn inc_wrap(n: u8) -> u8 {
    (Wrapping(n) + Wrapping(1)).0
}

#[derive(PartialEq)]
pub struct Cpu {
    ir: u8, // instruction register
    a: u8,  // accumulator
    x: u8,  // index registers
    y: u8,
    p: u8,     // processor status
    pc: usize, // program counter
    s: u8,     // stack pointer
}

impl fmt::Debug for Cpu {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("Cpu")
            .field("ir", &format_args!("{:#02X}", self.ir))
            .field("a", &self.a)
            .field("x", &self.x)
            .field("y", &self.y)
            .field("p", &format_args!("{:08b}", self.p))
            .field("pc", &format_args!("{:#06X}", self.pc))
            .field("s", &self.s)
            .finish()
    }
}

impl fmt::Display for Cpu {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "\n| ----------------------------------------- |\n\
        | PC | {:#06X} | {:5} | {:04b} {:04b} {:04b} {:04b} |\n\
        | ----------------------------------------- |\n\
        | IR |   {:#04X} | {:5} | {:04b} {:04b}           |\n\
        |  A |   {:#04X} | {:5} | {:04b} {:04b}           |\n\
        |  X |   {:#04X} | {:5} | {:04b} {:04b}           |\n\
        |  Y |   {:#04X} | {:5} | {:04b} {:04b}           |\n\
        |  S |   {:#04X} | {:5} | {:04b} {:04b}           |\n\
        | ----------------------------------------- |\n\
        |  P | NV_BDIZC                             |\n\
        |    | {:08b}                             |\n\
        | ----------------------------------------- |\n",
            self.pc,
            self.pc,
            self.pc >> 12,
            self.pc >> 8 & 15,
            self.pc >> 4 & 15,
            self.pc & 15,
            self.ir,
            self.ir,
            self.ir >> 4,
            self.ir & 15,
            self.a,
            self.a,
            self.a >> 4,
            self.a & 15,
            self.x,
            self.x,
            self.x >> 4,
            self.x & 15,
            self.y,
            self.y,
            self.y >> 4,
            self.y & 15,
            self.s,
            self.s,
            self.s >> 4,
            self.s & 15,
            self.p
        )
    }
}

impl Cpu {
    pub fn new() -> Self {
        Cpu {
            ir: 0,
            a: 0,
            x: 0,
            y: 0,
            p: 0,
            pc: 0,
            s: 0,
        }
    }

    pub fn reset(&mut self) {
        self.ir = 0;
        self.a = 0;
        self.x = 0;
        self.y = 0;
        self.p = 0;
        self.pc = 0;
        self.s = 0;
    }

    // TODO: PC increments map to address modes - extract this to a function
    // TODO: Nest matches to avoid repeating logic for the same instruction in diff modes

    pub fn step<M, R>(&mut self, rom: &R, mem: &mut M)
    where
    R: Index<usize, Output = u8>,
    M: IndexMut<usize, Output = u8>,
    {
        let opcode = rom[self.pc];
        let instruction = load_instruction(opcode);
        self.ir = opcode;
        match instruction {
            Instruction::AND(_, AddressMode::IMMEDIATE) => {
                self.a &= self.one_byte_operand(rom);
                self.update_pnz(self.a);
                self.pc += 2;
            }
            Instruction::AND(_, AddressMode::ABS) => {
                self.a &= self.deref_abs(rom, mem);
                self.update_pnz(self.a);
                self.pc += 3;
            }
            Instruction::AND(_, AddressMode::AIX) => {
                self.a &= self.deref_aix(rom, mem);
                self.update_pnz(self.a);
                self.pc += 3;
            }
            Instruction::AND(_, AddressMode::AIY) => {
                self.a &= self.deref_aiy(rom, mem);
                self.update_pnz(self.a);
                self.pc += 3;
            }
            Instruction::AND(_, AddressMode::ZP) => {
                self.a &= self.deref_zp(rom, mem);
                self.update_pnz(self.a);
                self.pc += 2;
            }
            Instruction::AND(_, AddressMode::ZPIX) => {
                self.a &= self.deref_zpix(rom, mem);
                self.update_pnz(self.a);
                self.pc += 2;
            }
            Instruction::AND(_, AddressMode::ZPI) => {
                self.a &= self.deref_zpi(rom, mem);
                self.update_pnz(self.a);
                self.pc += 2;
            }
            Instruction::AND(_, AddressMode::ZPII) => {
                self.a &= self.deref_zpii(rom, mem);
                self.update_pnz(self.a);
                self.pc += 2;
            }
            Instruction::AND(_, AddressMode::ZPIIY) => {
                self.a &= self.deref_zpiiy(rom, mem);
                self.update_pnz(self.a);
                self.pc += 2;
            }

            Instruction::INX(_) => {
                self.x = inc_wrap(self.x);
                self.update_pnz(self.x);
                self.pc += 1;
            }

            Instruction::INY(_) => {
                self.y = inc_wrap(self.y);
                self.update_pnz(self.y);
                self.pc += 1;
            }

            Instruction::JMP(_, AddressMode::ABS) => {
                let new_pc = self.two_byte_operand(rom);
                self.pc = new_pc as usize;
            }

            Instruction::JMP(_, AddressMode::AI) => {
                let new_pc_addr = self.two_byte_operand(rom);
                let new_pcl: u16 = mem[new_pc_addr as usize].into();
                let new_pch: u16 = mem[(new_pc_addr + 1) as usize].into();
                self.pc = ((new_pch << 8) | new_pcl) as usize;
            }

            Instruction::JMP(_, AddressMode::AII) => {
                let new_pc_addr: u16 = self.two_byte_operand(rom) + self.x as u16;
                let new_pcl: u16 = mem[new_pc_addr as usize].into();
                let new_pch: u16 = mem[(new_pc_addr + 1) as usize].into();

                self.pc = ((new_pch << 8) | new_pcl) as usize;
            }

            Instruction::LDA(_, AddressMode::IMMEDIATE) => {
                self.a = self.one_byte_operand(rom);
                self.pc += 2;
            }

            Instruction::NOP(_) => {
                self.pc += 1;
            }

            Instruction::STA(_, AddressMode::ABS) => {
                let addr = self.two_byte_operand(rom);
                mem[addr as usize] = self.a;
                self.pc += 3;
            }

            instruction => {
                println!("Not implemented: {:?}", instruction);
                todo!();
            }
        }
    }

    fn one_byte_operand<R>(&self, rom: &R) -> u8
    where
        R: Index<usize, Output = u8>,
    {
        rom[self.pc + 1]
    }

    fn two_byte_operand<R>(&self, rom: &R) -> u16
    where
        R: Index<usize, Output = u8>,
    {
        let op_l: u16 = rom[self.pc + 1].into();
        let op_h: u16 = rom[self.pc + 2].into();
        (op_h << 8) | op_l
    }

    fn deref_abs<R, M>(&mut self, rom: &R, mem: &mut M) -> u8
    where
        R: Index<usize, Output = u8>,
        M: IndexMut<usize, Output = u8>,
    {
        mem[self.two_byte_operand(rom) as usize]
    }

    fn deref_aix<R, M>(&mut self, rom: &R, mem: &mut M) -> u8
    where
        R: Index<usize, Output = u8>,
        M: IndexMut<usize, Output = u8>,
    {
        mem[(self.two_byte_operand(rom) + self.x as u16) as usize]
    }

    fn deref_aiy<R, M>(&mut self, rom: &R, mem: &mut M) -> u8
    where
        R: Index<usize, Output = u8>,
        M: IndexMut<usize, Output = u8>,
    {
        mem[(self.two_byte_operand(rom) + self.y as u16) as usize]
    }

    fn deref_zp<R, M>(&mut self, rom: &R, mem: &mut M) -> u8
    where
        R: Index<usize, Output = u8>,
        M: IndexMut<usize, Output = u8>,
    {
        mem[self.one_byte_operand(rom) as usize]
    }

    fn deref_zpix<R, M>(&mut self, rom: &R, mem: &mut M) -> u8
    where
        R: Index<usize, Output = u8>,
        M: IndexMut<usize, Output = u8>,
    {
        mem[(self.one_byte_operand(rom) + self.x) as usize]
    }

    fn deref_zpi<R, M>(&mut self, rom: &R, mem: &mut M) -> u8
    where
        R: Index<usize, Output = u8>,
        M: IndexMut<usize, Output = u8>,
    {
        let indirect_address = self.one_byte_operand(rom);
        let operand_address_l: u16 = mem[indirect_address as usize].into();
        let operand_address_h: u16 = mem[(indirect_address + 1) as usize].into();
        let operand_address: u16 = (operand_address_h << 8) | operand_address_l;
        mem[operand_address as usize]
    }

    fn deref_zpii<R, M>(&mut self, rom: &R, mem: &mut M) -> u8
    where
        R: Index<usize, Output = u8>,
        M: IndexMut<usize, Output = u8>,
    {
        let indirect_address = self.one_byte_operand(rom) + self.x;
        let operand_address_l: u16 = mem[indirect_address as usize].into();
        let operand_address_h: u16 = mem[(indirect_address + 1) as usize].into();
        let operand_address: u16 = (operand_address_h << 8) | operand_address_l;
        mem[operand_address as usize]
    }

    fn deref_zpiiy<R, M>(&mut self, rom: &R, mem: &mut M) -> u8
    where
        R: Index<usize, Output = u8>,
        M: IndexMut<usize, Output = u8>,
    {
        // Deref the zero page pointer
        let zp = self.one_byte_operand(rom);
        let indirect_base_l: u16 = mem[zp as usize].into();
        let indirect_base_h: u16 = mem[(zp + 1) as usize].into();
        let indirect_base = (indirect_base_h << 8) | indirect_base_l;

        // Add y to the address found
        let indirect = indirect_base + self.y as u16;

        // Deref new address to get operand
        mem[indirect as usize]
    }

    fn update_pnz(&mut self, value: u8) {
        self.p = (PN_MASK & value) | (!PN_MASK & self.p);
        if value == 0 {
            self.p |= PZ_MASK;
        } else {
            self.p &= !PZ_MASK;
        }
    }

}

#[cfg(test)]
mod tests {
    use super::*;

    fn setup() -> (Cpu, [u8; 65_536]) {
        (Cpu::new(), [0; 65_536])
    }

    #[test]
    fn reset_cpu() {
        let mut cpu = Cpu {
            ir: 1,
            a: 2,
            x: 3,
            y: 4,
            p: 5,
            pc: 6,
            s: 7,
        };

        cpu.reset();

        assert_eq!(cpu, Cpu::new());
    }

    mod and_tests {
        use super::*;

        #[test]
        fn and_immediate() {
            let (mut cpu, mut mem) = setup();
            cpu.a = 0b00111100;
            let rom = vec![0x29, 0b00001111];

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x29,
                    pc: 2,
                    a: 0b00001100,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn and_immediate_pn() {
            let (mut cpu, mut mem) = setup();
            cpu.a = 0b10000000;
            let rom = vec![0x29, 0b10001111];

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x29,
                    pc: 2,
                    a: 0b10000000,
                    p: 0b10000000,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn and_immediate_pz() {
            let (mut cpu, mut mem) = setup();
            cpu.a = 0;
            let rom = vec![0x29, 0xFF];

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x29,
                    pc: 2,
                    a: 0,
                    p: 0b00000010,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn and_abs() {
            let (mut cpu, mut mem) = setup();
            cpu.a = 0b10001111;
            mem[0xABCD] = 0b10111100;
            let rom = vec![0x2D, 0xCD, 0xAB];

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x2D,
                    pc: 3,
                    a: 0b10001100,
                    p: 0b10000000,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn and_aix() {
            let (mut cpu, mut mem) = setup();
            cpu.a = 0b10001111;
            cpu.x = 10;
            mem[0xABCA] = 0b10111100;
            let rom = vec![0x3D, 0xC0, 0xAB];

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x3D,
                    pc: 3,
                    a: 0b10001100,
                    x: 10,
                    p: 0b10000000,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn and_aiy() {
            let (mut cpu, mut mem) = setup();
            cpu.a = 0b10001111;
            cpu.y = 10;
            mem[0xABCA] = 0b10111100;
            let rom = vec![0x39, 0xC0, 0xAB];

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x39,
                    pc: 3,
                    a: 0b10001100,
                    y: 10,
                    p: 0b10000000,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn and_zp() {
            let (mut cpu, mut mem) = setup();
            cpu.a = 0b10001111;
            mem[0x00CD] = 0b10111100;
            let rom = vec![0x25, 0xCD];

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x25,
                    pc: 2,
                    a: 0b10001100,
                    p: 0b10000000,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn and_zpix() {
            let (mut cpu, mut mem) = setup();
            cpu.a = 0b10001111;
            cpu.x = 10;
            mem[0x00CA] = 0b10111100;
            let rom = vec![0x35, 0xC0];

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x35,
                    pc: 2,
                    a: 0b10001100,
                    x: 10,
                    p: 0b10000000,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn and_zpi() {
            let (mut cpu, mut mem) = setup();
            cpu.a = 0b10001111;
            mem[0x00CD] = 0x57;
            mem[0x00CE] = 0x43;
            mem[0x4357] = 0b10111100;
            let rom = vec![0x32, 0xCD];

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x32,
                    pc: 2,
                    a: 0b10001100,
                    p: 0b10000000,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn and_zpii() {
            let (mut cpu, mut mem) = setup();
            cpu.a = 0b10001111;
            cpu.x = 10;
            mem[0x00CA] = 0x57;
            mem[0x00CB] = 0x43;
            mem[0x4357] = 0b10111100;
            let rom = vec![0x21, 0xC0];

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x21,
                    pc: 2,
                    a: 0b10001100,
                    x: 10,
                    p: 0b10000000,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn and_zpiiy() {
            let (mut cpu, mut mem) = setup();
            cpu.a = 0b10001111;
            cpu.y = 10;
            mem[0x00C0] = 0x00;
            mem[0x00C1] = 0xFF;
            mem[0xFF0A] = 0b10111100;
            let rom = vec![0x31, 0xC0];

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x31,
                    pc: 2,
                    a: 0b10001100,
                    y: 10,
                    p: 0b10000000,
                    ..Cpu::new()
                }
            )
        }
    }

    mod inc_tests {
        use super::*;

        #[test]
        fn inx() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0xE8];
            cpu.x = 41;

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0xE8,
                    pc: 1,
                    x: 42,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn inx_zero() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0xE8];
            cpu.x = u8::MAX;

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0xE8,
                    pc: 1,
                    x: 0,
                    p: PZ_MASK,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn inx_reset_zero() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0xE8];
            cpu.x = 5;
            cpu.p = PZ_MASK;

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0xE8,
                    pc: 1,
                    x: 6,
                    p: 0b00000000,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn inx_neg() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0xE8];
            cpu.x = 127;

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0xE8,
                    pc: 1,
                    x: 128,
                    p: 0b10000000,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn inx_reset_neg() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0xE8];
            cpu.x = u8::MAX;
            cpu.p = PN_MASK;

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0xE8,
                    pc: 1,
                    x: 0,
                    p: 0b00000010,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn iny() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0xC8];
            cpu.y = 40;

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0xC8,
                    pc: 1,
                    y: 41,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn iny_zero() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0xC8];
            cpu.y = u8::MAX;

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0xC8,
                    pc: 1,
                    y: 0,
                    p: PZ_MASK,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn iny_reset_zero() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0xC8];
            cpu.y = 5;
            cpu.p = PZ_MASK;

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0xC8,
                    pc: 1,
                    y: 6,
                    p: 0b00000000,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn iny_neg() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0xC8];
            cpu.y = 127;

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0xC8,
                    pc: 1,
                    y: 128,
                    p: 0b10000000,
                    ..Cpu::new()
                }
            )
        }

        #[test]
        fn iny_reset_neg() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0xC8];
            cpu.y = u8::MAX;
            cpu.p = PN_MASK;

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0xC8,
                    pc: 1,
                    y: 0,
                    p: 0b00000010,
                    ..Cpu::new()
                }
            )
        }
    }

    mod jmp_tests {
        use super::*;

        #[test]
        fn jmp_abs() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0x4C, 0x0A, 0x80];

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x4C,
                    pc: 0x800A,
                    ..Cpu::new()
                }
            );
        }

        #[test]
        fn jmp_ai() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0x6C, 0x0A, 0x80];
            mem[0x800A] = 0xCD;
            mem[0x800B] = 0xAB;

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x6C,
                    pc: 0xABCD,
                    ..Cpu::new()
                }
            );
        }

        #[test]
        fn jmp_aii() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0x7C, 0x00, 0x80];

            cpu.x = 6;
            mem[0x8006] = 0xCD;
            mem[0x8007] = 0xAB;

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x7C,
                    pc: 0xABCD,
                    x: 6,
                    ..Cpu::new()
                }
            );
        }
    }

    mod lda_tests {
        use super::*;

        #[test]
        fn lda_immediate() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0xA9, 0xED];

            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0xA9,
                    a: 0xED,
                    pc: 2,
                    ..Cpu::new()
                }
            );
        }
    }

    #[test]
    fn nop() {
        let (mut cpu, mut mem) = setup();
        let rom = vec![0xEA];

        cpu.step(&rom, &mut mem);

        assert_eq!(
            cpu,
            Cpu {
                ir: 0xEA,
                pc: 1,
                ..Cpu::new()
            }
        );
    }

    mod sta_tests {
        use super::*;

        #[test]
        fn sta_a() {
            let (mut cpu, mut mem) = setup();
            let rom = vec![0x8D, 0x02, 0x60];

            cpu.a = 57;
            cpu.step(&rom, &mut mem);

            assert_eq!(
                cpu,
                Cpu {
                    ir: 0x8D,
                    a: 57,
                    pc: 3,
                    ..Cpu::new()
                }
            );

            assert_eq!(mem[0x6002], 57);
        }
    }
}
