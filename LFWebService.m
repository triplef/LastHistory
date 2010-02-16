//
//  LFWebService.m
//  LastHistory
//
//  Created by Frederik Seiffert on 28.11.08.
//  Copyright 2008 Frederik Seiffert. All rights reserved.
//

#import "LFWebService.h"

#import "NSString+MD5.h"

#define LF_DEBUG 0

#define LF_ROOT_URL @"http://ws.audioscrobbler.com/2.0/"
#define LF_AUTHENTICATE_URL @"http://www.last.fm/api/auth/?api_key=%@&token=%@"

NSString *LFWebServiceErrorDomain = @"LFWebServiceErrorDomain";

// private read-write properties
@interface LFWebService ()
@property (readwrite, copy) NSString *apiKey;
@property (readwrite, copy) NSString *secret;
@property (readwrite, copy) NSString *userName;
@property (readwrite, copy) NSString *sessionKey;
@end

@interface LFWebService (LFPrivateAPI)
- (NSXMLDocument *)callMethod:(NSString *)methodName withParameters:(NSDictionary *)params authenticated:(BOOL)auth error:(NSError **)outError;
- (NSString *)apiSignatureForParameters:(NSDictionary *)params;
- (NSString *)stringFromParameters:(NSDictionary *)params;
- (NSString *)urlEncodeValue:(NSString *)value;
@end

@implementation LFWebService

@synthesize apiKey=_apiKey;
@synthesize secret=_secret;

@synthesize userName=_userName;
@synthesize sessionKey=_sessionKey;

- (id)initWithApiKey:(NSString *)apiKey secret:(NSString *)secret
{
	return [self initWithApiKey:apiKey secret:secret userName:nil sessionKey:nil];
}

- (id)initWithApiKey:(NSString *)apiKey
			  secret:(NSString *)secret
			userName:(NSString *)userName
		  sessionKey:(NSString *)sessionKey
{
	self = [super init];
	if (self != nil) {
		self.apiKey = apiKey;
		self.secret = secret;
		self.userName = userName;
		self.sessionKey = sessionKey;
	}
	return self;
}

- (void)dealloc
{
	[_apiKey release];
	[_secret release];
	[_userName release];
	[_sessionKey release];
	
	[_token release];
	
	[super dealloc];
}

- (BOOL)isAuthenticated
{
	return self.userName.length != 0 && self.sessionKey.length != 0;
}

- (NSString *)authenticateGetToken
{
	[_token release], _token = nil;
	
	NSXMLDocument *xml = [self callMethod:@"auth.getToken" withParameters:nil error:nil];
	if (!xml)
		return nil;
	
	NSXMLElement *token = [[[xml rootElement] elementsForName:@"token"] lastObject];
	if (!token) {
		NSLog(@"Error: unable to get token");
		return nil;
	}
	
	_token = [[token stringValue] copy];
	return _token;
}

- (NSURL *)authenticateGetAuthorizationURL
{
	NSString *token = [self authenticateGetToken];
	if (!token)
		return nil;
	
	NSString *urlStr = [NSString stringWithFormat:LF_AUTHENTICATE_URL, self.apiKey, token];
	return [NSURL URLWithString:urlStr];
}

- (BOOL)authenticateFinish
{
	// we need a token for auth.getSession
	if (!_token)
		return NO;
	
	self.userName = nil;
	self.sessionKey = nil;
	
	NSXMLDocument *xml = [self callMethod:@"auth.getSession"
						   withParameters:[NSDictionary dictionaryWithObject:_token forKey:@"token"]
									error:nil];
	if (!xml)
		return NO;
	
	NSXMLElement *session = [[[xml rootElement] elementsForName:@"session"] lastObject];
	if (!session) {
		NSLog(@"Error: unable to get session");
		return NO;
	}
	
	NSXMLElement *nameElement = [[session elementsForName:@"name"] lastObject];
	NSXMLElement *keyElement = [[session elementsForName:@"key"] lastObject];
	if (nameElement && keyElement) {
		self.userName = [nameElement stringValue];
		self.sessionKey = [keyElement stringValue];
		
		// no need for token any more
		[_token release], _token = nil;
		return YES;
	}
	
	return NO;
}

- (NSXMLDocument *)callMethod:(NSString *)methodName withParameters:(NSDictionary *)params error:(NSError **)outError
{
	return [self callMethod:methodName withParameters:params authenticated:NO error:outError];
}


- (NSXMLDocument *)callAuthenticatedMethod:(NSString *)methodName withParameters:(NSDictionary *)params error:(NSError **)outError
{
	return [self callMethod:methodName withParameters:params authenticated:YES error:outError];
}

@end


@implementation LFWebService (LFPrivateAPI)

- (NSXMLDocument *)callMethod:(NSString *)methodName withParameters:(NSDictionary *)params authenticated:(BOOL)auth error:(NSError **)outError
{
	if (auth && !self.sessionKey) {
		NSLog(@"Error: no session key for authenticated call");
		
		NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									   NSLocalizedString(@"No session key available for authenticated call", nil), NSLocalizedDescriptionKey,
									   NSLocalizedString(@"Please authenticate the application with Last.fm.", nil), NSLocalizedRecoverySuggestionErrorKey,
									   nil];
		NSError *error = [NSError errorWithDomain:LFWebServiceErrorDomain code:0 userInfo:errorUserInfo];
		if (outError)
			*outError = error;
		return nil;
	}
	
	NSMutableDictionary *paramsDict = params ?
	[NSMutableDictionary dictionaryWithDictionary:params] :
	[NSMutableDictionary dictionaryWithCapacity:3];
	
	if (auth || self.isAuthenticated)
		[paramsDict setValue:self.sessionKey forKey:@"sk"];
	[paramsDict setValue:self.apiKey forKey:@"api_key"];
	[paramsDict setValue:methodName forKey:@"method"];
	[paramsDict setValue:[self apiSignatureForParameters:paramsDict] forKey:@"api_sig"];
	
	NSString *paramsStr = [self stringFromParameters:paramsDict];
#if LF_DEBUG
	NSLog(@"params: %@", paramsStr);
#endif
	
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:LF_ROOT_URL]];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[paramsStr dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSHTTPURLResponse *response = nil;
	NSError *error = nil;
	NSData *responseData = [NSURLConnection sendSynchronousRequest:req
												 returningResponse:&response
															 error:&error];
	if (![responseData length] || error) {
		if (!error) {
			NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]], NSLocalizedDescriptionKey, nil];
			error = [NSError errorWithDomain:LFWebServiceErrorDomain code:[response statusCode] userInfo:errorUserInfo];
		}
		
		NSLog(@"Error retrieving data: %@ (%d)", [error localizedDescription], [error code]);
		if (outError)
			*outError = error;
		return nil;
	}
	
#if LF_DEBUG
//	NSLog(@"Response Code: %d", [response statusCode]);
//	NSLog(@"Content-Type: %@", [[response allHeaderFields] objectForKey:@"Content-Type"]);
#endif

	NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	
#if LF_DEBUG
	NSLog(@"Response: %@", responseStr);
#endif
	
	NSXMLDocument *result = [[[NSXMLDocument alloc] initWithXMLString:responseStr
															  options:0
																error:&error] autorelease];
	[responseStr release];
	if (!result) {
		NSLog(@"Error in XML: %@ (%d)", [error localizedDescription], [error code]);
		NSLog(@"Response:\n%@", responseStr);
		if (outError)
			*outError = error;
		return nil;
	}
	
	NSXMLElement *rootElement = [result rootElement];
	if ([[rootElement name] isEqualToString:@"lfm"])
	{
		if (![[[rootElement attributeForName:@"status"] stringValue] isEqualToString:@"ok"])
		{
			NSXMLElement *errorElement = [[rootElement elementsForName:@"error"] lastObject];
			NSInteger errorCode = [[[errorElement attributeForName:@"code"] stringValue] integerValue];
			NSString *errorDesc = [errorElement stringValue];
			NSLog(@"Error from Last.fm: %@ (%d)", errorDesc, errorCode);
			
			NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:errorDesc, NSLocalizedDescriptionKey, nil];
			NSError *error = [NSError errorWithDomain:LFWebServiceErrorDomain code:errorCode userInfo:errorUserInfo];
			if (outError)
				*outError = error;
			return nil;
		}
	}
	else
	{
		NSLog(@"Error: invalid response (%@)", responseStr);
		
		NSDictionary *errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Invalid response from Last.fm", nil), NSLocalizedDescriptionKey, nil];
		NSError *error = [NSError errorWithDomain:LFWebServiceErrorDomain code:0 userInfo:errorUserInfo];
		if (outError)
			*outError = error;
		return nil;
	}
	
	return result;
}

- (NSString *)apiSignatureForParameters:(NSDictionary *)params
{
	NSMutableString *signatureStr = [NSMutableString string];
	for (NSString *key in [[params allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
		NSString *value = [params valueForKey:key];
		[signatureStr appendString:key];
		[signatureStr appendString:value];
	}
	
	[signatureStr appendString:self.secret];
	return [signatureStr md5];
}

- (NSString *)stringFromParameters:(NSDictionary *)params
{
	NSMutableString *paramsStr = [NSMutableString string];
	for (NSString *key in [params allKeys]) {
		NSString *value = [params valueForKey:key];
		
		if ([paramsStr length] > 0)
			[paramsStr appendString:@"&"];
		[paramsStr appendFormat:@"%@=%@", key, [self urlEncodeValue:value]];
	}
	
	return paramsStr;
}

- (NSString *)urlEncodeValue:(NSString *)value
{
	CFStringRef result = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																 (CFStringRef)value,
																 NULL,
																 CFSTR("?=&+"),
																 kCFStringEncodingUTF8);
	if (result)
		CFMakeCollectable(result);
	return [(NSString *)result autorelease];
}

@end
