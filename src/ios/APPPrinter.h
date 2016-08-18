#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import <BRPtouchPrinterKit/BRPtouchNetwork.h>
#import <BRPtouchPrinterKit/BRPtouchPrinter.h>

@interface APPPrinter : CDVPlugin <BRPtouchNetworkDelegate>
{
    BRPtouchNetwork* ptn;
    BRPtouchPrinter* ptp;
    CDVInvokedUrlCommand* actCommand;
}

// Prints the content
- (BOOL) print:(CDVInvokedUrlCommand*)command;
// Find out whether printing is supported on this platform
- (void) isAvailable:(CDVInvokedUrlCommand*)command;
- (void) getPrinterList:(CDVInvokedUrlCommand*)command;
- (void) setPrinter:(CDVInvokedUrlCommand*) invokedCommand;
- (void) didFinishedSearch:(id)sender;

@end
