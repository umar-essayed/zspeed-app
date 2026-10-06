<?php
// Define your app store URLs
$android_url = "https://play.google.com/store/apps/details?id=com.zspeed.app";
$ios_url = "https://apps.apple.com/us/app/zspeed/id6761904689";

// Get user agent
$user_agent = isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : '';
$user_agent_lower = strtolower($user_agent);

// Check for iOS devices (more comprehensive detection)
$is_ios = false;
if (!empty($user_agent_lower)) {
    // Check for iOS device names
    if (strpos($user_agent_lower, 'iphone') !== false || 
        strpos($user_agent_lower, 'ipad') !== false || 
        strpos($user_agent_lower, 'ipod') !== false) {
        $is_ios = true;
    }
    // Check for iOS in user agent (some browsers include this)
    elseif (strpos($user_agent_lower, 'ios') !== false && strpos($user_agent_lower, 'like mac os x') !== false) {
        $is_ios = true;
    }
    // Check for Safari on iOS (common pattern)
    elseif (strpos($user_agent_lower, 'safari') !== false && strpos($user_agent_lower, 'mobile') !== false && strpos($user_agent_lower, 'like mac os x') !== false) {
        $is_ios = true;
    }
}

if ($is_ios) {
    header("HTTP/1.1 302 Found");
    header("Location: $ios_url");
    exit;
}

// Check for Android devices
if (strpos($user_agent_lower, 'android') !== false) {
    header("HTTP/1.1 302 Found");
    header("Location: $android_url");
    exit;
}

// Default redirect (if OS is not detected) - redirect to local APK file
header("HTTP/1.1 302 Found");
header("Location: ./app.apk");
exit;
?>
