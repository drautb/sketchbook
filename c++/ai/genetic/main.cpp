#include <iostream>
#include <vector>
#include <algorithm>
#include <map>
#include <string>
#include <sstream>
#include <cmath>
#include <cassert>

using namespace std;

const int TARGET = 778;
const int GENERATION_SIZE = 1000;
const int MAX_GENERATION_COUNT = 8;

const double CROSSOVER_PROBABILITY = 0.7;
const double MUTATION_RATE = 0.001;

enum 
{
    NUMBER=0,
    OPERATOR
};

enum
{
    ADD=43,
    SUBTRACT=45,
    MULTIPLY=42,
    DIVIDE=47
};

map<string, char> encodings = {
    { "0000", '0' },
    { "0001", '1' },
    { "0010", '2' },
    { "0011", '3' },
    { "0100", '4' },
    { "0101", '5' },
    { "0110", '6' },
    { "0111", '7' },
    { "1000", '8' },
    { "1001", '9' },
    { "1010", '+' },
    { "1011", '-' },
    { "1100", '*' },
    { "1101", '/' },
    { "1110", '!' },
    { "1111", '!' }
};

vector<string> numbers = 
{
    "0000",
    "0001",
    "0010",
    "0011",
    "0100",
    "0101",
    "0110",
    "0111",
    "1000",
    "1001"
};

vector<string> operators = 
{
    "1010",
    "1011",
    "1100",
    "1101"
};

class Chromosome
{
public:

    string data;

    double fitnessScore;

    void CalculateFitnessScore();

    double Evaluate();

    string ToString();

    static Chromosome RandomNew();
};

void Chromosome::CalculateFitnessScore()
{
    fitnessScore = abs(TARGET - Evaluate());
    if (fitnessScore != 0)
        fitnessScore = 1/fitnessScore;
}

double Chromosome::Evaluate()
{
    string str = ToString();
    
    if (str.length() == 0)
        return 0.0;

    unsigned int idx = 1;
    double total = (double)stoi(str.substr(0,1));

    while (idx < str.length()-1)
    {
        double next = (double)stoi(str.substr(idx+1, 1));
        int op = (int)((char)str[idx]);

        if (op == ADD)
            total = total + next;
        else if (op == MULTIPLY)
            total = total * next;
        else if (op == SUBTRACT)
            total = total - next;
        else if (op == DIVIDE && next != 0)
            total = total / next;

        idx += 2;
    }

    return total;
}

string Chromosome::ToString()
{
    stringstream str;
    int expected = NUMBER;

    unsigned int idx = 0;
    while (idx < data.length())
    {
        string temp = data.substr(idx, 4);
        if (encodings.find(temp) != encodings.end())
        {
            char c = encodings[temp];
            int cInt = (int)c;
            if (expected == NUMBER)
            {
                if (cInt >= 48 && cInt <= 57)
                {
                    str << c;
                    expected = OPERATOR;
                }
            }
            else if (expected == OPERATOR)
            {
                if (cInt == ADD || cInt == SUBTRACT || cInt == MULTIPLY || cInt == DIVIDE)
                {
                    str << c;
                    expected = NUMBER;
                }
            }
        }
        idx += 4;
    }

    string result = str.str();
    if (expected == NUMBER)
        result = result.substr(0, result.length() - 1);

    return result;
}

Chromosome Chromosome::RandomNew()
{
    stringstream stream;
    for (int i=1; i<10; i++)
    {
        if (i % 2 == 1)
            stream << numbers[rand()%9];
        else
            stream << operators[rand()%4];
    }

    Chromosome c;
    c.data = stream.str();
    c.CalculateFitnessScore();

    return c;
}

vector<Chromosome> currentGen, nextGen;
vector<int> rouletteWheel;

void PrepareRoulette()
{
    for (unsigned int i=0; i<currentGen.size(); i++)
    {
        int prob = currentGen[i].fitnessScore * GENERATION_SIZE;
        for (int j=0; j<prob; j++)
            rouletteWheel.push_back(i);
    }

    random_shuffle(rouletteWheel.begin(), rouletteWheel.end());
}

int main(int argc, char* argv[])
{
    cout << "Genetic Algorithm Test" << endl;
    srand(time(0));

    int nGeneration = 1;
    cout << "Generation 1" << endl;

    // Generate Initial population
    for (int i=0; i<GENERATION_SIZE; i++)
    {
        currentGen.push_back(Chromosome::RandomNew());
        if (currentGen[currentGen.size()-1].Evaluate() == TARGET)
        {
            Chromosome c = currentGen[currentGen.size()-1];
            cout << "\tTarget Reached [" << currentGen.size() << "]: " << c.ToString() << " = " << c.Evaluate() << endl;
            return 0;
        }
    }

    bool targetReached = false;

    while (true)
    {
        cout << "Generation " << nGeneration + 1 << endl;

        PrepareRoulette();

        while (nextGen.size() < GENERATION_SIZE)
        {
            // Pick two random chromosomes, weighted by fitnessScore
            Chromosome c1, c2;
            c1 = currentGen[rouletteWheel[rand()%rouletteWheel.size()]];
            c2 = currentGen[rouletteWheel[rand()%rouletteWheel.size()]];

            // Combine them
            // Crossover?
            if (((rand() % 100) / 100.0) < CROSSOVER_PROBABILITY)
            {
                // Pick a random point in the Chromosomes, switch all their bits after that.
                int crossPoint = rand() % c1.data.length();

                string newC1, newC2;
                if (crossPoint == 0)
                {
                    newC1 = c2.data;
                    newC2 = c1.data;
                }
                else
                {   
                    newC1 = c1.data.substr(0, crossPoint);
                    newC2 = c2.data.substr(0, crossPoint);

                    newC1.append(c2.data.substr(crossPoint));
                    newC2.append(c1.data.substr(crossPoint));   
                }           

                assert(newC1.length() == 36);
                assert(newC2.length() == 36);

                c1.data = newC1;
                c2.data = newC2;
            }

            // Mutation
            for (unsigned int i=0; i<c1.data.length(); i++)
            {
                bool mutate = (rand() / RAND_MAX) < MUTATION_RATE;
                if (mutate)
                    c1.data[i] = (c1.data[i] == '0' ? '1' : '0');

                mutate = (rand() / RAND_MAX) < MUTATION_RATE;
                if (mutate)
                    c2.data[i] = (c2.data[i] == '0' ? '1' : '0');
            }

            // Check it for Success
            if (c1.Evaluate() == TARGET)
            {
                targetReached = true;
                cout << "\tTarget Reached[" << nextGen.size() + 2 << "]: " << c1.ToString() << " = " << c1.Evaluate() << endl;
                break;
            }
            if (c2.Evaluate() == TARGET)
            {
                targetReached = true;
                cout << "\tTarget Reached[" << nextGen.size() + 2 << "]: " << c2.ToString() << " = " << c2.Evaluate() << endl;
                break;
            }

            // Add it to the nextGen
            c1.CalculateFitnessScore();
            c2.CalculateFitnessScore();
            nextGen.push_back(c1);
            nextGen.push_back(c2);
        }

        if (targetReached)
            break;

        currentGen = nextGen;
        nextGen.clear();

        nGeneration++;

        if (nGeneration > MAX_GENERATION_COUNT)
        {
            cout << "\t\t*** Max Generation Count Reached ***" << endl;
            double bestFitnessScore = 0.0;
            int bestChromosomeIdx = 0;
            for (unsigned int i=0; i<currentGen.size(); i++)
            {
                if (currentGen[i].fitnessScore > bestFitnessScore)
                {
                    bestFitnessScore = currentGen[i].fitnessScore;
                    bestChromosomeIdx = i;
                }
            }

            cout << "\t\t\tBest Chromosome[" << bestChromosomeIdx << "]: " << currentGen[bestChromosomeIdx].ToString() << " = " << currentGen[bestChromosomeIdx].Evaluate() << "\t\tFitness Score: " << currentGen[bestChromosomeIdx].fitnessScore << endl;

            return 0;
        }
    }

    return 0;
}