<?php
// A small HTTP server for the reproducers. It runs as its own PHP process, answers
// each connection with the next prepared response and reports every request it got.
//
//   $server = http_capture_start($port, array($response1, $response2, ...));
//   ... file_get_contents("http://127.0.0.1:$port/", ...) ...
//   $requests = http_capture_stop($server);   // array of raw request heads
//
// In a response, {PORT} is replaced with the server's own port.

function http_capture_start($port, array $responses)
{
    $cmd = escapeshellarg(PHP_BINARY) . ' -n ' . escapeshellarg(__FILE__) . ' http_capture_server '
        . (int) $port . ' ' . escapeshellarg(base64_encode(serialize($responses)));
    $process = proc_open($cmd, array(0 => array('pipe', 'r'), 1 => array('pipe', 'w'), 2 => STDERR), $pipes);
    if (!is_resource($process)) {
        throw new Exception('cannot start the HTTP server');
    }
    $line = fgets($pipes[1]);
    if (trim($line) !== 'READY') {
        throw new Exception("HTTP server did not start: $line");
    }
    return array($process, $pipes);
}

function http_capture_stop(array $server)
{
    list($process, $pipes) = $server;
    fclose($pipes[0]);
    $requests = array();
    // The server stops after its last response or after a timeout.
    while (($line = fgets($pipes[1])) !== false) {
        if (strpos($line, 'REQUEST ') === 0) {
            $requests[] = base64_decode(trim(substr($line, 8)));
        }
    }
    fclose($pipes[1]);
    proc_close($process);
    return $requests;
}

function http_capture_server($port, array $responses)
{
    $server = stream_socket_server("tcp://127.0.0.1:$port", $errno, $errstr);
    if (!$server) {
        echo "ERROR $errstr\n";
        exit(1);
    }
    echo "READY\n";
    foreach ($responses as $response) {
        $conn = @stream_socket_accept($server, 10);
        if (!$conn) {
            break;
        }
        stream_set_timeout($conn, 10);
        $request = '';
        while (strpos($request, "\r\n\r\n") === false && !feof($conn)) {
            $chunk = fread($conn, 8192);
            if ($chunk === false || $chunk === '') {
                $info = stream_get_meta_data($conn);
                if ($info['timed_out']) {
                    break;
                }
                continue;
            }
            $request .= $chunk;
        }
        echo 'REQUEST ', base64_encode($request), "\n";
        fwrite($conn, str_replace('{PORT}', $port, $response));
        fclose($conn);
    }
    fclose($server);
}

if (isset($argv[1]) && $argv[1] === 'http_capture_server') {
    http_capture_server((int) $argv[2], unserialize(base64_decode($argv[3])));
    exit(0);
}
