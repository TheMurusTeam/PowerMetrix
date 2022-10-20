#import <Foundation/Foundation.h>

@interface NSXPCConnection(PrivateAuditToken)

@property (nonatomic, readonly) audit_token_t auditToken;

@end


@interface XPCauditToken : NSObject

+(NSData *)auditTokenData:(NSXPCConnection *)xpcconnection;

@end
