//
//  TVIVideoTrackStoringSampleBufferVideoView.h
//  TwilioVideo
//
//  Created by Kevin Le Gof on 13/12/2023.
//  Copyright © 2023 Twilio, Inc. All rights reserved.

#import <Foundation/Foundation.h>
#import "TVISampleBufferVideoView.h"
#import "TVIVideoTrack.h"

/**
 * `TVIVideoTrackStoringSampleBufferVideoView` stores and manages a video track which is associated with a video view.
 * This class can be used to simplify the implementation of Picture in Picture.
*/
NS_SWIFT_NAME(VideoTrackStoringSampleBufferVideoView)
@interface TVIVideoTrackStoringSampleBufferVideoView : TVISampleBufferVideoView

/**
 * @brief Use this property to set or retrieve the `TVIVideoTrack`.
 */
@property (nonatomic, strong, nullable) TVIVideoTrack *videoTrack;

@end
