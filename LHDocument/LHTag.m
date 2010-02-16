#import "LHTag.h"

@implementation LHTag

- (NSUInteger)countSum
{
	return [[self valueForKeyPath:@"trackTags.@sum.count"] unsignedIntValue];
}

@end
