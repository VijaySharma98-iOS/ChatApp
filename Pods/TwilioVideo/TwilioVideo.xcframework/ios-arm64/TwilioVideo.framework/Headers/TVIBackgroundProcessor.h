//
//  TVIBackgroundProcessor.h
//  TwilioVideo
//
//  Copyright © 2018 Twilio, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TVIVideoFormat.h"
#import "TVIVideoFrame.h"
#import "TVIVideoSource.h"

/**
 * TVIBackgroundProcessor delegate delivers the captured frame as CMSampleBufferRef for further processing.
 * This delegate is invoked on the capturer thread.
 */
NS_SWIFT_NAME(BackgroundProcessor)
@protocol TVIBackgroundProcessor <NSObject>

- (void)processFrameBuffer:(nonnull CMSampleBufferRef)sampleBuffer
                 videoSink:(nonnull id<TVIVideoSink>)videoSink
               orientation:(TVIVideoOrientation)orientation;

@end

