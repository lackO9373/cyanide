//
//  oneko.m
//  RemoteCall-only Oneko implementation for Cyanide.
//

#import "oneko.h"
#import "remote_objc.h"
#import "../TaskRop/RemoteCall.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <stdio.h>
#import <string.h>
#import <unistd.h>

static uint64_t gOnekoWindow = 0;
static uint64_t gOnekoCat = 0;
static uint64_t gOnekoTick = 0;
static double gOnekoX = 100.0;
static double gOnekoY = 100.0;
static double gOnekoTargetX = 200.0;
static double gOnekoTargetY = 200.0;

typedef struct {
    double x;
    double y;
    double width;
    double height;
} RCGRect64;

bool oneko_apply_in_session(void)
{
    gOnekoTick++;
    
    if (!r_is_objc_ptr(gOnekoWindow)) {
        printf("[ONEKO] Initializing Oneko remote session tick=%llu\n", (unsigned long long)gOnekoTick);
        
        uint64_t UIWindow = r_class("UIWindow");
        if (!r_is_objc_ptr(UIWindow)) return false;
        
        // Create window
        gOnekoWindow = r_msg_main(UIWindow, r_sel("alloc"), 0, 0, 0, 0);
        if (!r_is_objc_ptr(gOnekoWindow)) return false;
        
        RCGRect64 frame = {0, 0, 32, 32};
        r_msg_main_raw(gOnekoWindow, "initWithFrame:", &frame, sizeof(frame), 0, 0);
        
        // Set window level high
        double winLevel = 1000000.0;
        r_msg_main_raw(gOnekoWindow, "setWindowLevel:", &winLevel, sizeof(winLevel), 0, 0);
        
        // Make it visible
        r_msg2_main(gOnekoWindow, "setHidden:", 0, 0, 0, 0);
        r_msg2_main(gOnekoWindow, "setUserInteractionEnabled:", 0, 0, 0, 0);
        
        // Create cat view
        uint64_t UIImageView = r_class("UIImageView");
        gOnekoCat = r_msg_main(UIImageView, r_sel("alloc"), 0, 0, 0, 0);
        r_msg_main_raw(gOnekoCat, "initWithFrame:", &frame, sizeof(frame), 0, 0);
        
        // Set a color as a placeholder for the cat
        uint64_t UIColor = r_class("UIColor");
        uint64_t orange = r_msg2_main(UIColor, "orangeColor", 0, 0, 0, 0);
        r_msg2_main(gOnekoCat, "setBackgroundColor:", orange, 0, 0, 0);
        
        // Make it a circle to look more like a "creature"
        uint64_t layer = r_msg2_main(gOnekoCat, "layer", 0, 0, 0, 0);
        double cornerRadius = 16.0;
        r_msg_main_raw(layer, "setCornerRadius:", &cornerRadius, sizeof(cornerRadius), 0, 0);
        r_msg2_main(layer, "setMasksToBounds:", 1, 0, 0, 0);
        
        r_msg2_main(gOnekoWindow, "addSubview:", gOnekoCat, 0, 0, 0);
        
        // Store window in UIApplication to keep it alive
        uint64_t UIApplication = r_class("UIApplication");
        uint64_t app = r_msg2_main(UIApplication, "sharedApplication", 0, 0, 0, 0);
        if (r_is_objc_ptr(app)) {
            uint64_t assocKey = r_sel("darkswordOnekoWindow");
            r_dlsym_call(R_TIMEOUT, "objc_setAssociatedObject", app, assocKey, gOnekoWindow, 1, 0, 0, 0, 0);
        }
    }
    
    // Simple movement logic
    if (r_is_objc_ptr(gOnekoWindow)) {
        // Move towards target
        double dx = gOnekoTargetX - gOnekoX;
        double dy = gOnekoTargetY - gOnekoY;
        double dist = sqrt(dx*dx + dy*dy);
        
        if (dist < 5.0) {
            // Pick new random target
            gOnekoTargetX = (double)(rand() % 300 + 50);
            gOnekoTargetY = (double)(rand() % 500 + 100);
        } else {
            gOnekoX += dx / dist * 5.0;
            gOnekoY += dy / dist * 5.0;
        }
        
        RCGRect64 newFrame = {gOnekoX, gOnekoY, 32, 32};
        r_msg_main_raw(gOnekoWindow, "setFrame:", &newFrame, sizeof(newFrame), 0, 0);
    }

    return true;
}

bool oneko_stop_in_session(void)
{
    uint64_t UIApplication = r_class("UIApplication");
    if (r_is_objc_ptr(UIApplication)) {
        uint64_t app = r_msg2_main(UIApplication, "sharedApplication", 0, 0, 0, 0);
        if (r_is_objc_ptr(app)) {
            uint64_t assocKey = r_sel("darkswordOnekoWindow");
            uint64_t win = r_dlsym_call(R_TIMEOUT, "objc_getAssociatedObject", app, assocKey, 0, 0, 0, 0, 0, 0);
            if (r_is_objc_ptr(win)) {
                r_msg2_main(win, "setHidden:", 1, 0, 0, 0);
                r_dlsym_call(R_TIMEOUT, "objc_setAssociatedObject", app, assocKey, 0, 1, 0, 0, 0, 0);
            }
        }
    }
    gOnekoWindow = 0;
    gOnekoCat = 0;
    printf("[ONEKO] Stopped\n");
    return true;
}

bool oneko_stop_in_session_fast(void)
{
    oneko_forget_remote_state();
    printf("[ONEKO] Stopped (fast)\n");
    return true;
}

void oneko_forget_remote_state(void)
{
    gOnekoWindow = 0;
    gOnekoCat = 0;
    gOnekoTick = 0;
}
