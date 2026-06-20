<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}

require_once dirname(__DIR__) . '/_private/db.php';

function backup_log(string $message): void
{
    fwrite(STDERR, '[' . date('Y-m-d H:i:s') . '] ' . $message . PHP_EOL);
}

function backup_ensure_jobs_table(PDO $pdo): void
{
    $pdo->exec(
        "CREATE TABLE IF NOT EXISTS photo_backup_jobs (
          id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
          display_url VARCHAR(512) NOT NULL,
          local_original_path VARCHAR(512) NOT NULL,
          local_display_path VARCHAR(512) NOT NULL DEFAULT '',
          remote_path VARCHAR(512) NOT NULL,
          status VARCHAR(16) NOT NULL DEFAULT 'pending',
          attempts INT NOT NULL DEFAULT 0,
          last_error TEXT NULL,
          created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
          updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          completed_at DATETIME NULL,
          PRIMARY KEY (id),
          KEY idx_status_attempts (status, attempts, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
    );
}

function backup_config(array $config, string $key, string $env, string $default = ''): string
{
    $value = getenv($env);
    if (is_string($value) && $value !== '') {
        return $value;
    }
    return (string) ($config[$key] ?? $default);
}

function backup_webdav_url(string $base, string $relative): string
{
    $parts = array_values(array_filter(explode('/', trim($relative, '/')), static fn ($part) => $part !== ''));
    return rtrim($base, '/') . '/' . implode('/', array_map('rawurlencode', $parts));
}

function backup_webdav_request(string $method, string $url, string $user, string $pass, ?string $filePath = null): array
{
    $ch = curl_init($url);
    $fh = null;
    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPAUTH => CURLAUTH_BASIC,
        CURLOPT_USERPWD => $user . ':' . $pass,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CONNECTTIMEOUT => 10,
        CURLOPT_TIMEOUT => 180,
        CURLOPT_HTTPHEADER => ['Expect:'],
    ]);
    if ($filePath !== null) {
        $fh = fopen($filePath, 'rb');
        if (!$fh) {
            throw new RuntimeException('open local original failed');
        }
        curl_setopt($ch, CURLOPT_UPLOAD, true);
        curl_setopt($ch, CURLOPT_INFILE, $fh);
        curl_setopt($ch, CURLOPT_INFILESIZE, filesize($filePath));
    }
    $body = curl_exec($ch);
    $errno = curl_errno($ch);
    $error = curl_error($ch);
    $status = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
    curl_close($ch);
    if (is_resource($fh)) {
        fclose($fh);
    }
    return ['status' => $status, 'errno' => $errno, 'error' => $error, 'body' => is_string($body) ? $body : ''];
}

function backup_ensure_remote_dirs(string $base, string $relative, string $user, string $pass): void
{
    $parts = array_values(array_filter(explode('/', trim($relative, '/')), static fn ($part) => $part !== ''));
    array_pop($parts);
    $current = '';
    foreach ($parts as $part) {
        $current .= ($current === '' ? '' : '/') . $part;
        $res = backup_webdav_request('MKCOL', backup_webdav_url($base, $current), $user, $pass);
        if (!in_array($res['status'], [200, 201, 204, 405], true)) {
            throw new RuntimeException('WebDAV MKCOL HTTP ' . $res['status'] . ' ' . $res['error']);
        }
    }
}

function backup_claim_jobs(PDO $pdo, int $batchSize, int $maxAttempts, int $retryDelayMinutes): array
{
    $batchSize = max(1, min(20, $batchSize));
    $retryDelayMinutes = max(1, min(1440, $retryDelayMinutes));
    $pdo->beginTransaction();
    $st = $pdo->prepare(
        "SELECT id, local_original_path, remote_path
         FROM photo_backup_jobs
         WHERE attempts < ?
           AND (
             status = 'pending'
             OR (status = 'failed' AND updated_at < DATE_SUB(NOW(), INTERVAL {$retryDelayMinutes} MINUTE))
             OR (status = 'processing' AND updated_at < DATE_SUB(NOW(), INTERVAL 15 MINUTE))
           )
         ORDER BY created_at ASC
         LIMIT {$batchSize}
         FOR UPDATE"
    );
    $st->execute([$maxAttempts]);
    $jobs = $st->fetchAll();
    if ($jobs) {
        $ids = array_map('intval', array_column($jobs, 'id'));
        $pdo->exec(
            'UPDATE photo_backup_jobs
             SET status = "processing", attempts = attempts + 1, updated_at = NOW()
             WHERE id IN (' . implode(',', $ids) . ')'
        );
    }
    $pdo->commit();
    return $jobs;
}

function backup_mark_done(PDO $pdo, int $id): void
{
    $st = $pdo->prepare(
        'UPDATE photo_backup_jobs
         SET status = "done", last_error = NULL, completed_at = NOW(), updated_at = NOW()
         WHERE id = ?'
    );
    $st->execute([$id]);
}

function backup_mark_failed(PDO $pdo, int $id, string $error): void
{
    $st = $pdo->prepare(
        'UPDATE photo_backup_jobs
         SET status = "failed", last_error = ?, updated_at = NOW()
         WHERE id = ?'
    );
    $st->execute([mb_substr($error, 0, 1000), $id]);
}

try {
    $pdo = db();
    $config = require dirname(__DIR__) . '/_private/config.php';
    backup_ensure_jobs_table($pdo);

    $base = backup_config($config, 'quark_webdav_base', 'QUARK_WEBDAV_BASE', 'http://127.0.0.1:5244/dav/quark/map-of-us-originals');
    $user = backup_config($config, 'quark_webdav_user', 'QUARK_WEBDAV_USER');
    $pass = backup_config($config, 'quark_webdav_pass', 'QUARK_WEBDAV_PASS');
    if ($user === '' || $pass === '') {
        throw new RuntimeException('missing WebDAV credentials');
    }

    $batchSize = (int) backup_config($config, 'photo_backup_batch_size', 'PHOTO_BACKUP_BATCH_SIZE', '5');
    $maxAttempts = (int) backup_config($config, 'photo_backup_max_attempts', 'PHOTO_BACKUP_MAX_ATTEMPTS', '1008');
    $retryDelayMinutes = (int) backup_config($config, 'photo_backup_retry_delay_minutes', 'PHOTO_BACKUP_RETRY_DELAY_MINUTES', '10');
    $jobs = backup_claim_jobs($pdo, $batchSize, max(1, $maxAttempts), $retryDelayMinutes);
    if (!$jobs) {
        backup_log('no pending photo backup jobs');
        exit(0);
    }

    foreach ($jobs as $job) {
        $id = (int) $job['id'];
        $local = (string) $job['local_original_path'];
        $remote = (string) $job['remote_path'];
        try {
            if (!is_file($local)) {
                throw new RuntimeException('local original missing');
            }
            backup_ensure_remote_dirs($base, $remote, $user, $pass);
            $res = backup_webdav_request('PUT', backup_webdav_url($base, $remote), $user, $pass, $local);
            if (!in_array($res['status'], [200, 201, 204], true)) {
                throw new RuntimeException('WebDAV PUT HTTP ' . $res['status'] . ' ' . $res['error']);
            }
            if (!@unlink($local)) {
                throw new RuntimeException('delete local original failed');
            }
            backup_mark_done($pdo, $id);
            backup_log('job ' . $id . ' done');
        } catch (Throwable $e) {
            backup_mark_failed($pdo, $id, $e->getMessage());
            backup_log('job ' . $id . ' failed: ' . $e->getMessage());
        }
    }
} catch (Throwable $e) {
    backup_log('worker failed: ' . $e->getMessage());
    exit(1);
}
