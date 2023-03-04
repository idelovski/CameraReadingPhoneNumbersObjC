/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Application preview view
*/

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PreviewView : UIView

- (AVCaptureVideoPreviewLayer*)videoPreviewLayer;
- (AVCaptureSession*)session;
- (void)setSession:(AVCaptureSession *)session;

@end


#ifdef _NIJE_
import UIKit
import AVFoundation

class PreviewView: UIView {
	var videoPreviewLayer: AVCaptureVideoPreviewLayer {
		guard let layer = layer as? AVCaptureVideoPreviewLayer else {
			fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
		}
		
		return layer
	}
	
	var session: AVCaptureSession? {
		get {
			return videoPreviewLayer.session
		}
		set {
			videoPreviewLayer.session = newValue
		}
	}
	
	// MARK: UIView
	
	override class var layerClass: AnyClass {
		return AVCaptureVideoPreviewLayer.self
	}
}
#endif
