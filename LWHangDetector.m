#import "LWHangDetector.h"

static volatile NSInteger DEAD_SIGNAL = 0;

@interface LWHangDetector ()

+ (void)_deadThreadTick;
+ (void)_deadThreadMain;

@end

@implementation LWHangDetector

+ (void)startHangDetector {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSThread *heartBeatThread = [[NSThread alloc] initWithTarget:self selector:@selector(_deadThreadMain) object:nil];
        [heartBeatThread start];
        [heartBeatThread release];
    });
}

#pragma mark - Private

+ (void)_deadThreadTick {
    if (DEAD_SIGNAL == 1) {
        [NSException raise:@"LWDeadLockException" format:@"Main thread has not responded to our hails"];
    }
    
    DEAD_SIGNAL = 1;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        DEAD_SIGNAL = 0;
    });
}

+ (void)_deadThreadMain {
    [NSThread currentThread].name = @"HangDetection";
    @autoreleasepool {
        [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(deadThreadTick) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate distantFuture]];
    }
}

@end
