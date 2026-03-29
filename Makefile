# Gold Star Echo Chamber - VST3 Makefile for macOS
# Uses JUCE modules directly

CXX = clang++
CC = clang
CXXFLAGS = -std=c++17 -O2 -fno-strict-aliasing -fPIC -fvisibility=hidden \
           -x objective-c++ \
           -I Source -I Source/audio -I Source/common -I JuceLibraryCode \
           -I /Users/bernie/JUCE/modules \
           -I /Users/bernie/JUCE/modules/juce_audio_processors/format_types/VST3_SDK
           
OBJCXXFLAGS = $(CXXFLAGS) -fobjc-arc
CFLAGS = -O2 -fPIC -I JuceLibraryCode -I /Users/bernie/JUCE/modules

DEFINES = -DJUCE_MAC=1 -DJUCE_STRICT_REFCOUNTEDPOINTER=1 -DDEBUG=1 \
          -DJUCE_GLOBAL_MODULE_SETTINGS_INCLUDED=1 \
          -DJucePlugin_Build_VST3=1 -DJucePlugin_Build_AU=0 \
          -DJucePlugin_Build_Standalone=0 '-DJucePlugin_Name="Gold Star Echo Chamber"' \
          -DJucePlugin_Version=31.0.0 -DJucePlugin_PluginCode=0x47536563 \
          -DJucePlugin_ManufacturerCode=0x47537472 -DJUCE_SHARED_CODE=1 \
          -DJucePlugin_IsSynth=0 -DJucePlugin_ProducesMidiOutput=0 \
          -DJucePlugin_WantsMidiInput=0 -DJucePlugin_EditorRequiresKeyboardFocus=0 \
          -DJucePlugin_VSTUniqueID=0x47536563 -DJucePlugin_VersionCode=0x1f0000 \
          '-DJucePlugin_Manufacturer="GoldStar"' '-DJucePlugin_ManufacturerWebsite="www.GoldStar.com"' \
          '-DJucePlugin_ManufacturerEmail=""' '-DJucePlugin_VersionString="31.0.0"'

FRAMEWORKS = -framework Accelerate -framework AudioToolbox -framework CoreAudio \
             -framework CoreFoundation -framework CoreGraphics -framework CoreText \
             -framework Cocoa -framework QuartzCore -framework UniformTypeIdentifiers \
             -framework AVFoundation -framework Foundation -framework CoreMIDI \
             -framework Security -framework IOKit -framework Metal -framework Carbon \
             -framework WebKit -framework CoreAudioKit

# Source files
PLUGIN_SRCS = Source/PluginProcessor.cpp \
              Source/PluginEditor.cpp \
              Source/audio/audio_engine.cpp \
              Source/audio/convolver.cpp \
              Source/audio/ir_loader.cpp \
              Source/audio/parameters.cpp

# JUCE modules (using the include files in JuceLibraryCode)
JUCE_SRCS = JuceLibraryCode/include_juce_audio_basics.cpp \
            JuceLibraryCode/include_juce_audio_devices.cpp \
            JuceLibraryCode/include_juce_audio_formats.cpp \
            JuceLibraryCode/include_juce_audio_processors.cpp \
            JuceLibraryCode/include_juce_audio_utils.cpp \
            JuceLibraryCode/include_juce_core.cpp \
            JuceLibraryCode/include_juce_core_CompilationTime.cpp \
            JuceLibraryCode/include_juce_data_structures.cpp \
            JuceLibraryCode/include_juce_events.cpp \
            JuceLibraryCode/include_juce_graphics.cpp \
            JuceLibraryCode/include_juce_graphics_Harfbuzz.cpp \
            JuceLibraryCode/include_juce_gui_basics.cpp \
            JuceLibraryCode/include_juce_gui_extra.cpp

# Add MM files for Mac modules
JUCE_MM_SRCS = JuceLibraryCode/include_juce_audio_basics.mm \
               JuceLibraryCode/include_juce_audio_devices.mm \
               JuceLibraryCode/include_juce_audio_formats.mm \
               JuceLibraryCode/include_juce_audio_processors.mm \
               JuceLibraryCode/include_juce_audio_utils.mm \
               JuceLibraryCode/include_juce_core.mm \
               JuceLibraryCode/include_juce_data_structures.mm \
               JuceLibraryCode/include_juce_events.mm \
               JuceLibraryCode/include_juce_graphics.mm \
               JuceLibraryCode/include_juce_gui_basics.mm \
               JuceLibraryCode/include_juce_gui_extra.mm \
               /Users/bernie/JUCE/modules/juce_audio_plugin_client/juce_audio_plugin_client_VST3.mm

# Add C file for Sheenbidi
JUCE_C_SRCS = JuceLibraryCode/include_juce_graphics_Sheenbidi.c

OBJS = $(PLUGIN_SRCS:.cpp=.o) $(JUCE_SRCS:.cpp=.o) $(JUCE_MM_SRCS:.mm=.o) $(JUCE_C_SRCS:.c=.o)

BUNDLE = GoldStarEchoChamber.vst3
BINARY = $(BUNDLE)/Contents/MacOS/GoldStarEchoChamber

all: $(BUNDLE)

$(BUNDLE): $(OBJS)
	@mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources/ir_samples
	$(CXX) -dynamiclib $(FRAMEWORKS) -o $(BINARY) $^
	@# Create PkgInfo
	@echo "BNDL????" > $(BUNDLE)/Contents/PkgInfo
	@# Generate Info.plist
	@echo '<?xml version="1.0" encoding="UTF-8"?>' > $(BUNDLE)/Contents/Info.plist
	@echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' >> $(BUNDLE)/Contents/Info.plist
	@echo '<plist version="1.0"><dict>' >> $(BUNDLE)/Contents/Info.plist
	@echo '<key>CFBundleDevelopmentRegion</key><string>English</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '<key>CFBundleExecutable</key><string>GoldStarEchoChamber</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '<key>CFBundleGetInfoString</key><string>Gold Star Echo Chamber v3.9</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '<key>CFBundleIdentifier</key><string>com.GoldStar.GoldStarEchoChamber.vst3</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '<key>CFBundleName</key><string>Gold Star Echo Chamber</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '<key>CFBundlePackageType</key><string>BNDL</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '<key>CFBundleShortVersionString</key><string>3.9</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '<key>CFBundleSignature</key><string>????</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '<key>CFBundleVersion</key><string>3.9</string>' >> $(BUNDLE)/Contents/Info.plist
	@echo '<key>NSHighResolutionCapable</key><true/>' >> $(BUNDLE)/Contents/Info.plist
	@echo '</dict></plist>' >> $(BUNDLE)/Contents/Info.plist
	@# Copy IR samples
	@cp Resources/ir_samples/*.wav $(BUNDLE)/Contents/Resources/ir_samples/
	@# Copy GUI assets
	@mkdir -p $(BUNDLE)/Contents/Resources/gui
	@cp Resources/gui/*.jpeg $(BUNDLE)/Contents/Resources/gui/ 2>/dev/null || :
	@cp Resources/gui/*.png $(BUNDLE)/Contents/Resources/gui/ 2>/dev/null || :
	@echo "Built $(BUNDLE)"

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(DEFINES) -c -o $@ $<

%.o: %.mm
	$(CXX) $(OBJCXXFLAGS) $(DEFINES) -c -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) $(DEFINES) -c -o $@ $<

clean:
	rm -rf $(OBJS) $(BUNDLE)
