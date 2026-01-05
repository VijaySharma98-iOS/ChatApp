//
//  TVICameraSourceOrientationTracker.h
//  TwilioVideo
//
//  Copyright © 2019 Twilio, Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@class UIWindowScene;

/**
 *  @brief A protocol which allows `TVICameraSourceOrientationTracker` to notify interested parties about orientation changes.
 */
NS_SWIFT_NAME(CameraSourceOrientationDelegate)
@protocol TVICameraSourceOrientationDelegate <NSObject>
@optional

/**
 *  @brief A callback that should be fired whenever the tracker's orientation changes.
 *
 *  @param orientation The updated orientation value.
 *
 *  @discussion This method should be called on the main thread. Calling the delegate causes `TVICameraSource` to enqueue an update task on its
 *  internal `AVCaptureVideoDataOutput` queue, and to update the `TVICameraPreviewView` orientation, if present.
 *  This method is deprecated in favor of `trackerRotationAngleDidChange`.
 */
- (void)trackerOrientationDidChange:(AVCaptureVideoOrientation)orientation
NS_SWIFT_NAME(trackerOrientationDidChange(_:))
__attribute__((deprecated("Use the `trackerRotationAngleDidChange:rotationAngle:` method instead.")));

/**
 *  @brief A callback that should be fired whenever the tracker's rotation angle changes.
 *
 *  @param rotationAngle The updated rotation angle value.
 *
 *  @discussion This method should be called on the main thread. Calling the delegate causes `TVICameraSource` to enqueue an update task on its
 *  internal `AVCaptureVideoDataOutput` queue, and to update the `TVICameraPreviewView` orientation, if present.
 */
- (void)trackerRotationAngleDidChange:(CGFloat)rotationAngle
NS_SWIFT_NAME(trackerRotationAngleDidChange(_:));

@end

/**
 *  @brief Allows the developer to customize how `TVICameraSource` tracks video orientation for capture and preview.
 */
NS_SWIFT_NAME(CameraSourceOrientationTracker)
@protocol TVICameraSourceOrientationTracker <NSObject>
@required

/**
 *  @brief The tracker's delegate, conforming to `TVICameraSourceOrientationDelegate`.
 *
 *  @discussion This property is set on the calling thread as part of the invocation for `-[TVICameraSource startCaptureWithDevice:]`.
 */
@property (nonatomic, weak, nullable) id<TVICameraSourceOrientationDelegate> delegate;

/**
 *  @brief The currently observed orientation, in the form of `AVCaptureVideoOrientation`.
 *  The value is used by `TVICameraSource` to configure its internal `AVCaptureVideoDataOutput` and `AVCaptureVideoPreviewLayer` connections.
 *  This property is deprecated in favor of `rotationAngle`.
 */
@property (nonatomic, assign, readonly) AVCaptureVideoOrientation orientation __attribute__((deprecated("Use the `rotationAngle` property instead.")));

/**
 *  @brief The currently observed video rotation angle, in the form of `CGFloat`.
 *  The value is used by `TVICameraSource` to configure its internal `AVCaptureVideoDataOutput` and `AVCaptureVideoPreviewLayer` connections.
 */
@property (nonatomic, assign, readonly) CGFloat rotationAngle;

@end

/**
 *  @brief An implementation of `TVICameraSourceOrientationTracker` that monitors for changes in `UIInterfaceOrientation` at the application or scene level (iOS 13+).
 *
 *  @discussion It is recommended that this class be constructed on the main thread.
 */

NS_SWIFT_NAME(UserInterfaceTracker)
@interface TVIUserInterfaceTracker : NSObject<TVICameraSourceOrientationTracker>

/**
 *  @brief The currently observed orientation based upon the UIApplication or UIScene.
 *
 *  @discussion It is highly recommended to construct this class on the main thread.
 *  When the tracker is constructed off the main thread, this property is eventually consistent with the state of the user interface, otherwise it is updated immediately.
 *  `UInterfaceOrientation` is mapped directly to `AVCaptureVideoOrientation` except for `UIIntefaceOrientationUnknown` which is translated to `AVCaptureVideoOrientationLandscapeRight`.
 *  This property is deprecated in favor of `rotationAngle`.
 */
@property (nonatomic, assign, readonly) AVCaptureVideoOrientation orientation __attribute__((deprecated("Use the `rotationAngle` property instead.")));

/**
 *  @brief The currently observed video rotation angle based upon the UIApplication or UIScene.
 *
 *  @discussion It is highly recommended to construct this class on the main thread.
 *  When the tracker is constructed off the main thread, this property is eventually consistent with the state of the user interface, otherwise it is updated immediately.
 */
@property (nonatomic, assign, readonly) CGFloat rotationAngle;

/**
 *  @brief The scene that is being monitored for orientation changes.
 *
 *  @discussion If `+[TVIUserInterfaceTracker sceneInterfaceOrientationDidChange:]` is called, and the scene provided matches this property, then the Tracker
 *  will read an updated orientation from the scene.
 */
@property (nonatomic, weak, readonly, nullable) UIWindowScene *scene API_AVAILABLE(ios(13.0));

/**
 *  @brief Creates a default `TVIUserInterfaceTracker` that monitors `UIApplication` for orientation changes.
 *
 *  @return An instance of `TVIUserInterfaceTracker`.
 */
+ (nonnull instancetype)tracker;

/**
 *  @brief Creates a `TVIUserInterfaceTracker` that monitors a `UIWindowScene` for orientation changes.
 *
 *  @param scene The scene that should be monitored for orientation changes.
 *
 *  @return An instance of `TVIUserInterfaceTracker`.
 *
 *  @see +[TVIUserInterfaceTracker sceneInterfaceOrientationDidChange:]
 */
+ (nonnull instancetype)trackerWithScene:(nonnull UIWindowScene *)scene API_AVAILABLE(ios(13.0));

/**
 *  @brief Informs interested `TVIUserInterfaceTracker` instances that the orientation of a `UIWindowScene` has changed.
 *
 *  @param scene The scene that has changed.
 *
 *  @discussion If you created a tracker using `+[TVIUserInterfaceTracker trackerWithScene:]` then you should call this method within
 *  `-[UIWindowSceneDelegate windowScene:didUpdateCoordinateSpace:interfaceOrientation:traitCollection:]`
 */
+ (void)sceneInterfaceOrientationDidChange:(nonnull UIWindowScene *)scene API_AVAILABLE(ios(13.0));

@end
