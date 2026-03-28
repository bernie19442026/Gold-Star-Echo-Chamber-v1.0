CXX = clang++
CXXFLAGS = -std=c++17 -O2 -Wall -Wextra -I src
OBJCXXFLAGS = $(CXXFLAGS) -fobjc-arc
FRAMEWORKS = -framework Accelerate -framework CoreAudio -framework AudioToolbox \
             -framework CoreFoundation -framework Cocoa -framework UniformTypeIdentifiers \
             -framework AVFoundation -framework QuartzCore

AUDIO_SRCS = src/audio/convolver.cpp \
             src/audio/ir_loader.cpp \
             src/audio/parameters.cpp \
             src/audio/audio_engine.cpp

STANDALONE_SRCS = src/standalone/audio_io.cpp \
                  src/standalone/standalone_app.cpp \
                  src/standalone/file_player.cpp

STANDALONE_MM = src/standalone/standalone_ui.mm \
                src/standalone/main.mm

AUDIO_OBJS = $(AUDIO_SRCS:.cpp=.o)
STANDALONE_OBJS = $(STANDALONE_SRCS:.cpp=.o)
STANDALONE_MM_OBJS = $(STANDALONE_MM:.mm=.o)

APP_BUNDLE = build/GoldStarEchoChamber.app
APP_CONTENTS = $(APP_BUNDLE)/Contents
APP_MACOS = $(APP_CONTENTS)/MacOS
APP_RESOURCES = $(APP_CONTENTS)/Resources
BINARY = $(APP_MACOS)/GoldStarEchoChamber

.PHONY: all clean run

all: $(APP_BUNDLE)

$(APP_BUNDLE): $(AUDIO_OBJS) $(STANDALONE_OBJS) $(STANDALONE_MM_OBJS) | build
	@mkdir -p $(APP_MACOS) $(APP_RESOURCES)/ir_samples $(APP_RESOURCES)/gui
	$(CXX) $(CXXFLAGS) $(FRAMEWORKS) -o $(BINARY) $^
	@# Copy Info.plist
	@cp Info.plist $(APP_CONTENTS)/Info.plist
	@# Copy resources
	@cp -f resources/ir_samples/*.wav $(APP_RESOURCES)/ir_samples/ 2>/dev/null || true
	@cp -f resources/gui/mockv30.jpeg $(APP_RESOURCES)/gui/ 2>/dev/null || true
	@cp -f resources/gui/logo_watermark.png $(APP_RESOURCES)/gui/ 2>/dev/null || true
	@cp -f resources/gui/AppIcon.icns $(APP_RESOURCES)/ 2>/dev/null || true
	@cp -f resources/gui/menubar_icon.png $(APP_RESOURCES)/gui/ 2>/dev/null || true
	@cp -f resources/gui/menubar_icon_1x.png $(APP_RESOURCES)/gui/ 2>/dev/null || true
	@# Ad-hoc sign so macOS allows mic access
	@codesign --force --deep --sign - $(APP_BUNDLE) 2>/dev/null || true
	@echo "Built: $(APP_BUNDLE)"

build:
	mkdir -p build

src/audio/%.o: src/audio/%.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

src/standalone/%.o: src/standalone/%.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

src/standalone/%.o: src/standalone/%.mm
	$(CXX) $(OBJCXXFLAGS) -c -o $@ $<

clean:
	rm -f $(AUDIO_OBJS) $(STANDALONE_OBJS) $(STANDALONE_MM_OBJS)
	rm -rf build/GoldStarEchoChamber build/GoldStarEchoChamber.app

run: $(APP_BUNDLE)
	open $(APP_BUNDLE)
