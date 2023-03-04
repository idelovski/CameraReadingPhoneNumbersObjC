/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Application preview view
*/

#import "PreviewView.h"


@implementation PreviewView

// Returns the class used to create the layer for instances of this class.

- (AVCaptureVideoPreviewLayer*)videoPreviewLayer;
{
   return ((AVCaptureVideoPreviewLayer *)self.layer);
}

+ (Class)layerClass
{
   return ([AVCaptureVideoPreviewLayer class]);
}

- (AVCaptureSession*)session
{
   return ([(AVCaptureVideoPreviewLayer*)self.layer session]);
}

- (void)setSession:(AVCaptureSession *)session
{
   [(AVCaptureVideoPreviewLayer*)self.layer setSession:session];
}

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

