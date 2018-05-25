#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import <BRPtouchPrinterKit/BRPtouchNetworkManager.h>
#import <BRPtouchPrinterKit/BRPtouchPrinter.h>

@interface APPPrinter : CDVPlugin <BRPtouchNetworkDelegate>
{
    BRPtouchNetworkManager* ptn;
    BRPtouchPrinter* ptp;
    CDVInvokedUrlCommand* actCommand;
    BOOL communicationStarted;
}

// Prints the content
- (BOOL) print:(CDVInvokedUrlCommand*)command;
// Find out whether printing is supported on this platform
- (void) isAvailable:(CDVInvokedUrlCommand*)command;
- (void) getPrinterList:(CDVInvokedUrlCommand*)command;
- (void) setPrinter:(CDVInvokedUrlCommand*) invokedCommand;
- (void) didFinishSearch:(id)sender;

@end
