#pragma once

#include <JuceHeader.h>
#include "audio/audio_engine.h"

class GoldStarEchoChamberAudioProcessor : public juce::AudioProcessor
{
public:
    GoldStarEchoChamberAudioProcessor();
    ~GoldStarEchoChamberAudioProcessor() override;

    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;

    bool isBusesLayoutSupported (const BusesLayout& layouts) const override;

    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override;

    const juce::String getName() const override;

    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    double getTailLengthSeconds() const override;

    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram (int index) override;
    const juce::String getProgramName (int index) override;
    void changeProgramName (int index, const juce::String& newName) override;

    void getStateInformation (juce::MemoryBlock& destData) override;
    void setStateInformation (const void* data, int sizeInBytes) override;

    juce::AudioProcessorValueTreeState apvts;

    // VU meter level accessors for the editor
    float getInputLevel() const;
    float getProcessLevel() const;
    float getOutputLevel() const;

private:
    juce::AudioProcessorValueTreeState::ParameterLayout createParameterLayout();
    
    // We'll use two engines for stereo processing
    std::unique_ptr<AudioEngine> leftEngine;
    std::unique_ptr<AudioEngine> rightEngine;

    // To handle parameter updates from APVTS to AudioEngine
    void updateEngineParameters();

    // Scratch buffers for safe in-place processing
    std::vector<float> scratchBufferL_;
    std::vector<float> scratchBufferR_;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (GoldStarEchoChamberAudioProcessor)
};
