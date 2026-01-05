//
//  TVINoiseCancellationProcessor.h
//  TwilioAudioProcessors
//
//  Created by Phillip Beadle on 3/28/22.
//  Copyright © 2022 Twilio, Inc. All rights reserved.
//

#import <TwilioVideo/TwilioVideo.h>
/**
 *  `TVINoiseCancellationProcessor` is an audio device that allows for background noise removal from the current audio source.
 */
NS_SWIFT_NAME(NoiseCancellationProcessor)
@interface TVINoiseCancellationProcessor : NSObject <TVIAudioDevice>

/**
 *  @brief Pause noise cancellation audio processing.
 *
 *  @discussion By default, the SDK initializes this property to NO. Setting it to YES disables the additional Twilio based underlying noise cancellation audio processing
 *  while allowing audio to play from the current source including any audio processing the system may be providing, i.e. Voice Isolation mode in iOS 15.
 *  Setting the property to NO enables the additional Twilio based noise cancellation audio processing on top of any system audio processing being used, i.e. Voice Isolation mode in iOS 15.
 */

@property (nonatomic, assign) BOOL pauseProcessing;

/**
 *  @brief Enable audio device
 *
 *  @discussion By default, the SDK initializes this property to YES. Setting it to NO entirely disables the audio device. When the device is disabled, both audio capture and playback halt. This toggle should be used in CallKit delegate (CXProviderDelegate) methods (ex: didReset, didActivate, didDeactivate) to negotiate call holding and other events taking place from the iOS dialer
 */

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

@end
