<?php
declare(strict_types=1);

return [
    'wx_appid' => 'your-wechat-mini-program-appid',
    'wx_secret' => 'your-wechat-mini-program-secret',
    'amap_key' => 'your-amap-web-service-key',
    'admin_user' => 'admin',
    'admin_pass_hash' => password_hash('change-this-password', PASSWORD_DEFAULT),
    'upload_dir' => '/www/wwwroot/example.com/uploads',
    'upload_base' => '/uploads',
    'upload_original_max_mb' => 30,
    'upload_display_max_side' => 1600,
    'upload_display_jpeg_quality' => 82,
    'quark_webdav_base' => 'http://openlist:5244/dav/quark/map-of-us-originals',
    'quark_webdav_user' => 'openlist-user',
    'quark_webdav_pass' => 'openlist-password',
    'photo_backup_batch_size' => 5,
    'photo_backup_max_attempts' => 1008,
    'photo_backup_retry_delay_minutes' => 10,
];
