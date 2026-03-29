#pragma once

#include <JuceHeader.h>
#include "PluginProcessor.h"

//==============================================================================
// Custom rotary knob that draws a gold indicator line over the faceplate
class GoldStarKnob : public juce::Slider
{
public:
    GoldStarKnob() {
        setSliderStyle(juce::Slider::RotaryVerticalDrag);
        setTextBoxStyle(juce::Slider::NoTextBox, true, 0, 0);
        setRotaryParameters(juce::MathConstants<float>::pi * 0.75f,
                           juce::MathConstants<float>::pi * 2.25f, true);
        setMouseDragSensitivity(250);
        setColour(juce::Slider::rotarySliderFillColourId, juce::Colour(0xFFD4A843));
        setColour(juce::Slider::rotarySliderOutlineColourId, juce::Colours::transparentBlack);
        setColour(juce::Slider::thumbColourId, juce::Colour(0xFFD4A843));
    }
};

// Custom fader that's nearly transparent to overlay on the faceplate
class GoldStarFader : public juce::Slider
{
public:
    GoldStarFader() {
        setSliderStyle(juce::Slider::LinearVertical);
        setTextBoxStyle(juce::Slider::NoTextBox, true, 0, 0);
        setMouseDragSensitivity(180);
        setColour(juce::Slider::trackColourId, juce::Colours::transparentBlack);
        setColour(juce::Slider::backgroundColourId, juce::Colours::transparentBlack);
    }
};

//==============================================================================
class GoldStarEchoChamberAudioProcessorEditor : public juce::AudioProcessorEditor,
                                                 public juce::Timer
{
public:
    GoldStarEchoChamberAudioProcessorEditor (GoldStarEchoChamberAudioProcessor&);
    ~GoldStarEchoChamberAudioProcessorEditor() override;

    void paint (juce::Graphics&) override;
    void resized() override;
    void timerCallback() override;

private:
    GoldStarEchoChamberAudioProcessor& audioProcessor;
    juce::Image faceplateImage;

    // --- Rotary Knobs (7) ---
    GoldStarKnob lowPassKnob, highPassKnob, gainKnob;
    GoldStarKnob preDelayKnob, timeKnob, sizeKnob, diffusionKnob;

    // --- Vertical Faders (8) ---
    GoldStarFader eq100Fader, eq250Fader, eq1kFader, eq4kFader, eq10kFader;
    GoldStarFader dryFader, wetFader, outputFader;

    // --- Toggle Buttons ---
    juce::ToggleButton reverseToggle {""}; 
    juce::ToggleButton bypassToggle {""};

    // --- APVTS Attachments ---
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> lowPassAtt, highPassAtt, gainAtt;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> preDelayAtt, timeAtt, sizeAtt, diffusionAtt;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> eq100Att, eq250Att, eq1kAtt, eq4kAtt, eq10kAtt;
    std::unique_ptr<juce::AudioProcessorValueTreeState::SliderAttachment> dryAtt, wetAtt, outputAtt;
    std::unique_ptr<juce::AudioProcessorValueTreeState::ButtonAttachment> reverseAtt, bypassAtt;

    // VU meter levels (smoothed)
    float vuInput = 0.0f, vuProcess = 0.0f, vuOutput = 0.0f;

    // Helper
    void drawVUMeter(juce::Graphics& g, float cx, float cy, float level, const juce::String& label);

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (GoldStarEchoChamberAudioProcessorEditor)
};
