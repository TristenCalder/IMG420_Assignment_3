#include "flappy_sprite.h"
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/node.hpp>
#include <cmath>

using namespace godot;

void FlappySprite::_bind_methods() {
    // Properties
    ClassDB::bind_method(D_METHOD("set_amplitude","v"), &FlappySprite::set_amplitude);
    ClassDB::bind_method(D_METHOD("get_amplitude"), &FlappySprite::get_amplitude);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "amplitude", PROPERTY_HINT_RANGE, "0,200,0.1"), "set_amplitude", "get_amplitude");

    ClassDB::bind_method(D_METHOD("set_frequency","v"), &FlappySprite::set_frequency);
    ClassDB::bind_method(D_METHOD("get_frequency"), &FlappySprite::get_frequency);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "frequency", PROPERTY_HINT_RANGE, "0,10,0.01"), "set_frequency", "get_frequency");

    ClassDB::bind_method(D_METHOD("set_tilt_strength","v"), &FlappySprite::set_tilt_strength);
    ClassDB::bind_method(D_METHOD("get_tilt_strength"), &FlappySprite::get_tilt_strength);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "tilt_strength", PROPERTY_HINT_RANGE, "0,90,0.1"), "set_tilt_strength", "get_tilt_strength");

    // Methods callable by other nodes/signals
    ClassDB::bind_method(D_METHOD("on_game_event","state"), &FlappySprite::on_game_event);
    ClassDB::bind_method(D_METHOD("play"), &FlappySprite::play);
    ClassDB::bind_method(D_METHOD("pause"), &FlappySprite::pause);
    ClassDB::bind_method(D_METHOD("stop"), &FlappySprite::stop);

    // Signals (this node emits)
    ADD_SIGNAL(MethodInfo("bobbing_peak",
        PropertyInfo(Variant::OBJECT, "sprite", PROPERTY_HINT_RESOURCE_TYPE, "Node"),
        PropertyInfo(Variant::VECTOR2, "position")));
}

void FlappySprite::_ready() {
    origin = get_position();
    last_y = origin.y;
    last_sin = 0.0;
    set_process(true);  
}

void FlappySprite::_process(double delta) {
    if (!playing) return;

    t += delta;
    const double s = std::sin(2.0 * Math_PI * frequency * t);
    Vector2 p = origin;
    p.y += static_cast<float>(amplitude * s);

    // approximate vertical velocity for tilt
    const double vy = (p.y - last_y) / delta;
    last_y = p.y;

    // Rotate based on velocity
    const double deg = (vy / 100.0) * tilt_strength;
    set_rotation_degrees(static_cast<float>(deg));

    set_position(p);

    // Emit on positive peaks: zero-crossing from + to - derivative ⇒ s near +1.
    // Simple heuristic: previously s < current s and (1 - s) small.
    if (last_sin < s && (1.0 - s) < 0.015) {
        emit_signal("bobbing_peak", this, p);
    }
    last_sin = s;
}

// Properties
void FlappySprite::set_amplitude(double v) { amplitude = v; }
double FlappySprite::get_amplitude() const { return amplitude; }

void FlappySprite::set_frequency(double v) { frequency = v; }
double FlappySprite::get_frequency() const { return frequency; }

void FlappySprite::set_tilt_strength(double v) { tilt_strength = v; }
double FlappySprite::get_tilt_strength() const { return tilt_strength; }

// External control via signals
void FlappySprite::on_game_event(const String &state) {
    // examples:
    // "game_over" -> pause and gray out
    // "shield_collected" -> flash color briefly
    if (state == "game_over") {
        pause();
        set_modulate(Color(0.7, 0.7, 0.7, 1.0));
    } else if (state == "resume") {
        set_modulate(Color(1,1,1,1));
        play();
    } else if (state == "shield_collected") {
        // brief visual feedback
        set_modulate(Color(0.6, 0.8, 1.0, 1.0));
    }
}

// Extra credit controls
void FlappySprite::play()  { playing = true; }
void FlappySprite::pause() { playing = false; }
void FlappySprite::stop()  { playing = false; t = 0.0; set_position(origin); set_rotation(0.0); }
