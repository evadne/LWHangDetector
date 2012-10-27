#import "LWHangDetector.h"

NSString * const LWMainThreadDeadLockException = @"LWMainThreadDeadLockException";

@interface LWHangDetector ()
@property (nonatomic, readwrite, assign) BOOL deadSignal;
@property (nonatomic, readwrite, strong) NSThread *deadThread;
- (void) deadThreadMain;
- (void) deadThreadTick;
@end

@implementation LWHangDetector
@synthesize queue = _queue;
@synthesize interval = _interval;
@synthesize deadSignal = _deadSignal;
@synthesize deadThread = _deadThread;

+ (instancetype) sharedHangDetector {

	static dispatch_once_t onceToken;
	static LWHangDetector *detector;
	dispatch_once(&onceToken, ^{
    detector = [self new];
	});
	
	return detector;

}

- (id) init {

	return [self initWithQueue:dispatch_get_main_queue() interval:10.0f];

}

- (id) initWithQueue:(dispatch_queue_t)queue interval:(NSTimeInterval)interval {

	self = [super init];
	if (!self)
		return nil;
	
	_queue = queue;
	_interval = interval;
	_deadSignal = 0;
	
	return self;

}

- (BOOL) isRunning {

	return !!_deadThread;

}

- (void) start {

	if (!_deadThread) {
	
		_deadThread = [[NSThread alloc] initWithTarget:self selector:@selector(deadThreadMain) object:nil];
		_deadThread.name = [self description];
		
	}
	
	[_deadThread start];

}

- (void) stop {

	if (_deadThread) {
	
		[_deadThread cancel];
		_deadThread = nil;
	
	}

}

- (void) deadThreadMain {
		
	@autoreleasepool {
		NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
		NSTimer *timer = [NSTimer timerWithTimeInterval:self.interval target:self selector:@selector(deadThreadTick) userInfo:nil repeats:YES];
		[runLoop addTimer:timer forMode:NSRunLoopCommonModes];
		[runLoop runUntilDate:[NSDate distantFuture]];
	}
		
}

- (void) deadThreadTick {
  
	@autoreleasepool {

		if (_deadSignal) {
			[NSException raise:LWMainThreadDeadLockException format:@"Main thread has not responded to our hails"];
		}
		
		self.deadSignal = YES;
		
		__weak typeof(self) wSelf = self;
		
		dispatch_async(self.queue, ^{
			wSelf.deadSignal = NO;
		});
	
	}
	
}

@end
