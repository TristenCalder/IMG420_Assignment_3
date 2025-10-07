#ifndef FLAPPY_SPRITE_H
#define FLAPPY_SPRITE_H

#include <godot_cpp/classes/sprite2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/vector2.hpp>

namespace godot {

class FlappySprite : public Sprite2D {
    GDCLASS(FlappySprite, Sprite2D)

private:
    // Configurable in inspector
    double amplitude = 12.0;      // pixels
    double frequency = 1.2;       // Hz
    double tilt_strength = 18.0;  // degrees per 100 px/s

    // Animation state
    bool playing = true;
    double t = 0.0;
    double last_sin = 0.0;
    Vector2 origin;
    double last_y = 0.0;

protected:
    static void _bind_methods();

public:
    FlappySprite() = default;
    ~FlappySprite() = default;

    // Godot lifecycle
    void _ready() override;
    void _process(double delta) override;

    // Properties
    void set_amplitude(double v);
    double get_amplitude() const;

    void set_frequency(double v);
    double get_frequency() const;

    void set_tilt_strength(double v);
    double get_tilt_strength() const;

    // Signals-invoked public API
    void on_game_event(const String &state); // called by external signal
    void play();
    void pause();
    void stop();
};

} // namespace godot

#endif
