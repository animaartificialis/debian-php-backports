<?php
// A small HTTP server for the reproducers. It runs as its own PHP process, answers
// each connection with the next prepared response and reports every request it got.
//
//   $server = http_capture_start($port, array($response1, $response2, ...));
//   ... file_get_contents("http://127.0.0.1:$port/", ...) ...
//   $requests = http_capture_stop($server);   // array of raw request heads
//
// In a response, {PORT} is replaced with the server's own port. Pick ports below 32768:
// higher ones are in Linux's range for outgoing connections and can be taken.

function http_capture_start($port, array $responses)
{
    // The port can still be busy: the server of the case before waits up to 10 seconds
    // for a connection that may never come. So keep trying for a while.
    for ($try = 1; ; $try++) {
        $cmd = escapeshellarg(PHP_BINARY) . ' -n ' . escapeshellarg(__FILE__) . ' http_capture_server '
            . (int) $port . ' ' . escapeshellarg(base64_encode(serialize($responses)));
        $process = proc_open($cmd, array(0 => array('pipe', 'r'), 1 => array('pipe', 'w'), 2 => STDERR), $pipes);
        if (!is_resource($process)) {
            throw new Exception('cannot start the HTTP server');
        }
        $line = fgets($pipes[1]);
        if (trim($line) === 'READY') {
            return array($process, $pipes);
        }
        // PHP prints a warning after an empty line, so read all of the output.
        $line = trim($line . stream_get_contents($pipes[1]));
        fclose($pipes[0]);
        fclose($pipes[1]);
        proc_close($process);
        if ($try >= 15) {
            throw new Exception("HTTP server did not start: $line");
        }
        sleep(1);
    }
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
