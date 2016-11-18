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


- (int) getTextWidth:(NSString*) text
            fontSize:(int) fontSize
          fontWeight:(float) fontWeight
{
    return [text sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize weight:fontWeight]}].width;
}

- (int) getTextHeight:(NSString*) text
            fontSize:(int) fontSize
          fontWeight:(float) fontWeight
             maxWidth:(int) maxWidth
{
    return [text boundingRectWithSize:CGSizeMake(maxWidth, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize weight:fontWeight]} context:nil].size.height;
}

- (int) getMaximumFontSize:(NSString*) text
                  maxWidth:(int) maxWidth
           largestFontSize:(int) largestFontSize
                fontWeight:(float) fontWeight
{
    while ([self getTextWidth:text fontSize:largestFontSize fontWeight:fontWeight] > maxWidth)
    {
        largestFontSize -= 5;
    }
    return largestFontSize;
}

- (int) getMaximumFontSizeMultiline:(NSString*) text
                       boundingSize:(CGSize) boundingSize
                    largestFontSize:(int) largestFontSize
                         fontWeight:(float) fontWeight
{
    while ([self getTextHeight:text fontSize:largestFontSize fontWeight:fontWeight maxWidth:boundingSize.width] > boundingSize.height)
    {
        largestFontSize -= 10;
    }
    return largestFontSize;
}


- (void) _drawLine:(NSString*) text
            toRect:(CGRect)    rect
              font:(UIFont*) font
         alignment:(NSTextAlignment) alignment
{
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    paragraphStyle.alignment = alignment;
    NSDictionary *attributes = @{ NSFontAttributeName: font,
                                  NSParagraphStyleAttributeName: paragraphStyle };
    [text drawInRect:rect withAttributes:attributes];
}



- (void) drawLine:(NSString*) text
           toRect:(CGRect)    rect
         fontSize:(int)       fontSize
       fontWeight:(float)     fontWeight
        alignment:(NSTextAlignment)     alignment
{
    fontSize = [self getMaximumFontSize:text maxWidth:rect.size.width largestFontSize:fontSize fontWeight:fontWeight];
    UIFont *font = [UIFont systemFontOfSize:fontSize weight:fontWeight];
    [self _drawLine:text toRect:rect font:font alignment:alignment];
}


- (void) drawItalicLine:(NSString*) text
                 toRect:(CGRect)    rect
               fontSize:(int)       fontSize
              alignment:(NSTextAlignment)     alignment
{
    fontSize = [self getMaximumFontSize:text maxWidth:rect.size.width largestFontSize:fontSize fontWeight:UIFontWeightSemibold];
    UIFont *font = [UIFont italicSystemFontOfSize:fontSize];
    [self _drawLine:text toRect:rect font:font alignment:alignment];
}


- (void) drawCenteredText:(NSString*) text
                   toRect:(CGRect)    rect
                 fontSize:(int)       fontSize
               fontWeight:(float)     fontWeight
{
    fontSize = [self getMaximumFontSizeMultiline:text boundingSize:rect.size largestFontSize:fontSize fontWeight:fontWeight];
    UIFont *font = [UIFont systemFontOfSize:fontSize weight:fontWeight];
    int textHeight = [self getTextHeight:text fontSize:fontSize fontWeight:fontWeight maxWidth:rect.size.width];
    float y_pos = (rect.size.height - textHeight) /2;

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

- (void) drawStupidText4:(NSString*) text
           toRect:(CGRect)    rect
         fontSize:(int)       fontSize
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 3.0f);
    NSTextAlignment alignment = NSTextAlignmentRight;
    NSString* text4_1 = [text substringToIndex:text.length - 1];
    NSString* text4_2 = [text substringFromIndex:text.length - 1];
    int text41Width = [self getTextWidth:text4_1 fontSize:FONT_SIZE_MEDIUM fontWeight:UIFontWeightBold] + 5;
    int text42Width = [self getTextWidth:text4_2 fontSize:FONT_SIZE_MEDIUM + 5 fontWeight:UIFontWeightBold];
    int text4Width = text41Width + text42Width;
    int textOriginX = rect.origin.x + rect.size.width - text4Width - 10;
    CGContextStrokeRect(context, CGRectMake(textOriginX - 10, rect.origin.y - 5, text4Width + 20, 85));
    fontSize = [self getMaximumFontSize:text maxWidth:rect.size.width largestFontSize:fontSize fontWeight:UIFontWeightRegular];

    UIFont *font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightBold];
    [self _drawLine:text4_1 toRect:CGRectMake(textOriginX, rect.origin.y, text41Width, 80) font:font alignment:alignment];

    UIFont *font2 = [UIFont systemFontOfSize:fontSize + 5 weight:UIFontWeightBold];
    [self _drawLine:text4_2 toRect:CGRectMake(textOriginX + text41Width, rect.origin.y - 5, text42Width, 80) font:font2 alignment:alignment];
}


- (UIImage*) draw54_100_QrCode:(NSMutableDictionary*) settings
{
    NSString* qrFilePath = [settings objectForKey:@"qrFile"];
    NSString* text1 = [settings objectForKey:@"text1"];
    NSString* text2 = [settings objectForKey:@"text2"];
    NSString* text3 = [settings objectForKey:@"text3"];
    NSString* text4 = [settings objectForKey:@"text4"];
    NSString* text5 = [settings objectForKey:@"text5"];
    UIImage *image = [UIImage imageWithContentsOfFile:qrFilePath];

    CGSize size = CGSizeMake(1000, 540);
    UIGraphicsBeginImageContext(size);
    [[UIColor blackColor] set];
    int offsetLeft = 0;

    // name
    NSString* fullName = [NSString stringWithFormat:@"%@ %@", text1, [text2 uppercaseString]];
    [self drawLine:fullName toRect:CGRectMake(offsetLeft, 20, size.width, 90) fontSize:FONT_SIZE_LARGE fontWeight:UIFontWeightBold alignment:NSTextAlignmentCenter];
    // vertically centered text3
    [self drawCenteredText:text3 toRect:CGRectMake(offsetLeft, 140, 580, 300) fontSize:FONT_SIZE_MEDIUM fontWeight:UIFontWeightRegular];
    // text4 with bounding rectangle
    if (text4.length > 0) {
        [self drawStupidText4:text4 toRect:CGRectMake(380, 460 - 10, 200, 80) fontSize:FONT_SIZE_MEDIUM];
    }
    // italic text5
    [self drawItalicLine:text5 toRect:CGRectMake(offsetLeft, 460, 380, 80) fontSize:FONT_SIZE_MEDIUM alignment:NSTextAlignmentCenter];
    // QR Code
    [image drawInRect:CGRectMake(600, 140, 400, 400)];
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

- (UIImage*) draw17_54:(NSMutableDictionary*) settings
{
    NSString* text1 = [settings objectForKey:@"text1"];
    NSString* text2 = [settings objectForKey:@"text2"];

    CGSize size = CGSizeMake(510, 160);
    UIGraphicsBeginImageContext(size);
    [[UIColor blackColor] set];

    NSString* fullName = [NSString stringWithFormat:@"%@ %@", text1, text2];
    [self drawLine:text1 toRect:CGRectMake(0, 0, size.width, 80) fontSize:FONT_SIZE_LARGE-6 fontWeight:UIFontWeightHeavy alignment:NSTextAlignmentCenter];
    [self drawLine:text2 toRect:CGRectMake(0, 80, size.width, 80) fontSize:FONT_SIZE_LARGE-6 fontWeight:UIFontWeightHeavy alignment:NSTextAlignmentCenter];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}


- (UIImage*) draw62_html:(NSMutableDictionary*) settings
                 command:(CDVInvokedUrlCommand*) invokedCommand
{
    NSString* text = [settings objectForKey:@"htmlText"];
    CGSize size = CGSizeMake(990, 680);
    UIGraphicsBeginImageContext(size);
    [[UIColor blackColor] set];

    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc]
                                            initWithData: [text dataUsingEncoding:NSUnicodeStringEncoding]
                                            options: @{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding] }
                                            documentAttributes: nil
                                            error: nil
                                            ];

    [attString drawInRect:CGRectMake(0, 0, 990, 680)];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}


- (UIImage*) drawHtml:(NSMutableDictionary*) settings
{
    NSString* text = [settings objectForKey:@"htmlText"];
    NSInteger width = [[settings objectForKey:@"width"] integerValue];
    NSInteger height = [[settings objectForKey:@"height"] integerValue];
    CGSize size = CGSizeMake(width, height);
    UIGraphicsBeginImageContext(size);
    [[UIColor blackColor] set];

    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc]
                                            initWithData: [text dataUsingEncoding:NSUnicodeStringEncoding]
                                            options: @{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding] }
                                            documentAttributes: nil
                                            error: nil
                                            ];

    [attString drawInRect:CGRectMake(0, 0, width, height)];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

- (UIImage*) drawText:(NSMutableDictionary*) settings
{
    NSString* text = [settings objectForKey:@"text"];
    NSInteger width = [[settings objectForKey:@"width"] integerValue];
    NSInteger height = [[settings objectForKey:@"height"] integerValue];
    CGSize size = CGSizeMake(width, height);
    UIGraphicsBeginImageContext(size);
    [[UIColor blackColor] set];

    // vertically centered text3
    [self drawCenteredText:text toRect:CGRectMake(0, 0, width, height) fontSize:FONT_SIZE_LARGE fontWeight:UIFontWeightHeavy];
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
    if ([preset isEqualToString:@"54_100_qrcode"]) {
        newImage = [self draw54_100_QrCode:settings];
    }
    else if ([preset isEqualToString:@"29_90"]){
        newImage = [self draw29_90:settings];
    }
    else if ([preset isEqualToString:@"62_29_5fields"]){
        newImage = [self draw62_29_5fields:settings];
    }
    else if ([preset isEqualToString:@"17_54"]){
        newImage = [self draw17_54:settings];
    }
    else if ([preset isEqualToString:@"62_html"]){
        newImage = [self draw62_html:settings command:invokedCommand];
    }
    else if ([preset isEqualToString:@"html"]) {
        newImage = [self drawHtml:settings];
    }
    else if ([preset isEqualToString:@"text"]) {
        newImage = [self drawText:settings];
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
