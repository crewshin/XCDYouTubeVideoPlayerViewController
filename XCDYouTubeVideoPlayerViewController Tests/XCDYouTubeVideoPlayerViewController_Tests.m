//
//  XCDYouTubeVideoPlayerViewController_Tests.m
//  XCDYouTubeVideoPlayerViewController Tests
//
//  Created by Cédric Luthi on 11.01.14.
//  Copyright (c) 2014 Cédric Luthi. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TRVSMonitor.h"
#import "XCDYouTubeVideoPlayerViewController.h"

@interface XCDYouTubeVideoPlayerViewController_Tests : XCTestCase

@property TRVSMonitor *monitor;

@end

@implementation XCDYouTubeVideoPlayerViewController_Tests

+ (void) initialize
{
	if (self != [XCDYouTubeVideoPlayerViewController_Tests class])
		return;
	
	// See http://stackoverflow.com/questions/21069515/avurlasset-isplayableextendedmimetype-behaves-differently-when-unit-tested/21081159#21081159
	setenv("IPHONE_SIMULATOR_CLASS", "N41", 0);
}

- (void) setUp
{
	[super setUp];
	self.monitor = [TRVSMonitor new];
}

- (void) tearDown
{
	self.monitor = nil;
	[super tearDown];
}

- (void) testThatGangnamStyleVideoHasURL
{
	XCDYouTubeVideoPlayerViewController *videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:@"9bZkp7q19f0"];
	[videoPlayerViewController addObserver:self forKeyPath:@"moviePlayer.contentURL" options:(NSKeyValueObservingOptions)0 context:_cmd];
	XCTAssertTrue([self.monitor waitWithTimeout:10], @"");
	XCTAssertNotNil(videoPlayerViewController.moviePlayer.contentURL, @"");
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == @selector(testThatGangnamStyleVideoHasURL))
	{
		[self.monitor signal];
		[object removeObserver:self forKeyPath:keyPath context:context];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void) testThatGangnamStyleVideoHasMetadata
{
	XCDYouTubeVideoPlayerViewController *videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:@"9bZkp7q19f0"];
	[[NSNotificationCenter defaultCenter] addObserverForName:XCDYouTubeVideoPlayerViewControllerDidReceiveMetadataNotification object:videoPlayerViewController queue:nil usingBlock:^(NSNotification *notification) {
		NSDictionary *metadata = notification.userInfo;
		XCTAssertEqualObjects(metadata[XCDMetadataKeyTitle], @"PSY - GANGNAM STYLE (\U0000ac15\U0000b0a8\U0000c2a4\U0000d0c0\U0000c77c) M/V", @"");
		XCTAssertTrue([metadata[XCDMetadataKeySmallThumbnailURL] isKindOfClass:[NSURL class]], @"Small thumbnail URL must be a NSURL");
		XCTAssertTrue([metadata[XCDMetadataKeyMediumThumbnailURL] isKindOfClass:[NSURL class]], @"Medium thumbnail URL must be a NSURL");
		XCTAssertTrue([metadata[XCDMetadataKeyLargeThumbnailURL] isKindOfClass:[NSURL class]], @"Large thumbnail URL must be a NSURL");
		[self.monitor signal];
	}];
	XCTAssertTrue([self.monitor waitWithTimeout:10], @"");
}

- (void) testThatGangnamStyleVideoStartsPlaying
{
	XCDYouTubeVideoPlayerViewController *videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:@"9bZkp7q19f0"];
	[[NSNotificationCenter defaultCenter] addObserverForName:MPMoviePlayerPlaybackStateDidChangeNotification object:videoPlayerViewController.moviePlayer queue:nil usingBlock:^(NSNotification *notification) {
		XCTAssertEqual(videoPlayerViewController.moviePlayer.playbackState, MPMoviePlaybackStatePlaying, @"");
		[self.monitor signal];
	}];
	XCTAssertTrue([self.monitor waitWithTimeout:10], @"");
}

- (void) testRestrictedVideo
{
	XCDYouTubeVideoPlayerViewController *videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:@"1kIsylLeHHU"];
	[[NSNotificationCenter defaultCenter] addObserverForName:MPMoviePlayerPlaybackDidFinishNotification object:videoPlayerViewController.moviePlayer queue:nil usingBlock:^(NSNotification *notification) {
		MPMovieFinishReason finishReason = [notification.userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
		XCTAssertEqual(finishReason, MPMovieFinishReasonPlaybackError, @"");
		NSError *error = notification.userInfo[XCDMoviePlayerPlaybackDidFinishErrorUserInfoKey];
		XCTAssertEqualObjects(error.domain, XCDYouTubeVideoErrorDomain, @"");
		XCTAssertEqual(error.code, XCDYouTubeErrorRestrictedPlayback, @"");
		[self.monitor signal];
	}];
	XCTAssertTrue([self.monitor waitWithTimeout:10], @"");
}

- (void) testRemovedVideo
{
	XCDYouTubeVideoPlayerViewController *videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:@"BXnA9FjvLSU"];
	[[NSNotificationCenter defaultCenter] addObserverForName:MPMoviePlayerPlaybackDidFinishNotification object:videoPlayerViewController.moviePlayer queue:nil usingBlock:^(NSNotification *notification) {
		MPMovieFinishReason finishReason = [notification.userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];
		XCTAssertEqual(finishReason, MPMovieFinishReasonPlaybackError, @"");
		NSError *error = notification.userInfo[XCDMoviePlayerPlaybackDidFinishErrorUserInfoKey];
		XCTAssertEqualObjects(error.domain, XCDYouTubeVideoErrorDomain, @"");
		XCTAssertEqual(error.code, XCDYouTubeErrorRemovedVideo, @"");
		[self.monitor signal];
	}];
	XCTAssertTrue([self.monitor waitWithTimeout:10], @"");
}

- (void) testAsynchronousVideoIdentifier
{
	XCDYouTubeVideoPlayerViewController *videoPlayerViewController = [XCDYouTubeVideoPlayerViewController new];
	[videoPlayerViewController performSelector:@selector(setVideoIdentifier:) withObject:@"9bZkp7q19f0" afterDelay:0];
	[[NSNotificationCenter defaultCenter] addObserverForName:MPMoviePlayerPlaybackStateDidChangeNotification object:videoPlayerViewController.moviePlayer queue:nil usingBlock:^(NSNotification *notification) {
		XCTAssertEqual(videoPlayerViewController.moviePlayer.playbackState, MPMoviePlaybackStatePlaying, @"");
		[self.monitor signal];
	}];
	XCTAssertTrue([self.monitor waitWithTimeout:10], @"");
}

@end