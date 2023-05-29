/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Vision view controller.
			Recognizes text using a Vision VNRecognizeTextRequest request handler in pixel buffers from an AVCaptureOutput.
			Displays bounding boxes around recognized text results in real time.
*/

#import "VisionViewController.h"

@implementation  VisionViewController

- (void)viewDidLoad
{
   __weak  typeof(self)    weakSelf = self;
   // Set up vision request before letting ViewController set up the camera
   // so that it exists when the first buffer is received.
   self.numberTracker = [[StringTracker alloc] init];
   self.boxLayers = [NSMutableArray array];
   
   self.ocrRequest = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest *request, NSError *error)  {
      [weakSelf recognizeTextHandler:request error:error];
   }];
   
   [super viewDidLoad];
   
   // if (self.previewView)
   //    NSLog (@"What is this?");
}

// void  (^recognizeTextHandler) (VNRequest *request, NSError *error) = ^(VNRequest *request, NSError *error)
- (void)recognizeTextHandler:(VNRequest *)request error:(NSError *)error
{
   NSMutableArray  *numbers = [NSMutableArray array];  // var numbers = [String]()
   NSMutableArray  *redBoxes = [NSMutableArray array];  // var redBoxes = [CGRect]() // Shows all recognized text lines
   NSMutableArray  *greenBoxes = [NSMutableArray array];  // var greenBoxes = [CGRect]() // Shows words that might be serials
   
   if (![request isKindOfClass:[VNRecognizeTextRequest class]])  {
      NSLog (@"Wrong!");
      return;
   }
   
   VNRecognizeTextRequest  *textRequests = (VNRecognizeTextRequest *)request;
      
   int    maximumCandidates = 1;
   BOOL   numberIsSubstring = YES;
   
   for (id rawResult in textRequests.results)  {
      if ([rawResult isKindOfClass:[VNRecognizedTextObservation class]])  {
         VNRecognizedTextObservation  *textObservation = (VNRecognizedTextObservation *)rawResult;
         NSArray<VNRecognizedText *>  *candidate = [textObservation topCandidates:maximumCandidates];
         
         if (candidate.count)  {
            NSRange    range;
            NSError   *bError;
            NSString  *numberStr = [candidate.firstObject.string extractPhoneNumber:&range];
            
            if (numberStr)  {
               VNRecognizedText  *recText = [candidate objectAtIndex:0];
               
               VNRectangleObservation  *boundingObservation = [recText boundingBoxForRange:range
                                                                                       error:&bError];
               CGRect  box = boundingObservation.boundingBox;

               NSLog (@"Green Box: %@", NSStringFromCGRect(boundingObservation.boundingBox)); 
               
               [numbers addObject:numberStr];
               [greenBoxes addObject:[NSValue valueWithCGRect:box]];
               
               numberIsSubstring = !(range.location == 0 && (range.location+range.length) == numberStr.length);
            }
         }
         if (numberIsSubstring)  {
            NSLog (@"Red Box: %@", NSStringFromCGRect(textObservation.boundingBox)); 
            [redBoxes addObject:[NSValue valueWithCGRect:textObservation.boundingBox]];
         }
      }
   }

   // Log any found numbers.
   [self.numberTracker logFrameStrings:numbers];

   [self showRedBoxes:redBoxes
        andGreenBoxes:greenBoxes];
   // show(boxGroups: [(color: UIColor.red.cgColor, boxes: redBoxes), (color: UIColor.green.cgColor, boxes: greenBoxes)])
   
   // Check if we have any temporally stable numbers.
   NSString  *sureNumber = [self.numberTracker getStableString];
   
   if (sureNumber)  {
      [self showString:sureNumber];
      [self.numberTracker resetString:sureNumber];
   }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
   NSError  *error;
   
   if (output == self.videoDataOutput)  {
      CVPixelBufferRef  pixelBuffer = CMSampleBufferGetImageBuffer (sampleBuffer); 
      
      if (pixelBuffer)  {
         // Configure for running in real-time.
         self.ocrRequest.recognitionLevel = VNRequestTextRecognitionLevelFast;
         // Language correction won't help recognizing phone numbers. It also
         // makes recognition slower.
         self.ocrRequest.usesLanguageCorrection = NO;
         // Only run on the region of interest for maximum speed.
         self.ocrRequest.regionOfInterest = self.ocrRegionOfInterest;
         
         VNImageRequestHandler  *requestHandler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:pixelBuffer
                                                                                           orientation:self.textOrientation
                                                                                               options:[NSDictionary dictionary]];
         if (![requestHandler performRequests:@[self.ocrRequest] error:&error] && error)
            NSLog (@"%@", error);
      }
   }
}

// MARK: - Bounding box drawing

// Draw a box on screen. Must be called from main queue.

- (void)drawRect:(CGRect)rect color:(CGColorRef)color
{
   CAShapeLayer  *layer = [CAShapeLayer layer];
   
   layer.opacity = 0.5;
   layer.borderColor = color;
   layer.borderWidth = 1.;
   layer.frame = rect;
   
   [self.boxLayers addObject:layer];
   
   [self.previewView.videoPreviewLayer insertSublayer:layer atIndex:1];
}

// Remove all drawn boxes. Must be called on main queue.
- (void)removeBoxes
{
   for (CAShapeLayer *layer in self.boxLayers)
      [layer removeFromSuperlayer];
   
   [self.boxLayers removeAllObjects];
}

- (void)showRedBoxes:(NSArray *)redBoxes andGreenBoxes:(NSArray *)greenBoxes
{
   dispatch_async (dispatch_get_main_queue(), ^{
      AVCaptureVideoPreviewLayer  *layer = self.previewView.videoPreviewLayer;
      CGRect                       box;
      
      [self removeBoxes];
      
      for (int i=0; i<redBoxes.count; i++)  {
         box = [[redBoxes objectAtIndex:i] CGRectValue];
         box = CGRectApplyAffineTransform (box, self.visionToAVFTransform);
      
         CGRect  rect = [layer rectForMetadataOutputRectOfInterest:box];  // box.applying(self.visionToAVFTransform)
         [self drawRect:rect color:[UIColor redColor].CGColor];
      }
      for (int i=0; i<greenBoxes.count; i++)  {
         box = [[greenBoxes objectAtIndex:i] CGRectValue];
         box = CGRectApplyAffineTransform (box, self.visionToAVFTransform);
         
         CGRect  rect = [layer rectForMetadataOutputRectOfInterest:box];  // box.applying(self.visionToAVFTransform)
         [self drawRect:rect color:[UIColor greenColor].CGColor];
      }
   });
}

@end

#ifdef _NIJE_

import Foundation
import UIKit
import AVFoundation
import Vision

class VisionViewController: ViewController {
	var request: VNRecognizeTextRequest!
	// Temporal string tracker
	let numberTracker = StringTracker()
	
	override func viewDidLoad() {
		// Set up vision request before letting ViewController set up the camera
		// so that it exists when the first buffer is received.
		request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)

		super.viewDidLoad()
	}
	
	// MARK: - Text recognition
	
	// Vision recognition handler.
	func recognizeTextHandler(request: VNRequest, error: Error?) {
		var numbers = [String]()
		var redBoxes = [CGRect]() // Shows all recognized text lines
		var greenBoxes = [CGRect]() // Shows words that might be serials
		
		guard let results = request.results as? [VNRecognizedTextObservation] else {
			return
		}
		
		let maximumCandidates = 1
		
		for visionResult in results {
			guard let candidate = visionResult.topCandidates(maximumCandidates).first else { continue }
			
			// Draw red boxes around any detected text, and green boxes around
			// any detected phone numbers. The phone number may be a substring
			// of the visionResult. If a substring, draw a green box around the
			// number and a red box around the full string. If the number covers
			// the full result only draw the green box.
			var numberIsSubstring = true
			
			if let result = candidate.string.extractPhoneNumber() {
				let (range, number) = result
				// Number may not cover full visionResult. Extract bounding box
				// of substring.
				if let box = try? candidate.boundingBox(for: range)?.boundingBox {
					numbers.append(number)
					greenBoxes.append(box)
					numberIsSubstring = !(range.lowerBound == candidate.string.startIndex && range.upperBound == candidate.string.endIndex)
				}
			}
			if numberIsSubstring {
				redBoxes.append(visionResult.boundingBox)
			}
		}
		
		// Log any found numbers.
		numberTracker.logFrame(strings: numbers)
		show(boxGroups: [(color: UIColor.red.cgColor, boxes: redBoxes), (color: UIColor.green.cgColor, boxes: greenBoxes)])
		
		// Check if we have any temporally stable numbers.
		if let sureNumber = numberTracker.getStableString() {
			showString(string: sureNumber)
			numberTracker.reset(string: sureNumber)
		}
	}
	
	override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
			// Configure for running in real-time.
			request.recognitionLevel = .fast
			// Language correction won't help recognizing phone numbers. It also
			// makes recognition slower.
			request.usesLanguageCorrection = false
			// Only run on the region of interest for maximum speed.
			request.regionOfInterest = regionOfInterest
			
			let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: textOrientation, options: [:])
			do {
				try requestHandler.perform([request])
			} catch {
				print(error)
			}
		}
	}
	
	// MARK: - Bounding box drawing
	
	// Draw a box on screen. Must be called from main queue.
	var boxLayer = [CAShapeLayer]()
	func draw(rect: CGRect, color: CGColor) {
		let layer = CAShapeLayer()
		layer.opacity = 0.5
		layer.borderColor = color
		layer.borderWidth = 1
		layer.frame = rect
		boxLayer.append(layer)
		previewView.videoPreviewLayer.insertSublayer(layer, at: 1)
	}
	
	// Remove all drawn boxes. Must be called on main queue.
	func removeBoxes() {
		for layer in boxLayer {
			layer.removeFromSuperlayer()
		}
		boxLayer.removeAll()
	}
	
	typealias ColoredBoxGroup = (color: CGColor, boxes: [CGRect])
	
	// Draws groups of colored boxes.
	func show(boxGroups: [ColoredBoxGroup]) {
		DispatchQueue.main.async {
			let layer = self.previewView.videoPreviewLayer
			self.removeBoxes()
			for boxGroup in boxGroups {
				let color = boxGroup.color
				for box in boxGroup.boxes {
					let rect = layer.layerRectConverted(fromMetadataOutputRect: box.applying(self.visionToAVFTransform))
					self.draw(rect: rect, color: color)
				}
			}
		}
	}
}
#endif

