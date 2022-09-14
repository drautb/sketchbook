#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN

#include <doctest.h>

#include <bits/stdc++.h>

using namespace std;

void sift_up(vector<int>&, int);

void heapify(vector<int>& data) {
  for (auto idx = data.size() - 1; idx > 0; idx--) {
    sift_up(data, idx);
  }
}

void sift_up(vector<int>& data, int child_idx) {
  auto parent_idx = (child_idx - 1) / 2;
  if (data[parent_idx] > data[child_idx]) {
    swap(data[parent_idx], data[child_idx]);
    sift_up(data, parent_idx);
  }
}

void sift_down(vector<int>& data, int child_idx) {
  auto left_child_idx = 2 * child_idx + 1;
  auto right_child_idx = left_child_idx + 1;

  auto target_idx = -1;
  if (left_child_idx < (int) data.size() && data[child_idx] > data[left_child_idx]) {
    target_idx = left_child_idx;
  }
  if (right_child_idx < (int) data.size() && data[child_idx] > data[right_child_idx] && data[right_child_idx] < data[left_child_idx]) {
    target_idx = right_child_idx;
  }
   
  if (target_idx > 0) {
    swap(data[child_idx], data[target_idx]);
    sift_down(data, target_idx);
  }
}

int find_min(vector<int>& heap) {
  return heap[0];
}

void insert(vector<int>& heap, int new_value) {
  heap.push_back(new_value);
  sift_up(heap, heap.size() - 1);
}

void erase(vector<int>& heap, int value_to_erase) {
  int idx_to_erase = -1;
  for (auto i = 0; i < (int) heap.size(); i++) {
    if  (heap[i] == value_to_erase) {
      idx_to_erase = i;
      break;
    }
  }

  if (idx_to_erase < 0) {
    return;
  }

  swap(heap[idx_to_erase], heap[heap.size() - 1]);
  heap.pop_back();
  sift_down(heap, idx_to_erase);
}

int extract_root(vector<int>& heap) {
  auto root_val = heap[0];
  erase(heap, root_val);
  return root_val;
}

string vec_to_str(vector<int>& v) {
  stringstream ss;
  ss << "[";
  for (auto n : v) {
    ss << n << ", ";
  }
  ss << "]";
  return ss.str();
}

TEST_CASE("min-heap") {
  vector<int> data = {8, 9, 12, 7, 4, 11, 3};
  
  heapify(data);

  CHECK(vec_to_str(data) == "[3, 4, 8, 7, 9, 11, 12, ]");
  CHECK(find_min(data) == 3);

  insert(data, 2);

  CHECK(find_min(data) == 2);
  CHECK(vec_to_str(data) == "[2, 3, 8, 4, 9, 11, 12, 7, ]");

  erase(data, 3);
  CHECK(find_min(data) == 2);
  CHECK(vec_to_str(data) == "[2, 4, 8, 7, 9, 11, 12, ]");
 
  data = {2, 3, 8, 6, 4, 11, 12, 7};

  heapify(data);

  CHECK(vec_to_str(data) == "[2, 3, 8, 6, 4, 11, 12, 7, ]");
  
  erase(data, 3);
  CHECK(vec_to_str(data) == "[2, 4, 8, 6, 7, 11, 12, ]");

  auto min = extract_root(data);

  CHECK(min == 2);
  CHECK(vec_to_str(data) == "[4, 6, 8, 12, 7, 11, ]");
}
