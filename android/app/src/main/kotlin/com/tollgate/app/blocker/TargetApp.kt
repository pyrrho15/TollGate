package com.tollgate.app.blocker

/**
 * A screen-region signature: a node of one of [classNames] that covers at least the
 * given fraction of the screen, optionally scrollable/long-clickable, optionally
 * containing (at any depth) a [descendant] that matches too.
 *
 * Used for apps that expose no usable view ids, where the shape of the layout is the
 * only stable signal — Facebook's Reels viewer, for instance, is a huge scrollable
 * list item holding a long-clickable video surface.
 */
data class StructureRule(
    val classNames: Set<String>,
    val minWidthFraction: Float,
    val minHeightFraction: Float,
    val requireScrollable: Boolean = false,
    val requireLongClickable: Boolean = false,
    val descendant: StructureRule? = null,
)

/**
 * A short-form surface we know how to detect.
 *
 * Detection is based on *view id markers* rather than visible text on purpose: resource
 * ids are language independent and structural, whereas strings like "Shorts" change per
 * locale and per release. Markers are matched against the suffix after the final '/'
 * (e.g. `com.google.android.youtube:id/reel_recycler` -> `reel_recycler`).
 *
 * Some apps (Facebook) expose no dependable ids at all. For those, [contentDescriptions],
 * [contentDescriptionPrefixes] and [structure] provide fallbacks; a target is blocked
 * when *any* of its rules match.
 */
data class TargetApp(
    val id: String,
    val displayName: String,
    val packageNames: List<String>,
    val description: String,
    /** If any suffix contains one of these, the full-screen player is probably on screen. */
    val playerViewIdMarkers: List<String> = emptyList(),
    /** If a suffix contains one of these we are looking at a shelf/preview, not the player. */
    val excludedViewIdMarkers: List<String> = emptyList(),
    /** Exact (case-insensitive) accessibility labels that only appear in the player. */
    val contentDescriptions: Set<String> = emptySet(),
    /** Accessibility labels that *start with* one of these (e.g. "Reels, tab 2 of 6"). */
    val contentDescriptionPrefixes: Set<String> = emptySet(),
    /** When true, a prefix match also requires the node to be the selected tab. */
    val requireSelectedForPrefix: Boolean = false,
    /** Last-resort structural signature for apps without stable ids. */
    val structure: StructureRule? = null,
) {
    /** The primary package, kept for callers that only need one. */
    val packageName: String get() = packageNames.first()
}

object SupportedTargets {

    val all: List<TargetApp> = listOf(
        TargetApp(
            id = "youtube_shorts",
            displayName = "YouTube Shorts",
            packageNames = listOf("com.google.android.youtube"),
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
            packageNames = listOf("com.instagram.android"),
            description = "Blocks the Reels tab and the full-screen Reels viewer. DMs, feed and stories keep working.",
            playerViewIdMarkers = listOf(
                "clips_viewer_view_pager",
                "clips_viewer",
                "clips_pager",
                "reel_viewer",
                "reel_recycler",
            ),
        ),
        TargetApp(
            id = "facebook_reels",
            displayName = "Facebook Reels",
            // "katana" is the main Facebook app. Facebook Lite is a different tree entirely.
            packageNames = listOf("com.facebook.katana"),
            description = "Blocks the full-screen Reels player. Feed, Groups, Marketplace and Messenger keep working.",
            // 1. A Reel opened from the feed still exposes one of these composer labels.
            contentDescriptions = setOf(
                "FbShortsComposerAttachmentComponentSpec_STICKER",
                "FbShortsComposerAttachmentComponentSpec_GIF",
            ),
            // 2. The Reels tab is the selected tab whose label starts with this.
            contentDescriptionPrefixes = setOf("Reels,"),
            requireSelectedForPrefix = true,
            // 3. Fallback: a full-screen scrollable list item whose long-clickable video
            //    surface fills the screen. Survives label and id changes.
            structure = StructureRule(
                classNames = setOf("androidx.recyclerview.widget.RecyclerView"),
                minWidthFraction = 0.9f,
                minHeightFraction = 0.75f,
                requireScrollable = true,
                descendant = StructureRule(
                    classNames = setOf("android.widget.Button"),
                    minWidthFraction = 0.9f,
                    minHeightFraction = 0.75f,
                    requireLongClickable = true,
                    descendant = StructureRule(
                        classNames = setOf("android.view.SurfaceView"),
                        minWidthFraction = 0.9f,
                        minHeightFraction = 0.75f,
                    ),
                ),
            ),
        ),
        TargetApp(
            id = "tiktok",
            displayName = "TikTok",
            // Global, older global, Douyin, and TikTok Lite.
            packageNames = listOf(
                "com.zhiliaoapp.musically",
                "com.ss.android.ugc.trill",
                "com.ss.android.ugc.aweme",
                "com.zhiliaoapp.musically.go",
            ),
            // TikTok is short video end to end, so the whole app is the "feed": the video
            // player view is on screen whenever the app is usable.
            description = "TikTok is short video start to finish, so opening it sends you straight back out.",
            playerViewIdMarkers = listOf(
                "player_view",
                "simplayer_api_player_view",
            ),
        ),
    )

    val packageNames: List<String> = all.flatMap { it.packageNames }

    fun forPackage(packageName: String): TargetApp? =
        all.firstOrNull { packageName in it.packageNames }

    fun byId(id: String): TargetApp? = all.firstOrNull { it.id == id }
}
