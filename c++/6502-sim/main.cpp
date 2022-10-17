#include <iostream> 
#include <fstream>

// Registers
uint8_t a = 0;
uint8_t x = 0;
uint8_t y = 0;

uint8_t flags = 0;

void reset() {
  a = x = y = 0;
  flags = 0;
}

int main(int argc, char* argv[]) {
  if (argc != 2) {
    std::cout << "Expected name of input program as argument" << std::endl;
    return 1;
  }
  
  char* program = nullptr;
  std::ifstream input_file(argv[1], std::ios::binary | std::ios::in | std::ios::ate);
  if (input_file.is_open()) {
    std::streampos size = input_file.tellg();
    program = new char[size];
    input_file.seekg(0, std::ios::beg);
    input_file.read(program, size);

    if (!input_file) {
      std::cout << "Error, only read " << input_file.gcount() << " characters." << std::endl;
    }

    input_file.close();

    std::cout << "Loading " << size << " bytes from " << argv[1] << std::endl;

    for (int i = 0; i < size; i++) {
      std::cout << std::hex << std::setfill('0') << std::setw(2) << (0xff & program[i]) << " ";
    }
    std::cout << std::endl << std::dec;

    delete[] program;
  }

  return 0;
}
