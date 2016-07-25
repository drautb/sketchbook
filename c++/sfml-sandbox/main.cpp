#include "config.h"
#include <iostream>
#include <SFML/Graphics.hpp>

using namespace std;

int main(int argc, char* argv[]) {

  /* Code adapted from the SFML 2 "Window" example */

  cout << "Version " << sfml_sandbox_VERSION_MAJOR << "." << sfml_sandbox_VERSION_MINOR << endl;

  sf::Window App(sf::VideoMode(800, 600), "SFML Sandbox");

  while (App.isOpen()) {
    sf::Event Event;
    while (App.pollEvent(Event)) {
      if (Event.type == sf::Event::Closed)
    App.close();
    }
    App.display();
  }
}
