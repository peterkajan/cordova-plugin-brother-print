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
    [self searchPrinters];
}


- (BRPtouchPrintInfo*) _getDefaultPrintInfo
{
    BRPtouchPrintInfo* printInfo;
    printInfo = [[BRPtouchPrintInfo alloc] init];
    printInfo.nPrintMode = PRINT_ORIGINAL;
    printInfo.nDensity = 0;
    printInfo.nOrientation = ORI_PORTRATE;
    printInfo.nHalftone = HALFTONE_ERRDIF;
    printInfo.nHorizontalAlign = ALIGN_CENTER;
    printInfo.nVerticalAlign = ALIGN_TOP;
    printInfo.nPaperAlign = PAPERALIGN_LEFT;
    printInfo.nAutoCutFlag = 1;
    printInfo.nAutoCutCopies = 1;
    return printInfo;
}


- (BRPtouchPrintInfo*) _getPrintInfo:(NSString*) paper
                         orientation:(int) orientation
{
    BRPtouchPrintInfo* printInfo = self._getDefaultPrintInfo;
    printInfo.nOrientation = orientation;
    printInfo.strPaperName = paper;
    return printInfo;
}

/*
 * Sets printer that will be used for printing
 *
 */
- (void) setPrinter:(CDVInvokedUrlCommand*) invokedCommand {
    NSArray*  arguments = [invokedCommand arguments];
    NSMutableDictionary* settings = [arguments objectAtIndex:0];
    int orientation = [[settings objectForKey:@"landscape"] boolValue] ? ORI_LANDSCAPE : ORI_PORTRATE;
    BRPtouchPrintInfo* printInfo = [self _getPrintInfo:[settings objectForKey:@"paper"] orientation:orientation];

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


- (int) getMaximumFontSize:(NSString*) text
                  maxWidth:(int) maxWidth
           largestFontSize:(int) largestFontSize
                fontWeight:(float) fontWeight
{
    while ([text sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:largestFontSize weight:fontWeight]}].width > maxWidth)
    {
        largestFontSize -= 10;
    }
    return largestFontSize;
}


- (void) drawLine:(NSString*) text
           toRect:(CGRect)    rect
         fontSize:(int)       fontSize
       fontWeight:(float)     fontWeight
        alignment:(NSTextAlignment)     alignment
{
    fontSize = [self getMaximumFontSize:text maxWidth:rect.size.width largestFontSize:fontSize fontWeight:fontWeight];
    UIFont *font = [UIFont systemFontOfSize:fontSize weight:fontWeight];
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.alignment = alignment;
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSParagraphStyleAttributeName: paragraphStyle };
    [text drawInRect:rect withAttributes:attributes];
}

- (void) drawCenteredText:(NSString*) text
                   toRect:(CGRect)    rect
                 fontSize:(int)       fontSize
               fontWeight:(float)     fontWeight
{
    UIFont *font = [UIFont systemFontOfSize:fontSize weight:fontWeight];
    CGSize size = [text sizeWithFont:font
                   constrainedToSize:rect.size
                       lineBreakMode:(UILineBreakModeWordWrap)];
    float x_pos = (rect.size.width - size.width) / 2;
    float y_pos = (rect.size.height - size.height) /2;

    CGRect textRect = CGRectMake(0, rect.origin.y + y_pos, rect.size.width, rect.size.height);
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSParagraphStyleAttributeName: paragraphStyle };
    [text drawInRect:textRect withAttributes:attributes];
}


- (UIImage*) draw62_29_3fields:(NSMutableDictionary*) settings
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

    [self drawLine:text1 toRect:CGRectMake(offsetLeft, 0, size.width - offsetLeft, 90) fontSize:FONT_SIZE_LARGE fontWeight:UIFontWeightHeavy alignment:NSTextAlignmentCenter];
    [self drawLine:text2 toRect:CGRectMake(offsetLeft, 90, size.width - offsetLeft, 90) fontSize:FONT_SIZE_LARGE fontWeight:UIFontWeightHeavy alignment:NSTextAlignmentCenter];
    [self drawLine:text3 toRect:CGRectMake(offsetLeft, 190, size.width - offsetLeft, 80) fontSize:FONT_SIZE_MEDIUM fontWeight:UIFontWeightBold alignment:NSTextAlignmentCenter];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

- (UIImage*) draw62_29_5fields:(NSMutableDictionary*) settings
{
    NSString* text1 = [settings objectForKey:@"text1"];
    NSString* text2 = [settings objectForKey:@"text2"];
    NSString* text3 = [settings objectForKey:@"text3"];
    NSString* text4 = [settings objectForKey:@"text4"];
    NSString* text5 = [settings objectForKey:@"text5"];

    CGSize size = CGSizeMake(620, 250);
    UIGraphicsBeginImageContext(size);
    [[UIColor blackColor] set];

    NSString* fullName = [NSString stringWithFormat:@"%@ %@", text1, text2];
    [self drawLine:fullName toRect:CGRectMake(0, 10, size.width, 70) fontSize:FONT_SIZE_MEDIUM fontWeight:UIFontWeightHeavy alignment:NSTextAlignmentLeft];
    [self drawLine:text3 toRect:CGRectMake(0, 80, size.width, 60) fontSize:FONT_SIZE_SMALL fontWeight:UIFontWeightBold alignment:NSTextAlignmentLeft];
    [self drawLine:text4 toRect:CGRectMake(0, 140, size.width, 60) fontSize:FONT_SIZE_SMALL fontWeight:UIFontWeightBold alignment:NSTextAlignmentLeft];
    [self drawLine:text5 toRect:CGRectMake(0, 200, size.width, 60) fontSize:FONT_SIZE_SMALL fontWeight:UIFontWeightBold alignment:NSTextAlignmentLeft];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}


- (UIImage*) drawQrCode:(NSMutableDictionary*) settings
{
    NSString* qrFilePath = [settings objectForKey:@"qrFile"];
    NSString* text1 = [settings objectForKey:@"text1"];
    NSString* text2 = [settings objectForKey:@"text2"];
    NSString* text3 = [settings objectForKey:@"text3"];
    UIImage *image = [UIImage imageWithContentsOfFile:qrFilePath];

    CGSize size = CGSizeMake(1000, 580);
    UIGraphicsBeginImageContext(size);
    [[UIColor blackColor] set];
    // name
    int offsetLeft = 0;
    int width = 500;
    NSString* text = [NSString stringWithFormat:@"%@\n%@\n%@", text1, [text2 uppercaseString], text3];

    [self drawCenteredText:text toRect:CGRectMake(offsetLeft, 0, width, 580) fontSize:FONT_SIZE_LARGE fontWeight:UIFontWeightBold];
    [image drawInRect:CGRectMake(500, 40, 500, 500)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}


- (UIImage*) draw29_90:(NSMutableDictionary*) settings
{
    NSString* text1 = [settings objectForKey:@"text1"];
    NSString* text2 = [settings objectForKey:@"text2"];
    NSString* text3 = [settings objectForKey:@"text3"];
    NSString* text4 = [settings objectForKey:@"text4"];
    NSString* text5 = [settings objectForKey:@"text5"];

    CGSize size = CGSizeMake(870, 280);
    UIGraphicsBeginImageContext(size);
    [[UIColor blackColor] set];

    NSString* fullName = [NSString stringWithFormat:@"%@ %@", text1, text2];
    [self drawLine:fullName toRect:CGRectMake(0, 20, size.width, 100) fontSize:FONT_SIZE_LARGE fontWeight:UIFontWeightHeavy alignment:NSTextAlignmentLeft];
    [self drawLine:text3 toRect:CGRectMake(0, 120, size.width, 80) fontSize:FONT_SIZE_MEDIUM fontWeight:UIFontWeightBold alignment:NSTextAlignmentLeft];
    [self drawLine:text4 toRect:CGRectMake(0, 200, size.width * 2/3, 80) fontSize:FONT_SIZE_MEDIUM fontWeight:UIFontWeightBold alignment:NSTextAlignmentLeft];
    [self drawLine:text5 toRect:CGRectMake(size.width * 2/3, 200, size.width / 3, 80) fontSize:FONT_SIZE_MEDIUM fontWeight:UIFontWeightBold alignment:NSTextAlignmentRight];

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
    NSString* preset = [settings objectForKey:@"preset"];
    UIImage *newImage;
    if ([preset isEqualToString:@"54_qrcode"]) {
        newImage = [self drawQrCode:settings];
    }
    else if ([preset isEqualToString:@"29_90"]){
        newImage = [self draw29_90:settings];
    }
    else if ([preset isEqualToString:@"62_29_5fields"]){
        newImage = [self draw62_29_5fields:settings];
    }
    else {
        newImage = [self draw62_29_3fields:settings];
    }

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
    NSMutableArray *printers =[NSMutableArray array];
    
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