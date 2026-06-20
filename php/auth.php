<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/_private/db.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function fail(string $msg, int $code = 400): void
{
    http_response_code($code);
    echo json_encode(['error' => 'auth_error', 'message' => $msg], JSON_UNESCAPED_UNICODE);
    exit;
}

function auth_webdav_url(array $config, string $relative): string
{
    $base = rtrim((string) ($config['quark_webdav_base'] ?? ''), '/');
    if ($base === '') {
        return '';
    }
    $parts = array_values(array_filter(explode('/', trim($relative, '/')), static fn ($part) => $part !== ''));
    return $base . '/' . implode('/', array_map('rawurlencode', $parts));
}

function auth_delete_webdav_file(array $config, string $remotePath): void
{
    $user = (string) ($config['quark_webdav_user'] ?? '');
    $pass = (string) ($config['quark_webdav_pass'] ?? '');
    $url = auth_webdav_url($config, $remotePath);
    if ($user === '' || $pass === '' || $url === '') {
        return;
    }
    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST => 'DELETE',
        CURLOPT_HTTPAUTH => CURLAUTH_BASIC,
        CURLOPT_USERPWD => $user . ':' . $pass,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CONNECTTIMEOUT => 5,
        CURLOPT_TIMEOUT => 20,
        CURLOPT_HTTPHEADER => ['Expect:'],
    ]);
    curl_exec($ch);
    curl_close($ch);
}

function cleanup_avatar_backup(PDO $pdo, array $config, string $avatarUrl): void
{
    if ($avatarUrl === '') {
        return;
    }
    try {
        $exists = $pdo->query("SHOW TABLES LIKE 'photo_backup_jobs'")->fetchColumn();
        if (!$exists) {
            return;
        }
        $st = $pdo->prepare(
            'SELECT id, local_original_path, remote_path
             FROM photo_backup_jobs
             WHERE display_url = ?'
        );
        $st->execute([$avatarUrl]);
        $rows = $st->fetchAll();
        foreach ($rows as $row) {
            $local = (string) ($row['local_original_path'] ?? '');
            $remote = (string) ($row['remote_path'] ?? '');
            if ($local !== '' && is_file($local)) {
                @unlink($local);
            }
            if ($remote !== '') {
                auth_delete_webdav_file($config, $remote);
            }
        }
        if ($rows) {
            $delete = $pdo->prepare('DELETE FROM photo_backup_jobs WHERE display_url = ?');
            $delete->execute([$avatarUrl]);
        }
    } catch (Throwable $e) {
        error_log('cleanup_avatar_backup failed: ' . $e->getMessage());
    }
}

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        fail('method_not_allowed', 405);
    }

    $body = json_decode((string) file_get_contents('php://input'), true) ?: [];
    $code = isset($body['code']) ? trim((string) $body['code']) : '';
    if ($code === '') {
        fail('missing code');
    }

    $config = require dirname(__DIR__) . '/_private/config.php';
    $appid = $config['wx_appid'] ?? '';
    $secret = $config['wx_secret'] ?? '';
    if ($appid === '' || $secret === '') {
        fail('server not configured', 500);
    }

    $url = 'https://api.weixin.qq.com/sns/jscode2session?' . http_build_query([
        'appid' => $appid,
        'secret' => $secret,
        'js_code' => $code,
        'grant_type' => 'authorization_code',
    ]);

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
        CURLOPT_SSL_VERIFYPEER => true,
    ]);
    $resp = curl_exec($ch);
    if ($resp === false) {
        fail('wechat request failed: ' . curl_error($ch), 502);
    }
    curl_close($ch);

    $data = json_decode((string) $resp, true) ?: [];
    if (!empty($data['errcode'])) {
        fail('wechat: ' . ($data['errmsg'] ?? 'unknown') . ' (' . $data['errcode'] . ')', 502);
    }
    $openid = $data['openid'] ?? '';
    if ($openid === '') {
        fail('no openid returned', 502);
    }

    // 可选：客户端带上昵称/头像（getUserProfile 或头像昵称填写）
    $nickname = isset($body['nickname']) ? mb_substr(trim((string) $body['nickname']), 0, 64) : '';
    $avatar = isset($body['avatarUrl']) ? mb_substr(trim((string) $body['avatarUrl']), 0, 512) : '';

    $pdo = db();
    $stmt = $pdo->prepare(
        'INSERT INTO app_users (openid, nickname, avatar_url) VALUES (:o, :n, :a)
         ON DUPLICATE KEY UPDATE
            nickname = IF(VALUES(nickname) = \'\', nickname, VALUES(nickname)),
            avatar_url = IF(VALUES(avatar_url) = \'\', avatar_url, VALUES(avatar_url))'
    );
    $stmt->execute([':o' => $openid, ':n' => $nickname, ':a' => $avatar]);
    cleanup_avatar_backup($pdo, $config, $avatar);

    $row = $pdo->prepare('SELECT openid, nickname, avatar_url, is_admin FROM app_users WHERE openid = ?');
    $row->execute([$openid]);
    $user = $row->fetch();

    echo json_encode([
        'openid' => $user['openid'],
        'nickname' => $user['nickname'],
        'avatarUrl' => $user['avatar_url'],
        'isAdmin' => (int) ($user['is_admin'] ?? 0) === 1,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['error' => 'server_error', 'message' => 'auth failed'], JSON_UNESCAPED_UNICODE);
}
