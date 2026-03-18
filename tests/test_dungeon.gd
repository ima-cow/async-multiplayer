extends GutTest



func test_no_intersections() -> void:
	const NUM_ITERATIONS := 50
	
	for i in range(NUM_ITERATIONS):
		pass
	assert_eq('one', 'two', "my should pass")

func test_assert_eq_number_not_equal() -> void:
	assert_eq(1, 2, "Should fail.  1 != 2")

func test_assert_eq_number_equal() -> void:
	assert_eq('asdf', 'asdf', "Should pass")

func test_assert_true_with_true() -> void:
	assert_true(true, "Should pass, true is true")

func test_assert_true_with_false() -> void:
	assert_true(false, "Should fail")

func test_something_else() -> void:
	assert_true(false, "didn't work")

func test_ethan() -> void:
	assert_eq(1, 1.0, "this is my test")
	assert_eq(1, 1.0, "this is my test2")
	assert_eq(1, 2.0, "this is my test3")
