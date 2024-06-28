@tool
extends Node
class_name TextureHelper


# ------------------------------------------------------------------------------
# Constants and Enums
# ------------------------------------------------------------------------------
enum StretchMode {
	SCALE=TextureRect.StretchMode.STRETCH_SCALE,
	TILE=TextureRect.StretchMode.STRETCH_TILE,
	KEEP=TextureRect.StretchMode.STRETCH_KEEP,
	KEEP_CENTERED=TextureRect.StretchMode.STRETCH_KEEP_CENTERED,
	KEEP_ASPECT=TextureRect.StretchMode.STRETCH_KEEP_ASPECT,
	KEEP_ASPECT_CENTERED=TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED,
	KEEP_ASPECT_COVERED=TextureRect.StretchMode.STRETCH_KEEP_ASPECT_COVERED
}

enum ExpandMode {
	KEEP_SIZE=TextureRect.EXPAND_KEEP_SIZE,
	IGNORE_SIZE=TextureRect.EXPAND_IGNORE_SIZE,
	FIT_WIDTH=TextureRect.EXPAND_FIT_WIDTH,
	FIT_WIDTH_PROPORTIONAL=TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL,
	FIT_HEIGHT=TextureRect.EXPAND_FIT_HEIGHT,
	FIT_HEIGHT_PROPORTIONAL=TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
}

# ------------------------------------------------------------------------------
# Public Static Methods
# ------------------------------------------------------------------------------
static func Get_Texture_Stretch_Data(texture : Texture2D, container_size : Vector2, stretch_mode : StretchMode, flip_h : bool = false, flip_v : bool = false) -> Dictionary:
	if texture == null: return {}
	
	var size : Vector2 = Vector2.ZERO
	var position : Vector2 = Vector2.ZERO
	var region : Rect2 = Rect2(Vector2.ZERO, texture.get_size())
	var tiled : bool = false
	
	match(stretch_mode):
		TextureRect.STRETCH_SCALE:
			size = container_size
		TextureRect.STRETCH_TILE:
			size = container_size
			tiled = true
		TextureRect.STRETCH_KEEP:
			size = texture.get_size()
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED, TextureRect.STRETCH_KEEP_ASPECT:
			var tw : float = texture.get_width() * (container_size.y / texture.get_height())
			var th : float = container_size.y
			
			if tw > container_size.x:
				tw = container_size.x
				th = texture.get_height() * (container_size.x / texture.get_width())
			
			if stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
				position = Vector2(
					(container_size.x - tw) * 0.5,
					(container_size.y - th) * 0.5
				)
			
			size.x = tw
			size.y = th
		TextureRect.STRETCH_KEEP_ASPECT_COVERED:
			var texture_size : Vector2 = texture.get_size()
			var scale_size : Vector2 = Vector2(
				container_size.x / texture_size.x,
				container_size.y / texture_size.y
			)
			var nscale : float = max(scale_size.x, scale_size.y)
			size = texture_size * nscale
			region.position = (((texture_size * nscale) - container_size) / nscale).abs() * 2.0
			region.size = container_size / nscale
	
	size.x *= -1.0 if flip_h else 1.0
	size.y *= -1.0 if flip_v else 1.0
	
	return {
		"rect":Rect2(position, size),
		"region":region,
		"tiled":tiled
	}

