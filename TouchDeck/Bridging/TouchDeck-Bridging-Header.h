//
//  TouchDeck-Bridging-Header.h
//
//  Type declarations for Apple's private MultitouchSupport.framework.
//  Only types live here — the functions are resolved at runtime with
//  dlopen/dlsym (see MultitouchManager.swift), so nothing links against
//  the private framework at build time.
//
//  Layout matches the well-known reverse-engineered struct used by
//  BetterTouchTool-style tools (sizeof(MTTouch) == 96).
//

#ifndef TouchDeck_Bridging_Header_h
#define TouchDeck_Bridging_Header_h

#include <CoreFoundation/CoreFoundation.h>

typedef struct {
    float x;
    float y;
} MTPoint;

typedef struct {
    MTPoint position;
    MTPoint velocity;
} MTVector;

/// Touch lifecycle as reported by the trackpad firmware.
typedef enum {
    MTTouchStateNotTracking   = 0,
    MTTouchStateStartInRange  = 1,
    MTTouchStateHoverInRange  = 2,
    MTTouchStateMakeTouch     = 3,
    MTTouchStateTouching      = 4,
    MTTouchStateBreakTouch    = 5,
    MTTouchStateLingerInRange = 6,
    MTTouchStateOutOfRange    = 7
} MTTouchState;

typedef struct {
    int frame;
    double timestamp;
    int pathIndex;              // stable per-finger id while the finger is down
    int stage;                  // MTTouchState
    int fingerID;
    int handID;
    MTVector normalizedVector;  // position 0..1, origin bottom-left
    float zTotal;               // contact "quality" / pressure-ish
    int field9;
    float angle;
    float majorAxis;
    float minorAxis;
    MTVector absoluteVector;    // millimetres
    int field14;
    int field15;
    float zDensity;
} MTTouch;

typedef void *MTDeviceRef;

typedef void (*MTFrameCallbackFunction)(MTDeviceRef device,
                                        MTTouch *touches,
                                        int numTouches,
                                        double timestamp,
                                        int frame);

#endif /* TouchDeck_Bridging_Header_h */
