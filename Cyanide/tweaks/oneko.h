//
//  oneko.h
//  RemoteCall-only Oneko implementation for Cyanide.
//

#ifndef oneko_h
#define oneko_h

#import <stdbool.h>

bool oneko_apply_in_session(void);
bool oneko_stop_in_session(void);
bool oneko_stop_in_session_fast(void);
void oneko_forget_remote_state(void);

#endif /* oneko_h */
