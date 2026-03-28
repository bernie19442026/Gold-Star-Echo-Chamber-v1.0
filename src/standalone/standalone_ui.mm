#import "standalone_ui.h"
#import <Cocoa/Cocoa.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <AVFoundation/AVFoundation.h>
#include "../audio/parameters.h"
#include <string>
#include <cmath>
#include <mach-o/dyld.h>

// Forward declare
@interface GoldStarAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@property (nonatomic) StandaloneApp* app;
@property (nonatomic, strong) NSWindow* window;
@property (nonatomic, strong) NSStatusItem* statusItem;
@end

// GUI image dimensions
static const CGFloat kImageW = 1376.0;
static const CGFloat kImageH = 768.0;

// ============================================================================
// RotaryKnobOverlay — transparent draggable knob over the GUI image
// Draws only the indicator line; the knob body is in the background image.
// ============================================================================
@interface RotaryKnobOverlay : NSView
@property (nonatomic) double minValue, maxValue, value;
@property (nonatomic, copy) void (^onChange)(double value);
@property (nonatomic, copy) NSString* label;
@end

@implementation RotaryKnobOverlay {
    NSPoint _dragStart;
    double _dragStartValue;
    BOOL _isDragging;
}

- (instancetype)initWithFrame:(NSRect)frame
                          min:(double)minVal max:(double)maxVal value:(double)val
                        label:(NSString*)lbl {
    self = [super initWithFrame:frame];
    if (self) {
        _minValue = minVal; _maxValue = maxVal; _value = val;
        _label = lbl; _isDragging = NO;
    }
    return self;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
- (BOOL)isOpaque { return NO; }

- (void)drawRect:(NSRect)dirtyRect {
    // Transparent background — image shows through
    NSRect bounds = self.bounds;
    CGFloat cx = NSMidX(bounds);
    CGFloat cy = NSMidY(bounds);
    CGFloat radius = MIN(bounds.size.width, bounds.size.height) * 0.42;

    double normalized = (_value - _minValue) / (_maxValue - _minValue);
    double angleDeg = -135.0 + normalized * 270.0;
    double angleRad = (angleDeg - 90.0) * M_PI / 180.0;

    CGFloat innerR = radius * 0.15;
    CGFloat outerR = radius * 0.92;
    NSPoint inner = NSMakePoint(cx + innerR * cos(angleRad), cy - innerR * sin(angleRad));
    NSPoint outer = NSMakePoint(cx + outerR * cos(angleRad), cy - outerR * sin(angleRad));

    NSBezierPath* line = [NSBezierPath bezierPath];
    [line moveToPoint:inner];
    [line lineToPoint:outer];
    [line setLineWidth:_isDragging ? 3.0 : 2.5];

    NSColor* lineColor = _isDragging ?
        [NSColor colorWithRed:1.0 green:0.9 blue:0.5 alpha:0.95] :
        [NSColor colorWithRed:0.914 green:0.757 blue:0.463 alpha:0.85];
    [lineColor setStroke];
    [line stroke];

    // Glow ring when dragging
    if (_isDragging) {
        NSBezierPath* ring = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(bounds, 4, 4)];
        [[NSColor colorWithRed:1.0 green:0.9 blue:0.5 alpha:0.15] setStroke];
        [ring setLineWidth:2.0];
        [ring stroke];
    }
}

- (void)mouseDown:(NSEvent *)event {
    _isDragging = YES;
    _dragStart = [NSEvent mouseLocation];
    _dragStartValue = _value;
    [self setNeedsDisplay:YES];

    while (YES) {
        NSEvent* nextEvent = [self.window nextEventMatchingMask:
            NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp];
        if (nextEvent.type == NSEventTypeLeftMouseUp) {
            _isDragging = NO;
            [self setNeedsDisplay:YES];
            break;
        }
        NSPoint current = [NSEvent mouseLocation];
        double deltaY = current.y - _dragStart.y;
        double sensitivity = (_maxValue - _minValue) / 250.0;
        double newValue = _dragStartValue + deltaY * sensitivity;
        _value = fmax(_minValue, fmin(_maxValue, newValue));
        if (_onChange) _onChange(_value);
        [self setNeedsDisplay:YES];
    }
}

@end

// ============================================================================
// FaderOverlay — transparent draggable fader over the GUI image
// Draws only the handle position marker.
// ============================================================================
@interface FaderOverlay : NSView
@property (nonatomic) double minValue, maxValue, value;
@property (nonatomic, copy) void (^onChange)(double value);
@property (nonatomic) BOOL isRedHandle;
@end

@implementation FaderOverlay {
    BOOL _isDragging;
    NSPoint _dragStart;
    double _dragStartValue;
}

- (instancetype)initWithFrame:(NSRect)frame
                          min:(double)minVal max:(double)maxVal value:(double)val
                    redHandle:(BOOL)red {
    self = [super initWithFrame:frame];
    if (self) {
        _minValue = minVal; _maxValue = maxVal; _value = val;
        _isRedHandle = red; _isDragging = NO;
    }
    return self;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
- (BOOL)isOpaque { return NO; }

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = self.bounds;
    CGFloat margin = 8.0;
    CGFloat trackH = bounds.size.height - margin * 2;

    double normalized = (_value - _minValue) / (_maxValue - _minValue);
    CGFloat handleY = margin + normalized * trackH;
    CGFloat handleW = bounds.size.width - 4;
    CGFloat handleH = 12.0;
    NSRect handleRect = NSMakeRect(2, handleY - handleH/2, handleW, handleH);

    // Semi-transparent handle overlay (the image shows the real track)
    NSColor* handleColor = _isRedHandle ?
        [NSColor colorWithRed:0.8 green:0.1 blue:0.1 alpha:0.7] :
        [NSColor colorWithRed:0.85 green:0.80 blue:0.73 alpha:0.6];

    if (_isDragging) {
        handleColor = _isRedHandle ?
            [NSColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.9] :
            [NSColor colorWithRed:1.0 green:0.95 blue:0.85 alpha:0.8];
    }

    [handleColor setFill];
    NSBezierPath* handle = [NSBezierPath bezierPathWithRoundedRect:handleRect xRadius:2 yRadius:2];
    [handle fill];

    // Thin bright line on handle center
    NSBezierPath* centerLine = [NSBezierPath bezierPath];
    [centerLine moveToPoint:NSMakePoint(4, handleY)];
    [centerLine lineToPoint:NSMakePoint(handleW, handleY)];
    [centerLine setLineWidth:1.0];
    [[NSColor colorWithWhite:1.0 alpha:0.4] setStroke];
    [centerLine stroke];
}

- (void)mouseDown:(NSEvent *)event {
    _isDragging = YES;
    _dragStart = [NSEvent mouseLocation];
    _dragStartValue = _value;
    [self setNeedsDisplay:YES];

    while (YES) {
        NSEvent* nextEvent = [self.window nextEventMatchingMask:
            NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp];
        if (nextEvent.type == NSEventTypeLeftMouseUp) {
            _isDragging = NO;
            [self setNeedsDisplay:YES];
            break;
        }
        NSPoint current = [NSEvent mouseLocation];
        double deltaY = current.y - _dragStart.y;
        double sensitivity = (_maxValue - _minValue) / 180.0;
        double newValue = _dragStartValue + deltaY * sensitivity;
        _value = fmax(_minValue, fmin(_maxValue, newValue));
        if (_onChange) _onChange(_value);
        [self setNeedsDisplay:YES];
    }
}

@end

// ============================================================================
// VUMeterOverlay — draws a complete, realistic analog VU meter face + needle
// ============================================================================
@interface VUMeterOverlay : NSView
@property (nonatomic) float level;
@property (nonatomic) float smoothedLevel;
@end

@implementation VUMeterOverlay

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _level = 0;
        _smoothedLevel = 0;
        self.wantsLayer = YES;
        self.layer.cornerRadius = 4.0;
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (BOOL)isOpaque { return YES; }

- (void)drawRect:(NSRect)dirtyRect {
    NSRect b = self.bounds;
    CGFloat w = b.size.width;
    CGFloat h = b.size.height;

    // === GAUGE FACE BACKGROUND ===
    // Warm cream gradient matching vintage VU meters
    NSGradient* faceGrad = [[NSGradient alloc] initWithStartingColor:
        [NSColor colorWithRed:0.96 green:0.93 blue:0.85 alpha:1.0]
        endingColor:
        [NSColor colorWithRed:0.91 green:0.86 blue:0.75 alpha:1.0]];
    [faceGrad drawInRect:b angle:270];

    // === PATINA / AGING ===
    // Warm brownish vignette around edges (aged darkening)
    {
        CGFloat inset = 6.0;
        NSRect inner = NSInsetRect(b, inset, inset);
        CGFloat locs[] = {0.0, 0.35, 1.0};
        NSGradient* vignetteGrad = [[NSGradient alloc] initWithColors:@[
            [NSColor colorWithRed:0.55 green:0.42 blue:0.28 alpha:0.18],
            [NSColor colorWithRed:0.70 green:0.58 blue:0.40 alpha:0.06],
            [NSColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]
        ] atLocations:locs colorSpace:[NSColorSpace sRGBColorSpace]];
        // Draw vignette from each edge
        // Top
        [vignetteGrad drawInRect:NSMakeRect(b.origin.x, inner.origin.y + inner.size.height,
                                             w, b.size.height - inner.size.height - inset) angle:270];
        // Bottom
        [vignetteGrad drawInRect:NSMakeRect(b.origin.x, b.origin.y, w, inset) angle:90];
        // Left
        [vignetteGrad drawInRect:NSMakeRect(b.origin.x, b.origin.y, inset, h) angle:0];
        // Right
        [vignetteGrad drawInRect:NSMakeRect(b.origin.x + w - inset, b.origin.y, inset, h) angle:180];
    }

    // Scattered subtle stain spots (deterministic per-meter based on frame position)
    {
        srand48((long)(self.frame.origin.x * 31 + self.frame.origin.y * 17));
        for (int i = 0; i < 12; i++) {
            CGFloat sx = drand48() * w;
            CGFloat sy = drand48() * h;
            CGFloat sr = 3.0 + drand48() * 8.0;
            CGFloat alpha = 0.02 + drand48() * 0.04;
            NSColor* stain = [NSColor colorWithRed:0.50 + drand48() * 0.15
                                             green:0.38 + drand48() * 0.10
                                              blue:0.20 + drand48() * 0.10
                                             alpha:alpha];
            [stain setFill];
            [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(sx - sr, sy - sr, sr * 2, sr * 2)] fill];
        }
    }

    // Very faint yellowish tint overlay (aged paper look)
    [[NSColor colorWithRed:0.82 green:0.72 blue:0.48 alpha:0.06] setFill];
    NSRectFillUsingOperation(b, NSCompositingOperationSourceOver);

    // Subtle inner shadow at edges
    NSBezierPath* borderPath = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(b, 0.5, 0.5)
                                                               xRadius:3 yRadius:3];
    [[NSColor colorWithRed:0.55 green:0.42 blue:0.28 alpha:0.45] setStroke];
    [borderPath setLineWidth:1.0];
    [borderPath stroke];

    // === PIVOT POINT (bottom center) ===
    CGFloat cx = w * 0.5;
    CGFloat cy = h * 0.10;

    // === SCALE ARC ===
    // The arc sweeps from -50° to +50° from vertical
    CGFloat arcRadius = h * 0.72;
    CGFloat startAngle = -50.0;
    CGFloat endAngle = 50.0;

    // --- Red zone (right ~20% of arc: roughly +20 to +50 degrees) ---
    {
        NSBezierPath* redZone = [NSBezierPath bezierPath];
        CGFloat redStart = 20.0;
        CGFloat innerR = arcRadius - 8.0;
        CGFloat outerR = arcRadius + 1.0;
        // Outer arc
        for (float deg = redStart; deg <= endAngle; deg += 1.0f) {
            float rad = deg * M_PI / 180.0f;
            NSPoint p = NSMakePoint(cx + outerR * sinf(rad), cy + outerR * cosf(rad));
            if (deg == redStart) [redZone moveToPoint:p];
            else [redZone lineToPoint:p];
        }
        // Inner arc (reverse)
        for (float deg = endAngle; deg >= redStart; deg -= 1.0f) {
            float rad = deg * M_PI / 180.0f;
            [redZone lineToPoint:NSMakePoint(cx + innerR * sinf(rad), cy + innerR * cosf(rad))];
        }
        [redZone closePath];
        [[NSColor colorWithRed:0.85 green:0.15 blue:0.10 alpha:0.30] setFill];
        [redZone fill];
    }

    // --- Scale arc line ---
    {
        NSBezierPath* arcLine = [NSBezierPath bezierPath];
        for (float deg = startAngle; deg <= endAngle; deg += 0.5f) {
            float rad = deg * M_PI / 180.0f;
            NSPoint p = NSMakePoint(cx + arcRadius * sinf(rad), cy + arcRadius * cosf(rad));
            if (deg == startAngle) [arcLine moveToPoint:p];
            else [arcLine lineToPoint:p];
        }
        [[NSColor colorWithRed:0.15 green:0.12 blue:0.08 alpha:0.85] setStroke];
        [arcLine setLineWidth:0.8];
        [arcLine stroke];
    }

    // --- Tick marks and labels ---
    // VU scale: -20, -10, -7, -5, -3, -2, -1, 0, +1, +2, +3
    // Map these to degrees: -20dB = startAngle, 0dB ~= +20°, +3dB = endAngle
    typedef struct { float dB; const char* label; BOOL major; } VUTick;
    VUTick ticks[] = {
        {-20, "-20", YES}, {-10, "-10", YES}, {-7, "-7", YES},
        {-5, "-5", YES}, {-3, "-3", YES}, {-2, NULL, NO},
        {-1, "-1", YES}, {0, "0", YES}, {1, "+1", YES},
        {2, "+2", YES}, {3, "+3", YES}
    };
    int numTicks = 11;

    // Map dB to angle: -20dB → -50°, 0dB → +20°, +3dB → +50°
    // Linear from -20 to 0: spans -50° to +20° (70° range for 20dB)
    // Linear from 0 to +3: spans +20° to +50° (30° range for 3dB)
    auto dbToAngle = [](float dB) -> float {
        if (dB <= 0) {
            return -50.0f + (dB + 20.0f) / 20.0f * 70.0f;
        } else {
            return 20.0f + dB / 3.0f * 30.0f;
        }
    };

    NSDictionary* labelAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:7.0 weight:NSFontWeightMedium],
        NSForegroundColorAttributeName: [NSColor colorWithRed:0.2 green:0.15 blue:0.10 alpha:0.9]
    };
    NSDictionary* redLabelAttrs = @{
        NSFontAttributeName: [NSFont systemFontOfSize:7.0 weight:NSFontWeightBold],
        NSForegroundColorAttributeName: [NSColor colorWithRed:0.8 green:0.12 blue:0.08 alpha:0.9]
    };

    for (int i = 0; i < numTicks; i++) {
        float deg = dbToAngle(ticks[i].dB);
        float rad = deg * M_PI / 180.0f;

        CGFloat tickInner = ticks[i].major ? arcRadius - 5.0 : arcRadius - 3.0;
        CGFloat tickOuter = arcRadius + 2.0;

        NSPoint inner = NSMakePoint(cx + tickInner * sinf(rad), cy + tickInner * cosf(rad));
        NSPoint outer = NSMakePoint(cx + tickOuter * sinf(rad), cy + tickOuter * cosf(rad));

        NSBezierPath* tick = [NSBezierPath bezierPath];
        [tick moveToPoint:inner];
        [tick lineToPoint:outer];

        BOOL isRed = ticks[i].dB > 0;
        if (isRed) {
            [[NSColor colorWithRed:0.8 green:0.12 blue:0.08 alpha:0.85] setStroke];
        } else {
            [[NSColor colorWithRed:0.15 green:0.12 blue:0.08 alpha:0.85] setStroke];
        }
        [tick setLineWidth:ticks[i].major ? 1.0 : 0.6];
        [tick stroke];

        // Labels
        if (ticks[i].label && ticks[i].major) {
            NSString* str = [NSString stringWithUTF8String:ticks[i].label];
            NSSize sz = [str sizeWithAttributes:labelAttrs];
            CGFloat labelR = arcRadius + 9.0;
            NSPoint labelPt = NSMakePoint(cx + labelR * sinf(rad) - sz.width * 0.5,
                                           cy + labelR * cosf(rad) - sz.height * 0.5);
            [str drawAtPoint:labelPt withAttributes:isRed ? redLabelAttrs : labelAttrs];
        }
    }

    // --- "VU" label ---
    {
        NSDictionary* vuAttrs = @{
            NSFontAttributeName: [NSFont systemFontOfSize:9.0 weight:NSFontWeightBold],
            NSForegroundColorAttributeName: [NSColor colorWithRed:0.2 green:0.15 blue:0.10 alpha:0.8]
        };
        NSString* vuStr = @"VU";
        NSSize sz = [vuStr sizeWithAttributes:vuAttrs];
        [vuStr drawAtPoint:NSMakePoint(cx - sz.width * 0.5, cy + h * 0.28) withAttributes:vuAttrs];
    }

    // === ANIMATED NEEDLE ===
    _smoothedLevel += 0.15f * (_level - _smoothedLevel);
    float normalizedLevel = fmin(1.0f, fmax(0.0f, _smoothedLevel));

    // Map 0.0-1.0 signal level to dB-like VU response
    // 0.0 → -20dB (far left), ~0.7 → 0dB, 1.0 → +3dB (far right)
    float vuDB;
    if (normalizedLevel < 0.001f) {
        vuDB = -20.0f;
    } else {
        vuDB = 20.0f * log10f(normalizedLevel);
        vuDB = fmax(-20.0f, fmin(3.0f, vuDB));
    }
    float needleAngleDeg = dbToAngle(vuDB);
    float needleAngleRad = needleAngleDeg * M_PI / 180.0f;

    CGFloat needleLen = arcRadius - 10.0;

    // Needle shadow
    {
        NSPoint shadowTip = NSMakePoint(cx + needleLen * sinf(needleAngleRad) + 0.5,
                                         cy + needleLen * cosf(needleAngleRad) - 0.5);
        NSBezierPath* shadow = [NSBezierPath bezierPath];
        [shadow moveToPoint:NSMakePoint(cx + 0.5, cy - 0.5)];
        [shadow lineToPoint:shadowTip];
        [shadow setLineWidth:1.8];
        [[NSColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.12] setStroke];
        [shadow stroke];
    }

    // Needle
    {
        NSPoint tip = NSMakePoint(cx + needleLen * sinf(needleAngleRad),
                                   cy + needleLen * cosf(needleAngleRad));
        NSBezierPath* needle = [NSBezierPath bezierPath];
        [needle moveToPoint:NSMakePoint(cx, cy)];
        [needle lineToPoint:tip];
        [needle setLineWidth:1.2];
        [[NSColor colorWithRed:0.08 green:0.02 blue:0.0 alpha:0.95] setStroke];
        [needle stroke];
    }

    // Pivot cap
    {
        CGFloat capR = 3.5;
        NSRect capRect = NSMakeRect(cx - capR, cy - capR, capR * 2, capR * 2);
        NSGradient* capGrad = [[NSGradient alloc] initWithStartingColor:
            [NSColor colorWithRed:0.25 green:0.20 blue:0.15 alpha:1.0]
            endingColor:
            [NSColor colorWithRed:0.10 green:0.06 blue:0.02 alpha:1.0]];
        NSBezierPath* cap = [NSBezierPath bezierPathWithOvalInRect:capRect];
        [capGrad drawInBezierPath:cap angle:270];
    }
}

@end

// ============================================================================
// IRButtonOverlay — transparent clickable overlay for IR selector buttons
// ============================================================================
@interface IRButtonOverlay : NSView
@property (nonatomic) BOOL isSelected;
@property (nonatomic, copy) void (^onSelect)(void);
@end

@implementation IRButtonOverlay

- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
- (BOOL)isOpaque { return NO; }

- (void)drawRect:(NSRect)dirtyRect {
    if (_isSelected) {
        // Highlight ring around selected button
        NSRect bounds = NSInsetRect(self.bounds, 2, 2);
        NSBezierPath* ring = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:4 yRadius:4];
        [[NSColor colorWithRed:0.914 green:0.757 blue:0.463 alpha:0.5] setStroke];
        [ring setLineWidth:2.5];
        [ring stroke];
    }
}

- (void)mouseDown:(NSEvent *)event {
    if (_onSelect) _onSelect();
}

@end

// ============================================================================
// ToggleOverlay — transparent toggle switch overlay
// ============================================================================
@interface ToggleOverlay : NSView
@property (nonatomic) BOOL isOn;
@property (nonatomic, copy) void (^onChange)(BOOL isOn);
@end

@implementation ToggleOverlay

- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
- (BOOL)isOpaque { return NO; }

- (void)drawRect:(NSRect)dirtyRect {
    if (_isOn) {
        // Green glow when ON
        NSRect bounds = NSInsetRect(self.bounds, 1, 1);
        NSBezierPath* glow = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:4 yRadius:4];
        [[NSColor colorWithRed:0.2 green:0.8 blue:0.3 alpha:0.3] setFill];
        [glow fill];
    }
}

- (void)mouseDown:(NSEvent *)event {
    _isOn = !_isOn;
    if (_onChange) _onChange(_isOn);
    [self setNeedsDisplay:YES];
}

@end

// ============================================================================
// TransportButtonOverlay — transparent clickable transport button
// ============================================================================
@interface TransportButtonOverlay : NSView
@property (nonatomic, copy) void (^onPress)(void);
@property (nonatomic) BOOL lit;          // Whether the button is currently lit
@property (nonatomic) BOOL isPlayButton; // YES = green play, NO = red stop
@end

@implementation TransportButtonOverlay

- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
- (BOOL)isOpaque { return NO; }

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bounds = self.bounds;
    CGFloat inset = 1.0;
    NSRect btnRect = NSInsetRect(bounds, inset, inset);
    CGFloat cr = 3.0;

    // Draw bypass-style raised button
    // Shadow underneath (3D depth)
    NSRect shadowRect = NSOffsetRect(btnRect, 1.0, -1.5);
    NSBezierPath* shadow = [NSBezierPath bezierPathWithRoundedRect:shadowRect xRadius:cr yRadius:cr];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.4] setFill];
    [shadow fill];

    // Main button face — beige/cream like the bypass button
    NSBezierPath* btn = [NSBezierPath bezierPathWithRoundedRect:btnRect xRadius:cr yRadius:cr];

    if (_lit) {
        if (_isPlayButton) {
            // Lit green
            [[NSColor colorWithCalibratedRed:0.25 green:0.6 blue:0.2 alpha:1.0] setFill];
        } else {
            // Lit red
            [[NSColor colorWithCalibratedRed:0.7 green:0.15 blue:0.12 alpha:1.0] setFill];
        }
    } else {
        // Off — same cream/beige as bypass button
        [[NSColor colorWithCalibratedRed:0.72 green:0.67 blue:0.60 alpha:1.0] setFill];
    }
    [btn fill];

    // Top bevel highlight
    NSRect topBevel = NSMakeRect(btnRect.origin.x + 2, btnRect.origin.y + btnRect.size.height * 0.55,
                                  btnRect.size.width - 4, btnRect.size.height * 0.4);
    NSBezierPath* bevel = [NSBezierPath bezierPathWithRoundedRect:topBevel xRadius:2 yRadius:2];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:(_lit ? 0.25 : 0.15)] setFill];
    [bevel fill];

    // Bottom edge darkening
    NSRect botBevel = NSMakeRect(btnRect.origin.x + 2, btnRect.origin.y + 1,
                                  btnRect.size.width - 4, btnRect.size.height * 0.2);
    NSBezierPath* botPath = [NSBezierPath bezierPathWithRoundedRect:botBevel xRadius:2 yRadius:2];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.08] setFill];
    [botPath fill];

    // Border
    [[NSColor colorWithCalibratedWhite:0.35 alpha:0.7] setStroke];
    btn.lineWidth = 0.8;
    [btn stroke];

    // Label text
    NSString* label = _isPlayButton ? @"PLAY" : @"STOP";
    NSColor* textColor = _lit ? [NSColor whiteColor]
                              : [NSColor colorWithCalibratedWhite:0.25 alpha:1.0];
    NSMutableParagraphStyle* pStyle = [[NSMutableParagraphStyle alloc] init];
    pStyle.alignment = NSTextAlignmentCenter;
    NSDictionary* attrs = @{
        NSFontAttributeName: [NSFont boldSystemFontOfSize:9.0],
        NSForegroundColorAttributeName: textColor,
        NSParagraphStyleAttributeName: pStyle
    };
    NSSize textSize = [label sizeWithAttributes:attrs];
    NSRect textRect = NSMakeRect(btnRect.origin.x,
                                  btnRect.origin.y + (btnRect.size.height - textSize.height) / 2.0,
                                  btnRect.size.width, textSize.height);
    [label drawInRect:textRect withAttributes:attrs];
}

- (void)mouseDown:(NSEvent *)event {
    if (!_isPlayButton) {
        _lit = YES;
        [self setNeedsDisplay:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 200 * NSEC_PER_MSEC),
            dispatch_get_main_queue(), ^{
                self.lit = NO;
                [self setNeedsDisplay:YES];
            });
    }
    if (_onPress) _onPress();
}

@end

// ============================================================================
// SignalLightOverlay — LED that lights up when signal is present
// ============================================================================
@interface SignalLightOverlay : NSView
@property (nonatomic) float level;
@end

@implementation SignalLightOverlay

- (BOOL)isOpaque { return NO; }

- (void)drawRect:(NSRect)dirtyRect {
    // Cover the static green dot from the image with a brass-colored circle first
    NSRect dotRect = self.bounds;

    // Draw brass background to cover static dot
    NSBezierPath* cover = [NSBezierPath bezierPathWithOvalInRect:dotRect];
    [[NSColor colorWithRed:0.65 green:0.50 blue:0.30 alpha:1.0] setFill];
    [cover fill];

    // Now draw the LED based on signal level
    NSRect ledRect = NSInsetRect(dotRect, 2, 2);
    NSBezierPath* led = [NSBezierPath bezierPathWithOvalInRect:ledRect];

    if (_level > 0.001f) {
        // Green glow proportional to level
        float brightness = fmin(1.0f, _level * 3.0f);
        [[NSColor colorWithRed:0.1 * (1.0f - brightness) + 0.2 * brightness
                         green:0.3 * (1.0f - brightness) + 0.85 * brightness
                          blue:0.1 * (1.0f - brightness) + 0.2 * brightness
                         alpha:1.0] setFill];
        [led fill];

        // Bright center highlight
        NSRect highlightRect = NSInsetRect(ledRect, 3, 3);
        NSBezierPath* highlight = [NSBezierPath bezierPathWithOvalInRect:highlightRect];
        [[NSColor colorWithRed:0.4 green:1.0 blue:0.4 alpha:brightness * 0.6] setFill];
        [highlight fill];
    } else {
        // Off state — black/unlit LED
        [[NSColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:1.0] setFill];
        [led fill];
    }

    // Subtle ring
    [[NSColor colorWithRed:0.3 green:0.25 blue:0.15 alpha:0.5] setStroke];
    led.lineWidth = 0.5;
    [led stroke];
}

@end

// ============================================================================
// BypassButtonOverlay — toggle bypass button
// ============================================================================
@interface BypassButtonOverlay : NSView
@property (nonatomic) BOOL isOn;
@property (nonatomic, copy) void (^onChange)(BOOL isOn);
@end

@implementation BypassButtonOverlay

- (BOOL)acceptsFirstMouse:(NSEvent *)event { return YES; }
- (BOOL)isOpaque { return NO; }

- (void)drawRect:(NSRect)dirtyRect {
    if (_isOn) {
        // Red glow when bypassed
        NSRect bounds = NSInsetRect(self.bounds, 1, 1);
        NSBezierPath* bg = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:3 yRadius:3];
        [[NSColor colorWithRed:0.7 green:0.1 blue:0.1 alpha:0.5] setFill];
        [bg fill];

        // "BYPASSED" text overlay
        NSMutableParagraphStyle* style = [[NSMutableParagraphStyle alloc] init];
        style.alignment = NSTextAlignmentCenter;
        NSDictionary* attrs = @{
            NSFontAttributeName: [NSFont boldSystemFontOfSize:9.0],
            NSForegroundColorAttributeName: [NSColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:0.9],
            NSParagraphStyleAttributeName: style
        };
        [@"BYPASSED" drawInRect:NSMakeRect(0, (self.bounds.size.height - 12)/2,
            self.bounds.size.width, 14) withAttributes:attrs];
    }
}

- (void)mouseDown:(NSEvent *)event {
    _isOn = !_isOn;
    if (_onChange) _onChange(_isOn);
    [self setNeedsDisplay:YES];
}

@end

// ============================================================================
// Helper: Convert image coords (origin top-left) to NSView coords (origin bottom-left)
// ============================================================================
static NSRect imageRectToView(CGFloat imgX, CGFloat imgY, CGFloat w, CGFloat h) {
    // imgX, imgY = center in image coords (top-left origin)
    // Convert to bottom-left origin for NSView
    CGFloat viewX = imgX - w / 2.0;
    CGFloat viewY = kImageH - imgY - h / 2.0;
    return NSMakeRect(viewX, viewY, w, h);
}

// ============================================================================
// Main App Delegate
// ============================================================================
@implementation GoldStarAppDelegate {
    NSTimer* _meterTimer;
    VUMeterOverlay* _vuInput;
    VUMeterOverlay* _vuProcess;
    VUMeterOverlay* _vuOutput;
    NSMutableArray<IRButtonOverlay*>* _irButtons;
    ToggleOverlay* _pendingMicToggle;
    SignalLightOverlay* _signalLight;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Window sized to the GUI image
    _window = [[NSWindow alloc]
        initWithContentRect:NSMakeRect(50, 50, kImageW, kImageH)
                  styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
                    backing:NSBackingStoreBuffered defer:NO];
    [_window setTitle:@"Gold Star Echo Chamber"];
    [_window setDelegate:self];

    NSView* content = [_window contentView];
    content.wantsLayer = YES;

    // === Set Dock icon from bundle ===
    NSString* icnsPath = [[NSBundle mainBundle] pathForResource:@"AppIcon" ofType:@"icns"];
    if (icnsPath) {
        NSImage* appIcon = [[NSImage alloc] initWithContentsOfFile:icnsPath];
        if (appIcon) {
            [NSApp setApplicationIconImage:appIcon];
        }
    }

    // === Background image ===
    NSString* imgPath = [self findGUIImage];
    if (imgPath) {
        NSImage* bgImage = [[NSImage alloc] initWithContentsOfFile:imgPath];
        if (bgImage) {
            NSImageView* bgView = [[NSImageView alloc] initWithFrame:
                NSMakeRect(0, 0, kImageW, kImageH)];
            bgView.image = bgImage;
            bgView.imageScaling = NSImageScaleAxesIndependently;
            [content addSubview:bgView];
        }
    }

    // === LOGO WATERMARK (faint, behind all controls) ===
    {
        NSString* logoPath = [self findLogoImage];
        if (logoPath) {
            NSImage* logoImage = [[NSImage alloc] initWithContentsOfFile:logoPath];
            if (logoImage) {
                // Place the logo centered on the main faceplate area
                // The faceplate spans roughly x=100-1300, y=250-750 in image coords
                // We'll make it large and centered, very faint
                CGFloat logoW = 625.0;   // 25% larger than 500
                CGFloat logoH = 350.0;   // 25% larger than 280
                // Center on the main control area, shifted down 2 inches (~144px)
                CGFloat logoCX = kImageW * 0.5;  // 688
                CGFloat logoCY = kImageH * 0.62 + 72.0;  // ~548 in image coords
                NSRect logoRect = imageRectToView(logoCX, logoCY, logoW, logoH);

                NSImageView* logoView = [[NSImageView alloc] initWithFrame:logoRect];
                logoView.image = logoImage;
                logoView.imageScaling = NSImageScaleProportionallyUpOrDown;
                logoView.alphaValue = 0.04;  // 20% less than 0.05
                logoView.imageAlignment = NSImageAlignCenter;
                [content addSubview:logoView];  // Above background, below controls (added next)
            }
        }
    }

    // ================================================================
    // CONTROL OVERLAYS — mapped to exact pixel positions on the image
    // All coordinates are (centerX, centerY) in image space (top-left origin)
    // ================================================================

    // --- INPUT CONTROL: 3 knobs ---
    CGFloat smallKnob = 80.0;

    RotaryKnobOverlay* lpKnob = [[RotaryKnobOverlay alloc]
        initWithFrame:imageRectToView(170, 357, smallKnob, smallKnob)
                  min:200 max:20000 value:20000 label:@"LOW PASS"];
    lpKnob.onChange = ^(double v) { self.app->setParameter(ParameterID::LOW_PASS, (float)v); };
    [content addSubview:lpKnob];

    RotaryKnobOverlay* hpKnob = [[RotaryKnobOverlay alloc]
        initWithFrame:imageRectToView(279, 357, smallKnob, smallKnob)
                  min:20 max:8000 value:20 label:@"HIGH PASS"];
    hpKnob.onChange = ^(double v) { self.app->setParameter(ParameterID::HIGH_PASS, (float)v); };
    [content addSubview:hpKnob];

    RotaryKnobOverlay* gainKnob = [[RotaryKnobOverlay alloc]
        initWithFrame:imageRectToView(388, 353, smallKnob + 10, smallKnob + 10)
                  min:-80 max:12 value:0 label:@"GAIN"];
    gainKnob.onChange = ^(double v) { self.app->setParameter(ParameterID::INPUT_GAIN, (float)v); };
    [content addSubview:gainKnob];

    // --- FIVE-BAND INPUT EQ: 5 faders ---
    CGFloat eqFaderW = 30.0;
    CGFloat eqFaderH = 300.0;
    CGFloat eqFaderXs[] = {171, 224, 280, 334, 388};
    CGFloat eqFaderCenterY = 585.0;  // center of the fader track area (tracks y=509-660)
    ParameterID eqParams[] = {ParameterID::EQ_100, ParameterID::EQ_250,
                               ParameterID::EQ_1K, ParameterID::EQ_4K, ParameterID::EQ_10K};

    for (int i = 0; i < 5; i++) {
        FaderOverlay* fader = [[FaderOverlay alloc]
            initWithFrame:imageRectToView(eqFaderXs[i], eqFaderCenterY, eqFaderW, eqFaderH)
                      min:-12 max:12 value:0 redHandle:NO];
        ParameterID pid = eqParams[i];
        fader.onChange = ^(double v) { self.app->setParameter(pid, (float)v); };
        [content addSubview:fader];
    }

    // --- IR MODULES: 5 buttons (A-E) ---
    _irButtons = [NSMutableArray array];
    CGFloat irBtnXs[] = {508, 592, 680, 765, 851};
    CGFloat irBtnY = 299.0;
    CGFloat irBtnSize = 60.0;

    for (int i = 0; i < 5; i++) {
        IRButtonOverlay* btn = [[IRButtonOverlay alloc]
            initWithFrame:imageRectToView(irBtnXs[i], irBtnY, irBtnSize, irBtnSize)];
        btn.isSelected = (i == 0);
        int idx = i;
        btn.onSelect = ^{
            self.app->selectIR(idx);
            for (IRButtonOverlay* b in self->_irButtons) b.isSelected = NO;
            [self->_irButtons[idx] setIsSelected:YES];
            for (IRButtonOverlay* b in self->_irButtons) [b setNeedsDisplay:YES];
        };
        [content addSubview:btn];
        [_irButtons addObject:btn];
    }

    // --- REVERB CONTROL: 4 large knobs ---
    CGFloat bigKnob = 120.0;

    RotaryKnobOverlay* preDelayKnob = [[RotaryKnobOverlay alloc]
        initWithFrame:imageRectToView(576, 490, bigKnob, bigKnob)
                  min:0 max:500 value:0 label:@"PRE-DELAY"];
    preDelayKnob.onChange = ^(double v) { self.app->setParameter(ParameterID::PRE_DELAY, (float)v); };
    [content addSubview:preDelayKnob];

    RotaryKnobOverlay* timeKnob = [[RotaryKnobOverlay alloc]
        initWithFrame:imageRectToView(789, 490, bigKnob, bigKnob)
                  min:0.1 max:100 value:100 label:@"TIME"];
    timeKnob.onChange = ^(double v) { self.app->setParameter(ParameterID::REVERB_LENGTH, (float)v); };
    [content addSubview:timeKnob];

    RotaryKnobOverlay* sizeKnob = [[RotaryKnobOverlay alloc]
        initWithFrame:imageRectToView(576, 655, bigKnob, bigKnob)
                  min:0 max:1 value:0.5 label:@"SIZE"];
    sizeKnob.onChange = ^(double v) { self.app->setParameter(ParameterID::ROOM_SIZE, (float)v); };
    [content addSubview:sizeKnob];

    RotaryKnobOverlay* diffKnob = [[RotaryKnobOverlay alloc]
        initWithFrame:imageRectToView(788, 656, bigKnob, bigKnob)
                  min:0 max:1 value:0.5 label:@"DIFFUSION"];
    diffKnob.onChange = ^(double v) { self.app->setParameter(ParameterID::DIFFUSION, (float)v); };
    [content addSubview:diffKnob];

    // --- OUTPUT CONTROL: 3 faders ---
    CGFloat outFaderW = 36.0;
    CGFloat outFaderH = 320.0;
    CGFloat outFaderCenterY = 360.0;  // tracks span y=243-475, center=359

    FaderOverlay* dryFader = [[FaderOverlay alloc]
        initWithFrame:imageRectToView(981, outFaderCenterY, outFaderW, outFaderH)
                  min:-80 max:0 value:-6 redHandle:NO];
    dryFader.onChange = ^(double v) { self.app->setParameter(ParameterID::DRY_LEVEL, (float)v); };
    [content addSubview:dryFader];

    FaderOverlay* wetFader = [[FaderOverlay alloc]
        initWithFrame:imageRectToView(1095, outFaderCenterY, outFaderW, outFaderH)
                  min:-80 max:0 value:-6 redHandle:NO];
    wetFader.onChange = ^(double v) { self.app->setParameter(ParameterID::WET_LEVEL, (float)v); };
    [content addSubview:wetFader];

    FaderOverlay* outputFader = [[FaderOverlay alloc]
        initWithFrame:imageRectToView(1205, outFaderCenterY, outFaderW, outFaderH)
                  min:-80 max:6 value:0 redHandle:YES];
    outputFader.onChange = ^(double v) { self.app->setParameter(ParameterID::OUTPUT_LEVEL, (float)v); };
    [content addSubview:outputFader];

    // --- VU METERS ---
    // Three analog gauge panels at the top-center of the image
    // Frames detected at: left x=393-567, mid x=592-767, right x=792-967
    CGFloat vuW = 165.0, vuH = 100.0;

    _vuInput = [[VUMeterOverlay alloc] initWithFrame:
        imageRectToView(480, 125, vuW, vuH)];
    [content addSubview:_vuInput];

    _vuProcess = [[VUMeterOverlay alloc] initWithFrame:
        imageRectToView(680, 125, vuW, vuH)];
    [content addSubview:_vuProcess];

    _vuOutput = [[VUMeterOverlay alloc] initWithFrame:
        imageRectToView(880, 125, vuW, vuH)];
    [content addSubview:_vuOutput];

    // --- TOGGLES ---
    CGFloat toggleW = 50.0, toggleH = 40.0;

    ToggleOverlay* reverseToggle = [[ToggleOverlay alloc]
        initWithFrame:imageRectToView(971, 582, toggleW, toggleH)];
    reverseToggle.onChange = ^(BOOL on) {
        self.app->setParameter(ParameterID::REVERSE, on ? 1.0f : 0.0f);
    };
    reverseToggle.wantsLayer = YES;
    [content addSubview:reverseToggle];

    ToggleOverlay* micToggle = [[ToggleOverlay alloc]
        initWithFrame:imageRectToView(1088, 582, toggleW, toggleH)];
    micToggle.onChange = ^(BOOL on) {
        if (on) {
            self->_pendingMicToggle = micToggle;
            // Defer to next run loop iteration so mouseDown completes first
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMenu* deviceMenu = [[NSMenu alloc] initWithTitle:@"Select Input"];
                auto inputDevices = self.app->getAudioIO()->listInputDevices();
                if (inputDevices.empty()) {
                    NSMenuItem* noDevItem = [[NSMenuItem alloc] initWithTitle:@"No input devices found"
                        action:nil keyEquivalent:@""];
                    noDevItem.enabled = NO;
                    [deviceMenu addItem:noDevItem];
                } else {
                    for (size_t i = 0; i < inputDevices.size(); i++) {
                        NSString* name = [NSString stringWithUTF8String:inputDevices[i].name.c_str()];
                        NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:name
                            action:@selector(selectInputDevice:) keyEquivalent:@""];
                        item.tag = (NSInteger)inputDevices[i].deviceId;
                        item.target = self;
                        [deviceMenu addItem:item];
                    }
                }
                [deviceMenu addItem:[NSMenuItem separatorItem]];
                NSMenuItem* cancelItem = [[NSMenuItem alloc] initWithTitle:@"Cancel"
                    action:@selector(cancelMicSelect:) keyEquivalent:@""];
                cancelItem.target = self;
                [deviceMenu addItem:cancelItem];

                // Show the menu anchored to the mic toggle view
                NSPoint pt = NSMakePoint(0, micToggle.bounds.size.height);
                [deviceMenu popUpMenuPositioningItem:nil atLocation:pt inView:micToggle];
            });
        } else {
            self.app->enableMicInput(NO);
        }
    };
    micToggle.wantsLayer = YES;
    [content addSubview:micToggle];

    // --- TRANSPORT: Play, Stop (bypass-style square buttons) ---
    // Positioned where the old round buttons were, sized like smaller bypass switches
    CGFloat tBtnW = 50.0;
    CGFloat tBtnH = 36.0;

    TransportButtonOverlay* playBtn = [[TransportButtonOverlay alloc]
        initWithFrame:imageRectToView(960, 693, tBtnW, tBtnH)];
    playBtn.wantsLayer = YES;
    playBtn.isPlayButton = YES;
    playBtn.lit = NO;
    playBtn.onPress = ^{
        if (self.app->isFilePlaying()) {
            self.app->playFile();
            return;
        }
        // Defer to next run loop so mouseDown completes first
        dispatch_async(dispatch_get_main_queue(), ^{
            NSOpenPanel* panel = [NSOpenPanel openPanel];
            panel.title = @"Load Audio File";
            panel.message = @"Select an audio file to process through the Echo Chamber";
            panel.allowedContentTypes = @[
                [UTType typeWithFilenameExtension:@"wav"],
                [UTType typeWithFilenameExtension:@"mp3"],
                [UTType typeWithFilenameExtension:@"aiff"],
                [UTType typeWithFilenameExtension:@"aif"],
                [UTType typeWithFilenameExtension:@"m4a"],
                [UTType typeWithFilenameExtension:@"flac"]
            ];
            panel.allowsMultipleSelection = NO;
            panel.canChooseDirectories = NO;
            if ([panel runModal] == NSModalResponseOK) {
                NSString* path = panel.URL.path;
                self.app->loadAudioFile(path.UTF8String);
                self.app->playFile();
            }
        });
    };
    [content addSubview:playBtn];

    TransportButtonOverlay* stopBtn = [[TransportButtonOverlay alloc]
        initWithFrame:imageRectToView(1030, 693, tBtnW, tBtnH)];
    stopBtn.wantsLayer = YES;
    stopBtn.isPlayButton = NO;
    stopBtn.lit = NO;
    stopBtn.onPress = ^{ self.app->stopFile(); };
    [content addSubview:stopBtn];

    // Timer to update play button lit state
    [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer* t) {
        (void)t;
        BOOL playing = self.app->isFilePlaying();
        if (playBtn.lit != playing) {
            playBtn.lit = playing;
            [playBtn setNeedsDisplay:YES];
        }
    }];

    // Bypass toggle
    BypassButtonOverlay* bypassOverlay = [[BypassButtonOverlay alloc]
        initWithFrame:imageRectToView(1240, 665, 80, 70)];
    bypassOverlay.wantsLayer = YES;
    bypassOverlay.onChange = ^(BOOL on) {
        self.app->setBypass(on);
        self.app->setParameter(ParameterID::BYPASS, on ? 1.0f : 0.0f);
    };
    [content addSubview:bypassOverlay];

    // Signal light — covers the static green dot, lights up only with signal
    _signalLight = [[SignalLightOverlay alloc]
        initWithFrame:imageRectToView(1130, 688, 14, 14)];
    _signalLight.wantsLayer = YES;
    _signalLight.level = 0.0f;
    [content addSubview:_signalLight];

    // Gemini watermark star removed directly from image via inpainting

    // === Menu bar icon ===
    [self setupMenuBarIcon];

    // === Meter timer (30fps) ===
    _meterTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0
        target:self selector:@selector(updateMeters) userInfo:nil repeats:YES];

    [_window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (NSString*)findLogoImage {
    // Check multiple locations for the logo watermark image
    NSArray* paths = @[
        @"resources/gui/logo_watermark.png",
        [NSString stringWithFormat:@"%s/Desktop/Gold Star Echo Chamber v33/resources/gui/logo_watermark.png",
            getenv("HOME") ?: ""]
    ];

    // Also check inside .app bundle
    char exePath[4096];
    uint32_t exePathSize = sizeof(exePath);
    if (_NSGetExecutablePath(exePath, &exePathSize) == 0) {
        NSString* exe = [NSString stringWithUTF8String:exePath];
        NSString* bundlePath = [[exe stringByDeletingLastPathComponent]
            stringByAppendingPathComponent:@"../Resources/gui/logo_watermark.png"];
        paths = [paths arrayByAddingObject:bundlePath];
    }

    for (NSString* p in paths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:p]) {
            return p;
        }
    }
    NSLog(@"WARNING: Logo watermark image not found");
    return nil;
}

- (NSString*)findGUIImage {
    // Check multiple locations for the GUI image
    NSArray* paths = @[
        @"resources/gui/mockv30.jpeg",
        [NSString stringWithFormat:@"%s/Desktop/GoldStar Echo Chamber D31/resources/gui/mockv30.jpeg",
            getenv("HOME") ?: ""],
        @"/Users/bernie/Pictures/GOLD STAR/GUI EXAMPLES/3-26-26/mockv30.jpeg"
    ];

    // Also check inside .app bundle
    char exePath[4096];
    uint32_t exePathSize = sizeof(exePath);
    if (_NSGetExecutablePath(exePath, &exePathSize) == 0) {
        NSString* exe = [NSString stringWithUTF8String:exePath];
        NSString* bundlePath = [[exe stringByDeletingLastPathComponent]
            stringByAppendingPathComponent:@"../Resources/mockv30.jpeg"];
        paths = [paths arrayByAddingObject:bundlePath];
    }

    for (NSString* p in paths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:p]) {
            return p;
        }
    }
    NSLog(@"WARNING: GUI image not found");
    return nil;
}

- (void)setupMenuBarIcon {
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    // Load menu bar icon from bundle resources
    NSString* iconPath = [[NSBundle mainBundle] pathForResource:@"menubar_icon" ofType:@"png" inDirectory:@"gui"];
    if (iconPath) {
        NSImage* icon = [[NSImage alloc] initWithContentsOfFile:iconPath];
        [icon setSize:NSMakeSize(18, 18)];
        [icon setTemplate:YES];
        _statusItem.button.image = icon;
    } else {
        _statusItem.button.title = @"★ GS";
        _statusItem.button.font = [NSFont boldSystemFontOfSize:12.0];
    }

    NSMenu* menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:@"Show Window" action:@selector(showWindow:) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
    for (NSMenuItem* item in menu.itemArray) item.target = self;
    _statusItem.menu = menu;
}

- (void)showWindow:(id)sender {
    [_window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)updateMeters {
    if (!_app) return;
    _vuInput.level = _app->getInputLevel();
    _vuProcess.level = _app->getProcessLevel();
    _vuOutput.level = _app->getOutputLevel();
    [_vuInput setNeedsDisplay:YES];
    [_vuProcess setNeedsDisplay:YES];
    [_vuOutput setNeedsDisplay:YES];

    // Signal light — use max of input and output levels
    float sigLevel = fmax(_app->getInputLevel(), _app->getOutputLevel());
    _signalLight.level = sigLevel;
    [_signalLight setNeedsDisplay:YES];
}

- (void)selectInputDevice:(NSMenuItem*)sender {
    AudioDeviceID deviceId = (AudioDeviceID)sender.tag;
    NSLog(@"[Mic] Selecting input device: %@ (ID=%u)", sender.title, deviceId);

    // Stop, set device AND enable input, then restart — avoids double restart
    CoreAudioIO* io = _app->getAudioIO();
    io->setInputDevice(deviceId);     // This restarts without input
    _app->enableMicInput(YES);         // This restarts WITH input

    NSLog(@"[Mic] Input enabled, running=%d", io->isRunning());
}

- (void)cancelMicSelect:(NSMenuItem*)sender {
    // User cancelled — turn toggle back off
    if (_pendingMicToggle) {
        _pendingMicToggle.isOn = NO;
        [_pendingMicToggle setNeedsDisplay:YES];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return NO;
}

@end

// ============================================================================
// StandaloneUI implementation
// ============================================================================
StandaloneUI::StandaloneUI(StandaloneApp* app) : app_(app) {}
StandaloneUI::~StandaloneUI() {}

void StandaloneUI::runEventLoop() {
    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

        GoldStarAppDelegate* delegate = [[GoldStarAppDelegate alloc] init];
        delegate.app = app_;
        [NSApp setDelegate:delegate];

        [NSApp run];
    }
}
