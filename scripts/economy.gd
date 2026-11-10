class_name Economy
extends RefCounted

static func can_afford(gold: int, cost: int) -> bool:
	return cost >= 0 and gold >= cost


static func try_spend(gold: int, cost: int) -> Dictionary:
	if not can_afford(gold, cost):
		return {"ok": false, "gold": gold}
	return {"ok": true, "gold": gold - cost}


static func grant(gold: int, amount: int) -> int:
	return gold + amount


static func sell_refund(spent: int, ratio: float) -> int:
	return int(floor(float(spent) * ratio))


static func wave_clear_bonus(wave_number: int, base: int, per_wave: int) -> int:
	return base + per_wave * wave_number
