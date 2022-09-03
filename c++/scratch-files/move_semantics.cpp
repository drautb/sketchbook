// Create a string
// Put it into a vector
// Print out addresses showing that the string was copied, not moved.
// Put the string into the vector again, but this time with std::move
// Print out addresses showing that the string memory was moved, not copied.
// (So the address should be the same)

#include <string>
#include <iostream>
#include <vector>
#include <memory>

void print_str_addresses(std::string& str);

int main(int argc, char** argv) {
  
  std::string test_str = "Hello world!";

  print_str_addresses(test_str);
  
  std::vector<std::string> string_vec;
  string_vec.push_back(test_str);

  std::cout << "Original test_str" << std::endl;
  print_str_addresses(test_str);

  std::cout << "Vec[0]" << std::endl;
  print_str_addresses(string_vec[0]);

  string_vec.push_back(std::move(test_str));
  std::cout << "Original test_str after move" << std::endl;
  print_str_addresses(test_str); 
 
  // So I expected this to print the same data as was printed originall on line 19,
  // but it doesn't. The addresses are different, so it looks like the string was
  // still copied? I must be missing something else still.
  std::cout << "Vec[1]" << std::endl; 
  print_str_addresses(string_vec[1]);

  return 0;
}

void print_str_addresses(std::string& str) {
  std::cout << "String: " << str << std::endl;
  std::cout << "Container:  " << &str << std::endl;
  std::cout << "Characters: " << (void*) str.data() << std::endl;
  std::cout << std::endl;
}

