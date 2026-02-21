#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>

/* -----------------------------------------------------------------------------
 Generate a preview for file

 This function's job is to create preview for designated file
 ----------------------------------------------------------------------------- */

NSData *processMMD(NSURL *url);
NSData *processOPML2MMD(NSURL *url);

BOOL logDebug = NO;

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    if (logDebug)
        NSLog(@"generate preview for content type: %@", contentTypeUTI);

    CFDataRef previewData;

    if (CFStringCompare(contentTypeUTI, CFSTR("org.opml.opml"), 0) == kCFCompareEqualTo)
    {
        // Preview an OPML file

        previewData = (CFDataRef)processOPML2MMD((NSURL *)url);
    }
    else if (CFStringCompare(contentTypeUTI, CFSTR("org.textbundle.package"), 0) == kCFCompareEqualTo)
    {
        NSString *docPath = [[(NSURL *)url path]
            stringByAppendingPathComponent:@"text.md"];
        NSURL *newURL = [NSURL fileURLWithPath:docPath];
        ;

        previewData = (CFDataRef)processMMD((NSURL *)newURL);
    }
    else
    {
        // Preview a text file

        previewData = (CFDataRef)processMMD((NSURL *)url);
    }

    if (previewData)
    {
        if (logDebug)
            NSLog(@"preview generated");

        CFDictionaryRef properties = (CFDictionaryRef)[NSDictionary dictionaryWithObject:@"UTF-8" forKey:(NSString *)kQLPreviewPropertyTextEncodingNameKey];
        QLPreviewRequestSetDataRepresentation(preview, previewData, kUTTypeHTML, properties);
    }

    return noErr;
}

NSData *processOPML2MMD(NSURL *url)
{
    if (logDebug)
        NSLog(@"create preview for OPML file %@", [url path]);

    NSString *path2MMD = [[NSBundle bundleWithIdentifier:@"net.fletcherpenney.quicklook"] pathForResource:@"multimarkdown" ofType:nil];

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:[path2MMD stringByExpandingTildeInPath]];

    [task setArguments:[NSArray array]];

    NSPipe *writePipe = [NSPipe pipe];
    NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
    [task setStandardInput:writePipe];

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

NSData *processMMD(NSURL *url)
{
    if (logDebug)
        NSLog(@"create preview for MMD file %@", [url path]);

    NSString *path2MMD = [[NSBundle bundleWithIdentifier:@"net.fletcherpenney.quicklook"] pathForResource:@"multimarkdown" ofType:nil];

    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:[path2MMD stringByExpandingTildeInPath]];

    [task setArguments:[NSArray array]];

    NSPipe *writePipe = [NSPipe pipe];
    NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
    [task setStandardInput:writePipe];

    NSPipe *readPipe = [NSPipe pipe];
    [task setStandardOutput:readPipe];

    [task launch];

    NSStringEncoding encoding = 0;

    // Ensure we used proper encoding - try different options until we get a hit
    //  if (plainText == nil)
    //    plainText = [NSString stringWithContentsOfFile:[url path] usedEncoding:<#(NSStringEncoding *)#> error:<#(NSError **)#> encoding:NSASCIIStringEncoding];

    NSString *theData = [NSString stringWithContentsOfFile:[url path] usedEncoding:&encoding error:nil];

    NSString *cssDir = @"~/.mdqlstyle.css";
    if ([[NSFileManager defaultManager] fileExistsAtPath:[cssDir stringByExpandingTildeInPath]])
    {
        NSString *cssStyle = [NSString stringWithFormat:@"\n<style>body{-webkit-font-smoothing:antialiased;padding:20px;max-width:900px;margin:0 auto;}%@</style>", [NSString stringWithContentsOfFile:[cssDir stringByExpandingTildeInPath] encoding:NSUTF8StringEncoding error:nil]];
        theData = [theData stringByAppendingString:cssStyle];
        if (logDebug)
        {
            NSLog(@"Using located style ~/.mdqlstyle.css: %@", cssStyle);
        }
    }
    else
    {
        theData = [theData stringByAppendingString:@"\n<style>html,body{color:black}*{margin:0;padding:0}body{font:13.34px helvetica,arial,freesans,clean,sans-serif;-webkit-font-smoothing:antialiased;line-height:1.4;padding:30px;background:#fff;border-radius:3px;-moz-border-radius:3px;-webkit-border-radius:3px;max-width:900px;margin:15px auto;border:3px solid #eee!important}p{margin:1em 0}a{color:#4183c4;text-decoration:none}#wrapper{background-color:#fff;border:3px solid #eee!important;padding:0 30px;margin:15px}#wrapper{padding:20px;font-size:14px;line-height:1.6}#wrapper>*:first-child{margin-top:0!important}#wrapper>*:last-child{margin-bottom:0!important}h1,h2,h3,h4,h5,h6{margin:0;padding:0}h1{margin:15px 0;padding-bottom:2px;font-size:24px;border-bottom:1px solid #eee}h2{margin:20px 0 10px 0;font-size:18px}h3{margin:20px 0 10px 0;padding-bottom:2px;font-size:14px;border-bottom:1px solid #ddd}h4{font-size:14px;line-height:26px;padding:18px 0 4px;font-weight:bold;text-transform:uppercase}h5{font-size:13px;line-height:26px;padding:14px 0 0;font-weight:bold;text-transform:uppercase}h6{color:#666;font-size:14px;line-height:26px;padding:18px 0 0;font-weight:normal;font-variant:italic}hr{background:transparent url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAYAAAAECAYAAACtBE5DAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYwIDYxLjEzNDc3NywgMjAxMC8wMi8xMi0xNzozMjowMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNSBNYWNpbnRvc2giIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6OENDRjNBN0E2NTZBMTFFMEI3QjRBODM4NzJDMjlGNDgiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6OENDRjNBN0I2NTZBMTFFMEI3QjRBODM4NzJDMjlGNDgiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo4Q0NGM0E3ODY1NkExMUUwQjdCNEE4Mzg3MkMyOUY0OCIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo4Q0NGM0E3OTY1NkExMUUwQjdCNEE4Mzg3MkMyOUY0OCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PqqezsUAAAAfSURBVHjaYmRABcYwBiM2QSA4y4hNEKYDQxAEAAIMAHNGAzhkPOlYAAAAAElFTkSuQmCC) repeat-x 0 0;border:0 none;color:#ccc;height:4px;margin:20px 0;padding:0}#wrapper>h2:first-child,#wrapper>h1:first-child,#wrapper>h1:first-child+h2{border:0;margin:0;padding:0}#wrapper>h3:first-child,#wrapper>h4:first-child,#wrapper>h5:first-child,#wrapper>h6:first-child{margin:0;padding:0}h4+p,h5+p,h6+p{margin-top:0}li p.first{display:inline-block}ul,ol{margin:15px 0 15px 25px}ul li,ol li{margin-top:7px;margin-bottom:7px}ul li>*:last-child,ol li>*:last-child{margin-bottom:0}ul li>*:first-child,ol li>*:first-child{margin-top:0}#wrapper>ul,#wrapper>ol{margin-top:21px;margin-left:36px}dl{margin:0;padding:20px 0 0}dl dt{font-size:14px;font-weight:bold;line-height:normal;margin:0;padding:20px 0 0}dl dt:first-child{padding:0}dl dd{font-size:13px;margin:0;padding:3px 0 0}blockquote{margin:14px 0;border-left:4px solid #ddd;padding-left:11px;color:#555}table{border-collapse:collapse;margin:20px 0 0;padding:0}table tr{border-top:1px solid #ccc;background-color:#fff;margin:0;padding:0}table tr:nth-child(2n){background-color:#f8f8f8}table tr th,table tr td{border:1px solid #ccc;text-align:left;margin:0;padding:6px 13px}img{max-width:100%;height:auto}code,tt{margin:0 2px;padding:2px 5px;white-space:nowrap;border:1px solid #ccc;background-color:#f8f8f8;border-radius:3px;-moz-border-radius:3px;-webkit-border-radius:3px;font-size:12px}pre>code{margin:0;padding:0;white-space:pre;border:0;background:transparent;font-size:13px}.highlight pre,pre{background-color:#f8f8f8;border:1px solid #ccc;font-size:13px;line-height:19px;overflow:auto;padding:6px 10px;border-radius:3px;-moz-border-radius:3px;-webkit-border-radius:3px}#wrapper>pre,#wrapper>div.highlight{margin:10px 0 0}pre code,pre tt{background-color:transparent;border:0}#wrapper{background-color:#fff;border:1px solid #cacaca;padding:30px}.poetry pre{font-family:Georgia,Garamond,serif!important;font-style:italic;font-size:110%!important;line-height:1.6em;display:block;margin-left:1em}.poetry pre code{font-family:Georgia,Garamond,serif!important}sup,sub,a.footnote{font-size:1.4ex;height:0;line-height:1;vertical-align:super;position:relative}sub{vertical-align:sub;top:-1px}@media print{body{background:#fff}img,pre,blockquote,table,figure{page-break-inside:avoid}#wrapper{background:#fff;border:0}code{background-color:#fff;color:#444!important;padding:0 .2em;border:1px solid #dedede}pre code{background-color:#fff!important;overflow:visible}pre{background:#fff}}@media screen{body.inverted,.inverted #wrapper,.inverted hr .inverted p,.inverted td,.inverted li,.inverted h1,.inverted h2,.inverted h3,.inverted h4,.inverted h5,.inverted h6,.inverted th,.inverted .math,.inverted caption,.inverted dd,.inverted dt,.inverted blockquote{color:#eee!important;border-color:#555}.inverted td,.inverted th{background:#333}.inverted pre,.inverted code,.inverted tt{background:#444!important}.inverted h2{border-color:#555}.inverted hr{border-color:#777;border-width:1px!important}::selection{background:rgba(157,193,200,.5)}h1::selection{background-color:rgba(45,156,208,.3)}h2::selection{background-color:rgba(90,182,224,.3)}h3::selection,h4::selection,h5::selection,h6::selection,li::selection,ol::selection{background-color:rgba(133,201,232,.3)}code::selection{background-color:rgba(0,0,0,.7);color:#eee}code span::selection{background-color:rgba(0,0,0,.7)!important;color:#eee!important}a::selection{background-color:rgba(255,230,102,.2)}.inverted a::selection{background-color:rgba(255,230,102,.6)}td::selection,th::selection,caption::selection{background-color:rgba(180,237,95,.5)}.inverted{background:#0b2531}.inverted #wrapper,.inverted{background:rgba(37,42,42,1)}.inverted a{color:rgba(172,209,213,1)}}.highlight .c{color:#998;font-style:italic}.highlight .err{color:#a61717;background-color:#e3d2d2}.highlight .k{font-weight:bold}.highlight .o{font-weight:bold}.highlight .cm{color:#998;font-style:italic}.highlight .cp{color:#999;font-weight:bold}.highlight .c1{color:#998;font-style:italic}.highlight .cs{color:#999;font-weight:bold;font-style:italic}.highlight .gd{color:#000;background-color:#fdd}.highlight .gd .x{color:#000;background-color:#faa}.highlight .ge{font-style:italic}.highlight .gr{color:#a00}.highlight .gh{color:#999}.highlight .gi{color:#000;background-color:#dfd}.highlight .gi .x{color:#000;background-color:#afa}.highlight .go{color:#888}.highlight .gp{color:#555}.highlight .gs{font-weight:bold}.highlight .gu{color:#800080;font-weight:bold}.highlight .gt{color:#a00}.highlight .kc{font-weight:bold}.highlight .kd{font-weight:bold}.highlight .kn{font-weight:bold}.highlight .kp{font-weight:bold}.highlight .kr{font-weight:bold}.highlight .kt{color:#458;font-weight:bold}.highlight .m{color:#099}.highlight .s{color:#d14}.highlight .na{color:#008080}.highlight .nb{color:#0086b3}.highlight .nc{color:#458;font-weight:bold}.highlight .no{color:#008080}.highlight .ni{color:#800080}.highlight .ne{color:#900;font-weight:bold}.highlight .nf{color:#900;font-weight:bold}.highlight .nn{color:#555}.highlight .nt{color:#000080}.highlight .nv{color:#008080}.highlight .ow{font-weight:bold}.highlight .w{color:#bbb}.highlight .mf{color:#099}.highlight .mh{color:#099}.highlight .mi{color:#099}.highlight .mo{color:#099}.highlight .sb{color:#d14}.highlight .sc{color:#d14}.highlight .sd{color:#d14}.highlight .s2{color:#d14}.highlight .se{color:#d14}.highlight .sh{color:#d14}.highlight .si{color:#d14}.highlight .sx{color:#d14}.highlight .sr{color:#009926}.highlight .s1{color:#d14}.highlight .ss{color:#990073}.highlight .bp{color:#999}.highlight .vc{color:#008080}.highlight .vg{color:#008080}.highlight .vi{color:#008080}.highlight .il{color:#099}.highlight .gc{color:#999;background-color:#eaf2f5}.type-csharp .highlight .k{color:#00F}.type-csharp .highlight .kt{color:#00F}.type-csharp .highlight .nf{color:#000;font-weight:normal}.type-csharp .highlight .nc{color:#2b91af}.type-csharp .highlight .nn{color:#000}.type-csharp .highlight .s{color:#a31515}.type-csharp .highlight .sc{color:#a31515}</style>"];

        if (logDebug)
        {
            NSLog(@"Using internal style");
        }
    }

    if (logDebug)
        NSLog(@"Used %lu encoding", (unsigned long)encoding);

    [writeHandle writeData:[theData dataUsingEncoding:NSUTF8StringEncoding]];

    [writeHandle closeFile];

    NSData *mmdData = [[readPipe fileHandleForReading] readDataToEndOfFile];
    
    [task release];
    return mmdData;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
