
/* Exchange the values by pointers. */
static inline void swap(void **i, void **j)
{
	void *temp;
	
	temp = *i;
	*i = *j;
	*j = temp;
}


#ifdef DEBUG_BUILD
	/* For a debug build, declare the LHLog() function */
	void LHLog(NSString *format, ...);

	#define DJ_START_TIMING		NSDate *__startDate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];

	#define DJ_END_TIMING(desc)	NSDate *__endDate = [[NSDate alloc] initWithTimeIntervalSinceNow:0]; \
		NSTimeInterval interval = [__endDate timeIntervalSinceDate:__startDate]; \
		NSLog(@"*** %@ *** took %f seconds", desc, interval); \
		[__startDate release]; \
		[__endDate release];
#else
	/* For a non-debug build, define it to be a comment so there is no overhead in using it liberally */
	#define LHLog(fmt, ...) /**/

	#define DJ_START_TIMING() /**/
	#define DJ_END_TIMING(desc) /**/
#endif
