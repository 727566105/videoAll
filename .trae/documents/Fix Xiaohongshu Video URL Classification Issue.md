## Problem Analysis
The issue is that Xiaohongshu video URLs are being incorrectly classified as images instead of videos. This happens because:

1. **Root Cause**: In the Python SDK's `_determine_media_type` method (`/media_parser_sdk/media_parser_sdk/platforms/xiaohongshu.py`), the logic only returns VIDEO type if:
   ```python
   if download_urls.video and not download_urls.images:
       return MediaType.VIDEO
   ```

2. **Why this fails**: Xiaohongshu video posts always have both video URLs AND image URLs (for the video cover), so this condition is never met, causing all posts to be classified as images.

3. **Impact**: The frontend displays image components instead of video players for Xiaohongshu videos.

## Solution
1. **Fix the media type determination logic** in `XiaohongshuParser._determine_media_type()` to prioritize VIDEO when video URLs are present, regardless of image URLs
2. **Update the logic** to:
   - Return VIDEO if `download_urls.video` has any URLs
   - Fall back to IMAGE if only images exist
   - Maintain LIVE_PHOTO detection
3. **No changes needed in frontend** - it already correctly handles video display when `media_type` is 'video'

## Implementation Steps
1. Modify `_determine_media_type` method in `/media_parser_sdk/media_parser_sdk/platforms/xiaohongshu.py`
2. Test the fix to ensure videos are correctly classified
3. Verify that frontend displays video player for Xiaohongshu videos
4. Ensure existing functionality still works correctly