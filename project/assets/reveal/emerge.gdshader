shader_type canvas_item;

// A part of the creature comes out from where it starts, rather than fading in whole. The part's modulate alpha, which
// the reveal's clip fades from 0 to 1 as it always did, says how far it has come; reach says how far each pixel lies
// from where it starts, 0 there and 1 at the farthest that shows (tools/art/gen_creature.py). The body, the head and
// the crest come out of the fog from the ridge (D119), so the ridge's edges never show through a half-faded body; the
// arm comes out from the shoulder to the hand (D120), so its hand never hangs half-seen in the air. From where it
// starts it spreads with a soft front; with the alpha at 1 the part is whole everywhere.

uniform sampler2D reach : filter_linear, hint_default_white;

const float SOFT = 0.25;

varying float come;

void vertex() {
	come = COLOR.a;
	COLOR.a = 1.0;
}

void fragment() {
	float d = texture(reach, UV).r;
	COLOR.a *= clamp((come * (1.0 + SOFT) - d) / SOFT, 0.0, 1.0);
}
