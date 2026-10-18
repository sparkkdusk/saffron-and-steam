class_name Economy
extends RefCounted
## Pure functions for money + mood. No state, easy to unit-test.

const FAST_RATIO := 0.6   # served before 60% of patience -> tip
const OK_RATIO := 1.0     # served before patience runs out -> happy


## wait_ratio = seconds waited / patience seconds.
static func payout(recipe: Recipe, profile: CustomerProfile, wait_ratio: float) -> Dictionary:
	var tip := 0
	if wait_ratio <= FAST_RATIO:
		tip += 1
	if profile != null and profile.personality == "generous":
		tip += 1
	return {"base": recipe.base_price, "tip": tip, "total": recipe.base_price + tip}


static func reaction_for_ok(wait_ratio: float) -> StringName:
	return &"happy" if wait_ratio <= OK_RATIO else &"neutral"


static func reaction_for_wrong(drink: DrinkState) -> StringName:
	# Only a cup (or nothing real) -> surprised. A real but wrong drink -> disappointed.
	return &"surprised" if drink == null or drink.steps.size() <= 1 else &"disappointed"
