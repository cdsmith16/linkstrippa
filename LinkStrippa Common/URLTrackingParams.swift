import Foundation

public struct URLTrackingParams {
    // Known tracking parameters to remove
    static let trackingParams = [
        // UTM & general analytics
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
        "_ga", "_gl", "_gid", "gclid", "dclid", "msclkid", "yclid",

        // Facebook/Meta
        "fbclid", "fb_action_ids", "fb_action_types", "fb_source",
        "action_object_map", "action_type_map", "action_ref_map", "fb_ref", "fb_sig", "fref",

        // Twitter/X, TikTok, Instagram
        "twclid", "ttclid", "igshid", "ig_cache_key", "ig_rid", "ig_mid",
        "xid", "s", "t", "si", "st", "smid",

        // LinkedIn
        "li_fat_id",

        // Microsoft Ads / Yahoo / Bing
        "ocid", "bclid", "rb_clickid",

        // Marketing platforms
        "mc_cid", "mc_eid", "_hsenc", "_hsmi", "mkt_tok",
        "elqTrackId", "elqTrack", "trk_contact", "trk_msg", "trk_module", "trk_sid",

        // Piwik / Matomo
        "pk_campaign", "pk_kwd", "pk_source", "pk_medium", "pk_content", "pk_cpm",

        // Affiliate & Ad Networks
        "clickid", "adid", "adgroupid", "campaignid", "creative", "matchtype",
        "network", "placement", "device", "keyword", "adposition", "s_kwcid",
        "aff_id", "aff_sub", "aff_sub2", "aff_sub3", "aff_sub4", "aff_sub5",
        "affiliate_id", "utm_affiliate", "irgwc", "irclickid", "irsid",
        "tag", "ascsubtag", "cjevent", "impactclkid", "cmpid", "mkwid", "mktid", "mkcid", "mktsrc", "mkevt", "mkrid",
        "u1", "u2", "u3", "u4", "u5",

        // AMP / redirect / click layers
        "amp", "amp_js_v", "amp_gsa", "amp_r", "amp_lite", "ampcachebust", "ampcid",
        "redirect", "redirect_uri", "redirect_log_mongo_id", "redirect_mongo_id",
        "ref", "ref_src", "ref_url", "source", "src", "from", "via", "r", "rtd", "original_referer",

        // iMessage / deep link / share clutter
        "is_copy_url", "entry_point", "share_id", "share_token", "share_link_id",
        "sender_device", "sender_web_id", "session_id", "session_key",
        "click_time", "shortlink", "deep_link_id", "app_id",

        // Shopify / content platforms
        "vercelAnalytics", "page", "position", "feeditemid",

        // Newsletter / personalization trackers
        "vero_conv", "vero_id", "ga_source", "ga_medium", "ga_term", "ga_content", "ga_campaign",
        "sc_campaign", "sc_channel", "sc_content", "sc_medium", "sc_outcome", "sc_geo", "sc_country", "sc_device",

        // Navigation noise
        "usp", "dti", "ns_mchannel", "ns_source", "ns_campaign", "ns_linkname", "ns_fee",
        "ei", "ved", "ct", "icid", "hash"
    ]
    
    // Utility method to clean a URL
    public static func cleanURL(_ urlString: String) -> (original: String, cleaned: String, paramsRemoved: Int)? {
        guard var urlComponents = URLComponents(string: urlString) else {
            return nil
        }
        
        let originalURL = urlString
        var removedCount = 0
        
        if var queryItems = urlComponents.queryItems {
            queryItems.removeAll { item in
                let shouldRemove = trackingParams.contains(item.name.lowercased())
                if shouldRemove {
                    removedCount += 1
                }
                return shouldRemove
            }
            
            urlComponents.queryItems = queryItems.isEmpty ? nil : queryItems
        }
        
        guard let cleanURL = urlComponents.url?.absoluteString else {
            return nil
        }
        
        return (originalURL, cleanURL, removedCount)
    }
}
