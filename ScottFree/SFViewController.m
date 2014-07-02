//
//  SFViewController.m
//  ScottFree
//
//  Created by Joel Glovacki on 6/29/14.
//  Copyright (c) 2014 Company B. All rights reserved.
//

#import "SFViewController.h"
#import "CIFilter+LUT.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "SFViewController.h"
#import "UIImage+Resize.h"
#import "ZFModalTransitionAnimator.h"
#import "SFModalViewController.h"
static void * CapturingStillImageContext = &CapturingStillImageContext;
static void * SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

@interface SFViewController () <AVCaptureFileOutputRecordingDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) NSArray *filters;
@property (strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) NSData *originalPhotoImageData;
@property (strong, nonatomic) UIImage *originalPhoto;

@property int countdown;
@property NSTimer *timer;

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureStillImageOutput *stillImageOutput;

@property (nonatomic, strong) ZFModalTransitionAnimator *animator;

// Utilities.
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic) id runtimeErrorHandlingObserver;

@property (nonatomic, strong) UIDocumentInteractionController *docController;

@end

@implementation SFViewController


- (BOOL)isSessionRunningAndDeviceAuthorized
{
    return [[self session] isRunning] && [self isDeviceAuthorized];
}

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized
{
    return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    _countdown = 3;
    
    //_filters = @[@"Anime", @"Brannan", @"Blue-Brown", @"Blue-Orange",  @"Cobalt-Crimson", @"Crimson-Clover", @"Decrease", @"Earlybird", @"Gold-Blue", @"Gold-Crimson", @"Gotham", @"Hefe",@"Increase",@"Inkwell",@"Lomo-fi",@"Lord-Kelvin",@"Nashville",@"Red-Blue-Yellow",@"Smokey",@"Sutro",@"Teal-Magenta-Gold",@"Toaster",@"Walden",@"X-Pro-II",@"Grimes",@"Lucille",@"Romero",@"None"];
        

    _filters = @[@"None", @"Nashville", @"Gotham", @"Inkwell", @"Grimes", @"Lucille", @"Earlybird", @"Lord-Kelvin", @"X-Pro-II", @"Brannan", @"Hefe"];

    
    
    [self.filterView setContentSize:CGSizeMake(193,[_filters count] * 187)];
    


    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [self setSession:session];
    [[self previewView] setSession:session];
    [self checkDeviceAuthorizationStatus];
    
    
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    [self setSessionQueue:sessionQueue];
    
    dispatch_async(sessionQueue, ^{
        [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
        
        NSError *error = nil;
        
        AVCaptureDevice *videoDevice = [SFViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionFront];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        
        if (error){NSLog(@"%@", error);}
        
        if ([session canAddInput:videoDeviceInput]){
            [session addInput:videoDeviceInput];
            [self setVideoDeviceInput:videoDeviceInput];
            
            dispatch_async(dispatch_get_main_queue(), ^{
    
                [[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)[self interfaceOrientation]];
                
                [(AVCaptureVideoPreviewLayer *)[[self previewView] layer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
                
                [(AVCaptureVideoPreviewLayer *)[[self previewView] layer] setFrame:CGRectMake(0, 256, 768, 768)];
                
                //_previewView.frame = CGRectMake(0, 256, 768, 768);
                
                //[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setAutomaticallyAdjustsVideoMirroring:NO];
                //[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoMirrored:NO];
                
                
            });
        }
        
        AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
        AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        
        if (error){NSLog(@"%@", error);}
        
        if ([session canAddInput:audioDeviceInput]){
            [session addInput:audioDeviceInput];
        }
    
        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        if ([session canAddOutput:stillImageOutput]){
            [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
            [session addOutput:stillImageOutput];
            [self setStillImageOutput:stillImageOutput];
        }
    });
    
    
    
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}













- (void)viewWillAppear:(BOOL)animated
{
    dispatch_async([self sessionQueue], ^{
        [self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:SessionRunningAndDeviceAuthorizedContext];
        [self addObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:CapturingStillImageContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
        
        __weak SFViewController *weakSelf = self;
        [self setRuntimeErrorHandlingObserver:[[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification object:[self session] queue:nil usingBlock:^(NSNotification *note) {
            SFViewController *strongSelf = weakSelf;
            dispatch_async([strongSelf sessionQueue], ^{
                // Manually restarting the session since it must have been stopped due to an error.
                [[strongSelf session] startRunning];
            });
        }]];
        [[self session] startRunning];
    });
}

- (void)viewDidDisappear:(BOOL)animated
{
    dispatch_async([self sessionQueue], ^{
        [[self session] stopRunning];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
        [[NSNotificationCenter defaultCenter] removeObserver:[self runtimeErrorHandlingObserver]];
        
        [self removeObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized" context:SessionRunningAndDeviceAuthorizedContext];
        [self removeObserver:self forKeyPath:@"stillImageOutput.capturingStillImage" context:CapturingStillImageContext];
    });
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotate
{
    // Disable autorotation of the interface when recording is in progress.
    return ![self lockInterfaceRotation];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] setVideoOrientation:(AVCaptureVideoOrientation)toInterfaceOrientation];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == CapturingStillImageContext)
    {
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        
        if (isCapturingStillImage)
        {
            [self runStillImageCaptureAnimation];
        }
    }
    else if (context == SessionRunningAndDeviceAuthorizedContext)
    {
        BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isRunning)
            {
           
                [[self stillButton] setEnabled:YES];
            }
            else
            {
                
                [[self stillButton] setEnabled:NO];
                
            }
        });
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Actions

- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{

    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)[[self previewView] layer] captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:[gestureRecognizer view]]];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake(.5, .5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

#pragma mark File Output Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (error)
        NSLog(@"%@", error);
    
    [self setLockInterfaceRotation:NO];
    
    // Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
    UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
    [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
    
    [[[ALAssetsLibrary alloc] init] writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        if (error)
            NSLog(@"%@", error);
        
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        
        if (backgroundRecordingID != UIBackgroundTaskInvalid)
            [[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
    }];
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async([self sessionQueue], ^{
        AVCaptureDevice *device = [[self videoDeviceInput] device];
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
            {
                [device setFocusMode:focusMode];
                [device setFocusPointOfInterest:point];
            }
            if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
            {
                [device setExposureMode:exposureMode];
                [device setExposurePointOfInterest:point];
            }
            [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
            [device unlockForConfiguration];
        }
        else
        {
            NSLog(@"%@", error);
        }
    });
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ([device hasFlash] && [device isFlashModeSupported:flashMode])
    {
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            [device setFlashMode:flashMode];
            [device unlockForConfiguration];
        }
        else
        {
            NSLog(@"%@", error);
        }
    }
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

#pragma mark UI

- (void)runStillImageCaptureAnimation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[self previewView] layer] setOpacity:0.0];
        [UIView animateWithDuration:.25 animations:^{
            [[[self previewView] layer] setOpacity:1.0];
        }];
    });
}

- (void)checkDeviceAuthorizationStatus
{
    NSString *mediaType = AVMediaTypeVideo;
    
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (granted)
        {
            //Granted access to mediaType
            [self setDeviceAuthorized:YES];
        }
        else
        {
            //Not granted access to mediaType
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Selfie"
                                            message:@"Selfie doesn't have permission to use Camera, please change privacy settings"
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
                [self setDeviceAuthorized:NO];
            });
        }
    }];
}


-(void)revealFilters {
    [_sidebar setAlpha:1];
    [_sidebar setHidden:false];
    [_snapSidebar setAlpha:0];
    [_snapSidebar setHidden:true];
}
-(void)hideFilters {
    [_sidebar setAlpha:0];
    [_sidebar setHidden:true];
    [_snapSidebar setAlpha:1];
    [_snapSidebar setHidden:false];
}


-(void)onTick:(NSTimer *)timer {
    if (!_countdown){
        _countdown = 3;
        [self triggerShutter: nil];
        [_timer invalidate];
        _timer = nil;
        NSLog(@"boom!");
        [self revealFilters];
        [_stillButton setImage:[UIImage imageNamed:@"go.png"] forState:UIControlStateNormal];
        [_stillButton setUserInteractionEnabled:true];
    } else {
        [_stillButton setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%d.png",_countdown--]] forState:UIControlStateNormal];
        [self beep];
        NSLog(@"tick");
    }
}


- (IBAction)startCountdown:(UIButton *)sender {
    
    NSMethodSignature *sgn = [self methodSignatureForSelector:@selector(onTick:)];
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature: sgn];
    [inv setTarget: self];
    [inv setSelector:@selector(onTick:)];
    
    _timer = [NSTimer timerWithTimeInterval: 1.0 invocation:inv repeats:YES];

    NSRunLoop *runner = [NSRunLoop currentRunLoop];
    [runner addTimer: _timer forMode: NSDefaultRunLoopMode];
    
}



-(void)beep {
    NSString *path =[[NSBundle mainBundle] pathForResource:@"IKBeep" ofType:@"aiff"];
    NSURL *url = [NSURL fileURLWithPath:path];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:NULL];
    [_player setVolume:1.0];
    [_player play];
}


- (IBAction)triggerShutter:(UIButton *)sender {
    
    
    dispatch_async([self sessionQueue], ^{
        // Update the orientation on the still image output video connection before capturing.
        [[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] setVideoOrientation:[[(AVCaptureVideoPreviewLayer *)[[self previewView] layer] connection] videoOrientation]];
        
        // Flash set to Auto for Still Capture
        [SFViewController setFlashMode:AVCaptureFlashModeAuto forDevice:[[self videoDeviceInput] device]];
        
        __weak SFViewController *weakSelf = self;
        
        // Capture a still image.
        [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[[self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            
            SFViewController *strongSelf = weakSelf;
            
            if (imageDataSampleBuffer){
            
                strongSelf.originalPhotoImageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                
                UIImage *image = [[UIImage alloc] initWithData:strongSelf.originalPhotoImageData];
      
                image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(612,612) interpolationQuality:kCGInterpolationHigh];
                image = [image croppedImage:CGRectMake(0,256,612,612)];
                
                [weakSelf.yourPhoto setImage:image];
                
                
                

                image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(181,181) interpolationQuality:kCGInterpolationNone];
                
                //image = [image croppedImage:CGRectMake(0,0,181,181)];
                
                for (int i = 0; i < [_filters count]; i++){
                    
                    CIFilter *lutFilter = [CIFilter filterWithLUT:_filters[i] dimension:64];
                    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
                    [lutFilter setValue:ciImage forKey:@"inputImage"];
                    CIImage *outputImage = [lutFilter outputImage];
                    CIContext *context = [CIContext contextWithOptions:[NSDictionary dictionaryWithObject:(__bridge id)(CGColorSpaceCreateDeviceRGB()) forKey:kCIContextWorkingColorSpace]];
                    
                    UIImage *img = [UIImage imageWithCGImage:[context createCGImage:outputImage fromRect:outputImage.extent]];
                    
                    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                    [btn setContentMode:UIViewContentModeScaleAspectFill];
                    [btn setFrame: CGRectMake(6, i * 187 + 6, 181, 181)];
                    [btn setBackgroundColor: [UIColor whiteColor]];
                    [[btn imageView] setContentMode:UIViewContentModeScaleAspectFill];
                    [btn setImage:img forState:UIControlStateNormal];
                    
                    [btn setShowsTouchWhenHighlighted: true];
                    
                    btn.tag = i;
                    
                    [btn addTarget:weakSelf action:@selector(applyFilter:) forControlEvents:UIControlEventTouchUpInside];
                    
                    [weakSelf.filterView addSubview:btn];
                    
                    img = nil;
                    ciImage = nil;
                    outputImage = nil;
                    
                }
                
                [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error){

                    //saved!
                    
                    
            }];
            }
        }];
    });
    
}


- (void)applyFilter:(UIButton *)sender {

    //photo = [photo resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(193,193) interpolationQuality:kCGInterpolationNone];
    
    UIImage *original = [[UIImage alloc] initWithData:_originalPhotoImageData];

    original = [original resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(612,612) interpolationQuality:kCGInterpolationHigh];
    original = [original croppedImage:CGRectMake(0,256,612,612)];
    
    CIFilter *lutFilter = [CIFilter filterWithLUT:_filters[sender.tag] dimension:64];
    CIImage *ciImage = [[CIImage alloc] initWithImage:original];
    [lutFilter setValue:ciImage forKey:@"inputImage"];
    CIImage *outputImage = [lutFilter outputImage];
    CIContext *context = [CIContext contextWithOptions:[NSDictionary dictionaryWithObject:(__bridge id)(CGColorSpaceCreateDeviceRGB()) forKey:kCIContextWorkingColorSpace]];
    
    UIImage *img = [UIImage imageWithCGImage:[context createCGImage:outputImage fromRect:outputImage.extent]];
    _yourPhoto.image = img;
    
    original = nil;
    outputImage = nil;
    img = nil;

    
}


- (IBAction)takePhoto:(UIButton *)sender {
    [sender setUserInteractionEnabled:false];
    [self startCountdown: sender];
    
}



















- (void)killZombies {
    
}

- (IBAction)getStarted:(UIButton *)sender {
    [_intro setAlpha:0];
    [_intro setHidden:true];
}

- (IBAction)retakePhoto:(UIButton *)sender {
    [self killZombies];
    [self hideFilters];
}

- (IBAction)postAndSendPhoto:(UIButton *)sender {
    
    UIImage *instaImage = _yourPhoto.image;
    NSString *imagePath = [NSString stringWithFormat:@"%@/image.igo",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
    [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
    [UIImageJPEGRepresentation(instaImage,90) writeToFile:imagePath atomically:YES];
    
    
    SFModalViewController *modalVC = [self.storyboard instantiateViewControllerWithIdentifier:@"SFModalViewController"];
    modalVC.modalPresentationStyle = UIModalPresentationCustom;
    
    self.animator = [[ZFModalTransitionAnimator alloc] initWithModalViewController:modalVC];
    self.animator.dragable = YES;
    self.animator.bounces = YES;
    self.animator.behindViewAlpha = 0.5f;
    self.animator.behindViewScale = 0.8f;
    self.animator.direction = ZFModalTransitonDirectionBottom;
    
    modalVC.transitioningDelegate = self.animator;
    [self presentViewController:modalVC animated:YES completion:^(void){
        [modalVC.email becomeFirstResponder];
        //[self PostPhoto:sender];
    }];
    
}

- (IBAction)PostPhoto:(UIButton *)sender {

    UIImage *instaImage = _yourPhoto.image;
    NSString *imagePath = [NSString stringWithFormat:@"%@/image.igo",[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
    [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
    [UIImageJPEGRepresentation(instaImage,90) writeToFile:imagePath atomically:YES];
    NSLog(@"image size: %@", NSStringFromCGSize(instaImage.size));
    _docController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:imagePath]];
    _docController.UTI = @"com.instagram.exclusivegram";
    [_docController presentOpenInMenuFromRect:CGRectMake(126, 905, 5, 5) inView:self.view animated:YES];
    
}
@end
