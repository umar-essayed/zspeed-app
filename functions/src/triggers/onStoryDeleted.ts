import { onDocumentDeleted } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import { getStorage } from "firebase-admin/storage";

/**
 * Fires when a story document is deleted in Firestore.
 * Automatically deletes the corresponding media file from Firebase Storage.
 */
export const onStoryDeleted = onDocumentDeleted("stories/{storyId}", async (event) => {
  const storyData = event.data?.data();
  if (!storyData) return;

  const mediaUrl: string | undefined = storyData.mediaUrl;
  if (!mediaUrl) return;

  try {
    const bucket = getStorage().bucket(); // Default bucket
    
    // Extract storage path from Firebase download URL:
    // https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<path>?alt=media
    const match = mediaUrl.match(/o\/(.+?)\?/);
    if (match && match[1]) {
      const storagePath = decodeURIComponent(match[1]);
      logger.info(`onStoryDeleted: Deleting file from storage: ${storagePath}`);
      const file = bucket.file(storagePath);
      await file.delete();
      logger.info(`onStoryDeleted: Successfully deleted file from storage: ${storagePath}`);
    } else {
      logger.error(`onStoryDeleted: Could not parse storage path from mediaUrl: ${mediaUrl}`);
    }
  } catch (error) {
    logger.error(`onStoryDeleted: Failed to delete media file from storage for story ${event.params.storyId}:`, error);
  }
});
