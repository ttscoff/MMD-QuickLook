#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

NSData* processMMD(NSURL* url);
NSData* processOPML2MMD(NSURL* url);

BOOL logDebug = NO;


OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    if (logDebug)
        NSLog(@"generate preview for content type: %@",contentTypeUTI);
    
    CFDataRef previewData;
    
    if (CFStringCompare(contentTypeUTI, CFSTR("org.opml.opml"), 0) == kCFCompareEqualTo)
    {
        // Preview an OPML file
        
        previewData = (CFDataRef) processOPML2MMD((NSURL*) url);
    } else {
        // Preview a text file
        
        previewData = (CFDataRef) processMMD((NSURL*) url);
    }
    
    if (previewData) {
        if (logDebug)
            NSLog(@"preview generated");
        
        CFDictionaryRef properties = (CFDictionaryRef) [NSDictionary dictionary];
        QLPreviewRequestSetDataRepresentation(preview, previewData, kUTTypeHTML, properties);
    }
    
    return noErr;
}

NSData* processOPML2MMD(NSURL* url)
{
    if (logDebug)
        NSLog(@"create preview for OPML file %@",[url path]);
    
    NSString *path2MMD = [[NSBundle bundleWithIdentifier:@"net.fletcherpenney.quicklook"] pathForResource:@"multimarkdown" ofType:nil];
    
	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath: [path2MMD stringByExpandingTildeInPath]];
	
    [task setArguments: [NSArray arrayWithObjects: nil]];
	
	NSPipe *writePipe = [NSPipe pipe];
	NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
	[task setStandardInput: writePipe];
	
	NSPipe *readPipe = [NSPipe pipe];
	[task setStandardOutput:readPipe];
	
	[task launch];

    
    NSString *theData = [NSString stringWithContentsOfFile:[url path] encoding:NSUTF8StringEncoding error:nil];
    
    NSXMLDocument *opmlDocument = [[NSXMLDocument alloc] initWithXMLString:theData
                                                              options:0
                                                                error:nil];
    NSURL *styleFilePath = [[NSBundle bundleWithIdentifier:@"net.fletcherpenney.quicklook"] URLForResource:@"opml2mmd"
                                                                                             withExtension:@"xslt"];
    
    NSData *mmdContents = [opmlDocument objectByApplyingXSLTAtURL:styleFilePath
                                                   arguments:nil 
                                                       error:nil];
    
    [opmlDocument release];
    
	[writeHandle writeData:mmdContents];
    
	[writeHandle closeFile];
	
	
	NSData *mmdData = [[readPipe fileHandleForReading] readDataToEndOfFile];
    
    [task release];
	return mmdData;
}

NSData* processMMD(NSURL* url)
{
    if (logDebug)
        NSLog(@"create preview for MMD file %@",[url path]);

    NSString *path2MMD = [[NSBundle bundleWithIdentifier:@"net.fletcherpenney.quicklook"] pathForResource:@"multimarkdown" ofType:nil];
    
	NSTask* task = [[NSTask alloc] init];
	[task setLaunchPath: [path2MMD stringByExpandingTildeInPath]];
	
    [task setArguments: [NSArray arrayWithObjects: nil]];
	
	NSPipe *writePipe = [NSPipe pipe];
	NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
	[task setStandardInput: writePipe];
	
	NSPipe *readPipe = [NSPipe pipe];
	[task setStandardOutput:readPipe];
	
	[task launch];
    
    NSStringEncoding encoding = 0;
        
    // Ensure we used proper encoding - try different options until we get a hit
  //  if (plainText == nil)
    //    plainText = [NSString stringWithContentsOfFile:[url path] usedEncoding:<#(NSStringEncoding *)#> error:<#(NSError **)#> encoding:NSASCIIStringEncoding];
    
		
    NSString *theData = [NSString stringWithContentsOfFile:[url path] usedEncoding:&encoding error:nil];
		NSString *cssDir = @"~/.mdqlstyle.css";
		if ([[NSFileManager defaultManager] fileExistsAtPath:[cssDir stringByExpandingTildeInPath]]) {
				NSString *cssStyle = [NSString stringWithFormat:@"\n<style>%@</style>",[NSString stringWithContentsOfFile:[cssDir stringByExpandingTildeInPath] encoding:NSUTF8StringEncoding error:nil]];
				theData = [theData stringByAppendingString:cssStyle];
		}
    
    if (logDebug)
        NSLog(@"Used %lu encoding",(unsigned long) encoding);
    
	[writeHandle writeData:[theData dataUsingEncoding:NSUTF8StringEncoding]];
    
	[writeHandle closeFile];
	
	
	NSData *mmdData = [[readPipe fileHandleForReading] readDataToEndOfFile];
		
    [task release];
	return mmdData;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
