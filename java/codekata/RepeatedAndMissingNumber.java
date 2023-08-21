import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.HashSet;

public class RepeatedAndMissingNumber {

  public static void main(String[] args) {
    System.out.println("Running tests...");
    RepeatedAndMissingNumber.test(2, 1, 1, 3, 1);
    RepeatedAndMissingNumber.test(3, 1, 1, 1, 2);
    RepeatedAndMissingNumber.test(6, 5, 2, 4, 3, 8, 5, 7, 1, 5);

    System.out.println("All Passed.");
  }

  public static void test(int missing, int repeated, Integer... input) {
    List<Integer> inputList = Arrays.asList(input);
    List<Integer> result = RepeatedAndMissingNumber.run(inputList);
    if (result.get(0) != missing || result.get(1) != repeated) {
      throw new RuntimeException(String.format("Expected result [%d, %d], but was %s, for input %s", missing, repeated, result, inputList));
    }
  }

  public static List<Integer> run(List<Integer> numbers) {
    List<Integer> result = new ArrayList<>();

    List<Integer> unique = new ArrayList<>(new HashSet<>(numbers));
    int missing = -1;
    for (int i = 0; i < unique.size(); i++) {
      int currentValue = unique.get(i);
      if (currentValue != i + 1) {
        missing = i + 1;
        break;
      }
    }

    if (missing < 0) {
      missing = numbers.size();
    }

    // Sum of 1 to n
    int actualSum = numbers.stream().reduce(0, Integer::sum);
    int n = numbers.size();
    int sum = (n * (n + 1)) / 2;
    int repeated = (actualSum + missing) - sum;

    result.add(missing);
    result.add(repeated);
    return result;
  }

}
