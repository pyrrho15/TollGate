package com.tollgate.app.blocker

/**
 * A short-form surface we know how to detect.
 *
 * Detection is based on *view id markers* rather than visible text on purpose: resource
 * ids are language independent and structural, whereas strings like "Shorts" change per
 * locale and per release. Markers are matched against the suffix after the final '/'
 * (e.g. `com.google.android.youtube:id/reel_recycler` -> `reel_recycler`).
 */
data class TargetApp(
    val id: String,
    val displayName: String,
    val packageName: String,
    val description: String,
    /** If any suffix contains one of these, the full-screen player is probably on screen. */
    val playerViewIdMarkers: List<String>,
    /** If a suffix contains one of these we are looking at a shelf/preview, not the player. */
    val excludedViewIdMarkers: List<String> = emptyList(),
)

object SupportedTargets {

    val all: List<TargetApp> = listOf(
        TargetApp(
            id = "youtube_shorts",
            displayName = "YouTube Shorts",
            packageName = "com.google.android.youtube",
            description = "Blocks the immersive Shorts player. Normal videos, search and subscriptions keep working.",
            playerViewIdMarkers = listOf(
                "reel_watch_fragment_root",
                "reel_recycler",
                "reel_player_page_container",
                "reel_watch_player",
                "shorts_video_pager",
            ),
            // Shelves in the home feed also contain "reel"; never treat those as the player.
            excludedViewIdMarkers = listOf("shorts_shelf", "reel_shelf"),
        ),
        TargetApp(
            id = "instagram_reels",
            displayName = "Instagram Reels",
            packageName = "com.instagram.android",
            description = "Blocks the Reels tab and the full-screen Reels viewer. DMs, feed and stories keep working.",
            playerViewIdMarkers = listOf(
                "clips_viewer_view_pager",
                "clips_viewer",
                "clips_pager",
                "reel_viewer",
                "reel_recycler",
            ),
        ),
    )

    val packageNames: List<String> = all.map { it.packageName }

    fun forPackage(packageName: String): TargetApp? =
        all.firstOrNull { it.packageName == packageName }

    fun byId(id: String): TargetApp? = all.firstOrNull { it.id == id }
}
