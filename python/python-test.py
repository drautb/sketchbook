"""
Determine which elements in each array are not present in the other.

Numbers in array 1 that aren't in array 2:
<num1> <num2> <num3>...

Numbers in array 2 that aren't in array 1:
<num1> <num2> <num3>...
"""
def reconcileHelper(arr_a, arr_b):
    in_a_not_b = []
    in_b_not_a = []

    # Some effort is wasted by subtracting both arrays from eachother.
    # Instead, sort both arrays up front, (2 * NlogN) then iterate over them in parallel,
    # noting which items are skipped in each array as we go.
    arr_a.sort()
    arr_b.sort()

    a_len = len(arr_a)
    b_len = len(arr_b)

    arr_a_idx = 0
    arr_b_idx = 0
    while arr_a_idx < a_len and arr_b_idx < b_len:
        # If the current element is in both, move on.
        a_val = arr_a[arr_a_idx]
        b_val = arr_b[arr_b_idx]
        if a_val == b_val:
            arr_a_idx += 1
            arr_b_idx += 1
            continue

        # If they're not the same, record the lower one as a difference,
        # and increment only that index.
        if a_val < b_val:
            in_a_not_b.append(a_val)
            arr_a_idx += 1
        else:
            in_b_not_a.append(b_val)
            arr_b_idx += 1

    # There may have been some numbers left at the end of one of the lists.
    # We need to add these to the difference.
    if arr_a_idx < a_len:
        in_a_not_b += arr_a[arr_a_idx:]
    elif arr_b_idx < b_len:
        in_b_not_a += arr_b[arr_b_idx:]


    print("Numbers in array 1 that aren't in array 2:")
    print_array(in_a_not_b)

    print("Numbers in array 2 that aren't in array 1:")
    print_array(in_b_not_a)

    return

def print_array(arr):
    for n in arr:
        print("%d" % n, end=" ")
    print("")