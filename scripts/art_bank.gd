class_name ArtBank
extends RefCounted

static var _cache: Dictionary = {}


static func tex(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key] as Texture2D
	var path := "res://art/%s.png" % key
	if not ResourceLoader.exists(path):
		return null
	var loaded: Texture2D = load(path) as Texture2D
	_cache[key] = loaded
	return loaded
