#import "LHAlbum.h"

@implementation LHAlbum

+ (NSSet *)keyPathsForValuesAffectingImage
{
	return [NSSet setWithObject:@"imagePath"];
}

- (NSImage *)image
{
	return [[[NSImage alloc] initByReferencingURL:[NSURL URLWithString:self.imagePath]] autorelease];
}

@end
