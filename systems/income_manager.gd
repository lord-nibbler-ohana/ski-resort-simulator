extends Node

# Skipass pricing (NOK)
const SKIPASS_FULL_DAY := 500.0
const SKIPASS_MORNING := 380.0
const SKIPASS_AFTERNOON := 300.0

# Skipass type distribution
const SKIPASS_FULL_DAY_CHANCE := 0.60
const SKIPASS_MORNING_CHANCE := 0.25
# Remaining 15% = afternoon

# Kiosk: 80% of skiers buy, average 50-100 NOK
const KIOSK_CHANCE := 0.8
const KIOSK_MIN := 50.0
const KIOSK_MAX := 100.0

# Restaurant: lunch spenders 150-250 NOK
const RESTAURANT_MIN := 150.0
const RESTAURANT_MAX := 250.0

# Season pass rate
const SEASON_PASS_RATE := 0.2

# Revenue accumulators
var skipass_revenue: float = 0.0
var kiosk_revenue: float = 0.0
var restaurant_revenue: float = 0.0


func get_total() -> float:
	return skipass_revenue + kiosk_revenue + restaurant_revenue


func add_skipass(skipass_type: int) -> void:
	match skipass_type:
		0:
			skipass_revenue += SKIPASS_FULL_DAY
		1:
			skipass_revenue += SKIPASS_MORNING
		2:
			skipass_revenue += SKIPASS_AFTERNOON


func add_kiosk() -> void:
	kiosk_revenue += randf_range(KIOSK_MIN, KIOSK_MAX)


func add_restaurant() -> void:
	restaurant_revenue += randf_range(RESTAURANT_MIN, RESTAURANT_MAX)


func roll_skipass_type() -> int:
	var roll := randf()
	if roll < SKIPASS_FULL_DAY_CHANCE:
		return 0  # full day
	elif roll < SKIPASS_FULL_DAY_CHANCE + SKIPASS_MORNING_CHANCE:
		return 1  # morning
	else:
		return 2  # afternoon


func is_season_pass_holder() -> bool:
	return randf() < SEASON_PASS_RATE
