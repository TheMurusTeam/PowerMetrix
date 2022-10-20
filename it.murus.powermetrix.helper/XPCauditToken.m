#import "XPCauditToken.h"

@implementation XPCauditToken

+ (NSData *)auditTokenData:(NSXPCConnection *)xpcconnection {
    audit_token_t auditToken = xpcconnection.auditToken;
    return [NSData dataWithBytes:&auditToken length:sizeof(audit_token_t)];
}

@end
