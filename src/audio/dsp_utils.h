#pragma once

#include <cmath>
#include <algorithm>

namespace DSPUtils {
    inline float dBToLinear(float dB) {
        return std::pow(10.0f, dB / 20.0f);
    }

    inline float linearToDb(float linear) {
        return 20.0f * std::log10(std::max(linear, 1e-10f));
    }

    inline float msToSamples(float ms, int sampleRate) {
        return ms * sampleRate / 1000.0f;
    }

    // Soft clipper using tanh — mathematically smooth everywhere,
    // transparent at low levels, gentle saturation above ±0.5,
    // asymptotically approaches ±1.0 (never exceeds it).
    inline float softClip(float x) {
        return std::tanh(x);
    }
}
