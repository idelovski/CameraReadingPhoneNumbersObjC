/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utilities for dealing with recognized strings
*/

#import "StringUtils.h"

@implementation  NSString (PhoneNumbers)

- (NSString *)extractCurrencyValueRange:(NSRange *)retRange currency:(NSString *__autoreleasing*)retCurrency;
{
   // Do a first pass with original self
   // Then modify it with alternate characters since some digits look
   // very similar to letters.
   
   int   i, j, loop;
   char  tmpStr[256];
   char  srcChars[10] = { 's', 'S', 'o', 'Q', 'O', 'l', 'I', '|', 'G', 'B' };   
   char  tarChars[10] = { '5', '5', '0', '0', '0', '1', '1', '1', '6', '8' };
   
   // NSArray   *currencies = @[ @"KN", @"kn", @"Kn", @"kuna", @"kune", @"Kuna", @"Kune", @"EUR", @"Eur", @"eur", @"€" ];

   NSString  *testStr = self;
   // NSString  *pattern = @"^\\d{1,3}(?:.\\d{3})*\\,\\d{2}.*(KN|kn|Kn|kuna|kune|Kuna|Kune|EUR|Eur|eur|€)?";   
   NSString  *fullPattern = @"^\\d{1,3}(?:.\\d{3})*\\,\\d{2}.*(Kn|Kuna|Kune|EUR|€)?";   
   NSString  *currPattern = @"(Kn|Kuna|Kune|EUR|€)";   
   NSError   *error = NULL;
   
   NSLog (@"String test: %@", self);

   NSRegularExpression  *fullRegex = [NSRegularExpression regularExpressionWithPattern:fullPattern
                                                                           options:NSRegularExpressionCaseInsensitive 
                                                                             error:&error];
   // First, find the currency
   
   if (retCurrency)  {
      *retCurrency = nil;
      NSRegularExpression  *currRegex = [NSRegularExpression regularExpressionWithPattern:currPattern
                                                                                  options:NSRegularExpressionCaseInsensitive 
                                                                                    error:&error];
      
      if (!error && currRegex)  {
         [currRegex enumerateMatchesInString:testStr
                                     options:0
                                       range:NSMakeRange(0, [testStr length])
                                  usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)  {
            if (match.numberOfRanges)  {
               NSRange    mRange = [match rangeAtIndex:0];
               NSString  *matchString = [testStr substringWithRange:mRange];
               
               *retCurrency = matchString;
            }
         }];
      }
   }
   
   // Now, find the value
   
   for (loop=0; loop<3; loop++)  {   
      if ([fullRegex numberOfMatchesInString:testStr options:0 range:NSMakeRange(0, [testStr length])])  {
         NSLog (@"String [%d] OK: %@", loop+1, testStr);
         if (retRange)
            *retRange = NSMakeRange(0, [testStr length]);
         return (testStr);
      }

      snprintf (tmpStr, 256, "%s", [testStr UTF8String]);
      
      if (!loop)  {
         for (i=0; tmpStr[i] && i<128; i++)  {
            for (j=0; j<10; j++)  {
               if (tmpStr[i] == srcChars[j])
                  tmpStr[i] = tarChars[j];
            }
         }
      }
      else  {
         char  *perdPtr = NULL, *comaPtr = NULL;
         
         perdPtr = strchr (tmpStr, '.');
         comaPtr = strchr (tmpStr, ',');
         
         if (!comaPtr && perdPtr)  // 123.23
            *perdPtr = ',';
         else  if (comaPtr && perdPtr)  {
            if (comaPtr < perdPtr)  {
               *perdPtr = ',';
               *comaPtr = '.';
            }
         }
      }
      
      testStr = [NSString stringWithUTF8String:tmpStr];
   }
   
#ifdef _NIJE_
   NSString  *pattern = @""
   @"(?x)"               //  Verbose regex, allows comments
   @"(?:\\+1-?)?"            //  Potential international prefix, may have -
   @"[(]?"               // Potential opening (
   @"\b(\\w{3})"            // Capture xxx
   @"[)]?"               // Potential closing )
   @"[\\ -./]?"            // Potential separator
   @"(\\w{3})"               // Capture xxx
   @"[\\ -./]?"            // Potential separator
   @"(\\w{4})\b"            // Capture xxxx
   @"";
   
   NSLog (@"String: %@", self);
   
   NSRange  range = [self rangeOfString:pattern 
                                options:NSRegularExpressionSearch 
                                  range:NSMakeRange(0, [self length]) 
                                 locale:nil];
   
   if (range.location == NSNotFound)
      return (nil);

   NSMutableString  *phoneNumberDigits = [NSMutableString stringWithString:@""];
   NSString         *substring = [self substringWithRange:range];
   NSError          *error = nil;
   
   // let nsrange = NSRange(substring.startIndex..., in: substring)  -> converting to nsrange

   NSRegularExpression  *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             /*range:range*/
                                                                             error:&error];
   if (!error && regex)
      [regex enumerateMatchesInString:substring
                              options:0
                                range:NSMakeRange(0, [substring length])
                           usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)  {
                              for (int ridx=0; ridx<match.numberOfRanges; ridx++)  {
                                 NSRange    mRange = [match rangeAtIndex:ridx];
                                 NSString  *matchString = [substring substringWithRange:mRange];
                                 
                                 [phoneNumberDigits appendString:matchString];
                              }
                           }]; 
     
   if (phoneNumberDigits.length < 2)
      return (nil);
   
   NSString  *allowedChars = @"0123456789";
   
   for (int i = 0; i < [phoneNumberDigits length]; ++i) {
      NSString  *subString1 = [phoneNumberDigits substringWithRange:NSMakeRange(i, 1)];
      
      NSString  *subString2 = getSimilarCharacterIfNotInAllowedChars (subString1, allowedChars);
      
      if (subString2 && (![subString1 isEqualToString:subString2]))
         phoneNumberDigits = [[phoneNumberDigits stringByReplacingCharactersInRange:NSMakeRange(i, 1) 
                                                    withString:subString2] mutableCopy];
      else  if (!subString2)
         return (nil);
   }
   
   if (retRange)
      *retRange = range;
   
   return (phoneNumberDigits);
#endif
   return (nil);
}
   
@end

#pragma mark -

@implementation  StringTracker

- (id)init
{
   if ([super init])  {
      self.seenStrings = [NSMutableDictionary dictionary];
      self.frameIndex = 0;
      self.bestCount = 0;
      self.bestString = @"";
   }
   
   return (self);
}

- (void)logFrameStrings:(NSArray<NSString *> *)strings
{
   NSValue           *value = nil;
   StringObservation  observation;

   for (NSString  *string in strings)  {
      NSLog (@"String %@ searching key!", string);
      value = [self.seenStrings objectForKey:string];

      if (!value)  {
         NSLog (@"NOT FOUND! %@ in dictionary of %d elements!", string, (int)self.seenStrings.count);
         observation.count = 0;
      }
      else  {
         [value getValue:&observation];
      }
      observation.lastSeen = self.frameIndex;
      observation.count++;

      value = [NSValue value:&observation withObjCType:@encode(StringObservation)]; 
      [self.seenStrings setObject:value forKey:string];

      NSLog (@"Seen %@ %d times, set into dic of %d elements.", string, observation.count, (int)self.seenStrings.count);
   }
   
   NSMutableArray<NSString *> *obsoleteStrings = [NSMutableArray array];
   
   for (NSString  *string in self.seenStrings.allKeys)  {
      NSValue           *value = [self.seenStrings objectForKey:string];
      StringObservation  observation;
      
      [value getValue:&observation];
      
      if (observation.lastSeen < self.frameIndex - 50)  {
         NSLog (@"Removing %@, last seen: %d and frameIndex is: %d", string, observation.lastSeen, self.frameIndex);
         [obsoleteStrings addObject:string];
      }
      
      int  count = observation.count;

      if (![obsoleteStrings containsObject:string] && (count > self.bestCount))  {
         self.bestCount = count;
         self.bestString = string;
      }
   }
   
   for (NSString *string in obsoleteStrings)
      [self.seenStrings removeObjectForKey:string];
   
   self.frameIndex += 1;
}

- (NSString *)getStableString
{
   if (self.bestCount >= 6)
      return (self.bestString);

   return (nil);
}

- (void)resetString:(NSString *)string
{
   [self.seenStrings removeObjectForKey:string];
   
   self.bestCount = 0;
   self.bestString = @"";
}

@end

NSString  *getSimilarCharacterIfNotInAllowedChars (NSString *chString, NSString *allowedChars)
{
   NSDictionary  *conversionTable = @{
                                      // @"s": @"S",
                                      @"s": @"5",
                                      @"S": @"5",
                                      // @"5": @"S",
                                      @"o": @"0",
                                      @"Q": @"0",
                                      @"O": @"0",
                                      // @"0": @"O",
                                      @"l": @"1",
                                      @"I": @"1",
                                      @"|": @"1",
                                      // @"1": @"I",
                                      @"G": @"6",
                                      @"B": @"8",
                                      // @"8": @"B"
                                      };
   
   for (int i=0; i<allowedChars.length; i++)  {
      if ([allowedChars containsString:chString])
         return (chString);
      NSString  *replacement = [conversionTable objectForKey:chString];
      
      if (replacement)
         return (replacement);
   }
   
   return (nil);
}

#ifdef _NIJE_
import Foundation

extension Character {
	// Given a list of allowed characters, try to convert self to those in list
	// if not already in it. This handles some common misclassifications for
	// characters that are visually similar and can only be correctly recognized
	// with more context and/or domain knowledge. Some examples (should be read
	// in Menlo or some other font that has different symbols for all characters):
	// 1 and l are the same character in Times New Roman
	// I and l are the same character in Helvetica
	// 0 and O are extremely similar in many fonts
	// oO, wW, cC, sS, pP and others only differ by size in many fonts
	func getSimilarCharacterIfNotIn(allowedChars: String) -> Character {
		let conversionTable = [
			"s": "S",
			"S": "5",
			"5": "S",
			"o": "O",
			"Q": "O",
			"O": "0",
			"0": "O",
			"l": "I",
			"I": "1",
			"1": "I",
			"B": "8",
			"8": "B"
		]
		// Allow a maximum of two substitutions to handle 's' -> 'S' -> '5'.
		let maxSubstitutions = 2
		var current = String(self)
		var counter = 0
		while !allowedChars.contains(current) && counter < maxSubstitutions {
			if let altChar = conversionTable[current] {
				current = altChar
				counter += 1
			} else {
				// Doesn't match anything in our table. Give up.
				break
			}
		}
		
		return current.first!
	}
}

extension String {
	// Extracts the first US-style phone number found in the string, returning
	// the range of the number and the number itself as a tuple.
	// Returns nil if no number is found.
	func extractPhoneNumber() -> (Range<String.Index>, String)? {
		// Do a first pass to find any substring that could be a US phone
		// number. This will match the following common patterns and more:
		// xxx-xxx-xxxx
		// xxx xxx xxxx
		// (xxx) xxx-xxxx
		// (xxx)xxx-xxxx
		// xxx.xxx.xxxx
		// xxx xxx-xxxx
		// xxx/xxx.xxxx
		// +1-xxx-xxx-xxxx
		// Note that this doesn't only look for digits since some digits look
		// very similar to letters. This is handled later.
		let pattern = #"""
		(?x)					# Verbose regex, allows comments
		(?:\+1-?)?				# Potential international prefix, may have -
		[(]?					# Potential opening (
		\b(\w{3})				# Capture xxx
		[)]?					# Potential closing )
		[\ -./]?				# Potential separator
		(\w{3})					# Capture xxx
		[\ -./]?				# Potential separator
		(\w{4})\b				# Capture xxxx
		"""#
		
		guard let range = self.range(of: pattern, options: .regularExpression, range: nil, locale: nil) else {
			// No phone number found.
			return nil
		}
		
		// Potential number found. Strip out punctuation, whitespace and country
		// prefix.
		var phoneNumberDigits = ""
		let substring = String(self[range])
		let nsrange = NSRange(substring.startIndex..., in: substring)
		do {
			// Extract the characters from the substring.
			let regex = try NSRegularExpression(pattern: pattern, options: [])
			if let match = regex.firstMatch(in: substring, options: [], range: nsrange) {
				for rangeInd in 1 ..< match.numberOfRanges {
					let range = match.range(at: rangeInd)
					let matchString = (substring as NSString).substring(with: range)
					phoneNumberDigits += matchString as String
				}
			}
		} catch {
			print("Error \(error) when creating pattern")
		}
		
		// Must be exactly 10 digits.
		guard phoneNumberDigits.count == 10 else {
			return nil
		}
		
		// Substitute commonly misrecognized characters, for example: 'S' -> '5' or 'l' -> '1'
		var result = ""
		let allowedChars = "0123456789"
		for var char in phoneNumberDigits {
			char = char.getSimilarCharacterIfNotIn(allowedChars: allowedChars)
			guard allowedChars.contains(char) else {
				return nil
			}
			result.append(char)
		}
		return (range, result)
	}
}

class StringTracker {
	var frameIndex: Int64 = 0

	typealias StringObservation = (lastSeen: Int64, count: Int64)
	
	// Dictionary of seen strings. Used to get stable recognition before
	// displaying anything.
	var seenStrings = [String: StringObservation]()
	var bestCount = Int64(0)
	var bestString = ""

	func logFrame(strings: [String]) {
		for string in strings {
			if seenStrings[string] == nil {
				seenStrings[string] = (lastSeen: Int64(0), count: Int64(-1))
			}
			seenStrings[string]?.lastSeen = frameIndex
			seenStrings[string]?.count += 1
			print("Seen \(string) \(seenStrings[string]?.count ?? 0) times")
		}
	
		var obsoleteStrings = [String]()

		// Go through strings and prune any that have not been seen in while.
		// Also find the (non-pruned) string with the greatest count.
		for (string, obs) in seenStrings {
			// Remove previously seen text after 30 frames (~1s).
			if obs.lastSeen < frameIndex - 30 {
				obsoleteStrings.append(string)
			}
			
			// Find the string with the greatest count.
			let count = obs.count
			if !obsoleteStrings.contains(string) && count > bestCount {
				bestCount = Int64(count)
				bestString = string
			}
		}
		// Remove old strings.
		for string in obsoleteStrings {
			seenStrings.removeValue(forKey: string)
		}
		
		frameIndex += 1
	}
	
	func getStableString() -> String? {
		// Require the recognizer to see the same string at least 10 times.
		if bestCount >= 10 {
			return bestString
		} else {
			return nil
		}
	}
	
	func reset(string: String) {
		seenStrings.removeValue(forKey: string)
		bestCount = 0
		bestString = @""
	}
}
#endif
      
