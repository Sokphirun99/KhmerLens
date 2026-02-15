//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<flutter_tesseract_ocr/FlutterTesseractOcrPlugin.h>)
#import <flutter_tesseract_ocr/FlutterTesseractOcrPlugin.h>
#else
@import flutter_tesseract_ocr;
#endif

#if __has_include(<image_picker_ios/FLTImagePickerPlugin.h>)
#import <image_picker_ios/FLTImagePickerPlugin.h>
#else
@import image_picker_ios;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FlutterTesseractOcrPlugin registerWithRegistrar:[registry registrarForPlugin:@"FlutterTesseractOcrPlugin"]];
  [FLTImagePickerPlugin registerWithRegistrar:[registry registrarForPlugin:@"FLTImagePickerPlugin"]];
}

@end
