#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
GoldStarEchoChamberAudioProcessorEditor::GoldStarEchoChamberAudioProcessorEditor (GoldStarEchoChamberAudioProcessor& p)
    : AudioProcessorEditor (&p), audioProcessor (p)
{
    // Load the skeuomorphic faceplate from the plugin bundle's Resources
    auto pluginFile = juce::File::getSpecialLocation(juce::File::currentExecutableFile);
    auto guiDir = pluginFile.getParentDirectory().getParentDirectory().getChildFile("Resources").getChildFile("gui");
    auto faceplateFile = guiDir.getChildFile("mock40.png");
    
    if (!faceplateFile.existsAsFile())
        faceplateFile = juce::File::getCurrentWorkingDirectory().getChildFile("Resources/gui/mock40.png");
    
    if (faceplateFile.existsAsFile())
        faceplateImage = juce::ImageFileFormat::loadFrom(faceplateFile);

    // --- Set up Rotary Knobs ---
    auto addKnob = [this](GoldStarKnob& knob) {
        addAndMakeVisible(knob);
        knob.setAlpha(0.0f); // Invisible — faceplate shows the knob art
    };
    addKnob(lowPassKnob);
    addKnob(highPassKnob);
    addKnob(gainKnob);
    addKnob(preDelayKnob);
    addKnob(timeKnob);
    addKnob(sizeKnob);
    addKnob(diffusionKnob);

    // Set skewed ranges for filter knobs (logarithmic feel)
    lowPassKnob.setRange(200.0, 20000.0, 1.0);
    lowPassKnob.setSkewFactorFromMidPoint(2000.0);
    highPassKnob.setRange(20.0, 8000.0, 1.0);
    highPassKnob.setSkewFactorFromMidPoint(500.0);

    // --- Set up Vertical Faders ---
    auto addFader = [this](GoldStarFader& fader) {
        addAndMakeVisible(fader);
        fader.setAlpha(0.0f);
    };
    addFader(eq100Fader);
    addFader(eq250Fader);
    addFader(eq1kFader);
    addFader(eq4kFader);
    addFader(eq10kFader);
    addFader(dryFader);
    addFader(wetFader);
    addFader(outputFader);

    // --- Set up Toggle Buttons ---
    addAndMakeVisible(reverseToggle);
    reverseToggle.setAlpha(0.0f);
    addAndMakeVisible(bypassToggle);
    bypassToggle.setAlpha(0.0f);

    // --- APVTS Attachments ---
    // Knobs
    lowPassAtt    = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "LOW_PASS",    lowPassKnob);
    highPassAtt   = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "HIGH_PASS",   highPassKnob);
    gainAtt       = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "INPUT_GAIN",  gainKnob);
    preDelayAtt   = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "PRE_DELAY",   preDelayKnob);
    timeAtt       = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "TIME",        timeKnob);
    sizeAtt       = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "SIZE",        sizeKnob);
    diffusionAtt  = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "DIFFUSION",   diffusionKnob);

    // EQ Faders
    eq100Att      = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "EQ_100",      eq100Fader);
    eq250Att      = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "EQ_250",      eq250Fader);
    eq1kAtt       = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "EQ_1K",       eq1kFader);
    eq4kAtt       = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "EQ_4K",       eq4kFader);
    eq10kAtt      = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "EQ_10K",      eq10kFader);

    // Output Faders
    dryAtt        = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "DRY_LEVEL",   dryFader);
    wetAtt        = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "WET_LEVEL",   wetFader);
    outputAtt     = std::make_unique<juce::AudioProcessorValueTreeState::SliderAttachment>(p.apvts, "OUTPUT_LEVEL",outputFader);

    // Toggle Buttons
    reverseAtt    = std::make_unique<juce::AudioProcessorValueTreeState::ButtonAttachment>(p.apvts, "REVERSE",     reverseToggle);
    bypassAtt     = std::make_unique<juce::AudioProcessorValueTreeState::ButtonAttachment>(p.apvts, "BYPASS",      bypassToggle);

    // Set window size to match the faceplate (1376 x 768)
    setSize(1376, 768);

    // Start timer for VU meter animation (30 FPS)
    startTimerHz(30);
}

GoldStarEchoChamberAudioProcessorEditor::~GoldStarEchoChamberAudioProcessorEditor()
{
    stopTimer();
}

//==============================================================================
void GoldStarEchoChamberAudioProcessorEditor::resized()
{
    // Position controls at exact pixel coordinates from the feature set spreadsheet.
    // Positions are (cx, cy) center points; we need to convert to top-left for setBounds.

    // --- Input Control Knobs ---
    lowPassKnob.setBounds   (170 - 40,  357 - 40,  80,  80);
    highPassKnob.setBounds  (279 - 40,  357 - 40,  80,  80);
    gainKnob.setBounds      (388 - 45,  353 - 45,  90,  90);

    // --- Reverb Control Knobs ---
    preDelayKnob.setBounds  (576 - 60,  490 - 60,  120, 120);
    timeKnob.setBounds      (789 - 60,  490 - 60,  120, 120);
    sizeKnob.setBounds      (576 - 60,  655 - 60,  120, 120);
    diffusionKnob.setBounds (788 - 60,  656 - 60,  120, 120);

    // --- Five-Band EQ Faders (30 wide, 300 tall, centered at given positions) ---
    eq100Fader.setBounds    (171 - 15,  585 - 150, 30,  300);
    eq250Fader.setBounds    (224 - 15,  585 - 150, 30,  300);
    eq1kFader.setBounds     (280 - 15,  585 - 150, 30,  300);
    eq4kFader.setBounds     (334 - 15,  585 - 150, 30,  300);
    eq10kFader.setBounds    (388 - 15,  585 - 150, 30,  300);

    // --- Output Faders (36 wide, 320 tall) ---
    dryFader.setBounds      (981 - 18,  360 - 160, 36,  320);
    wetFader.setBounds      (1095 - 18, 360 - 160, 36,  320);
    outputFader.setBounds   (1205 - 18, 360 - 160, 36,  320);

    // --- Toggle Switches ---
    reverseToggle.setBounds (971 - 25,  582 - 20,  50,  40);
    bypassToggle.setBounds  (1240 - 40, 665 - 35,  80,  70);
}

//==============================================================================
void GoldStarEchoChamberAudioProcessorEditor::timerCallback()
{
    // Read levels from the processor via public accessors
    {
        float newIn   = audioProcessor.getInputLevel();
        float newProc = audioProcessor.getProcessLevel();
        float newOut  = audioProcessor.getOutputLevel();

        // Smooth: attack fast, release slow
        vuInput   = (newIn  > vuInput)  ? newIn  : vuInput  * 0.85f + newIn  * 0.15f;
        vuProcess = (newProc > vuProcess) ? newProc : vuProcess * 0.85f + newProc * 0.15f;
        vuOutput  = (newOut > vuOutput) ? newOut : vuOutput * 0.85f + newOut * 0.15f;
    }

    // Repaint VU meter region only (top area)
    repaint(); // Repaint everything to ensure meters draw correctly
}

//==============================================================================
// New function: draws entire interior of the VU meter to fully cover the old graphics
void GoldStarEchoChamberAudioProcessorEditor::drawVUMeter(juce::Graphics& g, 
                                                           float cx, float cy, 
                                                           float level, 
                                                           const juce::String& /*label*/)
{
    // 1. Draw the window background to completely cover the old image.
    // The exact dimensions covering the glass window area smoothly.
    float width = 171.0f;
    float height = 96.0f;
    juce::Rectangle<float> meterBounds(cx - width/2.0f, cy - height/2.0f + 3.0f, width, height);

    // Cream background
    g.setColour(juce::Colour(0xFFF1E9D7));
    g.fillRoundedRectangle(meterBounds, 4.0f);
    
    // Add an inner shadow / shading gradient down
    juce::ColourGradient grad(juce::Colour(0x33000000), meterBounds.getX(), meterBounds.getY(),
                              juce::Colours::transparentBlack, meterBounds.getX(), meterBounds.getY() + 15.0f, false);
    g.setGradientFill(grad);
    g.fillRoundedRectangle(meterBounds, 4.0f);

    // --- Arc, Ticks, and Texts ---
    float pivotX = cx;
    float pivotY = cy + height/2.0f; // pivot is perfectly at the bottom center of the new window
    float radius = 70.0f;
    
    // Angle range: -40 to +40 degrees
    float angleRange = juce::MathConstants<float>::pi * 0.45f;
    float startAngle = -angleRange * 0.5f;
    
    // Draw Arc
    g.setColour(juce::Colour(0xFF333333));
    juce::Path arcPath;
    arcPath.addCentredArc(pivotX, pivotY, radius, radius, 0.0f, startAngle, startAngle + angleRange, true);
    g.strokePath(arcPath, juce::PathStrokeType(1.2f));

    // Red zone arc
    float zeroDbAngle = startAngle + ( (-0.0f - (-20.0f)) / (3.0f - (-20.0f)) ) * angleRange;
    juce::Path redArcPath;
    redArcPath.addCentredArc(pivotX, pivotY, radius, radius, 0.0f, zeroDbAngle, startAngle + angleRange, true);
    g.setColour(juce::Colour(0xFFD43A3A)); // vintage red
    g.strokePath(redArcPath, juce::PathStrokeType(6.0f));

    // Draw custom tick marks and numbers
    g.setFont(8.5f);
    auto drawTick = [&](float tickDB, bool major, const juce::String& text, bool isRed = false) {
        float norm = (tickDB - (-20.0f)) / (3.0f - (-20.0f));
        float theta = startAngle + norm * angleRange;
        float pX1 = pivotX + (radius) * std::sin(theta);
        float pY1 = pivotY - (radius) * std::cos(theta);
        float length = major ? 6.0f : 3.5f;
        float pX2 = pivotX + (radius - length) * std::sin(theta);
        float pY2 = pivotY - (radius - length) * std::cos(theta);
        
        g.setColour(isRed ? juce::Colour(0xFFB01D1D) : juce::Colour(0xFF333333));
        g.drawLine(pX1, pY1, pX2, pY2, major ? 1.5f : 1.0f);
        
        if (text.isNotEmpty()) {
            float tX = pivotX + (radius - length - 8.0f) * std::sin(theta);
            float tY = pivotY - (radius - length - 8.0f) * std::cos(theta);
            if (tickDB == -20.0f) { tX -= 6.0f; tY += 2.0f; } // tweak -20 pos
            g.drawText(text, tX - 10, tY - 6, 20, 12, juce::Justification::centred, false);
        }
    };

    // Major ticks (-20, -10, -7, -5, -3, -1, 0, +1, +2, +3)
    drawTick(-20.0f, true, "-20");
    drawTick(-10.0f, true, "-10");
    drawTick(-7.0f, true, "-7");
    drawTick(-5.0f, true, "-5");
    drawTick(-3.0f, true, "-3");
    drawTick(-1.0f, true, "");
    drawTick(0.0f, true, "0", true);
    drawTick(1.0f, true, "+1", true);
    drawTick(2.0f, true, "+2", true);
    drawTick(3.0f, true, "+3", true);
    
    // Draw "VU" branding
    g.setColour(juce::Colour(0xFF333333));
    g.setFont(10.0f);
    g.drawText("VU", pivotX - 15, pivotY - 26, 30, 15, juce::Justification::centred, false);

    // --- Draw the actual moving needle ---
    float dB = (level > 0.00001f) ? 20.0f * std::log10(level) : -60.0f;
    float normalized = juce::jlimit(0.0f, 1.0f, (dB - (-20.0f)) / (3.0f - (-20.0f)));
    float needleAngle = startAngle + normalized * angleRange;
    
    float needleLen = radius + 3.0f;
    float tipX = pivotX + needleLen * std::sin(needleAngle);
    float tipY = pivotY - needleLen * std::cos(needleAngle);
    
    // Needle drop shadow
    g.setColour(juce::Colour(0x33000000));
    g.drawLine(pivotX+1, pivotY, tipX+1, tipY, 1.5f);
    
    // Actual black needle
    g.setColour(juce::Colour(0xFF1E1E1E));
    g.drawLine(pivotX, pivotY, tipX, tipY, 1.5f);
    
    // Pivot Base Circle
    g.setColour(juce::Colour(0xFF111111));
    g.fillEllipse(pivotX - 3.5f, pivotY - 3.5f, 7.0f, 7.0f);
    
    // Highlight reflection on pivot
    g.setColour(juce::Colour(0x66FFFFFF));
    g.fillEllipse(pivotX - 1.5f, pivotY - 1.5f, 2.0f, 2.0f);
}

//==============================================================================
void GoldStarEchoChamberAudioProcessorEditor::paint (juce::Graphics& g)
{
    if (faceplateImage.isValid())
    {
        // Draw the full skeuomorphic faceplate as background scaled to fit
        g.drawImage(faceplateImage, getLocalBounds().toFloat());
    }
    else
    {
        g.fillAll(juce::Colour(0xFF1A1A2E));
        g.setColour(juce::Colours::gold);
        g.setFont(28.0f);
        g.drawFittedText("GOLD STAR ECHO CHAMBER", getLocalBounds(), juce::Justification::centred, 1);
        return;
    }

    // --- Draw knob indicator lines on top of faceplate ---
    auto drawKnobIndicator = [&](const GoldStarKnob& knob, float radius) {
        auto bounds = knob.getBounds().toFloat();
        float cx = bounds.getCentreX();
        float cy = bounds.getCentreY();
        
        float normalized = (float)(knob.getValue() - knob.getMinimum()) / 
                           (float)(knob.getMaximum() - knob.getMinimum());
        
        // -135° to +135° (270° sweep)
        float startAngle = -135.0f * juce::MathConstants<float>::pi / 180.0f;
        float endAngle   =  135.0f * juce::MathConstants<float>::pi / 180.0f;
        float angle = startAngle + normalized * (endAngle - startAngle);
        
        float innerR = radius * 0.35f;
        float outerR = radius * 0.85f;
        
        float x1 = cx + innerR * std::sin(angle);
        float y1 = cy - innerR * std::cos(angle);
        float x2 = cx + outerR * std::sin(angle);
        float y2 = cy - outerR * std::cos(angle);
        
        // Gold indicator line
        g.setColour(juce::Colour(0xFFD4A843));
        g.drawLine(x1, y1, x2, y2, 2.5f);
        
        // Bright dot at tip
        g.setColour(juce::Colour(0xFFFFE4A0));
        g.fillEllipse(x2 - 2.0f, y2 - 2.0f, 4.0f, 4.0f);
    };

    // Input control knobs (smaller)
    drawKnobIndicator(lowPassKnob,  40.0f);
    drawKnobIndicator(highPassKnob, 40.0f);
    drawKnobIndicator(gainKnob,     45.0f);

    // Reverb control knobs (larger)
    drawKnobIndicator(preDelayKnob,  60.0f);
    drawKnobIndicator(timeKnob,      60.0f);
    drawKnobIndicator(sizeKnob,      60.0f);
    drawKnobIndicator(diffusionKnob, 60.0f);

    // --- Draw fader handles on top of faceplate ---
    auto drawFaderHandle = [&](const GoldStarFader& fader, juce::Colour handleColour) {
        auto bounds = fader.getBounds().toFloat();
        float normalized = (float)(fader.getValue() - fader.getMinimum()) /
                           (float)(fader.getMaximum() - fader.getMinimum());
        
        // Fader handle position (bottom = min, top = max)
        float handleY = bounds.getBottom() - 15.0f - normalized * (bounds.getHeight() - 30.0f);
        float handleX = bounds.getCentreX();
        float handleW = bounds.getWidth() - 4.0f;
        float handleH = 14.0f;
        
        // Handle shadow
        g.setColour(juce::Colour(0x44000000));
        g.fillRoundedRectangle(handleX - handleW/2 + 1, handleY - handleH/2 + 1, handleW, handleH, 3.0f);
        
        // Handle body
        g.setColour(handleColour);
        g.fillRoundedRectangle(handleX - handleW/2, handleY - handleH/2, handleW, handleH, 3.0f);
        
        // Handle groove line
        g.setColour(handleColour.darker(0.3f));
        g.drawLine(handleX - handleW/4, handleY, handleX + handleW/4, handleY, 1.0f);
    };

    // EQ fader handles (tan/gold)
    juce::Colour tanHandle(0xFFCCB888);
    drawFaderHandle(eq100Fader, tanHandle);
    drawFaderHandle(eq250Fader, tanHandle);
    drawFaderHandle(eq1kFader,  tanHandle);
    drawFaderHandle(eq4kFader,  tanHandle);
    drawFaderHandle(eq10kFader, tanHandle);

    // Output fader handles
    drawFaderHandle(dryFader,    tanHandle);
    drawFaderHandle(wetFader,    tanHandle);
    drawFaderHandle(outputFader, juce::Colour(0xFFCC3333)); // Red handle for output

    // --- Draw Programmatically Generated VU meters ---
    drawVUMeter(g, 477.0f, 137.0f, vuInput,   "IN");
    drawVUMeter(g, 677.0f, 137.0f, vuProcess, "PROC");
    drawVUMeter(g, 876.0f, 137.0f, vuOutput,  "OUT");

    // --- Draw toggle switch states ---
    // Reverse toggle
    if (reverseToggle.getToggleState())
    {
        g.setColour(juce::Colour(0x6600FF44));
        g.fillRoundedRectangle(971.0f - 25.0f, 582.0f - 20.0f, 50.0f, 40.0f, 5.0f);
    }

    // Bypass toggle
    if (bypassToggle.getToggleState())
    {
        g.setColour(juce::Colour(0x88FF2222));
        g.fillRoundedRectangle(1240.0f - 40.0f, 665.0f - 35.0f, 80.0f, 70.0f, 5.0f);
        g.setColour(juce::Colours::white);
        g.setFont(11.0f);
        g.drawText("BYPASSED", juce::Rectangle<float>(1240.0f - 40.0f, 665.0f - 10.0f, 80.0f, 20.0f),
                   juce::Justification::centred);
    }

    // --- Signal LED ---
    float signalLevel = vuOutput;
    juce::Colour ledColour = (signalLevel > 0.001f) ? juce::Colour(0xFF00CC44) : juce::Colour(0xFF224422);
    g.setColour(ledColour);
    g.fillEllipse(1130.0f - 7.0f, 688.0f - 7.0f, 14.0f, 14.0f);
    if (signalLevel > 0.001f) {
        // Green glow
        g.setColour(juce::Colour(0x3300FF44));
        g.fillEllipse(1130.0f - 10.0f, 688.0f - 10.0f, 20.0f, 20.0f);
    }
}
