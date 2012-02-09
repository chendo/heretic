import subprocess
from select import select
import json
import thread
import time


class Heretic:
    def __init__(self):
        self.process = subprocess.Popen(['ruby', '../bin/heretic_listener.rb'], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        # thread.start_new_thread(self.read_loop, ())


    def eval(self, code):
        message = {
            'op': 'eval',
            'code': code
        }
        return self.send(message)
        data = self.process.stdout.readline()
        return self.parse_and_handle(data)

    def send(self, message):
        self.write_to_pipe(json.dumps(message))
        data = self.process.stdout.readline()
        return self.parse_and_handle(data)

    def write_to_pipe(self, data):
        self.process.stdin.write(data + "\n")
        self.process.stdin.flush()

    def read_loop(self):
        while True:
            select([self.process.stdout], [], [])
            data = self.process.stdout.readline()
            self.parse_and_handle(data)


    def parse_and_handle(self, data):
        message = json.loads(data)
        if message['op'] == 'return':
            value = message['object']
            if (type(value) is dict) and ('__object_proxy_id' in value):
                obj = RubyObjectProxy(value, self)
                return obj
            return value


class RubyObjectProxy:
    def __init__(self, data, bridge):
        self.ruby_object_proxy_id = data['__object_proxy_id']
        self.bridge = bridge

    def __str__(self):
        return "<RubyObjectProxy:" + str(self.ruby_object_proxy_id) + ">"

    def __getattr__(self, method_name):
        # Return a lambda/block that calls the object on the other side
        def call_method(*args, **kwargs):
            message = {
                'op': 'call',
                'object_proxy_id': self.ruby_object_proxy_id,
                'method_name': method_name,
                'args': args,
            }
            # FIXME: We need to handle serialising RubyObjectProxies too
            return self.bridge.send(message)

        return call_method


bridge = Heretic()
time = bridge.eval('Time')

print time.now().to_s()
print time.now().to_i()

import atexit
atexit.register(bridge.process.kill)

import timeit
#timer = timeit.Timer("bridge.eval(\"[Time.now]\")", "from __main__ import bridge")
#print timer.timeit(1000)

