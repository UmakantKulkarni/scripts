#!/usr/bin/env python3
from http.server import BaseHTTPRequestHandler, HTTPServer
import os
import json
import glob


class S(BaseHTTPRequestHandler):
    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_GET(self):
        json_str = json.dumps({"started": "yes"})
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json_str.encode(encoding='utf_8'))

    def do_HEAD(self):
        self._set_headers()

    def do_POST(self):
        self.data_string = self.rfile.read(int(self.headers['Content-Length']))

        json_str = json.dumps({"started": "yes"})
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json_str.encode(encoding='utf_8'))

        data = json.loads(self.data_string)
        numSession = data['numSessions']
        expDir = data['expDir']
        subExpDir = data['subExpDir']
        os.makedirs("/opt/Experiments/", exist_ok=True)
        os.makedirs("/opt/Experiments/{}/".format(expDir), exist_ok=True)
        os.makedirs("/opt/Experiments/{}/{}/".format(expDir,
                    subExpDir), exist_ok=True)
        edir = "/opt/Experiments/{}/{}".format(expDir, subExpDir)
        dirFiles = glob.glob('{}/*'.format(edir))
        for fl in dirFiles:
            os.remove(fl)

        cmd = "/opt/scripts/startUeCalls.sh {} {}".format(numSession, edir)
        os.system("cd {} && {} > /dev/null 2>&1 &".format(edir, cmd))

        return


def run(server_class=HTTPServer, handler_class=S, port=15692):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print('Starting httpd...')
    httpd.serve_forever()


if __name__ == "__main__":
    from sys import argv

if len(argv) == 2:
    run(port=int(argv[1]))
else:
    run()