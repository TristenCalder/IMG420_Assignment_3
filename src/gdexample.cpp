#include "gdexample.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

// -------------------------
// Bind methods & properties
// -------------------------
void GDExample::_bind_methods() {
    // Amplitude property
    ClassDB::bind_method(D_METHOD("get_amplitude"), &GDExample::get_amplitude);
    ClassDB::bind_method(D_METHOD("set_amplitude", "p_amplitude"), &GDExample::set_amplitude);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "amplitude"), "set_amplitude", "get_amplitude");

    // Speed property
    ClassDB::bind_method(D_METHOD("get_speed"), &GDExample::get_speed);
    ClassDB::bind_method(D_METHOD("set_speed", "p_speed"), &GDExample::set_speed);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "speed", PROPERTY_HINT_RANGE, "0,20,0.01"), "set_speed", "get_speed");

    // Signal: emitted every second with this node and new position
    ADD_SIGNAL(MethodInfo("position_changed", PropertyInfo(Variant::OBJECT, "node"), PropertyInfo(Variant::VECTOR2, "new_pos")));
}

// -------------------------
// Constructor / Destructor
// -------------------------
GDExample::GDExample() {
    time_passed = 0.0;
    time_emit = 0.0; // counter for signal
    amplitude = 10.0;
    speed = 1.0;
}

GDExample::~GDExample() {
    // Cleanup if needed
}

// -------------------------
// Process function (animation & signal)
// -------------------------
void GDExample::_process(double delta) {
    // Update time
    time_passed += speed * delta;

    // Calculate new position
    Vector2 new_position = Vector2(
        amplitude + (amplitude * sin(time_passed * 2.0)),  // X movement
        amplitude + (amplitude * cos(time_passed * 1.5))   // Y wave
    );

    set_position(new_position);

    // Emit signal every second
    time_emit += delta;
    if (time_emit > 1.0) {
        emit_signal("position_changed", this, new_position);
        time_emit = 0.0;
    }
}

// -------------------------
// Amplitude getters/setters
// -------------------------
void GDExample::set_amplitude(const double p_amplitude) {
    amplitude = p_amplitude;
}

double GDExample::get_amplitude() const {
    return amplitude;
}

// -------------------------
// Speed getters/setters
// -------------------------
void GDExample::set_speed(const double p_speed) {
    speed = p_speed;
}

double GDExample::get_speed() const {
    return speed;
}
