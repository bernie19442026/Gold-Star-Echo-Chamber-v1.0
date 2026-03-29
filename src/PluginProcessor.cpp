#include "PluginProcessor.h"
#include "PluginEditor.h"

GoldStarEchoChamberAudioProcessor::GoldStarEchoChamberAudioProcessor()
    : AudioProcessor (BusesProperties()
                      .withInput  ("Input",  juce::AudioChannelSet::stereo(), true)
                      .withOutput ("Output", juce::AudioChannelSet::stereo(), true)),
      apvts (*this, nullptr, "Parameters", createParameterLayout())
{
}

GoldStarEchoChamberAudioProcessor::~GoldStarEchoChamberAudioProcessor() {}

const juce::String GoldStarEchoChamberAudioProcessor::getName() const { return "Gold Star Echo Chamber"; }
bool GoldStarEchoChamberAudioProcessor::acceptsMidi() const { return false; }
bool GoldStarEchoChamberAudioProcessor::producesMidi() const { return false; }
bool GoldStarEchoChamberAudioProcessor::isMidiEffect() const { return false; }
double GoldStarEchoChamberAudioProcessor::getTailLengthSeconds() const { return 10.0; }
int GoldStarEchoChamberAudioProcessor::getNumPrograms() { return 1; }
int GoldStarEchoChamberAudioProcessor::getCurrentProgram() { return 0; }
void GoldStarEchoChamberAudioProcessor::setCurrentProgram (int index) {}
const juce::String GoldStarEchoChamberAudioProcessor::getProgramName (int index) { return {}; }
void GoldStarEchoChamberAudioProcessor::changeProgramName (int index, const juce::String& newName) {}

void GoldStarEchoChamberAudioProcessor::prepareToPlay (double sampleRate, int samplesPerBlock)
{
    leftEngine = std::make_unique<AudioEngine>((int)sampleRate, samplesPerBlock);
    rightEngine = std::make_unique<AudioEngine>((int)sampleRate, samplesPerBlock);
    
    // Allocate scratch buffers for safe in-place processing
    scratchBufferL_.resize(samplesPerBlock * 2, 0.0f);
    scratchBufferR_.resize(samplesPerBlock * 2, 0.0f);
    
    // Load default IR from Resources
    auto pluginFile = juce::File::getSpecialLocation(juce::File::currentExecutableFile);
    auto resources = pluginFile.getParentDirectory().getParentDirectory().getChildFile("Resources");
    auto irFile = resources.getChildFile("ir_samples").getChildFile("GOLDSTAR MONO 3.wav");
    
    // If not in bundle (e.g. debugging/standalone), check local folder
    if (!irFile.existsAsFile())
        irFile = juce::File::getCurrentWorkingDirectory().getChildFile("Resources/ir_samples/GOLDSTAR MONO 3.wav");

    if (irFile.existsAsFile())
    {
        try {
            leftEngine->loadIR(irFile.getFullPathName().toStdString());
            rightEngine->loadIR(irFile.getFullPathName().toStdString());
            DBG("Gold Star: IR loaded from " + irFile.getFullPathName());
        } catch (const std::exception& e) {
            DBG("Gold Star: Failed to load IR: " + juce::String(e.what()));
        }
    }
    else
    {
        DBG("Gold Star: IR file not found at " + irFile.getFullPathName());
    }
}

void GoldStarEchoChamberAudioProcessor::releaseResources()
{
    leftEngine.reset();
    rightEngine.reset();
}

bool GoldStarEchoChamberAudioProcessor::isBusesLayoutSupported (const BusesLayout& layouts) const
{
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
     && layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

    if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
        return false;

    return true;
}

void GoldStarEchoChamberAudioProcessor::updateEngineParameters()
{
    auto update = [&](AudioEngine* engine) {
        if (!engine) return;
        engine->setParameter(ParameterID::PRE_DELAY, *apvts.getRawParameterValue("PRE_DELAY"));
        engine->setParameter(ParameterID::OUTPUT_LEVEL, *apvts.getRawParameterValue("OUTPUT_LEVEL"));
        engine->setParameter(ParameterID::REVERB_LENGTH, *apvts.getRawParameterValue("TIME"));
        engine->setParameter(ParameterID::INPUT_GAIN, *apvts.getRawParameterValue("INPUT_GAIN"));
        engine->setParameter(ParameterID::LOW_PASS, *apvts.getRawParameterValue("LOW_PASS"));
        engine->setParameter(ParameterID::HIGH_PASS, *apvts.getRawParameterValue("HIGH_PASS"));
        engine->setParameter(ParameterID::EQ_100, *apvts.getRawParameterValue("EQ_100"));
        engine->setParameter(ParameterID::EQ_250, *apvts.getRawParameterValue("EQ_250"));
        engine->setParameter(ParameterID::EQ_1K, *apvts.getRawParameterValue("EQ_1K"));
        engine->setParameter(ParameterID::EQ_4K, *apvts.getRawParameterValue("EQ_4K"));
        engine->setParameter(ParameterID::EQ_10K, *apvts.getRawParameterValue("EQ_10K"));
        engine->setParameter(ParameterID::ROOM_SIZE, *apvts.getRawParameterValue("SIZE"));
        engine->setParameter(ParameterID::DIFFUSION, *apvts.getRawParameterValue("DIFFUSION"));
        engine->setParameter(ParameterID::DRY_LEVEL, *apvts.getRawParameterValue("DRY_LEVEL"));
        engine->setParameter(ParameterID::WET_LEVEL, *apvts.getRawParameterValue("WET_LEVEL"));
        engine->setParameter(ParameterID::REVERSE, *apvts.getRawParameterValue("REVERSE"));
        engine->setParameter(ParameterID::BYPASS, *apvts.getRawParameterValue("BYPASS"));
        engine->setParameter(ParameterID::DAMPING, *apvts.getRawParameterValue("DAMPING"));
    };

    update(leftEngine.get());
    update(rightEngine.get());
}

void GoldStarEchoChamberAudioProcessor::processBlock (juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    juce::ScopedNoDenormals noDenormals;
    auto totalNumInputChannels  = getTotalNumInputChannels();
    auto totalNumOutputChannels = getTotalNumOutputChannels();
    int numSamples = buffer.getNumSamples();

    for (auto i = totalNumInputChannels; i < totalNumOutputChannels; ++i)
        buffer.clear (i, 0, numSamples);

    // Update parameters from APVTS
    updateEngineParameters();

    // Ensure scratch buffers are large enough
    if ((int)scratchBufferL_.size() < numSamples)
        scratchBufferL_.resize(numSamples, 0.0f);
    if ((int)scratchBufferR_.size() < numSamples)
        scratchBufferR_.resize(numSamples, 0.0f);

    auto* channelDataL = buffer.getWritePointer(0);
    auto* channelDataR = totalNumInputChannels > 1 ? buffer.getWritePointer(1) : nullptr;

    // Copy input to scratch buffers so we don't process in-place
    std::copy(channelDataL, channelDataL + numSamples, scratchBufferL_.data());

    if (leftEngine)
        leftEngine->processBlock(scratchBufferL_.data(), channelDataL, numSamples);

    if (rightEngine && channelDataR)
    {
        std::copy(channelDataR, channelDataR + numSamples, scratchBufferR_.data());
        rightEngine->processBlock(scratchBufferR_.data(), channelDataR, numSamples);
    }
    else if (channelDataR)
    {
        buffer.copyFrom(1, 0, buffer.getReadPointer(0), numSamples);
    }
}

bool GoldStarEchoChamberAudioProcessor::hasEditor() const { return true; }
juce::AudioProcessorEditor* GoldStarEchoChamberAudioProcessor::createEditor()
{
    return new juce::GenericAudioProcessorEditor (*this);
}

void GoldStarEchoChamberAudioProcessor::getStateInformation (juce::MemoryBlock& destData)
{
    auto state = apvts.copyState();
    std::unique_ptr<juce::XmlElement> xml (state.createXml());
    copyXmlToBinary (*xml, destData);
}

void GoldStarEchoChamberAudioProcessor::setStateInformation (const void* data, int sizeInBytes)
{
    std::unique_ptr<juce::XmlElement> xmlState (getXmlFromBinary (data, sizeInBytes));
    if (xmlState.get() != nullptr)
        if (xmlState->hasTagName (apvts.state.getType()))
            apvts.replaceState (juce::ValueTree::fromXml (*xmlState));
}

juce::AudioProcessorValueTreeState::ParameterLayout GoldStarEchoChamberAudioProcessor::createParameterLayout()
{
    std::vector<std::unique_ptr<juce::RangedAudioParameter>> params;

    params.push_back(std::make_unique<juce::AudioParameterFloat>("PRE_DELAY", "Pre-Delay", 0.0f, 500.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("OUTPUT_LEVEL", "Output", -80.0f, 6.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("TIME", "Time", 0.1f, 10.0f, 2.0f)); // Reverb Length
    params.push_back(std::make_unique<juce::AudioParameterFloat>("INPUT_GAIN", "Input Gain", -80.0f, 12.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("LOW_PASS", "Low Pass", 200.0f, 20000.0f, 20000.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("HIGH_PASS", "High Pass", 20.0f, 8000.0f, 20.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("EQ_100", "EQ 100Hz", -12.0f, 12.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("EQ_250", "EQ 250Hz", -12.0f, 12.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("EQ_1K", "EQ 1kHz", -12.0f, 12.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("EQ_4K", "EQ 4kHz", -12.0f, 12.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("EQ_10K", "EQ 10kHz", -12.0f, 12.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("SIZE", "Size", 0.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("DIFFUSION", "Diffusion", 0.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("DRY_LEVEL", "Dry Level", -80.0f, 0.0f, -6.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("WET_LEVEL", "Wet Level", -80.0f, 0.0f, -6.0f));
    params.push_back(std::make_unique<juce::AudioParameterBool>("REVERSE", "Reverse", false));
    params.push_back(std::make_unique<juce::AudioParameterBool>("BYPASS", "Bypass", false));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("DAMPING", "Damping", 0.0f, 1.0f, 0.0f));

    return { params.begin(), params.end() };
}

// This creates the processor
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new GoldStarEchoChamberAudioProcessor();
}
