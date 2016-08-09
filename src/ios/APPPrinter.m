#import "APPPrinter.h"
#import <Cordova/CDVAvailability.h>
#import <BRPtouchPrinterKit/BRPtouchPrintInfo.h>
#import <BRPtouchPrinterKit/BRPtouchPrinter.h>
#import <BRPtouchPrinterKit/BRPtouchNetworkInfo.h>


@interface APPPrinter ()

@property (retain) NSString* callbackId;

@end


@implementation APPPrinter


int FONT_SIZE_LARGE = 74;
int FONT_SIZE_MEDIUM = 60;
int FONT_SIZE_SMALL = 50;

/*
 * Checks if the printing service is available.
 *
 * @param {Function} callback
 *      A callback function to be called with the result
 */
- (void) isAvailable:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult;
        BOOL isAvailable = ptp != nil && [ptp isPrinterReady];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                           messageAsBool:isAvailable];

        [self.commandDelegate sendPluginResult:pluginResult
                                    callbackId:command.callbackId];
    }];
}

/*
 * Finds list of available printers.
 *
 * @param {Function} callback
 *      A callback function to be called with the result
 */
- (void) getPrinterList:(CDVInvokedUrlCommand*)command
{
    actCommand = command;
    self.searchPrinters;
}


/*
 * Sets printer that will be used for printing
 *
 */
- (void) setPrinter:(CDVInvokedUrlCommand*) invokedCommand {
    NSArray*  arguments = [invokedCommand arguments];
    NSMutableDictionary* settings = [arguments objectAtIndex:0];

    BRPtouchPrintInfo* printInfo;
    printInfo = [[BRPtouchPrintInfo alloc] init];
    printInfo.strPaperName = @"62mm x 29mm";
    printInfo.nPrintMode = PRINT_ORIGINAL;
    printInfo.nDensity = 0;
    printInfo.nOrientation = ORI_PORTRATE;
    printInfo.nHalftone = HALFTONE_ERRDIF;
    printInfo.nHorizontalAlign = ALIGN_CENTER;
    printInfo.nVerticalAlign = ALIGN_TOP;
    printInfo.nPaperAlign = PAPERALIGN_LEFT;
    printInfo.nAutoCutFlag = 1;
    printInfo.nAutoCutCopies = 1;

    //	BRPtouchPrinter Class initialize (Release will be done in [dealloc])
    ptp = [[BRPtouchPrinter alloc] initWithPrinterName:[settings objectForKey:@"name"]];
    [ptp setPrintInfo:printInfo];
    [ptp setIPAddress:[settings objectForKey:@"ipAddress"]];

    CDVPluginResult* pluginResult;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:invokedCommand.callbackId];
}


/*
 * Prints text
 *
 */
- (BOOL) print:(CDVInvokedUrlCommand*) invokedCommand {
    if (ptp == nil) {
        NSLog(@"Printer not set");
        return NO;
    }
    NSArray*  arguments = [invokedCommand arguments];
    NSMutableDictionary* settings = [arguments objectAtIndex:1];

    [self.commandDelegate runInBackground:^{
        [self _print:settings command:invokedCommand];
    }];
    return YES;
}


- (void) searchPrinters
{
    ptn = [[BRPtouchNetwork alloc] init];
    ptn.delegate = self;

    NSArray *printerList = [NSArray arrayWithObjects:@"Brother QL-720NW", nil];
    [ptn setPrinterNames:printerList];
    [ptn startSearch: 5.0];
}


- (int) getPrimaryFontSize:(NSUInteger) length
{
    if (length < 14) {
        return FONT_SIZE_LARGE;
    }
    if (length < 17) {
        return FONT_SIZE_MEDIUM;
    }
    return FONT_SIZE_SMALL;
}


- (int) getSecondaryFontSize:(NSUInteger) length
{
    if (length < 18) {
        return FONT_SIZE_MEDIUM;
    }
    return FONT_SIZE_SMALL;
}


- (void) drawLine:(NSString*) text
           toRect:(CGRect)    rect
         fontSize:(int)       fontSize
       fontWeight:(float)     fontWeight
{
    UIFont *font = [UIFont systemFontOfSize:fontSize weight:fontWeight];
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSParagraphStyleAttributeName: paragraphStyle };
    [text drawInRect:rect withAttributes:attributes];
}


- (UIImage*) drawText:(NSMutableDictionary*) settings
{
    NSString* text1 = [settings objectForKey:@"text1"];
    NSString* text2 = [settings objectForKey:@"text2"];
    NSString* text3 = [settings objectForKey:@"text3"];

    CGSize size = CGSizeMake(620, 270);
    // uncoment to use the not sticky paper
    // int offsetLeft = 100;
    int offsetLeft = 0;
    UIGraphicsBeginImageContext(size);
    [[UIColor blackColor] set];

    [self drawLine:text1 toRect:CGRectMake(offsetLeft, 0, size.width - offsetLeft, 90) fontSize:[self getPrimaryFontSize:text1.length] fontWeight:UIFontWeightHeavy];
    [self drawLine:text2 toRect:CGRectMake(offsetLeft, 90, size.width - offsetLeft, 90) fontSize:[self getPrimaryFontSize:text2.length] fontWeight:UIFontWeightHeavy];
    [self drawLine:text3 toRect:CGRectMake(offsetLeft, 190, size.width - offsetLeft, 80) fontSize:[self getSecondaryFontSize:text3.length] fontWeight:UIFontWeightBold];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}


/**
 * Sends the printing content to the printer controller and opens them.
 */
- (BOOL) _print: (NSMutableDictionary*) settings
        command: (CDVInvokedUrlCommand*) invokedCommand
{
    UIImage *newImage = [self drawText:settings];
    CGImageRef imgRef = [newImage CGImage];

    if (nil == imgRef) {
        NSLog(@"NIL");
        return NO;
    }

    // Do print
    NSString* resultStr;
    BOOL error = NO;
    if ([ptp isPrinterReady]) {
        NSLog(@"Ready");
        int result = [ptp printImage:imgRef copy:1 timeout:10];

        if (result <= 0) {
            NSLog(@"Result: %d", result);
            resultStr = @"error_other";
            error = YES;
        }
        else {
            NSLog(@"Print successful");
        }
    }
    else {
        NSLog(@"Not ready");
        resultStr = @"error_notready";
        error = YES;
    }

    CDVPluginResult* pluginResult;
    if (!error) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                        messageAsString:resultStr];
    }

    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:invokedCommand.callbackId];
    return YES;
}

-(void)didFinishedSearch:(id)sender
{
    NSMutableArray* aryListData = (NSMutableArray*)[ptn getPrinterNetInfo];

    BRPtouchPrintInfo* printInfo;
    printInfo = [[BRPtouchPrintInfo alloc] init];
    printInfo.strPaperName = @"62mm x 29mm";
    printInfo.nPrintMode = PRINT_ORIGINAL;
    printInfo.nDensity = 0;
    printInfo.nOrientation = ORI_PORTRATE;
    printInfo.nHalftone = HALFTONE_ERRDIF;
    printInfo.nHorizontalAlign = ALIGN_CENTER;
    printInfo.nVerticalAlign = ALIGN_TOP;
    printInfo.nPaperAlign = PAPERALIGN_LEFT;
    printInfo.nAutoCutFlag = 1;
    printInfo.nAutoCutCopies = 1;

    NSMutableArray *printers =[NSMutableArray arrayWithObjects: nil];
    for (BRPtouchNetworkInfo* bpni in aryListData) {
        NSMutableDictionary* printerDict = [NSMutableDictionary dictionaryWithCapacity:2];
        [printerDict setObject:bpni.strModelName forKey:@"name"];
        [printerDict setObject:bpni.strIPAddress forKey:@"ipAddress"];
        [printers addObject:printerDict];
    }

    CDVPluginResult* pluginResult;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                      messageAsArray:printers];

    [self.commandDelegate sendPluginResult:pluginResult
                                callbackId:actCommand.callbackId];
}

@end