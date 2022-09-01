#include <iostream>
#include <unordered_map>

int main(int argc, char **argv) {
  std::cout << "Constructing map..." << std::endl;

  std::unordered_map<int, std::string> my_map;
  my_map.emplace(std::make_pair(42, "Hey Ben"));

  for (const auto &p : my_map) {
    std::cout << p.first << " => " << p.second << std::endl;
  }

  std::cout << "Map contains " << my_map.size() << " elements" << std::endl;

  return 0;
}
